import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../core/theme/index.dart';
import '../../domain/entities/branch.dart';
import '../../domain/entities/activity.dart';
import '../../domain/entities/activity_field.dart';
import '../providers/app_providers.dart';
import '../widgets/module_header.dart';
import '../widgets/branch_card.dart';
import '../widgets/stat_pod.dart';
import 'package:uuid/uuid.dart';

class ConfigPage extends ConsumerStatefulWidget {
  const ConfigPage({super.key});

  @override
  ConsumerState<ConfigPage> createState() => _ConfigPageState();
}

class _ConfigPageState extends ConsumerState<ConfigPage> {
  final _patController = TextEditingController();
  final _repoController = TextEditingController();
  final _aiApiKeyController = TextEditingController();
  final _aiModelController = TextEditingController();
  final _githubFormKey = GlobalKey<FormState>();
  final _aiFormKey = GlobalKey<FormState>();

  @override
  void dispose() {
    _patController.dispose();
    _repoController.dispose();
    _aiApiKeyController.dispose();
    _aiModelController.dispose();
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
            // AI Configuration Section
            SliverToBoxAdapter(
              child: _buildModuleHeader('NEURAL AI CONFIGURATION', AppColors.electricViolet, '[LLM INTEGRATION]'),
            ),
            SliverToBoxAdapter(
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: _buildAiConfig(),
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
            key: _githubFormKey,
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
                                if (_githubFormKey.currentState!.validate()) {
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

  Widget _buildAiConfig() {
    return Consumer(
      builder: (context, ref, _) {
        final aiState = ref.watch(aiConfigurationProvider);
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
                      color: aiState.isConfigured ? AppColors.electricViolet : AppColors.overloadCrimson,
                      shape: BoxShape.circle,
                    ),
                  ),
                  const SizedBox(width: 8),
                  Text(
                    aiState.isConfigured ? 'NEURAL AI: CONNECTED' : 'NEURAL AI: OFFLINE',
                    style: AppTextStyles.labelSmallUpper.copyWith(
                      color: aiState.isConfigured ? AppColors.electricViolet : AppColors.overloadCrimson,
                    ),
                  ),
                  const Spacer(),
                  if (aiState.isLoading)
                    const SizedBox(
                      width: 16,
                      height: 16,
                      child: CircularProgressIndicator(strokeWidth: 2),
                    ),
                ],
              ),
              const SizedBox(height: 16),
              Text(
                'Configure your LLM provider for AI-generated insights, quests, and badges.',
                style: AppTextStyles.bodySmall.copyWith(color: AppColors.onSurfaceVariant),
              ),
              const SizedBox(height: 16),
              Form(
                key: _aiFormKey,
                child: Column(
                  children: [
                    TextFormField(
                      controller: _aiApiKeyController,
                      obscureText: true,
                      style: AppTextStyles.bodyMedium,
                      decoration: InputDecoration(
                        labelText: 'API Key',
                        hintText: 'sk-***************',
                        prefixIcon: const Icon(Icons.vpn_key, color: AppColors.electricViolet),
                        helperText: 'OpenAI-compatible API key (stored securely)',
                      ),
                      validator: (value) {
                        if (value == null || value.isEmpty) {
                          return 'API key is required';
                        }
                        return null;
                      },
                    ),
                    const SizedBox(height: 16),
                    TextFormField(
                      controller: _aiModelController,
                      style: AppTextStyles.bodyMedium,
                      decoration: InputDecoration(
                        labelText: 'Model',
                        hintText: 'gpt-4o-mini',
                        prefixIcon: const Icon(Icons.memory, color: AppColors.electricViolet),
                        helperText: 'Model identifier (e.g., gpt-4o-mini, claude-3-haiku)',
                      ),
                      validator: (value) {
                        if (value == null || value.isEmpty) {
                          return 'Model is required';
                        }
                        return null;
                      },
                    ),
                    const SizedBox(height: 16),
                    DropdownButtonFormField<String>(
                      value: aiState.provider,
                      decoration: InputDecoration(
                        labelText: 'Provider',
                        prefixIcon: const Icon(Icons.cloud, color: AppColors.electricViolet),
                        filled: true,
                        fillColor: AppColors.surfaceContainerLowest,
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(8),
                          borderSide: BorderSide(color: AppColors.brushedMetallicTrim),
                        ),
                        focusedBorder: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(8),
                          borderSide: BorderSide(color: AppColors.electricViolet, width: 2),
                        ),
                      ),
                      dropdownColor: AppColors.surfaceContainerHigh,
                      items: const [
                        DropdownMenuItem(value: 'openai', child: Text('OpenAI')),
                        DropdownMenuItem(value: 'anthropic', child: Text('Anthropic')),
                        DropdownMenuItem(value: 'custom', child: Text('Custom OpenAI-compatible')),
                      ],
                      onChanged: (val) {
                        ref.read(aiConfigurationProvider.notifier).setProvider(val!);
                      },
                    ),
                    const SizedBox(height: 16),
                    if (aiState.error != null)
                      Container(
                        width: double.infinity,
                        padding: const EdgeInsets.all(12),
                        margin: const EdgeInsets.only(bottom: 16),
                        decoration: BoxDecoration(
                          color: AppColors.overloadCrimson.withValues(alpha: 0.1),
                          border: Border.all(color: AppColors.overloadCrimson, width: 1),
                        ),
                        child: Text(
                          aiState.error!,
                          style: AppTextStyles.bodySmall.copyWith(color: AppColors.overloadCrimson),
                        ),
                      ),
                    Row(
                      children: [
                        Expanded(
                          child: ElevatedButton.icon(
                            onPressed: aiState.isLoading
                                ? null
                                : () async {
                                    if (_aiFormKey.currentState!.validate()) {
                                      await ref.read(aiConfigurationProvider.notifier).configure(
                                        _aiApiKeyController.text.trim(),
                                        _aiModelController.text.trim(),
                                        aiState.provider,
                                      );
                                    }
                                  },
                            icon: const Icon(Icons.save, size: 18),
                            label: Text(
                              aiState.isConfigured ? 'UPDATE AI CONFIG' : 'SAVE AI CONFIG',
                              style: AppTextStyles.labelMediumUpper,
                            ),
                            style: ElevatedButton.styleFrom(
                              padding: const EdgeInsets.symmetric(vertical: 14),
                            ),
                          ),
                        ),
                        if (aiState.isConfigured) ...[
                          const SizedBox(width: 12),
                          Expanded(
                            child: OutlinedButton.icon(
                              onPressed: () {
                                _aiApiKeyController.clear();
                                _aiModelController.clear();
                                ref.read(aiConfigurationProvider.notifier).clear();
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
                    const SizedBox(height: 16),
                    // Test connection button
                    if (aiState.isConfigured)
                      SizedBox(
                        width: double.infinity,
                        child: OutlinedButton.icon(
                          onPressed: aiState.isLoading
                              ? null
                              : () async {
                                  await ref.read(aiConfigurationProvider.notifier).testConnection();
                                },
                          icon: const Icon(Icons.wifi, size: 18),
                          label: Text('TEST CONNECTION', style: AppTextStyles.labelMediumUpper),
                          style: OutlinedButton.styleFrom(
                            padding: const EdgeInsets.symmetric(vertical: 14),
                            side: BorderSide(color: AppColors.electricViolet),
                          ),
                        ),
                      ),
                  ],
                ),
              ),
            ],
          ),
        );
      },
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
      builder: (context) => _CreateBranchDialog(),
    );
  }

  void _showAddActivityDialog(BuildContext context) {
    showDialog(
      context: context,
      builder: (context) => _CreateActivityDialog(),
    );
  }

  void _showConfigureMetricsDialog(BuildContext context) {
    showDialog(
      context: context,
      builder: (context) => _ConfigureMetricsDialog(),
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
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                gradient: AppColors.primaryActionGradient,
                border: Border(bottom: BorderSide(color: AppColors.electricCyan, width: 2)),
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
            Padding(
              padding: const EdgeInsets.all(16),
              child: Form(
                key: _formKey,
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
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
                                BoxShadow(color: color.withValues(alpha: 0.5), blurRadius: 8),
                              ],
                            ),
                            child: isSelected ? const Icon(Icons.check, color: AppColors.coreVoid, size: 24) : null,
                          ),
                        );
                      }).toList(),
                    ),
                    const SizedBox(height: 16),
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
                    Row(
                      children: [
                        Expanded(
                          child: OutlinedButton(
                            onPressed: _isSubmitting ? null : () => Navigator.pop(context),
                            style: OutlinedButton.styleFrom(
                              padding: const EdgeInsets.symmetric(vertical: 14),
                              side: BorderSide(color: AppColors.brushedMetallicTrim),
                            ),
                            child: Text('CANCEL', style: AppTextStyles.labelLargeUpper),
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
                              shape: const ContinuousRectangleBorder(borderRadius: BorderRadius.zero),
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
                                        child: CircularProgressIndicator(strokeWidth: 2, color: AppColors.coreVoid),
                                      )
                                    : Row(
                                        mainAxisAlignment: MainAxisAlignment.center,
                                        children: [
                                          const Icon(Icons.electric_bolt, color: AppColors.coreVoid, size: 22),
                                          const SizedBox(width: 12),
                                          Text('INITIALIZE BRANCH', style: AppTextStyles.labelLargeUpper.copyWith(color: AppColors.coreVoid, fontWeight: FontWeight.bold)),
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
        id: const Uuid().v4(),
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
          SnackBar(content: Text('Failed to create branch: $e', style: AppTextStyles.bodyMedium), backgroundColor: AppColors.overloadCrimson, behavior: SnackBarBehavior.floating),
        );
      }
    } finally {
      if (mounted) setState(() => _isSubmitting = false);
    }
  }
}

class _CreateActivityDialog extends ConsumerStatefulWidget {
  @override
  ConsumerState<_CreateActivityDialog> createState() => _CreateActivityDialogState();
}

class _CreateActivityDialogState extends ConsumerState<_CreateActivityDialog> {
  final _formKey = GlobalKey<FormState>();
  final _nameController = TextEditingController();
  final _descriptionController = TextEditingController();
  final _baseXpController = TextEditingController(text: '45');
  String? _selectedBranchId;
  Color _selectedColor = AppColors.electricCyan;
  IconData _selectedIcon = Icons.add_task;
  String _selectedCategory = 'STRENGTH';
  bool _isSubmitting = false;

  final List<String> _categories = ['STRENGTH', 'CARDIO', 'ENDURANCE', 'FLEXIBILITY', 'SKILL', 'MENTAL', 'RECOVERY'];
  final List<Color> _availableColors = [AppColors.electricCyan, AppColors.highVoltageYellow, AppColors.electricViolet, AppColors.overloadCrimson];
  final List<IconData> _availableIcons = [Icons.fitness_center, Icons.directions_run, Icons.timer, Icons.self_improvement, Icons.psychology, Icons.spa, Icons.code, Icons.auto_awesome];

  @override
  void dispose() {
    _nameController.dispose();
    _descriptionController.dispose();
    _baseXpController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final branchesAsync = ref.watch(branchesProvider);
    
    return Dialog(
      backgroundColor: Colors.transparent,
      child: Container(
        width: double.maxFinite,
        constraints: const BoxConstraints(maxWidth: 450),
        decoration: BoxDecoration(
          color: AppColors.surfaceContainerHigh,
          border: Border.all(color: AppColors.electricViolet, width: 2),
          boxShadow: [BoxShadow(color: AppColors.electricViolet.withValues(alpha: 0.3), blurRadius: 24, spreadRadius: 2)],
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(gradient: AppColors.voltageGradient, border: Border(bottom: BorderSide(color: AppColors.electricViolet, width: 2))),
              child: Row(
                children: [const Icon(Icons.add_task, color: AppColors.coreVoid, size: 28), const SizedBox(width: 12), Text('DEPLOY NEW RITUAL', style: AppTextStyles.headlineSmall.copyWith(color: AppColors.coreVoid, fontWeight: FontWeight.bold))],
              ),
            ),
            Padding(
              padding: const EdgeInsets.all(16),
              child: Form(
                key: _formKey,
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    branchesAsync.when(
                      data: (branches) {
                        if (branches.isEmpty) {
                          return Column(
                            children: [
                              Text('NO BRANCHES AVAILABLE', style: AppTextStyles.labelSmallUpper.copyWith(color: AppColors.overloadCrimson)),
                              const SizedBox(height: 8),
                              Text('Create a branch first in the Deployment Protocols section', style: AppTextStyles.bodySmall.copyWith(color: AppColors.onSurfaceVariant)),
                            ],
                          );
                        }
                        _selectedBranchId ??= branches.first.id;
                        return DropdownButtonFormField<String>(
                          value: _selectedBranchId,
                          decoration: InputDecoration(
                            labelText: 'TARGET BRANCH',
                            prefixIcon: Icon(Icons.account_tree, color: AppColors.electricViolet),
                            filled: true,
                            fillColor: AppColors.surfaceContainerLowest,
                            border: OutlineInputBorder(borderRadius: BorderRadius.circular(8), borderSide: BorderSide(color: AppColors.brushedMetallicTrim)),
                            focusedBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(8), borderSide: BorderSide(color: AppColors.electricViolet, width: 2)),
                          ),
                          dropdownColor: AppColors.surfaceContainerHigh,
                          items: branches.map((b) => DropdownMenuItem(value: b.id, child: Text(b.name, style: AppTextStyles.bodyMedium))).toList(),
                          onChanged: (val) => setState(() => _selectedBranchId = val),
                        );
                      },
                      loading: () => const LinearProgressIndicator(),
                      error: (_, __) => Text('Error loading branches', style: AppTextStyles.bodySmall.copyWith(color: AppColors.overloadCrimson)),
                    ),
                    const SizedBox(height: 16),
                    Text('RITUAL DESIGNATION', style: AppTextStyles.labelSmallUpper.copyWith(color: AppColors.electricViolet)),
                    const SizedBox(height: 8),
                    TextFormField(
                      controller: _nameController,
                      style: AppTextStyles.bodyLarge.copyWith(color: AppColors.onSurface),
                      decoration: InputDecoration(hintText: 'e.g., Morning Mobility Flow', hintStyle: AppTextStyles.bodyMedium.copyWith(color: AppColors.onSurfaceVariant), filled: true, fillColor: AppColors.surfaceContainerLowest, border: OutlineInputBorder(borderRadius: BorderRadius.circular(8), borderSide: BorderSide(color: AppColors.brushedMetallicTrim)), focusedBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(8), borderSide: BorderSide(color: AppColors.electricViolet, width: 2))),
                      validator: (value) => value == null || value.trim().isEmpty ? 'Activity name is required' : null,
                    ),
                    const SizedBox(height: 16),
                    Text('SYSTEM DESCRIPTION', style: AppTextStyles.labelSmallUpper.copyWith(color: AppColors.electricViolet)),
                    const SizedBox(height: 8),
                    TextFormField(
                      controller: _descriptionController,
                      maxLines: 3,
                      style: AppTextStyles.bodyLarge.copyWith(color: AppColors.onSurface),
                      decoration: InputDecoration(hintText: 'e.g., Dynamic stretching routine for joint health', hintStyle: AppTextStyles.bodyMedium.copyWith(color: AppColors.onSurfaceVariant), filled: true, fillColor: AppColors.surfaceContainerLowest, border: OutlineInputBorder(borderRadius: BorderRadius.circular(8), borderSide: BorderSide(color: AppColors.brushedMetallicTrim)), focusedBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(8), borderSide: BorderSide(color: AppColors.electricViolet, width: 2))),
                    ),
                    const SizedBox(height: 16),
                    Row(
                      children: [
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text('BASE XP REWARD', style: AppTextStyles.labelSmallUpper.copyWith(color: AppColors.electricViolet)),
                              const SizedBox(height: 8),
                              TextFormField(
                                controller: _baseXpController,
                                keyboardType: TextInputType.number,
                                style: AppTextStyles.bodyLarge.copyWith(color: AppColors.onSurface),
                                decoration: InputDecoration(hintText: '45', filled: true, fillColor: AppColors.surfaceContainerLowest, border: OutlineInputBorder(borderRadius: BorderRadius.circular(8), borderSide: BorderSide(color: AppColors.brushedMetallicTrim)), focusedBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(8), borderSide: BorderSide(color: AppColors.electricViolet, width: 2))),
                                validator: (value) => int.tryParse(value ?? '') == null ? 'Valid XP required' : null,
                              ),
                            ],
                          ),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text('CATEGORY', style: AppTextStyles.labelSmallUpper.copyWith(color: AppColors.electricViolet)),
                              const SizedBox(height: 8),
                              DropdownButtonFormField<String>(
                                value: _selectedCategory,
                                decoration: InputDecoration(filled: true, fillColor: AppColors.surfaceContainerLowest, border: OutlineInputBorder(borderRadius: BorderRadius.circular(8), borderSide: BorderSide(color: AppColors.brushedMetallicTrim)), focusedBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(8), borderSide: BorderSide(color: AppColors.electricViolet, width: 2))),
                                dropdownColor: AppColors.surfaceContainerHigh,
                                items: _categories.map((c) => DropdownMenuItem(value: c, child: Text(c, style: AppTextStyles.bodyMedium))).toList(),
                                onChanged: (val) => setState(() => _selectedCategory = val ?? 'STRENGTH'),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 16),
                    Text('ACCENT COLOR', style: AppTextStyles.labelSmallUpper.copyWith(color: AppColors.electricViolet)),
                    const SizedBox(height: 8),
                    Wrap(spacing: 8, runSpacing: 8, children: _availableColors.map((color) {
                      final isSelected = color == _selectedColor;
                      return GestureDetector(onTap: () => setState(() => _selectedColor = color), child: Container(width: 40, height: 40, decoration: BoxDecoration(color: color, shape: BoxShape.circle, border: Border.all(color: isSelected ? AppColors.highVoltageYellow : Colors.transparent, width: 3), boxShadow: [BoxShadow(color: color.withValues(alpha: 0.5), blurRadius: 8)]), child: isSelected ? const Icon(Icons.check, color: AppColors.coreVoid, size: 24) : null));
                    }).toList()),
                    const SizedBox(height: 16),
                    Text('NEURAL ICON', style: AppTextStyles.labelSmallUpper.copyWith(color: AppColors.electricViolet)),
                    const SizedBox(height: 8),
                    Wrap(spacing: 8, runSpacing: 8, children: _availableIcons.map((icon) {
                      final isSelected = icon == _selectedIcon;
                      return GestureDetector(onTap: () => setState(() => _selectedIcon = icon), child: Container(width: 48, height: 48, decoration: BoxDecoration(color: AppColors.surfaceContainerLowest, border: Border.all(color: isSelected ? AppColors.electricViolet : AppColors.brushedMetallicTrim, width: isSelected ? 2 : 1), borderRadius: BorderRadius.circular(8)), child: Icon(icon, color: isSelected ? _selectedColor : AppColors.onSurfaceVariant, size: 24)));
                    }).toList()),
                    const SizedBox(height: 24),
                    Row(
                      children: [
                        Expanded(child: OutlinedButton(onPressed: _isSubmitting ? null : () => Navigator.pop(context), style: OutlinedButton.styleFrom(padding: const EdgeInsets.symmetric(vertical: 14), side: BorderSide(color: AppColors.brushedMetallicTrim)), child: Text('CANCEL', style: AppTextStyles.labelLargeUpper))),
                        const SizedBox(width: 12),
                        Expanded(child: ElevatedButton(onPressed: _isSubmitting ? null : _createActivity, style: ElevatedButton.styleFrom(backgroundColor: Colors.transparent, shadowColor: Colors.transparent, padding: EdgeInsets.zero, shape: const ContinuousRectangleBorder(borderRadius: BorderRadius.zero)), child: Ink(decoration: BoxDecoration(gradient: AppColors.voltageGradient, border: Border.all(color: AppColors.electricViolet, width: 1.5)), child: Container(alignment: Alignment.center, padding: const EdgeInsets.symmetric(vertical: 14), child: _isSubmitting ? const SizedBox(width: 24, height: 24, child: CircularProgressIndicator(strokeWidth: 2, color: AppColors.coreVoid)) : Row(mainAxisAlignment: MainAxisAlignment.center, children: [const Icon(Icons.electric_bolt, color: AppColors.coreVoid, size: 22), const SizedBox(width: 12), Text('DEPLOY RITUAL', style: AppTextStyles.labelLargeUpper.copyWith(color: AppColors.coreVoid, fontWeight: FontWeight.bold)), const SizedBox(width: 12), const Icon(Icons.keyboard_double_arrow_right, color: AppColors.coreVoid, size: 22)]))))),
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

  Future<void> _createActivity() async {
    if (!_formKey.currentState!.validate() || _selectedBranchId == null) return;
    setState(() => _isSubmitting = true);
    try {
      final createActivityUseCase = ref.read(createActivityUseCaseProvider);
      final activity = Activity(
        id: const Uuid().v4(),
        branchId: _selectedBranchId!,
        name: _nameController.text.trim(),
        description: _descriptionController.text.trim(),
        category: _selectedCategory,
        accentColor: _selectedColor,
        icon: _selectedIcon,
        baseXp: int.parse(_baseXpController.text),
        fields: [],
        isActive: true,
        createdAt: DateTime.now(),
        updatedAt: DateTime.now(),
        metadata: {},
      );
      await createActivityUseCase.call(activity);
      if (mounted) {
        Navigator.pop(context);
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Ritual "${activity.name}" deployed', style: AppTextStyles.bodyMedium), backgroundColor: AppColors.surfaceContainerHigh, behavior: SnackBarBehavior.floating, shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8))));
      }
    } catch (e) {
      if (mounted) ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Failed to create activity: $e', style: AppTextStyles.bodyMedium), backgroundColor: AppColors.overloadCrimson, behavior: SnackBarBehavior.floating));
    } finally {
      if (mounted) setState(() => _isSubmitting = false);
    }
  }
}

class _ConfigureMetricsDialog extends ConsumerStatefulWidget {
  @override
  ConsumerState<_ConfigureMetricsDialog> createState() => _ConfigureMetricsDialogState();
}

class _ConfigureMetricsDialogState extends ConsumerState<_ConfigureMetricsDialog> {
  final _formKey = GlobalKey<FormState>();
  final List<_FieldConfig> _fields = [
    _FieldConfig(name: 'Repetition Counter', type: FieldType.integer, icon: Icons.pin, color: AppColors.electricCyan, required: true),
    _FieldConfig(name: 'Duration Timer', type: FieldType.seconds, icon: Icons.timer, color: AppColors.electricViolet, required: true),
    _FieldConfig(name: 'Perceived Exertion (RPE)', type: FieldType.slider1to10, icon: Icons.speed, color: AppColors.highVoltageYellow, required: false),
  ];
  bool _isSubmitting = false;

  @override
  Widget build(BuildContext context) {
    final fieldWidgets = _fields.asMap().entries.map((entry) {
      final index = entry.key;
      final field = entry.value;
      return _FieldConfigWidget(
        index: index,
        field: field,
        onChanged: (updated) => setState(() => _fields[index] = updated),
        onDelete: () => setState(() => _fields.removeAt(index)),
      );
    }).toList();

    return Dialog(
      backgroundColor: Colors.transparent,
      child: Container(
        width: double.maxFinite,
        constraints: const BoxConstraints(maxWidth: 500),
        decoration: BoxDecoration(
          color: AppColors.surfaceContainerHigh,
          border: Border.all(color: AppColors.highVoltageYellow, width: 2),
          boxShadow: [
            BoxShadow(
              color: AppColors.highVoltageYellow.withValues(alpha: 0.3),
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
                gradient: AppColors.voltageGradient,
                border: Border(
                  bottom: BorderSide(color: AppColors.highVoltageYellow, width: 2),
                ),
              ),
              child: Row(
                children: [
                  const Icon(Icons.tune, color: AppColors.coreVoid, size: 28),
                  const SizedBox(width: 12),
                  Text(
                    'CONFIGURE TELEMETRY FIELDS',
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
                    Text('FIELD DEFINITIONS', style: AppTextStyles.labelSmallUpper.copyWith(color: AppColors.highVoltageYellow)),
                    const SizedBox(height: 8),
                    Text('Define the data points captured when recording this activity', style: AppTextStyles.bodySmall.copyWith(color: AppColors.onSurfaceVariant)),
                    const SizedBox(height: 16),
                    ...fieldWidgets,
                    const SizedBox(height: 12),
                    OutlinedButton.icon(
                      onPressed: () => setState(() => _fields.add(_FieldConfig(name: 'New Field', type: FieldType.integer, icon: Icons.add, color: AppColors.electricCyan, required: false))),
                      icon: const Icon(Icons.add, size: 16),
                      label: Text('ADD FIELD', style: AppTextStyles.labelMediumUpper),
                      style: OutlinedButton.styleFrom(minimumSize: const Size(double.infinity, 48)),
                    ),
                    const SizedBox(height: 24),
                    Row(
                      children: [
                        Expanded(
                          child: OutlinedButton(
                            onPressed: _isSubmitting ? null : () => Navigator.pop(context),
                            style: OutlinedButton.styleFrom(
                              padding: const EdgeInsets.symmetric(vertical: 14),
                              side: BorderSide(color: AppColors.brushedMetallicTrim),
                            ),
                            child: Text('CANCEL', style: AppTextStyles.labelLargeUpper),
                          ),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: ElevatedButton(
                            onPressed: _isSubmitting ? null : _saveFields,
                            style: ElevatedButton.styleFrom(
                              backgroundColor: Colors.transparent,
                              shadowColor: Colors.transparent,
                              padding: EdgeInsets.zero,
                              shape: const ContinuousRectangleBorder(borderRadius: BorderRadius.zero),
                            ),
                            child: Ink(
                              decoration: BoxDecoration(
                                gradient: AppColors.voltageGradient,
                                border: Border.all(color: AppColors.highVoltageYellow, width: 1.5),
                              ),
                              child: Container(
                                alignment: Alignment.center,
                                padding: const EdgeInsets.symmetric(vertical: 14),
                                child: _isSubmitting
                                    ? const SizedBox(width: 24, height: 24, child: CircularProgressIndicator(strokeWidth: 2, color: AppColors.coreVoid))
                                    : Row(
                                        mainAxisAlignment: MainAxisAlignment.center,
                                        children: [
                                          const Icon(Icons.electric_bolt, color: AppColors.coreVoid, size: 22),
                                          const SizedBox(width: 12),
                                          Text('SAVE SCHEMA', style: AppTextStyles.labelLargeUpper.copyWith(color: AppColors.coreVoid, fontWeight: FontWeight.bold)),
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

  Future<void> _saveFields() async {
    if (!_formKey.currentState!.validate()) return;
    setState(() => _isSubmitting = true);
    await Future.delayed(const Duration(milliseconds: 500));
    if (mounted) {
      Navigator.pop(context);
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Telemetry schema saved (${_fields.length} fields)', style: AppTextStyles.bodyMedium), backgroundColor: AppColors.surfaceContainerHigh, behavior: SnackBarBehavior.floating, shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8))));
    }
    setState(() => _isSubmitting = false);
  }
}

class _FieldConfig {
  final String name;
  final FieldType type;
  final IconData icon;
  final Color color;
  final bool required;

  _FieldConfig({required this.name, required this.type, required this.icon, required this.color, required this.required});
}

enum FieldType { integer, seconds, slider1to10, boolean, text }

class _FieldConfigWidget extends StatelessWidget {
  final int index;
  final _FieldConfig field;
  final Function(_FieldConfig) onChanged;
  final VoidCallback onDelete;

  const _FieldConfigWidget({required this.index, required this.field, required this.onChanged, required this.onDelete});

  @override
  Widget build(BuildContext context) {
    final typeLabels = {FieldType.integer: 'INTEGER', FieldType.seconds: 'SECONDS', FieldType.slider1to10: 'SLIDER 1-10', FieldType.boolean: 'BOOLEAN', FieldType.text: 'TEXT'};
    return CyberCard(padding: const EdgeInsets.all(12), margin: const EdgeInsets.only(bottom: 8), child: Row(children: [
      Container(width: 40, height: 40, decoration: BoxDecoration(color: AppColors.surfaceContainerHigh, border: Border.all(color: AppColors.brushedMetallicTrim, width: 1)), child: Icon(field.icon, color: field.color, size: 18)),
      const SizedBox(width: 12),
      Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        TextFormField(initialValue: field.name, style: AppTextStyles.bodyMedium.copyWith(fontWeight: FontWeight.w600), decoration: InputDecoration(isDense: true, contentPadding: EdgeInsets.zero, border: InputBorder.none), onChanged: (v) => onChanged(_FieldConfig(name: v, type: field.type, icon: field.icon, color: field.color, required: field.required))),
        Text('[TYPE: ${typeLabels[field.type]!}]', style: AppTextStyles.labelSmall.copyWith(color: AppColors.onSurfaceVariant, fontFamily: 'JetBrains Mono')),
      ])),
      DropdownButton<FieldType>(value: field.type, dropdownColor: AppColors.surfaceContainerHigh, underline: const SizedBox(), items: FieldType.values.map((t) => DropdownMenuItem(value: t, child: Text(typeLabels[t]!, style: AppTextStyles.bodySmall))).toList(), onChanged: (v) => onChanged(_FieldConfig(name: field.name, type: v!, icon: field.icon, color: field.color, required: field.required))),
      const SizedBox(width: 8),
      Checkbox(value: field.required, onChanged: (v) => onChanged(_FieldConfig(name: field.name, type: field.type, icon: field.icon, color: field.color, required: v ?? false)), activeColor: AppColors.highVoltageYellow),
      const SizedBox(width: 4),
      Text(field.required ? 'REQ' : 'OPT', style: AppTextStyles.labelSmall.copyWith(color: field.required ? AppColors.highVoltageYellow : AppColors.outline)),
      IconButton(icon: Icon(Icons.delete, color: AppColors.overloadCrimson, size: 20), onPressed: onDelete, tooltip: 'Delete field'),
    ]));
  }
}