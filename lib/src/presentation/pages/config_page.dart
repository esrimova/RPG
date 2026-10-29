import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../core/theme/index.dart';
import '../../domain/entities/branch.dart';
import '../providers/app_providers.dart';
import '../widgets/module_header.dart';
import '../widgets/branch_card.dart';
import '../widgets/stat_pod.dart';

class ConfigPage extends ConsumerStatefulWidget {
  const ConfigPage({super.key});

  @override
  ConsumerState<ConfigPage> createState() => _ConfigPageState();
}

class _ConfigPageState extends ConsumerState<ConfigPage> {
  final _patController = TextEditingController();
  final _repoController = TextEditingController();
  final _formKey = GlobalKey<FormState>();

  @override
  void dispose() {
    _patController.dispose();
    _repoController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final configState = ref.watch(githubConfigurationProvider);
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
                              'System Config',
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
            // Sub-header metric bar
            SliverToBoxAdapter(
              child: Container(
                margin: const EdgeInsets.all(16),
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: AppColors.surfaceContainerLowest,
                  border: Border.all(color: AppColors.brushedMetallicTrim, width: 1),
                ),
                child: Column(
                  children: [
                    Row(
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
                          '// SYS.CFG_NEURAL_CORE',
                          style: AppTextStyles.labelSmallUpper.copyWith(
                            color: AppColors.electricCyan,
                          ),
                        ),
                        const Spacer(),
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                          decoration: BoxDecoration(
                            color: AppColors.surfaceContainerHigh,
                            border: Border.all(color: AppColors.brushedMetallicTrim, width: 1),
                          ),
                          child: Text(
                            'Kernel v4.2 // SYNC_OK',
                            style: AppTextStyles.labelSmallUpper.copyWith(
                              color: AppColors.highVoltageYellow,
                            ),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 8),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceAround,
                      children: [
                        _MetricItem(label: 'NODES', value: '4 RUNNING', valueColor: AppColors.onSurface),
                        _MetricItem(label: 'ALLOCATED XP', value: '4.7x POOL', valueColor: AppColors.highVoltageYellow),
                        _MetricItem(label: 'MEM', value: '82%', valueColor: AppColors.electricCyan),
                      ],
                    ),
                  ],
                ),
              ),
            ),
            // Inspiration banner
            SliverToBoxAdapter(
              child: Container(
                margin: const EdgeInsets.symmetric(horizontal: 16),
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: AppColors.surfaceContainer,
                  border: Border.all(color: AppColors.brushedMetallicTrim, width: 1),
                ),
                child: Row(
                  children: [
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                            decoration: BoxDecoration(
                              color: AppColors.surfaceContainerHigh,
                              border: Border.all(color: AppColors.highVoltageYellow, width: 1),
                            ),
                            child: Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                const Icon(Icons.bolt, color: AppColors.highVoltageYellow, size: 14),
                                const SizedBox(width: 6),
                                Text(
                                  'ARCHITECT MODE ACTIVE',
                                  style: AppTextStyles.labelSmallUpper.copyWith(
                                    color: AppColors.highVoltageYellow,
                                  ),
                                ),
                              ],
                            ),
                          ),
                          const SizedBox(height: 8),
                          Text(
                            'NEURAL MATRIX RESTRUCTURE',
                            style: AppTextStyles.headlineSmall,
                          ),
                          const SizedBox(height: 4),
                          Text(
                            'Overclock, reweight, and engineer your biological and digital experiential pathways.',
                            style: AppTextStyles.bodySmall.copyWith(
                              color: AppColors.onSurfaceVariant,
                            ),
                          ),
                        ],
                      ),
                    ),
                    Container(
                      width: 64,
                      height: 64,
                      decoration: BoxDecoration(
                        gradient: AppColors.voltageGradient,
                        border: Border.all(color: AppColors.highVoltageYellow, width: 1.5),
                      ),
                      child: const Icon(Icons.auto_awesome, color: AppColors.coreVoid, size: 32),
                    ),
                  ],
                ),
              ),
            ),
            // Module 01: Deployment Protocols
            SliverToBoxAdapter(
              child: _buildModuleHeader('DEPLOYMENT PROTOCOLS', AppColors.electricCyan, '[ACTIONS // MOD.01]'),
            ),
            SliverToBoxAdapter(
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16),
                child: Column(
                  children: [
                    _ActionCard(
                      icon: Icons.account_tree,
                      iconColor: AppColors.electricCyan,
                      title: 'ADD NEW BRANCH',
                      badge: '+NEW',
                      badgeColor: AppColors.electricCyan,
                      description: 'Forge new tree (e.g., Mental Resilience, Bio-Hacking)',
                      onTap: () => _showAddBranchDialog(context),
                    ),
                    const SizedBox(height: 12),
                    _ActionCard(
                      icon: Icons.add_task,
                      iconColor: AppColors.electricViolet,
                      title: 'ADD ACTIVITY',
                      badge: 'RITUAL',
                      badgeColor: AppColors.electricViolet,
                      description: 'Map routine or quest to an active branch node',
                      onTap: () => _showAddActivityDialog(context),
                    ),
                    const SizedBox(height: 12),
                    _ActionCard(
                      icon: Icons.tune,
                      iconColor: AppColors.highVoltageYellow,
                      title: 'CONFIGURE METRICS',
                      badge: 'SCHEMAS',
                      badgeColor: AppColors.highVoltageYellow,
                      description: 'Define telemetry: sets, reps, duration, mental focus',
                      onTap: () => _showConfigureMetricsDialog(context),
                    ),
                  ],
                ),
              ),
            ),
            // Module 02: Active Branches
            SliverToBoxAdapter(
              child: _buildModuleHeader('ACTIVE SKILL BRANCHES', AppColors.highVoltageYellow, '[INVENTORY: 4 NODES]'),
            ),
            SliverToBoxAdapter(
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16),
                child: branchesAsync.when(
                  data: (branches) => Column(
                    children: branches.map((branch) => _buildBranchConfigCard(branch)).toList(),
                  ),
                  loading: () => Column(
                    children: List.generate(4, (i) => Container(
                      margin: const EdgeInsets.only(bottom: 12),
                      height: 100,
                      child: CyberCard(
                        child: Row(
                          children: List.generate(3, (j) => Expanded(
                            child: Container(
                              margin: const EdgeInsets.all(8),
                              color: AppColors.surfaceContainerLow,
                            ),
                          )),
                        ),
                      ),
                    )),
                  ),
                  error: (e, _) => _buildErrorState(e.toString()),
                ),
              ),
            ),
            // Module 03: Field Schema Template
            SliverToBoxAdapter(
              child: _buildModuleHeader('LIVE TELEMETRY SCHEMA TEMPLATE', AppColors.electricViolet, '[PUSH-UPS]'),
            ),
            SliverToBoxAdapter(
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16),
                child: _buildSchemaTemplate(),
              ),
            ),
            // Module 04: Database Protocols
            SliverToBoxAdapter(
              child: _buildModuleHeader('DATABASE PROTOCOLS', AppColors.electricCyan, '[JSON // FLUTTER]'),
            ),
            SliverToBoxAdapter(
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16),
                child: Column(
                  children: [
                    _ProtocolButton(
                      icon: Icons.code,
                      title: 'EXPORT CONFIG TO FLUTTER JSON',
                      subtitle: 'Compatible with Hive / Isar Local DB',
                      color: AppColors.highVoltageYellow,
                      onPressed: () {},
                    ),
                    const SizedBox(height: 12),
                    _ProtocolButton(
                      icon: Icons.cloud_sync,
                      title: 'CLOUD SYNC OVERWRITE',
                      subtitle: 'Mirror architecture to remote node server',
                      color: AppColors.electricCyan,
                      onPressed: () {},
                    ),
                  ],
                ),
              ),
            ),
            // GitHub Configuration Section
            SliverToBoxAdapter(
              child: _buildModuleHeader('GITHUB SYNC CONFIGURATION', AppColors.electricViolet, '[SECURE STORAGE]'),
            ),
            SliverToBoxAdapter(
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: _buildGithubConfig(configState),
              ),
            ),
            const SliverToBoxAdapter(child: SizedBox(height: 100)),
          ],
        ),
      ),
    );
  }

  Widget _buildModuleHeader(String title, Color color, String subtitle) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 16, 16, 8),
      child: Row(
        children: [
          Container(
            width: 4,
            height: 20,
            color: color,
          ),
          const SizedBox(width: 8),
          Text(
            title,
            style: AppTextStyles.labelMediumUpper.copyWith(color: color),
          ),
          const Spacer(),
          Text(
            subtitle,
            style: AppTextStyles.labelSmallUpper.copyWith(
              color: AppColors.onSurfaceVariant,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildBranchConfigCard(Branch branch) {
    return CyberCard(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(16),
      child: Column(
        children: [
          Row(
            children: [
              const Icon(Icons.drag_indicator, color: AppColors.outline, size: 22),
              const SizedBox(width: 8),
              Container(
                width: 10,
                height: 10,
                decoration: BoxDecoration(
                  color: branch.accentColor,
                  shape: BoxShape.circle,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      branch.name.toUpperCase(),
                      style: AppTextStyles.headlineSmall,
                    ),
                    Text(
                      'BRANCH_ID: ${branch.id} // ${branch.activities.length} ACTIVITIES',
                      style: AppTextStyles.labelSmall.copyWith(
                        color: AppColors.onSurfaceVariant,
                      ),
                    ),
                  ],
                ),
              ),
              // Toggle
              Container(
                width: 48,
                height: 24,
                decoration: BoxDecoration(
                  color: branch.isActive ? branch.accentColor : AppColors.surfaceVariant,
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(
                    color: branch.isActive ? branch.accentColor : AppColors.brushedMetallicTrim,
                    width: 1,
                  ),
                ),
                child: AnimatedAlign(
                  duration: const Duration(milliseconds: 200),
                  alignment: branch.isActive ? Alignment.centerRight : Alignment.centerLeft,
                  child: Container(
                    width: 20,
                    height: 20,
                    margin: const EdgeInsets.all(2),
                    decoration: BoxDecoration(
                      color: branch.isActive
                          ? (branch.accentColor == AppColors.electricCyan
                              ? AppColors.onPrimaryContainer
                              : AppColors.onSecondary)
                          : AppColors.surfaceVariant,
                      shape: BoxShape.circle,
                    ),
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: AppColors.surfaceContainerLow,
              border: Border.all(color: AppColors.brushedMetallicTrim, width: 1),
            ),
            child: Row(
              children: [
                Expanded(
                  child: Row(
                    children: [
                      _StatItem(label: 'WEIGHT', value: '${branch.weight}x', valueColor: AppColors.highVoltageYellow),
                      const SizedBox(width: 24),
                      _StatItem(label: 'OUTPUT', value: '${branch.estimatedWeeklyXp} XP/WK', valueColor: AppColors.electricCyan),
                    ],
                  ),
                ),
                Row(
                  children: [
                    OutlinedButton.icon(
                      onPressed: () {},
                      icon: const Icon(Icons.edit, size: 14),
                      label: Text('EDIT', style: AppTextStyles.labelSmallUpper),
                      style: OutlinedButton.styleFrom(
                        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                      ),
                    ),
                    const SizedBox(width: 8),
                    IconButton(
                      onPressed: () {},
                      icon: const Icon(Icons.visibility, size: 16, color: AppColors.electricCyan),
                      style: IconButton.styleFrom(
                        backgroundColor: AppColors.surfaceContainerHigh,
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSchemaTemplate() {
    return CyberCard(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'TARGET ACTIVITY:',
                    style: AppTextStyles.labelSmallUpper.copyWith(
                      color: AppColors.onSurfaceVariant,
                    ),
                  ),
                  Text(
                    'PUSH-UPS // UPPER BODY OVERCLOCK',
                    style: AppTextStyles.headlineSmall.copyWith(
                      color: AppColors.electricCyan,
                    ),
                  ),
                ],
              ),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                decoration: BoxDecoration(
                  color: AppColors.surfaceContainerHigh,
                  border: Border.all(color: AppColors.electricCyan, width: 1),
                ),
                child: Text(
                  '3 FIELDS ACTIVE',
                  style: AppTextStyles.labelSmallUpper.copyWith(
                    color: AppColors.electricCyan,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          _SchemaField(
            icon: Icons.pin,
            iconColor: AppColors.electricCyan,
            name: 'Repetition Counter',
            type: '[TYPE: INTEGER] • UNIT: REPS',
            required: true,
          ),
          const SizedBox(height: 8),
          _SchemaField(
            icon: Icons.timer,
            iconColor: AppColors.electricViolet,
            name: 'Duration Timer',
            type: '[TYPE: SECONDS] • AUTO-STOP',
            required: true,
          ),
          const SizedBox(height: 8),
          _SchemaField(
            icon: Icons.speed,
            iconColor: AppColors.highVoltageYellow,
            name: 'Perceived Exertion (RPE)',
            type: '[TYPE: 1-10 SLIDER SCALE]',
            required: false,
          ),
          const SizedBox(height: 16),
          OutlinedButton.icon(
            onPressed: () {},
            icon: const Icon(Icons.library_add, size: 16),
            label: Text('ATTACH NEW TELEMETRY FIELD', style: AppTextStyles.labelMediumUpper),
            style: OutlinedButton.styleFrom(
              minimumSize: const Size(double.infinity, 48),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildGithubConfig(GithubConfigState configState) {
    return CyberCard(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                width: 8,
                height: 8,
                decoration: BoxDecoration(
                  color: configState.isConfigured ? AppColors.electricCyan : AppColors.overloadCrimson,
                  shape: BoxShape.circle,
                ),
              ),
              const SizedBox(width: 8),
              Text(
                configState.isConfigured ? 'GITHUB SYNC: ONLINE' : 'GITHUB SYNC: OFFLINE',
                style: AppTextStyles.labelSmallUpper.copyWith(
                  color: configState.isConfigured ? AppColors.electricCyan : AppColors.overloadCrimson,
                ),
              ),
              const Spacer(),
              if (configState.isLoading)
                const SizedBox(
                  width: 16,
                  height: 16,
                  child: CircularProgressIndicator(strokeWidth: 2),
                ),
            ],
          ),
          const SizedBox(height: 16),
          Form(
            key: _formKey,
            child: Column(
              children: [
                TextFormField(
                  controller: _patController,
                  obscureText: true,
                  style: AppTextStyles.bodyMedium,
                  decoration: InputDecoration(
                    labelText: 'Personal Access Token (PAT)',
                    hintText: 'ghp_***************',
                    prefixIcon: const Icon(Icons.vpn_key, color: AppColors.electricCyan),
                  ),
                  validator: (value) {
                    if (value == null || value.isEmpty) {
                      return 'PAT is required';
                    }
                    if (!value.startsWith('ghp_') && !value.startsWith('github_pat_')) {
                      return 'Invalid PAT format';
                    }
                    return null;
                  },
                ),
                const SizedBox(height: 16),
                TextFormField(
                  controller: _repoController,
                  style: AppTextStyles.bodyMedium,
                  decoration: InputDecoration(
                    labelText: 'Repository (owner/repo)',
                    hintText: 'esrimova/RPG',
                    prefixIcon: const Icon(Icons.folder, color: AppColors.electricCyan),
                  ),
                  validator: (value) {
                    if (value == null || value.isEmpty) {
                      return 'Repository is required';
                    }
                    if (!value.contains('/')) {
                      return 'Format: owner/repo';
                    }
                    return null;
                  },
                ),
                const SizedBox(height: 16),
                if (configState.error != null)
                  Container(
                    width: double.infinity,
                    padding: const EdgeInsets.all(12),
                    margin: const EdgeInsets.only(bottom: 16),
                    decoration: BoxDecoration(
                      color: AppColors.overloadCrimson.withOpacity(0.1),
                      border: Border.all(color: AppColors.overloadCrimson, width: 1),
                    ),
                    child: Text(
                      configState.error!,
                      style: AppTextStyles.bodySmall.copyWith(color: AppColors.overloadCrimson),
                    ),
                  ),
                Row(
                  children: [
                    Expanded(
                      child: ElevatedButton.icon(
                        onPressed: configState.isLoading
                            ? null
                            : () async {
                                if (_formKey.currentState!.validate()) {
                                  await ref.read(githubConfigurationProvider.notifier).configure(
                                    _patController.text.trim(),
                                    _repoController.text.trim(),
                                  );
                                }
                              },
                        icon: const Icon(Icons.save, size: 18),
                        label: Text(
                          configState.isConfigured ? 'UPDATE CONFIG' : 'SAVE CONFIG',
                          style: AppTextStyles.labelMediumUpper,
                        ),
                        style: ElevatedButton.styleFrom(
                          padding: const EdgeInsets.symmetric(vertical: 14),
                        ),
                      ),
                    ),
                    if (configState.isConfigured) ...[
                      const SizedBox(width: 12),
                      Expanded(
                        child: OutlinedButton.icon(
                          onPressed: () {
                            _patController.clear();
                            _repoController.clear();
                            ref.read(githubConfigurationProvider.notifier).clear();
                          },
                          icon: const Icon(Icons.delete, size: 18),
                          label: Text(
                            'CLEAR',
                            style: AppTextStyles.labelMediumUpper,
                          ),
                          style: OutlinedButton.styleFrom(
                            padding: const EdgeInsets.symmetric(vertical: 14),
                          ),
                        ),
                      ),
                    ],
                  ],
                ),
              ],
            ),
          ),
        ],
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

  void _showAddBranchDialog(BuildContext context) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: AppColors.surfaceContainer,
        title: Text('ADD NEW BRANCH', style: AppTextStyles.headlineSmall),
        content: Text('Branch creation dialog would go here', style: AppTextStyles.bodyMedium),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context), child: Text('CANCEL', style: AppTextStyles.labelMediumUpper)),
          ElevatedButton(onPressed: () => Navigator.pop(context), child: Text('CREATE', style: AppTextStyles.labelMediumUpper)),
        ],
      ),
    );
  }

  void _showAddActivityDialog(BuildContext context) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: AppColors.surfaceContainer,
        title: Text('ADD ACTIVITY', style: AppTextStyles.headlineSmall),
        content: Text('Activity creation dialog would go here', style: AppTextStyles.bodyMedium),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context), child: Text('CANCEL', style: AppTextStyles.labelMediumUpper)),
          ElevatedButton(onPressed: () => Navigator.pop(context), child: Text('CREATE', style: AppTextStyles.labelMediumUpper)),
        ],
      ),
    );
  }

  void _showConfigureMetricsDialog(BuildContext context) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: AppColors.surfaceContainer,
        title: Text('CONFIGURE METRICS', style: AppTextStyles.headlineSmall),
        content: Text('Metrics configuration dialog would go here', style: AppTextStyles.bodyMedium),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context), child: Text('CANCEL', style: AppTextStyles.labelMediumUpper)),
          ElevatedButton(onPressed: () => Navigator.pop(context), child: Text('SAVE', style: AppTextStyles.labelMediumUpper)),
        ],
      ),
    );
  }
}

class _ActionCard extends StatelessWidget {
  final IconData icon;
  final Color iconColor;
  final String title;
  final String badge;
  final Color badgeColor;
  final String description;
  final VoidCallback onTap;

  const _ActionCard({
    required this.icon,
    required this.iconColor,
    required this.title,
    required this.badge,
    required this.badgeColor,
    required this.description,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return CyberCard(
      onTap: onTap,
      child: Row(
        children: [
          Container(
            width: 48,
            height: 48,
            decoration: BoxDecoration(
              color: AppColors.surfaceContainerLowest,
              border: Border.all(color: AppColors.brushedMetallicTrim, width: 1),
            ),
            child: Icon(icon, color: iconColor, size: 28),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Text(
                      title,
                      style: AppTextStyles.headlineSmall,
                    ),
                    const SizedBox(width: 8),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                      decoration: BoxDecoration(
                        color: badgeColor.withOpacity(0.2),
                        border: Border.all(color: badgeColor, width: 1),
                      ),
                      child: Text(
                        badge,
                        style: AppTextStyles.labelSmall.copyWith(color: badgeColor),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 4),
                Text(
                  description,
                  style: AppTextStyles.bodySmall.copyWith(
                    color: AppColors.onSurfaceVariant,
                  ),
                ),
              ],
            ),
          ),
          Container(
            width: 40,
            height: 40,
            decoration: BoxDecoration(
              color: AppColors.surfaceContainerHigh,
              border: Border.all(color: AppColors.brushedMetallicTrim, width: 1),
            ),
            child: Icon(Icons.add, color: iconColor, size: 20),
          ),
        ],
      ),
    );
  }
}

class _ProtocolButton extends StatelessWidget {
  final IconData icon;
  final String title;
  final String subtitle;
  final Color color;
  final VoidCallback onPressed;

  const _ProtocolButton({
    required this.icon,
    required this.title,
    required this.subtitle,
    required this.color,
    required this.onPressed,
  });

  @override
  Widget build(BuildContext context) {
    return CyberCard(
      onTap: onPressed,
      padding: const EdgeInsets.all(16),
      child: Row(
        children: [
          Icon(icon, color: color, size: 24),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: AppTextStyles.headlineSmall.copyWith(
                    color: color,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                Text(
                  subtitle,
                  style: AppTextStyles.labelSmall.copyWith(
                    color: AppColors.onSurfaceVariant,
                  ),
                ),
              ],
            ),
          ),
          Icon(Icons.arrow_forward, color: color, size: 20),
        ],
      ),
    );
  }
}

class _SchemaField extends StatelessWidget {
  final IconData icon;
  final Color iconColor;
  final String name;
  final String type;
  final bool required;

  const _SchemaField({
    required this.icon,
    required this.iconColor,
    required this.name,
    required this.type,
    required this.required,
  });

  @override
  Widget build(BuildContext context) {
    return CyberCard(
      padding: const EdgeInsets.all(12),
      child: Row(
        children: [
          Container(
            width: 40,
            height: 40,
            decoration: BoxDecoration(
              color: AppColors.surfaceContainerHigh,
              border: Border.all(color: AppColors.brushedMetallicTrim, width: 1),
            ),
            child: Icon(icon, color: iconColor, size: 18),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  name,
                  style: AppTextStyles.bodyMedium.copyWith(fontWeight: FontWeight.w600),
                ),
                Text(
                  type,
                  style: AppTextStyles.labelSmall.copyWith(
                    color: AppColors.onSurfaceVariant,
                    fontFamily: 'JetBrains Mono',
                  ),
                ),
              ],
            ),
          ),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
            decoration: BoxDecoration(
              color: required ? AppColors.highVoltageYellow : AppColors.surfaceContainerLowest,
              border: Border.all(
                color: required ? AppColors.highVoltageYellow : AppColors.brushedMetallicTrim,
                width: 1,
              ),
            ),
            child: Text(
              required ? 'REQUIRED' : 'OPTIONAL',
              style: AppTextStyles.labelSmall.copyWith(
                color: required ? AppColors.onSecondary : AppColors.outline,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _MetricItem extends StatelessWidget {
  final String label;
  final String value;
  final Color valueColor;

  const _MetricItem({
    required this.label,
    required this.value,
    required this.valueColor,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Text(label, style: AppTextStyles.labelSmallUpper.copyWith(color: AppColors.onSurfaceVariant)),
        Text(value, style: AppTextStyles.labelMedium.copyWith(color: valueColor, fontWeight: FontWeight.bold)),
      ],
    );
  }
}

class _StatItem extends StatelessWidget {
  final String label;
  final String value;
  final Color valueColor;

  const _StatItem({
    required this.label,
    required this.value,
    required this.valueColor,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(label, style: AppTextStyles.labelSmallUpper.copyWith(color: AppColors.outline)),
        Text(value, style: AppTextStyles.hudMetricSmall.copyWith(color: valueColor)),
      ],
    );
  }
}