import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../core/theme/index.dart';
import '../../domain/entities/branch.dart';
import '../../domain/entities/activity.dart';
import '../../domain/entities/activity_field.dart';
import '../providers/app_providers.dart';
import '../widgets/module_header.dart';
import '../widgets/branch_card.dart';
import '../widgets/activity_item.dart';

class ActivityPage extends ConsumerStatefulWidget {
  const ActivityPage({super.key});

  @override
  ConsumerState<ActivityPage> createState() => _ActivityPageState();
}

class _ActivityPageState extends ConsumerState<ActivityPage> {
  final PageController _branchPageController = PageController(viewportFraction: 0.9);
  int _selectedBranchIndex = 0;

  @override
  void dispose() {
    _branchPageController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final branchesAsync = ref.watch(branchesProvider);

    return Scaffold(
      backgroundColor: AppColors.background,
      body: SafeArea(
        child: CustomScrollView(
          slivers: [
            // App Bar
            SliverToBoxAdapter(
              child: Container(
                height: 72,
                padding: const EdgeInsets.symmetric(horizontal: 16),
                decoration: BoxDecoration(
                  color: AppColors.surfaceContainerLow.withOpacity(0.8),
                  border: Border(
                    bottom: BorderSide(color: AppColors.brushedMetallicTrim, width: 0.5),
                  ),
                ),
                child: Row(
                  children: [
                    Row(
                      children: [
                        Container(
                          width: 36,
                          height: 36,
                          decoration: BoxDecoration(
                            gradient: AppColors.cyanGlowGradient,
                            border: Border.all(color: AppColors.electricCyan, width: 1),
                          ),
                          child: const Icon(Icons.bolt, color: AppColors.coreVoid, size: 20),
                        ),
                        const SizedBox(width: 10),
                        Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Text(
                              'PERSONAL LIFE RPG',
                              style: AppTextStyles.labelSmallUpper.copyWith(
                                color: AppColors.electricCyan,
                              ),
                            ),
                            Text(
                              'Activity Log',
                              style: AppTextStyles.headlineSmall,
                            ),
                          ],
                        ),
                      ],
                    ),
                    const Spacer(),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                      decoration: BoxDecoration(
                        color: AppColors.surfaceContainerHigh,
                        border: Border.all(color: AppColors.brushedMetallicTrim, width: 1),
                      ),
                      child: Row(
                        children: [
                          Container(
                            width: 8,
                            height: 8,
                            decoration: const BoxDecoration(
                              color: AppColors.highVoltageYellow,
                              shape: BoxShape.circle,
                            ),
                          ),
                          const SizedBox(width: 6),
                          Text(
                            'LVL 28 • CYBER_RUNNER',
                            style: AppTextStyles.labelSmallUpper.copyWith(
                              color: AppColors.highVoltageYellow,
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(width: 12),
                    Container(
                      width: 44,
                      height: 44,
                      decoration: BoxDecoration(
                        color: AppColors.surfaceContainerHigh,
                        border: Border.all(color: AppColors.brushedMetallicTrim, width: 1),
                      ),
                      child: IconButton(
                        icon: const Icon(Icons.home, color: AppColors.electricCyan, size: 22),
                        onPressed: () {},
                        tooltip: 'Quick Return Hub',
                      ),
                    ),
                  ],
                ),
              ),
            ),
            // Module Header
            SliverToBoxAdapter(
              child: ModuleHeader(
                moduleCode: 'MOD.03_ACTIVITY_LOG',
                status: 'SIGNAL: 98.4% LOCKED',
                statusColor: AppColors.highVoltageYellow,
              ),
            ),
            // Branch Selector
            SliverToBoxAdapter(
              child: branchesAsync.when(
                data: (branches) => _buildBranchSelector(branches),
                loading: () => _buildBranchSelectorSkeleton(),
                error: (e, _) => _buildErrorState(e.toString()),
              ),
            ),
            // Activities List
            SliverToBoxAdapter(
              child: branchesAsync.when(
                data: (branches) {
                  if (branches.isEmpty) return _buildEmptyState();
                  final selectedBranch = branches[_selectedBranchIndex.clamp(0, branches.length - 1)];
                  return _buildActivitiesList(selectedBranch);
                },
                loading: () => _buildActivitiesSkeleton(),
                error: (e, _) => _buildErrorState(e.toString()),
              ),
            ),
            const SliverToBoxAdapter(child: SizedBox(height: 100)),
          ],
        ),
      ),
    );
  }

  Widget _buildBranchSelector(List<Branch> branches) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.fromLTRB(16, 16, 16, 8),
          child: Row(
            children: [
              const Icon(Icons.account_tree, color: AppColors.electricCyan, size: 20),
              const SizedBox(width: 8),
              Text(
                'SELECT BRANCH',
                style: AppTextStyles.headlineSmall,
              ),
            ],
          ),
        ),
        SizedBox(
          height: 200,
          child: PageView.builder(
            controller: _branchPageController,
            itemCount: branches.length,
            onPageChanged: (index) {
              setState(() => _selectedBranchIndex = index);
            },
            itemBuilder: (context, index) {
              final branch = branches[index];
              final isSelected = index == _selectedBranchIndex;
              return Padding(
                padding: EdgeInsets.only(
                  left: index == 0 ? 16 : 8,
                  right: index == branches.length - 1 ? 16 : 8,
                ),
                child: BranchCard.fromEntity(
                  branch: branch,
                  isSelected: isSelected,
                  onTap: () {
                    setState(() => _selectedBranchIndex = index);
                    _branchPageController.animateToPage(
                      index,
                      duration: const Duration(milliseconds: 300),
                      curve: Curves.easeOutCubic,
                    );
                  },
                ),
              );
            },
          ),
        ),
      ],
    );
  }

  Widget _buildBranchSelectorSkeleton() {
    return SizedBox(
      height: 200,
      child: ListView.builder(
        scrollDirection: Axis.horizontal,
        padding: const EdgeInsets.symmetric(horizontal: 16),
        itemCount: 4,
        itemBuilder: (context, index) => Container(
          width: 280,
          margin: const EdgeInsets.only(right: 8),
          child: CyberCard(
            child: Column(
              children: List.generate(4, (i) => Container(
                height: 40,
                margin: const EdgeInsets.only(bottom: 8),
                decoration: BoxDecoration(
                  color: AppColors.surfaceContainerLow,
                  border: Border.all(color: AppColors.brushedMetallicTrim),
                ),
              )),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildActivitiesList(Branch branch) {
    // Demo activities based on branch
    final activities = _getDemoActivities(branch);
    
    return Column(
      children: [
        Padding(
          padding: const EdgeInsets.fromLTRB(16, 16, 16, 8),
          child: Row(
            children: [
              const Icon(Icons.format_list_bulleted_add, color: AppColors.highVoltageYellow, size: 20),
              const SizedBox(width: 8),
              Text(
                '${branch.name.toUpperCase()} QUEUE',
                style: AppTextStyles.headlineSmall,
              ),
              const Spacer(),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                decoration: BoxDecoration(
                  color: AppColors.electricCyan.withOpacity(0.2),
                  border: Border.all(color: AppColors.electricCyan, width: 1),
                ),
                child: Text(
                  '${activities.length} READY',
                  style: AppTextStyles.hudMetricSmall.copyWith(color: AppColors.electricCyan),
                ),
              ),
            ],
          ),
        ),
        ListView.builder(
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          padding: const EdgeInsets.symmetric(horizontal: 16),
          itemCount: activities.length,
          itemBuilder: (context, index) {
            final activity = activities[index];
            return ActivityItem(
              name: activity.name,
              description: activity.description,
              category: activity.category,
              categoryColor: activity.accentColor,
              icon: activity.icon,
              iconColor: activity.accentColor,
              xpReward: activity.baseXp,
              statReward: '+2 ${activity.category.toUpperCase()}',
              statColor: activity.accentColor,
              onRecord: () => _recordActivity(activity),
              onSync: () => _syncActivity(activity),
            );
          },
        ),
      ],
    );
  }

  List<Activity> _getDemoActivities(Branch branch) {
    // Return demo activities based on branch name
    switch (branch.name) {
      case 'Physical Development':
        return [
          Activity(
            id: 'pushups',
            branchId: branch.id,
            name: 'Push-ups Protocol',
            description: '3 Sets × 25 Tactical Repetitions',
            category: 'STRENGTH',
            accentColor: AppColors.electricCyan,
            icon: Icons.sports_martial_arts,
            baseXp: 45,
            createdAt: DateTime.now(),
            updatedAt: DateTime.now(),
          ),
          Activity(
            id: 'run',
            branchId: branch.id,
            name: 'High-Velocity Neon Run',
            description: 'Distance Goal: 5.0 KM • Cyber Pacing',
            category: 'CARDIO',
            accentColor: AppColors.highVoltageYellow,
            icon: Icons.directions_run,
            baseXp: 80,
            createdAt: DateTime.now(),
            updatedAt: DateTime.now(),
          ),
          Activity(
            id: 'plank',
            branchId: branch.id,
            name: 'Heavy Core Plank',
            description: 'Isometric Hold • 3 Minutes Constant Tension',
            category: 'ENDURANCE',
            accentColor: AppColors.electricCyan,
            icon: Icons.timer,
            baseXp: 35,
            createdAt: DateTime.now(),
            updatedAt: DateTime.now(),
          ),
        ];
      case 'Professional Skills':
        return [
          Activity(
            id: 'coding',
            branchId: branch.id,
            name: 'Deep Code Session',
            description: '90 min focused architecture work',
            category: 'CODE',
            accentColor: AppColors.electricViolet,
            icon: Icons.code,
            baseXp: 60,
            createdAt: DateTime.now(),
            updatedAt: DateTime.now(),
          ),
          Activity(
            id: 'learning',
            branchId: branch.id,
            name: 'Tech Documentation Study',
            description: 'Read & annotate 3 RFCs/specs',
            category: 'LEARNING',
            accentColor: AppColors.electricCyan,
            icon: Icons.menu_book,
            baseXp: 40,
            createdAt: DateTime.now(),
            updatedAt: DateTime.now(),
          ),
        ];
      case 'Personal Skills':
        return [
          Activity(
            id: 'meditation',
            branchId: branch.id,
            name: 'Neural Calibration',
            description: '20 min mindfulness protocol',
            category: 'FOCUS',
            accentColor: AppColors.electricViolet,
            icon: Icons.self_improvement,
            baseXp: 30,
            createdAt: DateTime.now(),
            updatedAt: DateTime.now(),
          ),
          Activity(
            id: 'reading',
            branchId: branch.id,
            name: 'Knowledge Ingestion',
            description: '30 pages technical literature',
            category: 'READING',
            accentColor: AppColors.electricCyan,
            icon: Icons.auto_stories,
            baseXp: 25,
            createdAt: DateTime.now(),
            updatedAt: DateTime.now(),
          ),
        ];
      default:
        return [
          Activity(
            id: 'family',
            branchId: branch.id,
            name: 'Quality Time Protocol',
            description: 'Uninterrupted family engagement',
            category: 'BONDING',
            accentColor: AppColors.highVoltageYellow,
            icon: Icons.favorite,
            baseXp: 50,
            createdAt: DateTime.now(),
            updatedAt: DateTime.now(),
          ),
        ];
    }
  }

  void _recordActivity(Activity activity) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => _ActivityRecordModal(activity: activity),
    );
  }

  void _syncActivity(Activity activity) {
    // Show sync feedback
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text('Syncing ${activity.name}...', style: AppTextStyles.bodyMedium),
        backgroundColor: AppColors.surfaceContainerHigh,
        behavior: SnackBarBehavior.floating,
      ),
    );
  }

  Widget _buildEmptyState() {
    return Container(
      margin: const EdgeInsets.all(16),
      padding: const EdgeInsets.all(32),
      child: CyberCard(
        child: Column(
          children: [
            const Icon(Icons.format_list_bulleted_add, color: AppColors.mutedAlloyText, size: 48),
            const SizedBox(height: 16),
            Text(
              'NO BRANCHES CONFIGURED',
              style: AppTextStyles.headlineSmall.copyWith(color: AppColors.mutedAlloyText),
            ),
            const SizedBox(height: 8),
            Text(
              'Create branches in the Config module to start tracking activities',
              style: AppTextStyles.bodyMedium.copyWith(color: AppColors.onSurfaceVariant),
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildActivitiesSkeleton() {
    return Column(
      children: List.generate(3, (i) => Container(
        margin: const EdgeInsets.only(bottom: 12, left: 16, right: 16),
        height: 180,
        child: CyberCard(
          child: Column(
            children: List.generate(3, (j) => Container(
              height: 40,
              margin: const EdgeInsets.only(bottom: 8),
              decoration: BoxDecoration(
                color: AppColors.surfaceContainerLow,
                border: Border.all(color: AppColors.brushedMetallicTrim),
              ),
            )),
          ),
        ),
      )),
    );
  }

  Widget _buildErrorState(String error) {
    return Container(
      margin: const EdgeInsets.all(16),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.surfaceContainerHigh,
        border: Border.all(color: AppColors.overloadCrimson, width: 1),
      ),
      child: Text(
        'ERROR: $error',
        style: AppTextStyles.bodyMedium.copyWith(color: AppColors.overloadCrimson),
      ),
    );
  }
}

class _ActivityRecordModal extends ConsumerStatefulWidget {
  final Activity activity;

  const _ActivityRecordModal({required this.activity});

  @override
  ConsumerState<_ActivityRecordModal> createState() => _ActivityRecordModalState();
}

class _ActivityRecordModalState extends ConsumerState<_ActivityRecordModal> {
  @override
  Widget build(BuildContext context) {
    final quickEntry = ref.watch(quickEntryProvider);
    final notifier = ref.read(quickEntryProvider.notifier);

    return Container(
      height: MediaQuery.of(context).size.height * 0.9,
      decoration: const BoxDecoration(
        color: AppColors.surfaceContainer,
        border: Border(
          top: BorderSide(color: AppColors.electricCyan, width: 2),
        ),
      ),
      child: Column(
        children: [
          // Header
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: AppColors.surfaceContainerLowest,
              border: Border(
                bottom: BorderSide(color: AppColors.brushedMetallicTrim, width: 1),
              ),
            ),
            child: Row(
              children: [
                Container(
                  width: 8,
                  height: 8,
                  decoration: const BoxDecoration(
                    color: AppColors.electricCyan,
                    shape: BoxShape.circle,
                  ),
                ),
                const SizedBox(width: 8),
                Text(
                  '// MOD.03_ACTIVITY_RECORD',
                  style: AppTextStyles.labelSmallUpper.copyWith(
                    color: AppColors.electricCyan,
                  ),
                ),
                const Spacer(),
                Text(
                  widget.activity.name.toUpperCase(),
                  style: AppTextStyles.labelSmallUpper.copyWith(
                    color: AppColors.highVoltageYellow,
                  ),
                ),
              ],
            ),
          ),
          // Content
          Expanded(
            child: SingleChildScrollView(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Activity Header
                  CyberCard(
                    padding: const EdgeInsets.all(16),
                    child: Row(
                      children: [
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Container(
                                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                                decoration: BoxDecoration(
                                  color: AppColors.surfaceContainerLowest,
                                  border: Border.all(color: AppColors.brushedMetallicTrim),
                                ),
                                child: Text(
                                  'SESSION LOG // ${widget.activity.category.toUpperCase()}',
                                  style: AppTextStyles.labelSmallUpper.copyWith(
                                    color: AppColors.electricCyan,
                                  ),
                                ),
                              ),
                              const SizedBox(height: 8),
                              Row(
                                children: [
                                  Text(
                                    widget.activity.name,
                                    style: AppTextStyles.headlineMedium,
                                  ),
                                  const SizedBox(width: 8),
                                  Icon(Icons.bolt, color: widget.activity.accentColor, size: 22),
                                ],
                              ),
                            ],
                          ),
                        ),
                        Container(
                          width: 48,
                          height: 48,
                          decoration: BoxDecoration(
                            color: AppColors.surfaceContainerLowest,
                            border: Border.all(color: AppColors.brushedMetallicTrim),
                          ),
                          child: Icon(widget.activity.icon, color: widget.activity.accentColor, size: 24),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 16),
                  // Reward Display
                  Container(
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: AppColors.surfaceContainerLowest,
                      border: Border.all(color: AppColors.brushedMetallicTrim, width: 1),
                    ),
                    child: Row(
                      children: [
                        Row(
                          children: [
                            Container(width: 8, height: 8, decoration: const BoxDecoration(color: AppColors.electricCyan, shape: BoxShape.circle)),
                            const SizedBox(width: 8),
                            Text(
                              'Base: ',
                              style: AppTextStyles.labelSmall,
                            ),
                            Text(
                              '+${widget.activity.baseXp} XP',
                              style: AppTextStyles.hudMetricSmall.copyWith(color: AppColors.electricCyan),
                            ),
                          ],
                        ),
                        const Spacer(),
                        Row(
                          children: [
                            Container(width: 8, height: 8, decoration: const BoxDecoration(color: AppColors.highVoltageYellow, shape: BoxShape.circle)),
                            const SizedBox(width: 8),
                            Text(
                              'Synergy Bonus: +15 XP active',
                              style: AppTextStyles.labelSmall.copyWith(color: AppColors.highVoltageYellow),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 16),
                  // Rep Counter
                  _buildRepCounter(notifier, quickEntry),
                  const SizedBox(height: 16),
                  // Sets
                  _buildSets(notifier, quickEntry),
                  const SizedBox(height: 16),
                  // RPE
                  _buildRpeGauge(notifier, quickEntry),
                  const SizedBox(height: 16),
                  // Notes
                  _buildNotes(notifier, quickEntry),
                  const SizedBox(height: 16),
                  // XP Preview
                  _buildXpPreview(quickEntry),
                  const SizedBox(height: 24),
                  // Actions
                  _buildActions(notifier, quickEntry),
                ],
              ),
            ),
          ),
          // Bottom bar
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: AppColors.surfaceContainerLowest,
              border: Border(
                top: BorderSide(color: AppColors.brushedMetallicTrim, width: 1),
              ),
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text('// CHASSIS: MK-VII_EXP', style: AppTextStyles.labelSmallUpper),
                Text('BUFFER: ACTIVE', style: AppTextStyles.labelSmallUpper),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildRepCounter(QuickEntryNotifier notifier, QuickEntryState state) {
    return CyberCard(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Row(
                children: [
                  const Icon(Icons.repeat, color: AppColors.electricCyan, size: 16),
                  const SizedBox(width: 8),
                  Text('Repetition Counter', style: AppTextStyles.labelSmallUpper),
                ],
              ),
              Text('TARGET: 30 REPS', style: AppTextStyles.labelSmallUpper.copyWith(color: AppColors.electricCyan)),
            ],
          ),
          const SizedBox(height: 16),
          Row(
            children: [
              _CounterButton(icon: Icons.remove, onPressed: () => notifier.incrementReps(-1)),
              Expanded(
                child: Container(
                  height: 60,
                  alignment: Alignment.center,
                  decoration: BoxDecoration(
                    color: AppColors.surfaceContainerLowest,
                    border: Border.all(color: AppColors.brushedMetallicTrim, width: 1),
                    boxShadow: [BoxShadow(color: AppColors.electricCyan.withOpacity(0.1), blurRadius: 8, offset: const Offset(0, 2))],
                  ),
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Text('${state.reps}', style: AppTextStyles.displayLargeMobile.copyWith(color: AppColors.electricCyan, fontSize: 36)),
                      Text('EXECUTIONS', style: AppTextStyles.labelSmallUpper.copyWith(color: AppColors.outline)),
                    ],
                  ),
                ),
              ),
              _CounterButton(icon: Icons.add, onPressed: () => notifier.incrementReps(1)),
            ],
          ),
          const SizedBox(height: 12),
          Row(
            children: [
              _QuickBoostButton(label: '+5', onPressed: () => notifier.incrementReps(5)),
              const SizedBox(width: 8),
              _QuickBoostButton(label: '+10', onPressed: () => notifier.incrementReps(10)),
              const SizedBox(width: 8),
              _QuickBoostButton(label: '+25', onPressed: () => notifier.incrementReps(25)),
              const SizedBox(width: 8),
              _QuickBoostButton(label: 'MAX', onPressed: () => notifier.setReps(50), isMax: true),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildSets(QuickEntryNotifier notifier, QuickEntryState state) {
    return CyberCard(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Row(
                children: [
                  const Icon(Icons.layers, color: AppColors.highVoltageYellow, size: 16),
                  const SizedBox(width: 8),
                  Text('Sets Completed', style: AppTextStyles.labelSmallUpper),
                ],
              ),
              Text('CHAIN STREAK: x${state.sets}', style: AppTextStyles.labelSmallUpper.copyWith(color: AppColors.highVoltageYellow)),
            ],
          ),
          const SizedBox(height: 12),
          Row(
            children: List.generate(4, (index) {
              final isActive = index < state.sets;
              return Expanded(
                child: Container(
                  margin: EdgeInsets.only(right: index == 3 ? 0 : 8),
                  padding: const EdgeInsets.symmetric(vertical: 16),
                  decoration: BoxDecoration(
                    color: isActive ? AppColors.electricCyan : AppColors.surfaceContainer,
                    border: Border.all(color: isActive ? AppColors.electricCyan : AppColors.brushedMetallicTrim, width: isActive ? 2 : 1),
                    boxShadow: isActive ? [BoxShadow(color: AppColors.electricCyan.withOpacity(0.4), blurRadius: 8)] : null,
                  ),
                  child: Column(
                    children: [
                      Text('${index + 1}', style: AppTextStyles.hudMetricSmall.copyWith(color: isActive ? AppColors.coreVoid : AppColors.onSurfaceVariant)),
                      Text(index == 0 ? 'WARMUP' : index == 1 ? 'NORMAL' : index == 2 ? 'CURRENT' : 'OVERLOAD', style: AppTextStyles.labelSmall.copyWith(color: isActive ? AppColors.coreVoid : AppColors.onSurfaceVariant, fontSize: 8)),
                    ],
                  ),
                ),
              );
            }),
          ),
        ],
      ),
    );
  }

  Widget _buildRpeGauge(QuickEntryNotifier notifier, QuickEntryState state) {
    String rpeLabel;
    if (state.rpe >= 8.5) rpeLabel = 'HIGH VOLTAGE';
    else if (state.rpe >= 7) rpeLabel = 'STABLE BURN';
    else rpeLabel = 'CRUISE ENERGY';

    return CyberCard(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Row(
                children: [
                  const Icon(Icons.speed, color: AppColors.highVoltageYellow, size: 16),
                  const SizedBox(width: 8),
                  Text('Intensity / RPE Gauge', style: AppTextStyles.labelSmallUpper),
                ],
              ),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                decoration: BoxDecoration(color: AppColors.surfaceContainerLowest, border: Border.all(color: AppColors.highVoltageYellow, width: 1)),
                child: Text('RPE ${state.rpe.toStringAsFixed(1)} • $rpeLabel', style: AppTextStyles.labelSmallUpper.copyWith(color: AppColors.highVoltageYellow)),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Row(
            children: List.generate(10, (index) {
              final filled = index < state.rpe.floor();
              final isYellow = index >= 7;
              return Expanded(
                child: Container(
                  height: 12,
                  margin: EdgeInsets.only(right: index == 9 ? 0 : 2),
                  decoration: BoxDecoration(
                    color: filled ? (isYellow ? AppColors.highVoltageYellow : AppColors.electricCyan) : AppColors.surfaceContainerLowest,
                    border: Border.all(color: filled ? (isYellow ? AppColors.highVoltageYellow : AppColors.electricCyan) : AppColors.brushedMetallicTrim, width: 1),
                    boxShadow: filled ? [BoxShadow(color: (isYellow ? AppColors.highVoltageYellow : AppColors.electricCyan).withOpacity(0.7), blurRadius: 6)] : null,
                  ),
                ),
              );
            }),
          ),
          const SizedBox(height: 8),
          SliderTheme(
            data: SliderTheme.of(context).copyWith(activeTrackColor: AppColors.electricCyan, inactiveTrackColor: AppColors.brushedMetallicTrim, thumbColor: AppColors.electricCyan, trackHeight: 4),
            child: Slider(value: state.rpe, min: 1, max: 10, divisions: 18, onChanged: notifier.setRpe),
          ),
        ],
      ),
    );
  }

  Widget _buildNotes(QuickEntryNotifier notifier, QuickEntryState state) {
    return CyberCard(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(children: [const Icon(Icons.code, color: AppColors.outline, size: 16), const SizedBox(width: 8), Text('Operational Debrief / Memo', style: AppTextStyles.labelSmallUpper)]),
          const SizedBox(height: 12),
          TextField(
            onChanged: notifier.setNotes,
            style: AppTextStyles.bodyMedium,
            decoration: InputDecoration(
              hintText: 'Enter operational debrief / form notes...',
              hintStyle: AppTextStyles.bodyMedium.copyWith(color: AppColors.mutedAlloyText.withOpacity(0.6)),
              filled: true,
              fillColor: AppColors.surfaceContainerLowest,
              border: OutlineInputBorder(borderRadius: BorderRadius.zero, borderSide: const BorderSide(color: AppColors.brushedMetallicTrim)),
              focusedBorder: OutlineInputBorder(borderRadius: BorderRadius.zero, borderSide: const BorderSide(color: AppColors.electricCyan, width: 2)),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildXpPreview(QuickEntryState state) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.surfaceContainerLowest,
        border: Border.all(color: AppColors.highVoltageYellow, width: 2),
        boxShadow: [BoxShadow(color: AppColors.highVoltageYellow.withOpacity(0.3), blurRadius: 16)],
      ),
      child: Row(
        children: [
          Container(width: 4, height: 60, color: AppColors.highVoltageYellow),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('CALCULATED POWER GAIN', style: AppTextStyles.labelSmallUpper.copyWith(color: AppColors.onSurfaceVariant)),
                const SizedBox(height: 4),
                Row(children: [
                  Text('+${state.calculatedXp} XP', style: AppTextStyles.hudMetric.copyWith(color: AppColors.highVoltageYellow, fontSize: 28)),
                  const SizedBox(width: 8),
                  Text('⚡ OVERCLOCK READY', style: AppTextStyles.labelSmallUpper.copyWith(color: AppColors.electricCyan)),
                ]),
              ],
            ),
          ),
          Column(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              Text('OVERLOAD RISK', style: AppTextStyles.labelSmallUpper.copyWith(color: AppColors.outline)),
              Text('18.0% PROBABILITY', style: AppTextStyles.labelMedium.copyWith(color: AppColors.electricCyan)),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildActions(QuickEntryNotifier notifier, QuickEntryState state) {
    return Column(
      children: [
        SizedBox(
          width: double.infinity,
          height: 56,
          child: ElevatedButton(
            onPressed: state.isSubmitting ? null : () async {
              notifier.setSubmitting(true);
              await Future.delayed(const Duration(milliseconds: 900));
              notifier.setSubmitting(false);
              notifier.reset();
              if (mounted) Navigator.pop(context);
            },
            style: ElevatedButton.styleFrom(backgroundColor: Colors.transparent, shadowColor: Colors.transparent, padding: EdgeInsets.zero, shape: const ContinuousRectangleBorder(borderRadius: BorderRadius.zero)),
            child: Ink(
              decoration: BoxDecoration(
                gradient: AppColors.primaryActionGradient,
                border: Border.all(color: AppColors.electricCyan, width: 1.5),
                boxShadow: [BoxShadow(color: AppColors.electricCyan.withOpacity(0.4), blurRadius: 16), BoxShadow(color: AppColors.highVoltageYellow.withOpacity(0.3), blurRadius: 24)],
              ),
              child: Container(
                alignment: Alignment.center,
                child: Row(mainAxisAlignment: MainAxisAlignment.center, children: [
                  const Icon(Icons.electric_bolt, color: AppColors.coreVoid, size: 22),
                  const SizedBox(width: 12),
                  Text(state.isSubmitting ? 'TRANSMITTING TELEMETRY...' : 'RECORD OVERCLOCK [SYNC]', style: AppTextStyles.labelLargeUpper.copyWith(color: AppColors.coreVoid, fontWeight: FontWeight.bold)),
                  const SizedBox(width: 12),
                  const Icon(Icons.keyboard_double_arrow_right, color: AppColors.coreVoid, size: 22),
                ]),
              ),
            ),
          ),
        ),
        const SizedBox(height: 12),
        SizedBox(
          width: double.infinity,
          child: OutlinedButton(
            onPressed: () { notifier.reset(); Navigator.pop(context); },
            style: OutlinedButton.styleFrom(padding: const EdgeInsets.symmetric(vertical: 14)),
            child: Text('DISCARD PROTOCOL LOG', style: AppTextStyles.labelSmallUpper),
          ),
        ),
      ],
    );
  }
}

class _CounterButton extends StatelessWidget {
  final IconData icon;
  final VoidCallback onPressed;
  const _CounterButton({required this.icon, required this.onPressed});
  @override Widget build(BuildContext context) => Container(width: 52, height: 60, decoration: BoxDecoration(color: AppColors.surfaceContainerLowest, border: Border.all(color: AppColors.brushedMetallicTrim, width: 1)), child: IconButton(icon: Icon(icon, color: AppColors.electricCyan, size: 24), onPressed: onPressed));
}

class _QuickBoostButton extends StatelessWidget {
  final String label; final VoidCallback onPressed; final bool isMax;
  const _QuickBoostButton({required this.label, required this.onPressed, this.isMax = false});
  @override Widget build(BuildContext context) => Expanded(child: OutlinedButton(onPressed: onPressed, style: OutlinedButton.styleFrom(padding: const EdgeInsets.symmetric(vertical: 10), side: BorderSide(color: isMax ? AppColors.highVoltageYellow : AppColors.brushedMetallicTrim, width: isMax ? 1.5 : 1), backgroundColor: isMax ? AppColors.highVoltageYellow.withOpacity(0.1) : null), child: Text(label, style: AppTextStyles.labelSmallUpper.copyWith(color: isMax ? AppColors.highVoltageYellow : AppColors.onSurfaceVariant, fontWeight: isMax ? FontWeight.bold : FontWeight.normal))));
}