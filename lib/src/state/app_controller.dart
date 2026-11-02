import 'dart:async';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../data/local_store.dart';
import '../data/remote_store.dart';
import '../domain/apply.dart';
import '../domain/models.dart';

class AppState {
  final bool loaded;
  final Snapshot base; // last known repository content (or local data when offline-only)
  final List<Operation> ops; // changes not yet confirmed by GitHub
  final Snapshot view; // base + pending ops: what the UI shows
  final GithubConfig github;
  final bool syncing;
  final DateTime? lastSync;
  final String? notice; // last problem worth telling the user about
  final ConnectionReport? connection;

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
  });

  bool get hasPending => ops.isNotEmpty;

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

  final LocalStore _local;
  final RemoteFactory _remoteFactory;
  final List<int> pollDelays;
  final Duration pollUnit;
  final Map<String, Completer<OpResult>> _waiters = {};
  bool _draining = false;
  int _idCounter = 0;

  String newId([String prefix = 'id']) =>
      '${prefix}_${DateTime.now().microsecondsSinceEpoch.toRadixString(36)}${(_idCounter++).toRadixString(36)}';

  Future<void> init() async {
    final gh = await _local.loadGithub();
    final base = _local.loadBase();
    final ops = _local.loadOps();
    state = state.copyWith(loaded: true, base: base, ops: ops, github: gh, lastSync: _local.loadLastSync());
    if (gh.isConfigured) unawaited(syncNow());
  }

  RemoteStore get _remote => _remoteFactory(state.github);

  // ---- writing ------------------------------------------------------

  /// Applies [op] right away and, when GitHub is connected, syncs it. The
  /// returned future completes when GitHub confirms/rejects (or times out).
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
    final ops = [...state.ops, op];
    state = state.copyWith(ops: ops, clearNotice: true);
    final c = _waiters[op.id] = Completer<OpResult>();
    await _local.saveOps(ops);
    unawaited(_drain());
    return c.future;
  }

  Operation _op(OpAction a, EntityType t, String id, Map<String, dynamic> payload) => Operation(
        id: newId('op'),
        action: a,
        type: t,
        entityId: id,
        payload: payload,
        createdAt: DateTime.now(),
      );

  Future<OpResult> saveBranch(Branch b, {required bool isNew}) =>
      submit(_op(isNew ? OpAction.create : OpAction.update, EntityType.branch, b.id, b.toJson()));
  Future<OpResult> deleteBranch(String id) => submit(_op(OpAction.delete, EntityType.branch, id, {'id': id}));
  Future<OpResult> saveActivity(Activity a, {required bool isNew}) =>
      submit(_op(isNew ? OpAction.create : OpAction.update, EntityType.activity, a.id, a.toJson()));
  Future<OpResult> deleteActivity(String id) => submit(_op(OpAction.delete, EntityType.activity, id, {'id': id}));
  Future<OpResult> addRecord(Record r) => submit(_op(OpAction.create, EntityType.record, r.id, r.toJson()));
  Future<OpResult> deleteRecord(String id) => submit(_op(OpAction.delete, EntityType.record, id, {'id': id}));

  // ---- syncing ------------------------------------------------------

  Future<void> syncNow() async {
    if (!state.github.isConfigured) return;
    await _drain(forcePull: true);
  }

  Future<void> _drain({bool forcePull = false}) async {
    if (_draining) return;
    _draining = true;
    state = state.copyWith(syncing: true);
    var failed = false;
    var pulled = false;
    try {
      final remote = _remote;
      while (state.ops.isNotEmpty) {
        var op = state.ops.first;
        OpResult res;
        try {
          if (!op.dispatched) {
            await remote.dispatch(op);
            op = op.markDispatched();
            final ops = [op, ...state.ops.skip(1)];
            await _local.saveOps(ops);
            state = state.copyWith(ops: ops);
          }
          res = await _awaitResult(remote, op.id);
        } on RemoteException catch (e) {
          _finish(op.id, OpResult(OpOutcome.failed, e.message));
          state = state.copyWith(notice: e.message);
          failed = true;
          break;
        }
        if (res.outcome == OpOutcome.pending) {
          _finish(op.id, const OpResult(OpOutcome.pending, 'Still syncing in the background…'));
          failed = true;
          break;
        }
        final ops = state.ops.skip(1).toList();
        // An accepted operation now lives in the repository: fold it into the base right away,
        // otherwise it would vanish from the view until the final pull.
        var base = state.base;
        if (res.ok) {
          final applied = applyOperation(base, op);
          if (applied.ok) base = applied.snapshot;
        }
        await _local.saveBase(base);
        await _local.saveOps(ops);
        state = state.copyWith(base: base, ops: ops);
        if (!res.ok) {
          state = state.copyWith(notice: 'Change was not saved: ${res.message}');
        }
        if (state.ops.isEmpty) {
          // Last one: refresh from the repository first so the caller sees the final state.
          try {
            await _pull();
            pulled = true;
          } on RemoteException catch (e) {
            state = state.copyWith(notice: e.message);
          }
        }
        _finish(op.id, res);
      }
      if ((!failed || forcePull) && !pulled) {
        try {
          await _pull();
        } on RemoteException catch (e) {
          state = state.copyWith(notice: e.message);
        }
      }
    } finally {
      _draining = false;
      state = state.copyWith(syncing: false);
    }
  }

  void _finish(String id, OpResult r) {
    final c = _waiters.remove(id);
    if (c != null && !c.isCompleted) c.complete(r);
  }

  Future<OpResult> _awaitResult(RemoteStore remote, String opId) async {
    OpResult last = const OpResult(OpOutcome.pending, '');
    for (final d in pollDelays) {
      await Future<void>.delayed(pollUnit * d);
      last = await remote.status(opId);
      if (last.outcome != OpOutcome.pending) return last;
    }
    return last;
  }

  Future<void> _pull() async {
    final snap = await _remote.pull();
    final now = DateTime.now();
    await _local.saveBase(snap);
    await _local.saveLastSync(now);
    state = state.copyWith(base: snap, lastSync: now);
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
  /// repository: nothing is lost, missing items are uploaded.
  Future<ConnectionReport> connect(GithubConfig cfg) async {
    final report = await testConnection(cfg);
    if (!report.ok) return report;
    await _local.saveGithub(cfg);
    state = state.copyWith(github: cfg, clearNotice: true);
    try {
      final remote = await _remote.pull();
      final local = state.view;
      final ids = {
        for (final b in remote.branches) b.id,
        for (final a in remote.activities) a.id,
        for (final r in remote.records) r.id,
      };
      final ops = <Operation>[
        ...state.ops,
        for (final b in local.branches.where((b) => !ids.contains(b.id)))
          _op(OpAction.create, EntityType.branch, b.id, b.toJson()),
        for (final a in local.activities.where((a) => !ids.contains(a.id)))
          _op(OpAction.create, EntityType.activity, a.id, a.toJson()),
        for (final r in local.records.where((r) => !ids.contains(r.id)))
          _op(OpAction.create, EntityType.record, r.id, r.toJson()),
      ];
      await _local.saveBase(remote);
      await _local.saveOps(ops);
      state = state.copyWith(base: remote, ops: ops);
      unawaited(_drain(forcePull: true));
    } on RemoteException catch (e) {
      state = state.copyWith(notice: e.message);
    }
    return report;
  }

  Future<void> disconnect() async {
    final keep = state.view;
    await _local.clearGithub();
    await _local.saveBase(keep);
    await _local.saveOps(const []);
    state = state.copyWith(github: const GithubConfig(), base: keep, ops: const [], clearNotice: true);
  }

  void dismissNotice() => state = state.copyWith(clearNotice: true);
}
