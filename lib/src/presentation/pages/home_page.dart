import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../core/theme/index.dart';
import '../../domain/entities/branch.dart';
import '../../domain/entities/user_profile.dart';
import '../providers/app_providers.dart';
import '../widgets/branch_card.dart';
import '../widgets/activity_item.dart';
import '../widgets/stat_pod.dart';
import '../widgets/module_header.dart';
import '../widgets/quick_action_button.dart';

class HomePage extends ConsumerStatefulWidget {
  const HomePage({super.key});

  @override
  ConsumerState<HomePage> createState() => _HomePageState();
}

class _HomePageState extends ConsumerState<HomePage> {
  final PageController _branchPageController = PageController(viewportFraction: 0.85);

  @override
  void dispose() {
    _branchPageController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final branchesAsync = ref.watch(branchesProvider);
    final profileAsync = ref.watch(userProfileProvider);
    final selectedIndex = ref.watch(selectedBranchIndexProvider);

    return Scaffold(
      backgroundColor: AppColors.background,
      body: SafeArea(
        child: CustomScrollView(
          slivers: [
            // App Bar
            SliverToBoxAdapter(
              child: _buildAppBar(profileAsync),
            ),
            // System Telemetry Marquee
            SliverToBoxAdapter(
              child: _buildTelemetryMarquee(profileAsync),
            ),
            // Character Status HUD
            SliverToBoxAdapter(
              child: _buildCharacterHUD(profileAsync),
            ),
            // Core Stats Quad
            SliverToBoxAdapter(
              child: _buildCoreStats(profileAsync),
            ),
            // Neural Skill Trees (Horizontal PageView)
            SliverToBoxAdapter(
              child: _buildSkillTreesHeader(),
            ),
            SliverToBoxAdapter(
              child: branchesAsync.when(
                data: (branches) => _buildBranchCarousel(branches, selectedIndex),
                loading: () => _buildBranchCarouselSkeleton(),
                error: (e, _) => _buildErrorState(e.toString()),
              ),
            ),
            // Activities Queue
            SliverToBoxAdapter(
              child: _buildActivitiesHeader(),
            ),
            SliverToBoxAdapter(
              child: branchesAsync.when(
                data: (branches) {
                  if (branches.isEmpty || selectedIndex >= branches.length) {
                    return _buildEmptyActivities();
                  }
                  final selectedBranch = branches[selectedIndex];
                  return _buildActivitiesList(selectedBranch);
                },
                loading: () => _buildActivitiesSkeleton(),
                error: (e, _) => _buildErrorState(e.toString()),
              ),
            ),
            // Quick Action Button
            SliverToBoxAdapter(
              child: _buildQuickAction(),
            ),
            // Bottom padding for navigation bar
            const SliverToBoxAdapter(
              child: SizedBox(height: 100),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildAppBar(AsyncValue<UserProfile?> profileAsync) {
    return Container(
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
          // Logo and title
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
                    'Dashboard',
                    style: AppTextStyles.headlineSmall,
                  ),
                ],
              ),
            ],
          ),
          const Spacer(),
          // Level badge
          profileAsync.when(
            data: (profile) {
              if (profile == null) return const SizedBox.shrink();
              return Container(
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
                      'LVL ${profile.level} • ${profile.title}',
                      style: AppTextStyles.labelSmallUpper.copyWith(
                        color: AppColors.highVoltageYellow,
                      ),
                    ),
                  ],
                ),
              );
            },
            loading: () => const SizedBox(width: 100, child: LinearProgressIndicator()),
            error: (_, __) => const SizedBox.shrink(),
          ),
          const SizedBox(width: 12),
          // Home button (upper right as per requirement)
          Container(
            width: 44,
            height: 44,
            decoration: BoxDecoration(
              color: AppColors.surfaceContainerHigh,
              border: Border.all(color: AppColors.brushedMetallicTrim, width: 1),
            ),
            child: IconButton(
              icon: const Icon(Icons.home, color: AppColors.electricCyan, size: 22),
              onPressed: () {
                // Scroll to top or navigate to home
              },
              tooltip: 'Quick Return Hub',
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildTelemetryMarquee(AsyncValue<UserProfile?> profileAsync) {
    return Container(
      margin: const EdgeInsets.all(16),
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      decoration: BoxDecoration(
        color: AppColors.surfaceContainerLowest,
        border: Border.all(color: AppColors.brushedMetallicTrim, width: 1),
        boxShadow: [
          BoxShadow(
            color: AppColors.electricCyan.withOpacity(0.1),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
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
          const SizedBox(width: 8),
          Text(
            'CORE OVERCLOCKED',
            style: AppTextStyles.labelSmallUpper.copyWith(
              color: AppColors.highVoltageYellow,
            ),
          ),
          const Spacer(),
          Row(
            children: [
              const Icon(Icons.local_fire_department, color: AppColors.highVoltageYellow, size: 16),
              const SizedBox(width: 4),
              Text(
                '14-DAY OVERCLOCK STREAK',
                style: AppTextStyles.hudMetricSmall.copyWith(
                  color: AppColors.highVoltageYellow,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildCharacterHUD(AsyncValue<UserProfile?> profileAsync) {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 16),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.surfaceContainerHigh,
        border: Border.all(color: AppColors.brushedMetallicTrim, width: 1),
        boxShadow: AppColors.cardElevation,
      ),
      child: Column(
        children: [
          // Module header
          Row(
            children: [
              Text(
                '// OPERATOR_STATUS: ACTIVE',
                style: AppTextStyles.labelSmallUpper.copyWith(
                  color: AppColors.electricCyan,
                ),
              ),
              const Spacer(),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                decoration: BoxDecoration(
                  color: AppColors.surfaceContainer,
                  border: Border.all(color: AppColors.brushedMetallicTrim, width: 1),
                ),
                child: profileAsync.when(
                  data: (profile) => Text(
                    'STAGE_0${(profile?.level ?? 1).clamp(1, 9)} // ${profile?.title ?? 'INITIATE'}',
                    style: AppTextStyles.labelSmallUpper.copyWith(
                      color: AppColors.highVoltageYellow,
                    ),
                  ),
                  loading: () => Text(
                    'STAGE_01 // INITIATE',
                    style: AppTextStyles.labelSmallUpper.copyWith(
                      color: AppColors.highVoltageYellow,
                    ),
                  ),
                  error: (_, __) => Text(
                    'STAGE_01 // INITIATE',
                    style: AppTextStyles.labelSmallUpper.copyWith(
                      color: AppColors.highVoltageYellow,
                    ),
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          // Identity & Level
          Row(
            children: [
              // Avatar/Emblem
              Container(
                width: 64,
                height: 64,
                decoration: BoxDecoration(
                  color: AppColors.surfaceContainerLowest,
                  border: Border.all(color: AppColors.electricCyan, width: 1.5),
                  boxShadow: [
                    BoxShadow(
                      color: AppColors.electricCyan.withOpacity(0.3),
                      blurRadius: 12,
                    ),
                  ],
                ),
                child: const Icon(Icons.person, color: AppColors.electricCyan, size: 32),
              ),
              const SizedBox(width: 16),
              // Identity Meta
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        profileAsync.when(
                          data: (profile) => Text(
                            profile?.displayName.toUpperCase() ?? 'V-NEXUS',
                            style: AppTextStyles.headlineMedium.copyWith(
                              color: AppColors.electricCyan,
                            ),
                          ),
                          loading: () => Text(
                            'V-NEXUS',
                            style: AppTextStyles.headlineMedium.copyWith(
                              color: AppColors.electricCyan,
                            ),
                          ),
                          error: (_, __) => Text(
                            'V-NEXUS',
                            style: AppTextStyles.headlineMedium.copyWith(
                              color: AppColors.electricCyan,
                            ),
                          ),
                        ),
                        const SizedBox(width: 8),
                        Text(
                          '#NX-8082',
                          style: AppTextStyles.labelSmall.copyWith(
                            color: AppColors.onSurfaceVariant,
                          ),
                        ),
                      ],
                    ),
                    profileAsync.when(
                      data: (profile) => Text(
                        'LVL ${profile?.level ?? 1} • ${profile?.title ?? 'CYBER TITAN'}',
                        style: AppTextStyles.labelMediumUpper.copyWith(
                          color: AppColors.highVoltageYellow,
                        ),
                      ),
                      loading: () => Text(
                        'LVL 1 • INITIATE',
                        style: AppTextStyles.labelMediumUpper.copyWith(
                          color: AppColors.highVoltageYellow,
                        ),
                      ),
                      error: (_, __) => Text(
                        'LVL 1 • INITIATE',
                        style: AppTextStyles.labelMediumUpper.copyWith(
                          color: AppColors.highVoltageYellow,
                        ),
                      ),
                    ),
                    const SizedBox(height: 4),
                    Row(
                      children: [
                        const Icon(Icons.memory, color: AppColors.electricCyan, size: 16),
                        const SizedBox(width: 6),
                        Text(
                          'Neural Matrix: Optimal State (99.4%)',
                          style: AppTextStyles.bodySmall.copyWith(
                            color: AppColors.onSurfaceVariant,
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          // XP Progress Bar
          _buildXpProgressBar(profileAsync),
        ],
      ),
    );
  }

  Widget _buildXpProgressBar(AsyncValue<UserProfile?> profileAsync) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: AppColors.surfaceContainerLowest,
        border: Border.all(color: AppColors.brushedMetallicTrim, width: 1),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                'NEURAL WATTAGE (XP)',
                style: AppTextStyles.labelSmallUpper.copyWith(
                  color: AppColors.onSurfaceVariant,
                ),
              ),
              profileAsync.when(
                data: (profile) {
                  final current = profile?.currentXp ?? 0;
                  final next = profile?.xpToNextLevel ?? 1000;
                  final percent = ((current / next) * 100).round();
                  return Row(
                    children: [
                      Text(
                        '$current',
                        style: AppTextStyles.hudMetric,
                      ),
                      Text(
                        ' / $next XP',
                        style: AppTextStyles.labelSmall.copyWith(
                          color: AppColors.outline,
                        ),
                      ),
                      const SizedBox(width: 8),
                      Text(
                        '($percent%)',
                        style: AppTextStyles.hudMetricSmall.copyWith(
                          color: AppColors.highVoltageYellow,
                        ),
                      ),
                    ],
                  );
                },
                loading: () => const SizedBox.shrink(),
                error: (_, __) => const SizedBox.shrink(),
              ),
            ],
          ),
          const SizedBox(height: 8),
          // Segmented track
          Row(
            children: List.generate(10, (index) {
              final progress = profileAsync.when(
                data: (p) => (p?.currentXp ?? 0) / (p?.xpToNextLevel ?? 1000),
                loading: () => 0.0,
                error: (_, __) => 0.0,
              );
              final filled = index < (progress * 10).floor();
              return Expanded(
                child: Container(
                  height: 8,
                  margin: EdgeInsets.only(right: index == 9 ? 0 : 2),
                  decoration: BoxDecoration(
                    color: filled ? AppColors.electricCyan : AppColors.surfaceContainer,
                    border: Border.all(
                      color: filled ? AppColors.electricCyan : AppColors.brushedMetallicTrim,
                      width: 1,
                    ),
                    boxShadow: filled
                        ? [BoxShadow(color: AppColors.electricCyan.withOpacity(0.7), blurRadius: 8)]
                        : null,
                  ),
                ),
              );
            }),
          ),
          const SizedBox(height: 8),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text('LVL ${profileAsync.value?.level ?? 1} INIT', style: AppTextStyles.labelSmall.copyWith(color: AppColors.outline)),
              Text('⚡ +${(profileAsync.value?.xpToNextLevel ?? 1000) - (profileAsync.value?.currentXp ?? 0)} XP TO ASCENSION', style: AppTextStyles.labelSmallUpper.copyWith(color: AppColors.electricCyan)),
              Text('LVL ${(profileAsync.value?.level ?? 1) + 1}', style: AppTextStyles.labelSmall.copyWith(color: AppColors.outline)),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildCoreStats(AsyncValue<UserProfile?> profileAsync) {
    final stats = profileAsync.when(
      data: (p) => p?.coreStats ?? {
        'energy': 94,
        'willpower': 88,
        'synapse': 76,
        'cyberware': 92,
      },
      loading: () => {
        'energy': 94,
        'willpower': 88,
        'synapse': 76,
        'cyberware': 92,
      },
      error: (_, __) => {
        'energy': 94,
        'willpower': 88,
        'synapse': 76,
        'cyberware': 92,
      },
    );

    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 16),
      child: GridView.count(
        crossAxisCount: 2,
        shrinkWrap: true,
        physics: const NeverScrollableScrollPhysics(),
        childAspectRatio: 2.5,
        crossAxisSpacing: 12,
        mainAxisSpacing: 12,
        children: [
          StatPod(
            icon: Icons.bolt,
            label: 'ENERGY RESERVES',
            value: '${stats['energy']}%',
            iconColor: AppColors.electricCyan,
            valueColor: AppColors.electricCyan,
            progress: stats['energy']! / 100,
          ),
          StatPod(
            icon: Icons.favorite,
            label: 'WILLPOWER CORE',
            value: '${stats['willpower']}%',
            iconColor: AppColors.highVoltageYellow,
            valueColor: AppColors.highVoltageYellow,
            progress: stats['willpower']! / 100,
          ),
          StatPod(
            icon: Icons.psychology,
            label: 'SYNAPSE POWER',
            value: '${stats['synapse']}%',
            iconColor: AppColors.electricViolet,
            valueColor: AppColors.electricViolet,
            progress: stats['synapse']! / 100,
          ),
          StatPod(
            icon: Icons.sync,
            label: 'CYBERWARE SYNC',
            value: '${stats['cyberware']}%',
            iconColor: AppColors.electricCyan,
            valueColor: AppColors.electricCyan,
            progress: stats['cyberware']! / 100,
          ),
        ],
      ),
    );
  }

  Widget _buildSkillTreesHeader() {
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 16, 16, 8),
      child: Row(
        children: [
          const Icon(Icons.hub, color: AppColors.highVoltageYellow, size: 20),
          const SizedBox(width: 8),
          Text(
            'NEURAL SKILL TREES',
            style: AppTextStyles.headlineSmall,
          ),
          const Spacer(),
          Text(
            '4 ACTIVE NODES',
            style: AppTextStyles.labelSmallUpper.copyWith(
              color: AppColors.electricCyan,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildBranchCarousel(List<Branch> branches, int selectedIndex) {
    return SizedBox(
      height: 320,
      child: PageView.builder(
        controller: _branchPageController,
        itemCount: branches.length,
        onPageChanged: (index) {
          ref.read(selectedBranchIndexProvider.notifier).state = index;
        },
        itemBuilder: (context, index) {
          final branch = branches[index];
          final isSelected = index == selectedIndex;
          return Padding(
            padding: EdgeInsets.only(right: 12, left: index == 0 ? 16 : 0),
            child: BranchCard.fromEntity(
              branch: branch,
              isSelected: isSelected,
              onTap: () {
                ref.read(selectedBranchIndexProvider.notifier).state = index;
              },
            ),
          );
        },
      ),
    );
  }

  Widget _buildBranchCarouselSkeleton() {
    return SizedBox(
      height: 320,
      child: ListView.builder(
        scrollDirection: Axis.horizontal,
        padding: const EdgeInsets.symmetric(horizontal: 16),
        itemCount: 4,
        itemBuilder: (context, index) => Container(
          width: 280,
          margin: const EdgeInsets.only(right: 12),
          child: CyberCard(
            child: Column(
              children: List.generate(4, (i) => Container(
                height: 60,
                margin: const EdgeInsets.only(bottom: 12),
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

  Widget _buildActivitiesHeader() {
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 16, 16, 8),
      child: Row(
        children: [
          const Icon(Icons.offline_bolt, color: AppColors.electricCyan, size: 22),
          const SizedBox(width: 8),
          Text(
            'ACTIVITIES IN QUEUE',
            style: AppTextStyles.headlineSmall,
          ),
          const SizedBox(width: 8),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
            decoration: BoxDecoration(
              color: AppColors.electricCyan.withOpacity(0.2),
              border: Border.all(color: AppColors.electricCyan, width: 1),
            ),
            child: Text(
              '3 READY',
              style: AppTextStyles.hudMetricSmall.copyWith(color: AppColors.electricCyan),
            ),
          ),
          const Spacer(),
          TextButton(
            onPressed: () {},
            child: Text(
              'HISTORY',
              style: AppTextStyles.labelSmallUpper.copyWith(
                color: AppColors.highVoltageYellow,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildActivitiesList(Branch branch) {
    // Sample activities for demo - in real app would come from activitiesProvider
    return Column(
      children: [
        ActivityItem(
          name: 'Push-ups Protocol',
          description: '3 Sets × 25 Tactical Repetitions',
          category: 'STRENGTH',
          categoryColor: AppColors.electricCyan,
          icon: Icons.sports_martial_arts,
          iconColor: AppColors.electricCyan,
          xpReward: 45,
          statReward: '+2 POWER',
          statColor: AppColors.electricCyan,
          onRecord: () {},
        ),
        ActivityItem(
          name: 'High-Velocity Neon Run',
          description: 'Distance Goal: 5.0 KM • Cyber Pacing',
          category: 'CARDIO',
          categoryColor: AppColors.highVoltageYellow,
          icon: Icons.directions_run,
          iconColor: AppColors.highVoltageYellow,
          xpReward: 80,
          statReward: '+5 STAMINA',
          statColor: AppColors.highVoltageYellow,
          onSync: () {},
        ),
        ActivityItem(
          name: 'Heavy Core Plank',
          description: 'Isometric Hold • 3 Minutes Constant Tension',
          category: 'ENDURANCE',
          categoryColor: AppColors.electricCyan,
          icon: Icons.timer,
          iconColor: AppColors.electricCyan,
          xpReward: 35,
          statReward: '+1 WILLPOWER',
          statColor: AppColors.highVoltageYellow,
          onRecord: () {},
        ),
      ],
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

  Widget _buildEmptyActivities() {
    return Container(
      margin: const EdgeInsets.all(16),
      padding: const EdgeInsets.all(32),
      child: CyberCard(
        child: Column(
          children: [
            const Icon(Icons.add_task, color: AppColors.mutedAlloyText, size: 48),
            const SizedBox(height: 16),
            Text(
              'NO ACTIVITIES IN QUEUE',
              style: AppTextStyles.headlineSmall.copyWith(color: AppColors.mutedAlloyText),
            ),
            const SizedBox(height: 8),
            Text(
              'Add activities in the Config module to start tracking',
              style: AppTextStyles.bodyMedium.copyWith(color: AppColors.onSurfaceVariant),
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildQuickAction() {
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 8, 16, 16),
      child: QuickActionButton(
        label: '+ Quick Action Entry',
        icon: Icons.add_circle,
        onPressed: () {
          // Navigate to quick entry modal
          _showQuickEntryModal(context);
        },
      ),
    );
  }

  void _showQuickEntryModal(BuildContext context) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => _QuickEntryModal(),
    );
  }
}

class _QuickEntryModal extends ConsumerStatefulWidget {
  @override
  ConsumerState<_QuickEntryModal> createState() => _QuickEntryModalState();
}

class _QuickEntryModalState extends ConsumerState<_QuickEntryModal> {
  @override
  Widget build(BuildContext context) {
    final quickEntry = ref.watch(quickEntryProvider);
    final notifier = ref.read(quickEntryProvider.notifier);

    return Container(
      height: MediaQuery.of(context).size.height * 0.85,
      decoration: const BoxDecoration(
        color: AppColors.surfaceContainer,
        borderRadius: BorderRadius.vertical(top: Radius.circular(0)),
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
                  '// MOD.03_ACTIVITY_LOG',
                  style: AppTextStyles.labelSmallUpper.copyWith(
                    color: AppColors.electricCyan,
                  ),
                ),
                const Spacer(),
                Text(
                  'SIGNAL: 98.4% LOCKED',
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
                  _buildActivityHeader(),
                  const SizedBox(height: 16),
                  // Rep Counter
                  _buildRepCounter(notifier, quickEntry),
                  const SizedBox(height: 16),
                  // Sets
                  _buildSets(notifier, quickEntry),
                  const SizedBox(height: 16),
                  // RPE Gauge
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

  Widget _buildActivityHeader() {
    return CyberCard(
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
                    'SESSION LOG // PHYSICAL DEVELOPMENT',
                    style: AppTextStyles.labelSmallUpper.copyWith(
                      color: AppColors.electricCyan,
                    ),
                  ),
                ),
                const SizedBox(height: 8),
                Row(
                  children: [
                    Text(
                      'Push-ups Protocol',
                      style: AppTextStyles.headlineMedium,
                    ),
                    const SizedBox(width: 8),
                    const Icon(Icons.bolt, color: AppColors.highVoltageYellow, size: 22),
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
            child: const Icon(Icons.fitness_center, color: AppColors.electricCyan, size: 24),
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
                  Text(
                    'Repetition Counter',
                    style: AppTextStyles.labelSmallUpper,
                  ),
                ],
              ),
              Text(
                'TARGET: 30 REPS',
                style: AppTextStyles.labelSmallUpper.copyWith(
                  color: AppColors.electricCyan,
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          Row(
            children: [
              // Minus button
              _CounterButton(
                icon: Icons.remove,
                onPressed: () => notifier.incrementReps(-1),
              ),
              // Display
              Expanded(
                child: Container(
                  height: 60,
                  alignment: Alignment.center,
                  decoration: BoxDecoration(
                    color: AppColors.surfaceContainerLowest,
                    border: Border.all(color: AppColors.brushedMetallicTrim, width: 1),
                    boxShadow: [
                      BoxShadow(
                        color: AppColors.electricCyan.withOpacity(0.1),
                        blurRadius: 8,
                        offset: const Offset(0, 2),
                      ),
                    ],
                  ),
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Text(
                        '${state.reps}',
                        style: AppTextStyles.displayLargeMobile.copyWith(
                          color: AppColors.electricCyan,
                          fontSize: 36,
                        ),
                      ),
                      Text(
                        'EXECUTIONS',
                        style: AppTextStyles.labelSmallUpper.copyWith(
                          color: AppColors.outline,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
              // Plus button
              _CounterButton(
                icon: Icons.add,
                onPressed: () => notifier.incrementReps(1),
              ),
            ],
          ),
          const SizedBox(height: 12),
          // Quick boost buttons
          Row(
            children: [
              _QuickBoostButton(label: '+5', onPressed: () => notifier.incrementReps(5)),
              const SizedBox(width: 8),
              _QuickBoostButton(label: '+10', onPressed: () => notifier.incrementReps(10)),
              const SizedBox(width: 8),
              _QuickBoostButton(label: '+25', onPressed: () => notifier.incrementReps(25)),
              const SizedBox(width: 8),
              _QuickBoostButton(
                label: 'MAX',
                onPressed: () => notifier.setReps(50),
                isMax: true,
              ),
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
                  Text(
                    'Sets Completed',
                    style: AppTextStyles.labelSmallUpper,
                  ),
                ],
              ),
              Text(
                'CHAIN STREAK: x${state.sets}',
                style: AppTextStyles.labelSmallUpper.copyWith(
                  color: AppColors.highVoltageYellow,
                ),
              ),
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
                    border: Border.all(
                      color: isActive ? AppColors.electricCyan : AppColors.brushedMetallicTrim,
                      width: isActive ? 2 : 1,
                    ),
                    boxShadow: isActive
                        ? [BoxShadow(color: AppColors.electricCyan.withOpacity(0.4), blurRadius: 8)]
                        : null,
                  ),
                  child: Column(
                    children: [
                      Text(
                        '${index + 1}',
                        style: AppTextStyles.hudMetricSmall.copyWith(
                          color: isActive ? AppColors.coreVoid : AppColors.onSurfaceVariant,
                        ),
                      ),
                      Text(
                        index == 0 ? 'WARMUP' : index == 1 ? 'NORMAL' : index == 2 ? 'CURRENT' : 'OVERLOAD',
                        style: AppTextStyles.labelSmall.copyWith(
                          color: isActive ? AppColors.coreVoid : AppColors.onSurfaceVariant,
                          fontSize: 8,
                        ),
                      ),
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
                  Text(
                    'Intensity / RPE Gauge',
                    style: AppTextStyles.labelSmallUpper,
                  ),
                ],
              ),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                decoration: BoxDecoration(
                  color: AppColors.surfaceContainerLowest,
                  border: Border.all(color: AppColors.highVoltageYellow, width: 1),
                ),
                child: Text(
                  'RPE ${state.rpe.toStringAsFixed(1)} • $rpeLabel',
                  style: AppTextStyles.labelSmallUpper.copyWith(
                    color: AppColors.highVoltageYellow,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          // Segmented rail
          Row(
            children: List.generate(10, (index) {
              final filled = index < state.rpe.floor();
              final isYellow = index >= 7;
              return Expanded(
                child: Container(
                  height: 12,
                  margin: EdgeInsets.only(right: index == 9 ? 0 : 2),
                  decoration: BoxDecoration(
                    color: filled
                        ? (isYellow ? AppColors.highVoltageYellow : AppColors.electricCyan)
                        : AppColors.surfaceContainerLowest,
                    border: Border.all(
                      color: filled
                          ? (isYellow ? AppColors.highVoltageYellow : AppColors.electricCyan)
                          : AppColors.brushedMetallicTrim,
                      width: 1,
                    ),
                    boxShadow: filled
                        ? [BoxShadow(
                            color: (isYellow ? AppColors.highVoltageYellow : AppColors.electricCyan)
                                .withOpacity(0.7),
                            blurRadius: 6,
                          )]
                        : null,
                  ),
                ),
              );
            }),
          ),
          const SizedBox(height: 8),
          // Slider
          SliderTheme(
            data: SliderTheme.of(context).copyWith(
              activeTrackColor: AppColors.electricCyan,
              inactiveTrackColor: AppColors.brushedMetallicTrim,
              thumbColor: AppColors.electricCyan,
              trackHeight: 4,
            ),
            child: Slider(
              value: state.rpe,
              min: 1,
              max: 10,
              divisions: 18,
              onChanged: notifier.setRpe,
            ),
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
          Row(
            children: [
              const Icon(Icons.code, color: AppColors.outline, size: 16),
              const SizedBox(width: 8),
              Text(
                'Operational Debrief / Memo',
                style: AppTextStyles.labelSmallUpper,
              ),
            ],
          ),
          const SizedBox(height: 12),
          TextField(
            onChanged: notifier.setNotes,
            style: AppTextStyles.bodyMedium,
            decoration: InputDecoration(
              hintText: 'Enter operational debrief / form notes...',
              hintStyle: AppTextStyles.bodyMedium.copyWith(
                color: AppColors.mutedAlloyText.withOpacity(0.6),
              ),
              filled: true,
              fillColor: AppColors.surfaceContainerLowest,
              border: OutlineInputBorder(
                borderRadius: BorderRadius.zero,
                borderSide: const BorderSide(color: AppColors.brushedMetallicTrim),
              ),
              focusedBorder: OutlineInputBorder(
                borderRadius: BorderRadius.zero,
                borderSide: const BorderSide(color: AppColors.electricCyan, width: 2),
              ),
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
        boxShadow: [
          BoxShadow(
            color: AppColors.highVoltageYellow.withOpacity(0.3),
            blurRadius: 16,
          ),
        ],
      ),
      child: Row(
        children: [
          Container(
            width: 4,
            height: 60,
            color: AppColors.highVoltageYellow,
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'CALCULATED POWER GAIN',
                  style: AppTextStyles.labelSmallUpper.copyWith(
                    color: AppColors.onSurfaceVariant,
                  ),
                ),
                const SizedBox(height: 4),
                Row(
                  children: [
                    Text(
                      '+${state.calculatedXp} XP',
                      style: AppTextStyles.hudMetric.copyWith(
                        color: AppColors.highVoltageYellow,
                        fontSize: 28,
                      ),
                    ),
                    const SizedBox(width: 8),
                    Text(
                      '⚡ OVERCLOCK READY',
                      style: AppTextStyles.labelSmallUpper.copyWith(
                        color: AppColors.electricCyan,
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
          Column(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              Text(
                'OVERLOAD RISK',
                style: AppTextStyles.labelSmallUpper.copyWith(
                  color: AppColors.outline,
                ),
              ),
              Text(
                '18.0% PROBABILITY',
                style: AppTextStyles.labelMedium.copyWith(
                  color: AppColors.electricCyan,
                ),
              ),
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
            onPressed: state.isSubmitting
                ? null
                : () async {
                    notifier.setSubmitting(true);
                    await Future.delayed(const Duration(milliseconds: 900));
                    notifier.setSubmitting(false);
                    notifier.reset();
                    if (mounted) Navigator.pop(context);
                  },
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.transparent,
              shadowColor: Colors.transparent,
              padding: EdgeInsets.zero,
              shape: const ContinuousRectangleBorder(
                borderRadius: BorderRadius.zero,
              ),
            ),
            child: Ink(
              decoration: BoxDecoration(
                gradient: AppColors.primaryActionGradient,
                border: Border.all(
                  color: AppColors.electricCyan,
                  width: 1.5,
                ),
                boxShadow: [
                  BoxShadow(
                    color: AppColors.electricCyan.withOpacity(0.4),
                    blurRadius: 16,
                  ),
                  BoxShadow(
                    color: AppColors.highVoltageYellow.withOpacity(0.3),
                    blurRadius: 24,
                  ),
                ],
              ),
              child: Container(
                alignment: Alignment.center,
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    const Icon(Icons.electric_bolt, color: AppColors.coreVoid, size: 22),
                    const SizedBox(width: 12),
                    Text(
                      state.isSubmitting ? 'TRANSMITTING TELEMETRY...' : 'RECORD OVERCLOCK [SYNC]',
                      style: AppTextStyles.labelLargeUpper.copyWith(
                        color: AppColors.coreVoid,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(width: 12),
                    const Icon(Icons.keyboard_double_arrow_right, color: AppColors.coreVoid, size: 22),
                  ],
                ),
              ),
            ),
          ),
        ),
        const SizedBox(height: 12),
        SizedBox(
          width: double.infinity,
          child: OutlinedButton(
            onPressed: () {
              notifier.reset();
              Navigator.pop(context);
            },
            style: OutlinedButton.styleFrom(
              padding: const EdgeInsets.symmetric(vertical: 14),
            ),
            child: Text(
              'DISCARD PROTOCOL LOG',
              style: AppTextStyles.labelSmallUpper,
            ),
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

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 52,
      height: 60,
      decoration: BoxDecoration(
        color: AppColors.surfaceContainerLowest,
        border: Border.all(color: AppColors.brushedMetallicTrim, width: 1),
      ),
      child: IconButton(
        icon: Icon(icon, color: AppColors.electricCyan, size: 24),
        onPressed: onPressed,
      ),
    );
  }
}

class _QuickBoostButton extends StatelessWidget {
  final String label;
  final VoidCallback onPressed;
  final bool isMax;

  const _QuickBoostButton({
    required this.label,
    required this.onPressed,
    this.isMax = false,
  });

  @override
  Widget build(BuildContext context) {
    return Expanded(
      child: OutlinedButton(
        onPressed: onPressed,
        style: OutlinedButton.styleFrom(
          padding: const EdgeInsets.symmetric(vertical: 10),
          side: BorderSide(
            color: isMax ? AppColors.highVoltageYellow : AppColors.brushedMetallicTrim,
            width: isMax ? 1.5 : 1,
          ),
          backgroundColor: isMax ? AppColors.highVoltageYellow.withOpacity(0.1) : null,
        ),
        child: Text(
          label,
          style: AppTextStyles.labelSmallUpper.copyWith(
            color: isMax ? AppColors.highVoltageYellow : AppColors.onSurfaceVariant,
            fontWeight: isMax ? FontWeight.bold : FontWeight.normal,
          ),
        ),
      ),
    );
  }
}