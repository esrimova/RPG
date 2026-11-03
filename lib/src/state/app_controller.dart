import 'dart:async';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../data/local_store.dart';
import '../data/remote_store.dart';
import '../domain/apply.dart';
import '../domain/models.dart';
import '../domain/quests.dart' show dateKey;

/// Where a running push is: [done] of [total] operations resolved.
class PushProgress {
  final int done;
  final int total;
  final bool running;
  const PushProgress({this.done = 0, this.total = 0, this.running = false});
}

class AppState {
  final bool loaded;
  final Snapshot base; // last known repository content (or local data when offline-only)
  final List<Operation> ops; // changes not yet confirmed by GitHub
  final Snapshot view; // base + pending ops: what the UI shows
  final GithubConfig github;
  final bool syncing; // true while pulling or pushing
  final DateTime? lastSync;
  final String? notice; // last problem worth telling the user about
  final ConnectionReport? connection;
  final PushProgress push;
  final List<PushLogEntry> pushLog; // newest first, at most 50

  const AppState({
    this.loaded = false,
    this.base = Snapshot.empty,
    this.ops = const [],
    this.view = Snapshot.empty,
    this.github = const GithubConfig(),
    this.syncing = false,
    this.lastSync,
    this.notice,
    this.connection,
    this.push = const PushProgress(),
    this.pushLog = const [],
  });

  bool get hasPending => ops.isNotEmpty;
  int get pendingCount => ops.length;

  AppState copyWith({
    bool? loaded,
    Snapshot? base,
    List<Operation>? ops,
    GithubConfig? github,
    bool? syncing,
    DateTime? lastSync,
    String? notice,
    bool clearNotice = false,
    ConnectionReport? connection,
    PushProgress? push,
    List<PushLogEntry>? pushLog,
  }) {
    final b = base ?? this.base;
    final o = ops ?? this.ops;
    return AppState(
      loaded: loaded ?? this.loaded,
      base: b,
      ops: o,
      view: (base != null || ops != null) ? applyAll(b, o) : view,
      github: github ?? this.github,
      syncing: syncing ?? this.syncing,
      lastSync: lastSync ?? this.lastSync,
      notice: clearNotice ? null : (notice ?? this.notice),
      connection: connection ?? this.connection,
      push: push ?? this.push,
      pushLog: pushLog ?? this.pushLog,
    );
  }
}

typedef RemoteFactory = RemoteStore Function(GithubConfig config);

class AppController extends StateNotifier<AppState> {
  AppController(
    this._local,
    this._remoteFactory, {
    this.pollDelays = const [2, 3, 4, 5, 6, 8, 8, 8, 8, 8, 8, 8, 8, 8, 8, 8, 8, 8, 8, 8],
    this.pollUnit = const Duration(seconds: 1),
  }) : super(const AppState());

  static const maxPushLog = 50;

  final LocalStore _local;
  final RemoteFactory _remoteFactory;
  final List<int> pollDelays;
  final Duration pollUnit;
  bool _pushing = false;
  Future<void>? _pulling;
  int _idCounter = 0;

  String newId([String prefix = 'id']) =>
      '${prefix}_${DateTime.now().microsecondsSinceEpoch.toRadixString(36)}${(_idCounter++).toRadixString(36)}';

  /// Loads local data. When GitHub is connected it pulls (read-only); it never pushes.
  Future<void> init() async {
    final gh = await _local.loadGithub();
    final base = _local.loadBase();
    final ops = _local.loadOps();
    state = state.copyWith(
        loaded: true, base: base, ops: ops, github: gh, lastSync: _local.loadLastSync(), pushLog: _local.loadPushLog());
    if (gh.isConfigured) _pulling = _launchPull();
  }

  Future<void> _launchPull() async {
    state = state.copyWith(syncing: true);
    try {
      await _pull();
    } on RemoteException catch (e) {
      state = state.copyWith(notice: e.message);
    } finally {
      _pulling = null;
      if (!_pushing) state = state.copyWith(syncing: false);
    }
  }

  RemoteStore get _remote => _remoteFactory(state.github);

  // ---- writing ------------------------------------------------------

  /// Applies [op] to the view right away. Local-only: saved on the device.
  /// Connected: queued until the user presses push; nothing is sent here.
  Future<OpResult> submit(Operation op) async {
    final r = applyOperation(state.view, op);
    if (!r.ok) return OpResult(OpOutcome.rejected, r.error!);

    // Update state synchronously (before any await) so concurrent submits see
    // each other's changes; persist afterwards.
    if (!state.github.isConfigured) {
      state = state.copyWith(base: r.snapshot);
      await _local.saveBase(r.snapshot);
      return const OpResult(OpOutcome.success, 'Saved on this device (GitHub not connected).');
    }
    state = state.copyWith(ops: [...state.ops, op], clearNotice: true);
    await _local.saveOps(state.ops);
    return const OpResult(OpOutcome.success, 'Saved - waiting for push');
  }

  Operation _op(OpAction a, EntityType t, String id, Map<String, dynamic> payload) {
    final now = DateTime.now();
    return Operation(
      id: newId('op'),
      action: a,
      type: t,
      entityId: id,
      payload: payload,
      createdAt: now,
      localDate: dateKey(now),
    );
  }

  Future<OpResult> saveBranch(Branch b, {required bool isNew}) =>
      submit(_op(isNew ? OpAction.create : OpAction.update, EntityType.branch, b.id, b.toJson()));
  Future<OpResult> deleteBranch(String id) => submit(_op(OpAction.delete, EntityType.branch, id, {'id': id}));
  Future<OpResult> saveActivity(Activity a, {required bool isNew}) =>
      submit(_op(isNew ? OpAction.create : OpAction.update, EntityType.activity, a.id, a.toJson()));
  Future<OpResult> deleteActivity(String id) => submit(_op(OpAction.delete, EntityType.activity, id, {'id': id}));
  Future<OpResult> addRecord(Record r) => submit(_op(OpAction.create, EntityType.record, r.id, r.toJson()));
  Future<OpResult> deleteRecord(String id) => submit(_op(OpAction.delete, EntityType.record, id, {'id': id}));

  // ---- pushing ------------------------------------------------------

  /// Kept for the UI until it calls [pushNow] directly. Pushes; with nothing
  /// to push it only refreshes from GitHub.
  Future<void> syncNow() async {
    if (!state.github.isConfigured || _pushing) return;
    if (state.ops.isNotEmpty) {
      await pushNow();
      return;
    }
    final pulling = _pulling;
    if (pulling != null) return pulling;
    _pulling = _launchPull();
    await _pulling;
  }

  /// Sends every pending operation to GitHub, in order, in batches. Returns
  /// the log entry, or null when nothing is pending, GitHub is not connected,
  /// or a push is already running.
  Future<PushLogEntry?> pushNow() async {
    if (_pushing || !state.github.isConfigured || state.ops.isEmpty) return null;
    _pushing = true;
    state = state.copyWith(syncing: true);
    final cfg = state.github;
    final handled = <String>{}; // operations sent or checked in this push
    var succeeded = 0, rejected = 0, failed = 0, done = 0, total = 0;
    final reasons = <String>[];
    String? stopNotice;
    var canPull = true;
    try {
      final pulling = _pulling;
      if (pulling != null) await pulling;
      if (!identical(state.github, cfg) || state.ops.isEmpty) return null;

      // Only what is queued now goes out; changes made meanwhile wait for the next push.
      final work = _coalesce(state.base, state.ops);
      state = state.copyWith(ops: work);
      await _local.saveOps(state.ops);
      final ids = [for (final o in work) o.id];
      final sentBefore = {for (final o in work) if (o.dispatched) o.id};
      final resent = <String>{};
      total = ids.length;
      state = state.copyWith(push: PushProgress(done: 0, total: total, running: true));
      final remote = _remoteFactory(cfg);

      try {
        for (var i = 0; i < ids.length; i++) {
          if (!identical(state.github, cfg)) {
            canPull = false; // disconnected meanwhile: stop here
            break;
          }
          var op = _find(ids[i]);
          if (op == null) continue;
          var freshBatch = false;
          if (!op.dispatched) {
            final batch = RemoteStore.chunk(_run(ids, i, (o) => !o.dispatched)).first;
            await remote.dispatchBatch(batch);
            handled.addAll(batch.map((o) => o.id));
            await _markDispatched({for (final o in batch) o.id}, cfg);
            op = _find(ids[i]) ?? op;
            freshBatch = true;
          } else {
            handled.add(op.id);
          }
          // The first operation of a batch just sent waits for the workflow; the
          // rest of it (and operations sent by an earlier push) are checked at once.
          var res = await _awaitResult(remote, op.id, checkFirst: !freshBatch);
          if (res.outcome == OpOutcome.pending && sentBefore.contains(op.id) && !resent.contains(op.id)) {
            // Sent by an earlier push and still no status file after the usual
            // wait: resend it, with the following ones in the same situation.
            // The workflow skips an operation id that already has a status, so
            // nothing is applied twice.
            final batch = RemoteStore.chunk(
                    _run(ids, i, (o) => o.dispatched && sentBefore.contains(o.id) && !resent.contains(o.id)))
                .first;
            await remote.dispatchBatch(batch);
            resent.addAll(batch.map((o) => o.id));
            res = await _awaitResult(remote, op.id);
          }
          if (!identical(state.github, cfg)) {
            canPull = false; // disconnected while waiting: leave local data alone
            break;
          }
          if (res.outcome == OpOutcome.pending) {
            stopNotice = 'GitHub has not finished yet; ${ids.length - done} change(s) stay queued for the next push.';
            break;
          }
          switch (res.outcome) {
            case OpOutcome.success:
              succeeded++;
            case OpOutcome.rejected:
              rejected++;
              reasons.add(res.message);
            case OpOutcome.failed:
              failed++;
              reasons.add(res.message);
            case OpOutcome.pending:
              break;
          }
          done++;
          await _resolve(op, res, PushProgress(done: done, total: total, running: true), cfg);
        }
      } on RemoteException catch (e) {
        // Offline or GitHub refused: unsent operations stay queued (not marked
        // dispatched); confirmed ones are already folded into the base.
        stopNotice = e.message;
        canPull = false;
      }

      if (canPull && identical(state.github, cfg)) {
        try {
          await _pull();
        } on RemoteException catch (e) {
          stopNotice ??= e.message;
        }
      }
      final entry = PushLogEntry(
          time: DateTime.now(), sent: handled.length, succeeded: succeeded, rejected: rejected, failed: failed);
      final log = [entry, ...state.pushLog].take(maxPushLog).toList();
      await _local.savePushLog(log);
      final notice = [
        if (reasons.length == 1) 'Change was not saved: ${reasons.single}',
        if (reasons.length > 1) '${reasons.length} changes were not saved: ${reasons.toSet().take(3).join('; ')}',
        ?stopNotice,
      ].join(' ');
      state = state.copyWith(pushLog: log, notice: notice.isEmpty ? null : notice);
      return entry;
    } finally {
      _pushing = false;
      state = state.copyWith(syncing: false, push: PushProgress(done: done, total: total, running: false));
    }
  }

  Operation? _find(String id) => state.ops.where((o) => o.id == id).firstOrNull;

  /// The queued operations from `ids[i]` onward while [take] holds.
  List<Operation> _run(List<String> ids, int i, bool Function(Operation) take) {
    final out = <Operation>[];
    for (var j = i; j < ids.length; j++) {
      final o = _find(ids[j]);
      if (o == null || !take(o)) break;
      out.add(o);
    }
    return out;
  }

  Future<void> _markDispatched(Set<String> ids, GithubConfig cfg) async {
    if (!identical(state.github, cfg)) return; // disconnected: queue already cleared
    state = state.copyWith(ops: [for (final o in state.ops) ids.contains(o.id) ? o.markDispatched() : o]);
    await _local.saveOps(state.ops);
  }

  /// A resolved operation leaves the queue. An accepted one now lives in the
  /// repository: fold it into the base right away, otherwise it would vanish
  /// from the view until the final pull.
  Future<void> _resolve(Operation op, OpResult res, PushProgress progress, GithubConfig cfg) async {
    // Each save is preceded by the guard with no await in between, so a
    // disconnect can never be overwritten by a push still in flight.
    if (!identical(state.github, cfg)) return;
    var base = state.base;
    if (res.ok) {
      final applied = applyOperation(base, op);
      if (applied.ok) base = applied.snapshot;
    }
    state = state.copyWith(base: base, ops: state.ops.where((o) => o.id != op.id).toList(), push: progress);
    await _local.saveBase(state.base);
    if (!identical(state.github, cfg)) return;
    await _local.saveOps(state.ops);
  }

  /// Collapses consecutive, not yet dispatched updates of the same entity into
  /// the latest one. Never touches creates, deletes or dispatched operations,
  /// and keeps both when the latest alone would be judged differently than
  /// step by step (e.g. quest task-removal rules compare with the prior state).
  static List<Operation> _coalesce(Snapshot base, List<Operation> ops) {
    final out = <Operation>[];
    for (final op in ops) {
      if (out.isNotEmpty) {
        final prev = out.last;
        final same = prev.action == OpAction.update &&
            op.action == OpAction.update &&
            !prev.dispatched &&
            !op.dispatched &&
            prev.type == op.type &&
            prev.entityId == op.entityId;
        if (same) {
          final before = applyAll(base, out.sublist(0, out.length - 1));
          final stepwise = applyOperation(before, prev);
          final viaPrev = stepwise.ok && applyOperation(stepwise.snapshot, op).ok;
          if (viaPrev && applyOperation(before, op).ok) {
            out[out.length - 1] = op;
            continue;
          }
        }
      }
      out.add(op);
    }
    return out;
  }

  Future<OpResult> _awaitResult(RemoteStore remote, String opId, {bool checkFirst = false}) async {
    if (checkFirst) {
      final now = await remote.status(opId);
      if (now.outcome != OpOutcome.pending) return now;
    }
    OpResult last = const OpResult(OpOutcome.pending, '');
    for (final d in pollDelays) {
      await Future<void>.delayed(pollUnit * d);
      last = await remote.status(opId);
      if (last.outcome != OpOutcome.pending) return last;
    }
    return last;
  }

  Future<void> _pull() async {
    final cfg = state.github;
    final snap = await _remoteFactory(cfg).pull();
    if (!identical(state.github, cfg)) return; // disconnected/reconnected meanwhile
    final now = DateTime.now();
    state = state.copyWith(base: snap, lastSync: now);
    await _local.saveBase(snap); // no await between the guard and this save
    await _local.saveLastSync(now);
  }

  // ---- GitHub connection ---------------------------------------------

  Future<ConnectionReport> testConnection(GithubConfig cfg) async {
    if (!GithubRemoteStore.isValidRepo(cfg.repo)) {
      return const ConnectionReport(ok: false, message: 'Repository must look like "owner/name".');
    }
    if (cfg.pat.trim().isEmpty) return const ConnectionReport(ok: false, message: 'Enter a personal access token.');
    final report = await _remoteFactory(cfg).check();
    state = state.copyWith(connection: report);
    return report;
  }

  /// Saves the connection and merges whatever exists locally with the
  /// repository: nothing is lost, missing items are queued for the next push.
  Future<ConnectionReport> connect(GithubConfig cfg) async {
    final report = await testConnection(cfg);
    if (!report.ok) return report;
    await _local.saveGithub(cfg);
    state = state.copyWith(github: cfg, clearNotice: true);
    try {
      final remote = await _remote.pull();
      if (!identical(state.github, cfg)) return report; // disconnected meanwhile
      final local = state.view;
      final ids = {
        for (final b in remote.branches) b.id,
        for (final a in remote.activities) a.id,
        for (final r in remote.records) r.id,
        for (final q in remote.quests) q.id,
      };
      final ops = <Operation>[
        ...state.ops,
        for (final b in local.branches.where((b) => !ids.contains(b.id)))
          _op(OpAction.create, EntityType.branch, b.id, b.toJson()),
        for (final a in local.activities.where((a) => !ids.contains(a.id)))
          _op(OpAction.create, EntityType.activity, a.id, a.toJson()),
        for (final r in local.records.where((r) => !ids.contains(r.id)))
          _op(OpAction.create, EntityType.record, r.id, r.toJson()),
        for (final q in local.quests.where((q) => !ids.contains(q.id)))
          _op(OpAction.create, EntityType.quest, q.id, q.toJson()),
      ];
      state = state.copyWith(base: remote, ops: ops);
      await _local.saveBase(remote);
      if (identical(state.github, cfg)) await _local.saveOps(state.ops);
    } on RemoteException catch (e) {
      state = state.copyWith(notice: e.message);
    }
    return report;
  }

  Future<void> disconnect() async {
    // Switch state first, synchronously, so every in-flight push/pull guard
    // (identical(state.github, cfg)) trips before anything else is persisted.
    final keep = state.view;
    state = state.copyWith(github: const GithubConfig(), base: keep, ops: const [], clearNotice: true);
    await _local.clearGithub();
    await _local.saveBase(keep);
    await _local.saveOps(const []);
  }

  void dismissNotice() => state = state.copyWith(clearNotice: true);
}
