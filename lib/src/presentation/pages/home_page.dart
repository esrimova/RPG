import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:uuid/uuid.dart';
import '../../core/theme/index.dart';
import '../../domain/entities/branch.dart';
import '../../domain/entities/activity.dart';
import '../../domain/entities/user_profile.dart';
import '../providers/app_providers.dart';
import '../widgets/branch_card.dart';
import '../widgets/activity_item.dart';
import '../widgets/stat_pod.dart';
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
            'DAILY PROGRESS',
            style: AppTextStyles.labelSmallUpper.copyWith(
              color: AppColors.highVoltageYellow,
            ),
          ),
          const Spacer(),
          Row(
            children: [
              const Icon(Icons.local_fire_department, color: AppColors.highVoltageYellow, size: 16),
              const SizedBox(width: 4),
              profileAsync.when(
                data: (profile) => Text(
                  profile?.currentStreak != null && profile!.currentStreak > 0 ? '${profile.currentStreak}-DAY STREAK' : 'NO STREAK',
                  style: AppTextStyles.hudMetricSmall.copyWith(
                    color: AppColors.highVoltageYellow,
                  ),
                ),
                loading: () => Text(
                  '...',
                  style: AppTextStyles.hudMetricSmall.copyWith(
                    color: AppColors.highVoltageYellow,
                  ),
                ),
                error: (_, __) => Text(
                  'NO STREAK',
                  style: AppTextStyles.hudMetricSmall.copyWith(
                    color: AppColors.highVoltageYellow,
                  ),
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
                'YOUR PROFILE',
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
                    'LEVEL ${profile?.level ?? 1}',
                    style: AppTextStyles.labelSmallUpper.copyWith(
                      color: AppColors.highVoltageYellow,
                    ),
                  ),
                  loading: () => Text(
                    'LEVEL 1',
                    style: AppTextStyles.labelSmallUpper.copyWith(
                      color: AppColors.highVoltageYellow,
                    ),
                  ),
                  error: (_, __) => Text(
                    'LEVEL 1',
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
                            profile?.displayName?.toUpperCase() ?? 'USER',
                            style: AppTextStyles.headlineMedium.copyWith(
                              color: AppColors.electricCyan,
                            ),
                          ),
                          loading: () => Text(
                            'USER',
                            style: AppTextStyles.headlineMedium.copyWith(
                              color: AppColors.electricCyan,
                            ),
                          ),
                          error: (_, __) => Text(
                            'USER',
                            style: AppTextStyles.headlineMedium.copyWith(
                              color: AppColors.electricCyan,
                            ),
                          ),
                        ),
                        const SizedBox(width: 8),
                        Text(
                          profileAsync.value?.username != null ? '@${profileAsync.value!.username}' : '',
                          style: AppTextStyles.labelSmall.copyWith(
                            color: AppColors.onSurfaceVariant,
                          ),
                        ),
                      ],
                    ),
                    profileAsync.when(
                      data: (profile) => Text(
                        'LEVEL ${profile?.level ?? 1} • ${profile?.title ?? 'Beginner'}',
                        style: AppTextStyles.labelMediumUpper.copyWith(
                          color: AppColors.highVoltageYellow,
                        ),
                      ),
                      loading: () => Text(
                        'LEVEL 1 • BEGINNER',
                        style: AppTextStyles.labelMediumUpper.copyWith(
                          color: AppColors.highVoltageYellow,
                        ),
                      ),
                      error: (_, __) => Text(
                        'LEVEL 1 • BEGINNER',
                        style: AppTextStyles.labelMediumUpper.copyWith(
                          color: AppColors.highVoltageYellow,
                        ),
                      ),
                    ),
                    const SizedBox(height: 4),
                    Row(
                      children: [
                        const Icon(Icons.trending_up, color: AppColors.electricCyan, size: 16),
                        const SizedBox(width: 6),
                        Text(
                          profileAsync.value?.currentXp != null ? '${profileAsync.value!.currentXp} XP' : '0 XP',
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
                'XP PROGRESS',
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
              Text('LEVEL ${profileAsync.value?.level ?? 1}', style: AppTextStyles.labelSmall.copyWith(color: AppColors.outline)),
              Text('${(profileAsync.value?.xpToNextLevel ?? 1000) - (profileAsync.value?.currentXp ?? 0)} XP TO NEXT LEVEL', style: AppTextStyles.labelSmallUpper.copyWith(color: AppColors.electricCyan)),
              Text('LEVEL ${(profileAsync.value?.level ?? 1) + 1}', style: AppTextStyles.labelSmall.copyWith(color: AppColors.outline)),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildCoreStats(AsyncValue<UserProfile?> profileAsync) {
    final stats = profileAsync.when(
      data: (p) => p?.coreStats ?? {
        'energy': 0,
        'willpower': 0,
        'synapse': 0,
        'cyberware': 0,
      },
      loading: () => {
        'energy': 0,
        'willpower': 0,
        'synapse': 0,
        'cyberware': 0,
      },
      error: (_, __) => {
        'energy': 0,
        'willpower': 0,
        'synapse': 0,
        'cyberware': 0,
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
            label: 'ENERGY',
            value: '${stats['energy']}%',
            iconColor: AppColors.electricCyan,
            valueColor: AppColors.electricCyan,
            progress: stats['energy']! / 100,
          ),
          StatPod(
            icon: Icons.favorite,
            label: 'WILLPOWER',
            value: '${stats['willpower']}%',
            iconColor: AppColors.highVoltageYellow,
            valueColor: AppColors.highVoltageYellow,
            progress: stats['willpower']! / 100,
          ),
          StatPod(
            icon: Icons.psychology,
            label: 'FOCUS',
            value: '${stats['synapse']}%',
            iconColor: AppColors.electricViolet,
            valueColor: AppColors.electricViolet,
            progress: stats['synapse']! / 100,
          ),
          StatPod(
            icon: Icons.sync,
            label: 'CONSISTENCY',
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
            'SKILL BRANCHES',
            style: AppTextStyles.headlineSmall,
          ),
          const Spacer(),
          Text(
            'ACTIVE BRANCHES',
            style: AppTextStyles.labelSmallUpper.copyWith(
              color: AppColors.electricCyan,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildBranchCarousel(List<Branch> branches, int selectedIndex) {
    if (branches.isEmpty) {
      return _buildEmptyBranches();
    }
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

  Widget _buildEmptyBranches() {
    return SizedBox(
      height: 320,
      child: Center(
        child: Container(
          width: 280,
          padding: const EdgeInsets.all(32),
          child: CyberCard(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                const Icon(Icons.hub, color: AppColors.mutedAlloyText, size: 48),
                const SizedBox(height: 16),
                Text(
                  'NO SKILL TREES INITIALIZED',
                  style: AppTextStyles.headlineSmall.copyWith(color: AppColors.mutedAlloyText),
                ),
                const SizedBox(height: 8),
                Text(
                  'Create your first branch in the Config module',
                  style: AppTextStyles.bodyMedium.copyWith(color: AppColors.onSurfaceVariant),
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 16),
                QuickActionButton(
                  label: '+ CREATE BRANCH',
                  icon: Icons.add,
                  onPressed: () => _showCreateBranchDialog(context),
                ),
              ],
            ),
          ),
        ),
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
    final branchesAsync = ref.watch(branchesProvider);
    final selectedIndex = ref.watch(selectedBranchIndexProvider);
    
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 16, 16, 8),
      child: branchesAsync.when(
        data: (branches) {
          if (branches.isEmpty || selectedIndex >= branches.length) {
            return Row(
              children: [
                const Icon(Icons.list_alt, color: AppColors.electricCyan, size: 22),
                const SizedBox(width: 8),
                Text(
                  'ACTIVITIES',
                  style: AppTextStyles.headlineSmall,
                ),
              ],
            );
          }
          final selectedBranch = branches[selectedIndex];
          return Row(
            children: [
              const Icon(Icons.list_alt, color: AppColors.electricCyan, size: 22),
              const SizedBox(width: 8),
              Text(
                'ACTIVITIES',
                style: AppTextStyles.headlineSmall,
              ),
              const SizedBox(width: 8),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                decoration: BoxDecoration(
                  color: AppColors.electricCyan.withValues(alpha: 0.2),
                  border: Border.all(color: AppColors.electricCyan, width: 1),
                ),
                child: FutureBuilder<List<Activity>>(
                  future: ref.read(getActivitiesUseCaseProvider).call(selectedBranch.id),
                  builder: (context, snapshot) {
                    final count = snapshot.data?.length ?? 0;
                    return Text(
                      '$count ACTIVITIES',
                      style: AppTextStyles.hudMetricSmall.copyWith(color: AppColors.electricCyan),
                    );
                  },
                ),
              ),
              const Spacer(),
              TextButton(
                onPressed: () {
                  // Navigate to activity page for this branch
                },
                child: Text(
                  'VIEW ALL',
                  style: AppTextStyles.labelSmallUpper.copyWith(
                    color: AppColors.highVoltageYellow,
                  ),
                ),
              ),
            ],
          );
        },
        loading: () => const SizedBox.shrink(),
        error: (_, __) => const SizedBox.shrink(),
      ),
    );
  }

  Widget _buildActivitiesList(Branch branch) {
    final activitiesAsync = ref.watch(activitiesProvider(branch.id));
    
    return activitiesAsync.when(
      data: (activities) {
        if (activities.isEmpty) {
          return _buildEmptyActivitiesForBranch(branch);
        }
        return Column(
          children: activities.map((activity) => ActivityItem(
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
          )).toList(),
        );
      },
      loading: () => _buildActivitiesSkeleton(),
      error: (e, _) => _buildErrorState(e.toString()),
    );
  }

  Widget _buildEmptyActivitiesForBranch(Branch branch) {
    return Container(
      margin: const EdgeInsets.all(16),
      padding: const EdgeInsets.all(32),
      child: CyberCard(
        child: Column(
          children: [
            const Icon(Icons.add_task, color: AppColors.mutedAlloyText, size: 48),
            const SizedBox(height: 16),
            Text(
              'NO ACTIVITIES IN ${branch.name}',
              style: AppTextStyles.headlineSmall.copyWith(color: AppColors.mutedAlloyText),
            ),
            const SizedBox(height: 8),
            Text(
              'Add activities in the Config tab to start tracking',
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
              'NO ACTIVITIES YET',
              style: AppTextStyles.headlineSmall.copyWith(color: AppColors.mutedAlloyText),
            ),
            const SizedBox(height: 8),
            Text(
              'Add activities in the Config tab to start tracking',
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

  void _showCreateBranchDialog(BuildContext context) {
    showDialog(
      context: context,
      builder: (context) => _CreateBranchDialog(),
    );
  }

  void _recordActivity(Activity activity) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text('Record ${activity.name}', style: AppTextStyles.bodyMedium),
        backgroundColor: AppColors.surfaceContainerHigh,
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
      ),
    );
  }

  void _syncActivity(Activity activity) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text('Sync ${activity.name}', style: AppTextStyles.bodyMedium),
        backgroundColor: AppColors.surfaceContainerHigh,
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
      ),
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
                  'RECORD ACTIVITY',
                  style: AppTextStyles.labelSmallUpper.copyWith(
                    color: AppColors.electricCyan,
                  ),
                ),
                const Spacer(),
                Text(
                  'READY TO LOG',
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
    final quickEntry = ref.watch(quickEntryProvider);
    final selectedBranch = quickEntry.selectedBranch;
    final selectedActivity = quickEntry.selectedActivity;
    
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
                    selectedBranch != null ? selectedBranch.name.toUpperCase() : 'SELECT BRANCH',
                    style: AppTextStyles.labelSmallUpper.copyWith(
                      color: AppColors.electricCyan,
                    ),
                  ),
                ),
                const SizedBox(height: 8),
                Row(
                  children: [
                    Text(
                      selectedActivity?.name ?? 'SELECT ACTIVITY',
                      style: AppTextStyles.headlineMedium,
                    ),
                    if (selectedActivity != null) ...[
                      const SizedBox(width: 8),
                      const Icon(Icons.bolt, color: AppColors.highVoltageYellow, size: 22),
                    ],
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
            child: Icon(
              selectedActivity?.icon ?? Icons.fitness_center, 
              color: selectedActivity?.accentColor ?? AppColors.electricCyan, 
              size: 24
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
                    'Sets',
                    style: AppTextStyles.labelSmallUpper,
                  ),
                ],
              ),
              Text(
                '${state.sets} SETS',
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
                        'SET ${index + 1}',
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
    if (state.rpe >= 8.5) rpeLabel = 'MAXIMUM';
    else if (state.rpe >= 7) rpeLabel = 'HARD';
    else rpeLabel = 'MODERATE';

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
                    'Intensity (RPE 1-10)',
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
              const Icon(Icons.note, color: AppColors.outline, size: 16),
              const SizedBox(width: 8),
              Text(
                'Notes',
                style: AppTextStyles.labelSmallUpper,
              ),
            ],
          ),
          const SizedBox(height: 12),
          TextField(
            onChanged: notifier.setNotes,
            style: AppTextStyles.bodyMedium,
            decoration: InputDecoration(
              hintText: 'Add optional notes...',
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
                  'ESTIMATED XP GAIN',
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
                      'READY TO LOG',
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
          backgroundColor: isMax ? AppColors.highVoltageYellow.withValues(alpha: 0.1) : null,
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

class _CreateBranchDialog extends ConsumerStatefulWidget {
  @override
  ConsumerState<_CreateBranchDialog> createState() => _CreateBranchDialogState();
}

class _CreateBranchDialogState extends ConsumerState<_CreateBranchDialog> {
  final _formKey = GlobalKey<FormState>();
  final _nameController = TextEditingController();
  final _descriptionController = TextEditingController();
  Color _selectedColor = AppColors.electricCyan;
  IconData _selectedIcon = Icons.hub;
  bool _isSubmitting = false;

  final List<Color> _availableColors = [
    AppColors.electricCyan,
    AppColors.highVoltageYellow,
    AppColors.electricViolet,
    AppColors.overloadCrimson,
  ];

  final List<IconData> _availableIcons = [
    Icons.hub,
    Icons.fitness_center,
    Icons.code,
    Icons.psychology,
    Icons.favorite,
    Icons.sync,
    Icons.bolt,
    Icons.auto_awesome,
  ];

  @override
  void dispose() {
    _nameController.dispose();
    _descriptionController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Dialog(
      backgroundColor: Colors.transparent,
      child: Container(
        width: double.maxFinite,
        constraints: const BoxConstraints(maxWidth: 400),
        decoration: BoxDecoration(
          color: AppColors.surfaceContainerHigh,
          border: Border.all(color: AppColors.electricCyan, width: 2),
          boxShadow: [
            BoxShadow(
              color: AppColors.electricCyan.withValues(alpha: 0.3),
              blurRadius: 24,
              spreadRadius: 2,
            ),
          ],
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            // Header
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                gradient: AppColors.primaryActionGradient,
                border: Border(
                  bottom: BorderSide(color: AppColors.electricCyan, width: 2),
                ),
              ),
              child: Row(
                children: [
                  const Icon(Icons.add_task, color: AppColors.coreVoid, size: 28),
                  const SizedBox(width: 12),
                  Text(
                    'INITIALIZE SKILL TREE',
                    style: AppTextStyles.headlineSmall.copyWith(
                      color: AppColors.coreVoid,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ],
              ),
            ),
            // Form
            Padding(
              padding: const EdgeInsets.all(16),
              child: Form(
                key: _formKey,
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Name
                    Text('BRANCH DESIGNATION', style: AppTextStyles.labelSmallUpper.copyWith(color: AppColors.electricCyan)),
                    const SizedBox(height: 8),
                    TextFormField(
                      controller: _nameController,
                      style: AppTextStyles.bodyLarge.copyWith(color: AppColors.onSurface),
                      decoration: InputDecoration(
                        hintText: 'e.g., Physical Development',
                        hintStyle: AppTextStyles.bodyMedium.copyWith(color: AppColors.onSurfaceVariant),
                        filled: true,
                        fillColor: AppColors.surfaceContainerLowest,
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(8),
                          borderSide: BorderSide(color: AppColors.brushedMetallicTrim),
                        ),
                        focusedBorder: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(8),
                          borderSide: BorderSide(color: AppColors.electricCyan, width: 2),
                        ),
                      ),
                      validator: (value) {
                        if (value == null || value.trim().isEmpty) {
                          return 'Branch name is required';
                        }
                        return null;
                      },
                    ),
                    const SizedBox(height: 16),
                    // Description
                    Text('SYSTEM DESCRIPTION', style: AppTextStyles.labelSmallUpper.copyWith(color: AppColors.electricCyan)),
                    const SizedBox(height: 8),
                    TextFormField(
                      controller: _descriptionController,
                      maxLines: 3,
                      style: AppTextStyles.bodyLarge.copyWith(color: AppColors.onSurface),
                      decoration: InputDecoration(
                        hintText: 'e.g., Strength, endurance, and vitality protocols',
                        hintStyle: AppTextStyles.bodyMedium.copyWith(color: AppColors.onSurfaceVariant),
                        filled: true,
                        fillColor: AppColors.surfaceContainerLowest,
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(8),
                          borderSide: BorderSide(color: AppColors.brushedMetallicTrim),
                        ),
                        focusedBorder: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(8),
                          borderSide: BorderSide(color: AppColors.electricCyan, width: 2),
                        ),
                      ),
                    ),
                    const SizedBox(height: 16),
                    // Color selection
                    Text('ACCENT COLOR', style: AppTextStyles.labelSmallUpper.copyWith(color: AppColors.electricCyan)),
                    const SizedBox(height: 8),
                    Wrap(
                      spacing: 8,
                      runSpacing: 8,
                      children: _availableColors.map((color) {
                        final isSelected = color == _selectedColor;
                        return GestureDetector(
                          onTap: () => setState(() => _selectedColor = color),
                          child: Container(
                            width: 40,
                            height: 40,
                            decoration: BoxDecoration(
                              color: color,
                              shape: BoxShape.circle,
                              border: Border.all(
                                color: isSelected ? AppColors.highVoltageYellow : Colors.transparent,
                                width: 3,
                              ),
                              boxShadow: [
                                BoxShadow(
                                  color: color.withValues(alpha: 0.5),
                                  blurRadius: 8,
                                ),
                              ],
                            ),
                            child: isSelected
                                ? const Icon(Icons.check, color: AppColors.coreVoid, size: 24)
                                : null,
                          ),
                        );
                      }).toList(),
                    ),
                    const SizedBox(height: 16),
                    // Icon selection
                    Text('NEURAL ICON', style: AppTextStyles.labelSmallUpper.copyWith(color: AppColors.electricCyan)),
                    const SizedBox(height: 8),
                    Wrap(
                      spacing: 8,
                      runSpacing: 8,
                      children: _availableIcons.map((icon) {
                        final isSelected = icon == _selectedIcon;
                        return GestureDetector(
                          onTap: () => setState(() => _selectedIcon = icon),
                          child: Container(
                            width: 48,
                            height: 48,
                            decoration: BoxDecoration(
                              color: AppColors.surfaceContainerLowest,
                              border: Border.all(
                                color: isSelected ? AppColors.electricCyan : AppColors.brushedMetallicTrim,
                                width: isSelected ? 2 : 1,
                              ),
                              borderRadius: BorderRadius.circular(8),
                            ),
                            child: Icon(
                              icon,
                              color: isSelected ? _selectedColor : AppColors.onSurfaceVariant,
                              size: 24,
                            ),
                          ),
                        );
                      }).toList(),
                    ),
                    const SizedBox(height: 24),
                    // Actions
                    Row(
                      children: [
                        Expanded(
                          child: OutlinedButton(
                            onPressed: _isSubmitting ? null : () => Navigator.pop(context),
                            style: OutlinedButton.styleFrom(
                              padding: const EdgeInsets.symmetric(vertical: 14),
                              side: BorderSide(color: AppColors.brushedMetallicTrim),
                            ),
                            child: Text(
                              'CANCEL',
                              style: AppTextStyles.labelLargeUpper,
                            ),
                          ),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: ElevatedButton(
                            onPressed: _isSubmitting ? null : _createBranch,
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
                                border: Border.all(color: AppColors.electricCyan, width: 1.5),
                              ),
                              child: Container(
                                alignment: Alignment.center,
                                padding: const EdgeInsets.symmetric(vertical: 14),
                                child: _isSubmitting
                                    ? const SizedBox(
                                        width: 24,
                                        height: 24,
                                        child: CircularProgressIndicator(
                                          strokeWidth: 2,
                                          color: AppColors.coreVoid,
                                        ),
                                      )
                                    : Row(
                                        mainAxisAlignment: MainAxisAlignment.center,
                                        children: [
                                          const Icon(Icons.electric_bolt, color: AppColors.coreVoid, size: 22),
                                          const SizedBox(width: 12),
                                          Text(
                                            'INITIALIZE BRANCH',
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
                      ],
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _createBranch() async {
    if (!_formKey.currentState!.validate()) return;
    
    setState(() => _isSubmitting = true);
    
    try {
      final createBranchUseCase = ref.read(createBranchUseCaseProvider);
      final branch = Branch(
        id: Uuid().v4(),
        name: _nameController.text.trim(),
        description: _descriptionController.text.trim(),
        accentColor: _selectedColor,
        icon: _selectedIcon,
        level: 1,
        currentXp: 0,
        xpToNextLevel: 5000,
        weight: 1.0,
        isActive: true,
        sortOrder: 0,
        createdAt: DateTime.now(),
        updatedAt: DateTime.now(),
        activities: [],
        metadata: {},
      );
      
      await createBranchUseCase.call(branch);
      
      if (mounted) {
        Navigator.pop(context);
        // Show success toast
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Branch "${branch.name}" initialized', style: AppTextStyles.bodyMedium),
            backgroundColor: AppColors.surfaceContainerHigh,
            behavior: SnackBarBehavior.floating,
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Failed to create branch: $e', style: AppTextStyles.bodyMedium),
            backgroundColor: AppColors.overloadCrimson,
            behavior: SnackBarBehavior.floating,
          ),
        );
      }
    } finally {
      if (mounted) {
        setState(() => _isSubmitting = false);
      }
    }
  }
}