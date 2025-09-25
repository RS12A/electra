import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../core/theme/theme_config.dart';
import '../core/theme/theme_controller.dart';
import '../core/theme/animations.dart';
import 'components/index.dart';

/// Enhanced theme showcase widget for development and testing
class ThemeShowcase extends ConsumerWidget {
  const ThemeShowcase({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final themeController = ref.watch(themeControllerProvider);
    
    return Scaffold(
      appBar: AppBar(
        title: const Text('Electra Theme Showcase'),
        actions: [
          _ThemeSelector(),
        ],
      ),
      body: ResponsiveContainer(
        child: SingleChildScrollView(
          padding: ResponsiveConfig.getScreenPadding(
            MediaQuery.of(context).size.width,
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _ThemeInfo(),
              const SizedBox(height: SpacingConfig.lg),
              _ButtonShowcase(),
              const SizedBox(height: SpacingConfig.lg),
              _CardShowcase(),
              const SizedBox(height: SpacingConfig.lg),
              _InputShowcase(),
              const SizedBox(height: SpacingConfig.lg),
              _SwitchShowcase(),
              const SizedBox(height: SpacingConfig.lg),
              _AnimationShowcase(),
              const SizedBox(height: SpacingConfig.lg),
              _ResponsiveShowcase(),
              const SizedBox(height: SpacingConfig.lg),
              _AccessibilityShowcase(),
            ],
          ),
        ),
      ),
      floatingActionButton: const BouncyFAB(
        onPressed: null,
        tooltip: 'Enhanced FAB with bounce animation',
        child: Icon(Icons.palette),
      ),
    );
  }
}

class _ThemeSelector extends ConsumerWidget {
  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final themeController = ref.watch(themeControllerProvider);
    
    return PopupMenuButton<AppThemeMode>(
      onSelected: (theme) async {
        await themeController.changeTheme(theme);
      },
      itemBuilder: (context) => [
        const PopupMenuItem(
          value: AppThemeMode.kwasu,
          child: Text('KWASU Theme'),
        ),
        const PopupMenuItem(
          value: AppThemeMode.light,
          child: Text('Light Theme'),
        ),
        const PopupMenuItem(
          value: AppThemeMode.dark,
          child: Text('Dark Theme'),
        ),
        const PopupMenuItem(
          value: AppThemeMode.highContrast,
          child: Text('High Contrast'),
        ),
      ],
      child: const Icon(Icons.palette),
    );
  }
}

class _ThemeInfo extends ConsumerWidget {
  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final themeController = ref.watch(themeControllerProvider);
    
    return NeomorphicCards.header(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Enhanced Theme System',
            style: Theme.of(context).textTheme.headlineSmall?.copyWith(
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: SpacingConfig.sm),
          ResponsiveWrap(
            spacing: SpacingConfig.lg,
            children: [
              _InfoCard('Current Theme', themeController.currentTheme.name),
              _InfoCard('Reduce Motion', themeController.reduceMotion.toString()),
              _InfoCard('High Contrast', themeController.highContrast.toString()),
              _InfoCard('Text Scale', themeController.textScaleFactor.toStringAsFixed(1)),
            ],
          ),
        ],
      ),
    );
  }

  Widget _InfoCard(String label, String value) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: const TextStyle(
            fontSize: 12,
            fontWeight: FontWeight.w500,
            color: Colors.grey,
          ),
        ),
        const SizedBox(height: 2),
        Text(
          value,
          style: const TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.bold,
          ),
        ),
      ],
    );
  }
}

class _ButtonShowcase extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Enhanced Neomorphic Buttons',
          style: Theme.of(context).textTheme.headlineSmall,
        ),
        const SizedBox(height: SpacingConfig.md),
        ResponsiveWrap(
          spacing: SpacingConfig.md,
          runSpacing: SpacingConfig.md,
          children: [
            NeomorphicButtons.primary(
              onPressed: () {},
              child: const Text('Primary Button'),
            ),
            NeomorphicButtons.secondary(
              onPressed: () {},
              child: const Text('Secondary Button'),
            ),
            NeomorphicButtons.icon(
              onPressed: () {},
              icon: const Icon(Icons.favorite),
              tooltip: 'Like',
            ),
            NeomorphicButtons.fab(
              onPressed: () {},
              child: const Icon(Icons.add),
              tooltip: 'Add',
            ),
          ],
        ),
      ],
    );
  }
}

class _CardShowcase extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Enhanced Neomorphic Cards',
          style: Theme.of(context).textTheme.headlineSmall,
        ),
        const SizedBox(height: SpacingConfig.md),
        ResponsiveGrid(
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          mobileColumns: 1,
          tabletColumns: 2,
          desktopColumns: 3,
          children: [
            NeomorphicCards.content(
              child: const Text('Content Card\nWith multiple lines of text'),
            ),
            NeomorphicCards.interactive(
              onTap: () {},
              child: const Text('Interactive Card\nHover to see animation'),
            ),
            NeomorphicCards.dashboard(
              onTap: () {},
              child: const Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(Icons.analytics, size: 32),
                  SizedBox(height: SpacingConfig.sm),
                  Text('Dashboard Tile'),
                ],
              ),
            ),
          ],
        ),
      ],
    );
  }
}

class _InputShowcase extends StatefulWidget {
  @override
  State<_InputShowcase> createState() => _InputShowcaseState();
}

class _InputShowcaseState extends State<_InputShowcase> {
  final _textController = TextEditingController();
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  final _searchController = TextEditingController();
  bool _obscurePassword = true;

  @override
  void dispose() {
    _textController.dispose();
    _emailController.dispose();
    _passwordController.dispose();
    _searchController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Enhanced Neomorphic Inputs',
          style: Theme.of(context).textTheme.headlineSmall,
        ),
        const SizedBox(height: SpacingConfig.md),
        ResponsiveFlex(
          mobileDirection: Axis.vertical,
          tabletDirection: Axis.vertical,
          desktopDirection: Axis.horizontal,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Expanded(
              child: Column(
                children: [
                  NeomorphicInputs.text(
                    controller: _textController,
                    labelText: 'Full Name',
                    hintText: 'Enter your full name',
                  ),
                  const SizedBox(height: SpacingConfig.md),
                  NeomorphicInputs.email(
                    controller: _emailController,
                    helperText: 'We\'ll never share your email',
                  ),
                ],
              ),
            ),
            const SizedBox(width: SpacingConfig.lg, height: SpacingConfig.lg),
            Expanded(
              child: Column(
                children: [
                  NeomorphicInputs.password(
                    controller: _passwordController,
                    obscureText: _obscurePassword,
                    onToggleVisibility: () {
                      setState(() {
                        _obscurePassword = !_obscurePassword;
                      });
                    },
                  ),
                  const SizedBox(height: SpacingConfig.md),
                  NeomorphicInputs.search(
                    controller: _searchController,
                    hintText: 'Search anything...',
                    onClear: () {
                      _searchController.clear();
                    },
                  ),
                ],
              ),
            ),
          ],
        ),
      ],
    );
  }
}

class _SwitchShowcase extends StatefulWidget {
  @override
  State<_SwitchShowcase> createState() => _SwitchShowcaseState();
}

class _SwitchShowcaseState extends State<_SwitchShowcase> {
  bool _switch1 = false;
  bool _switch2 = true;
  bool _switch3 = false;
  bool _switch4 = true;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Enhanced Neomorphic Switches',
          style: Theme.of(context).textTheme.headlineSmall,
        ),
        const SizedBox(height: SpacingConfig.md),
        NeomorphicCards.content(
          child: Column(
            children: [
              NeomorphicSwitches.withLabel(
                value: _switch1,
                onChanged: (value) => setState(() => _switch1 = value),
                label: 'Enable notifications',
              ),
              const SizedBox(height: SpacingConfig.md),
              NeomorphicSwitches.withDescription(
                value: _switch2,
                onChanged: (value) => setState(() => _switch2 = value),
                title: 'Dark Mode',
                subtitle: 'Switch to dark theme for better night viewing',
              ),
              const SizedBox(height: SpacingConfig.md),
              NeomorphicSwitches.listTile(
                value: _switch3,
                onChanged: (value) => setState(() => _switch3 = value),
                title: 'Biometric Authentication',
                subtitle: 'Use fingerprint or face recognition',
                leading: const Icon(Icons.fingerprint),
              ),
            ],
          ),
        ),
      ],
    );
  }
}

class _AnimationShowcase extends StatefulWidget {
  @override
  State<_AnimationShowcase> createState() => _AnimationShowcaseState();
}

class _AnimationShowcaseState extends State<_AnimationShowcase>
    with TickerProviderStateMixin {
  late List<AnimationController> _staggeredControllers;
  bool _isAnimating = false;

  @override
  void initState() {
    super.initState();
    _staggeredControllers = StaggeredAnimationController.createStaggeredControllers(
      vsync: this,
      itemCount: 6,
    );
  }

  @override
  void dispose() {
    StaggeredAnimationController.disposeControllers(_staggeredControllers);
    super.dispose();
  }

  void _triggerStaggeredAnimation() {
    setState(() => _isAnimating = true);
    
    // Reset controllers
    for (final controller in _staggeredControllers) {
      controller.reset();
    }
    
    // Start staggered animation
    StaggeredAnimationController.startStaggeredAnimation(
      controllers: _staggeredControllers,
    );
    
    // Reset animation state after completion
    Future.delayed(const Duration(seconds: 2), () {
      if (mounted) {
        setState(() => _isAnimating = false);
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'GPU-Optimized Animations',
          style: Theme.of(context).textTheme.headlineSmall,
        ),
        const SizedBox(height: SpacingConfig.md),
        NeomorphicButtons.primary(
          onPressed: _isAnimating ? null : _triggerStaggeredAnimation,
          child: Text(_isAnimating ? 'Animating...' : 'Trigger Staggered Animation'),
        ),
        const SizedBox(height: SpacingConfig.lg),
        ResponsiveGrid(
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          mobileColumns: 2,
          tabletColumns: 3,
          desktopColumns: 6,
          children: _staggeredControllers.map((controller) {
            return AnimatedBuilder(
              animation: controller,
              builder: (context, child) {
                return Transform.scale(
                  scale: controller.value,
                  child: Opacity(
                    opacity: controller.value,
                    child: NeomorphicCards.content(
                      child: Container(
                        height: 60,
                        alignment: Alignment.center,
                        child: Icon(
                          Icons.star,
                          color: Theme.of(context).colorScheme.primary,
                        ),
                      ),
                    ),
                  ),
                );
              },
            );
          }).toList(),
        ),
      ],
    );
  }
}

class _ResponsiveShowcase extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Responsive Layout System',
          style: Theme.of(context).textTheme.headlineSmall,
        ),
        const SizedBox(height: SpacingConfig.md),
        ScreenSizeHelper(
          builder: (context, screenSize) {
            return NeomorphicCards.content(
              child: Column(
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text('Current Screen Size:'),
                      Chip(
                        label: Text(screenSize.name.toUpperCase()),
                        backgroundColor: Theme.of(context).colorScheme.primaryContainer,
                      ),
                    ],
                  ),
                  const SizedBox(height: SpacingConfig.md),
                  ResponsiveFlex(
                    children: [
                      Expanded(
                        child: Container(
                          height: 60,
                          decoration: BoxDecoration(
                            color: Theme.of(context).colorScheme.primary.withOpacity(0.2),
                            borderRadius: BorderRadius.circular(8),
                          ),
                          alignment: Alignment.center,
                          child: const Text('Flex Item 1'),
                        ),
                      ),
                      const SizedBox(width: SpacingConfig.sm, height: SpacingConfig.sm),
                      Expanded(
                        child: Container(
                          height: 60,
                          decoration: BoxDecoration(
                            color: Theme.of(context).colorScheme.secondary.withOpacity(0.2),
                            borderRadius: BorderRadius.circular(8),
                          ),
                          alignment: Alignment.center,
                          child: const Text('Flex Item 2'),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            );
          },
        ),
      ],
    );
  }
}

class _AccessibilityShowcase extends ConsumerWidget {
  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final themeController = ref.watch(themeControllerProvider);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Accessibility Features',
          style: Theme.of(context).textTheme.headlineSmall,
        ),
        const SizedBox(height: SpacingConfig.md),
        NeomorphicCards.content(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text(
                'Accessibility Settings',
                style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
              ),
              const SizedBox(height: SpacingConfig.md),
              NeomorphicSwitches.withDescription(
                value: themeController.reduceMotion,
                onChanged: (value) {
                  themeController.setAccessibilitySettings(reduceMotion: value);
                },
                title: 'Reduce Motion',
                subtitle: 'Minimize animations for better accessibility',
              ),
              const SizedBox(height: SpacingConfig.md),
              NeomorphicSwitches.withDescription(
                value: themeController.highContrast,
                onChanged: (value) {
                  themeController.setAccessibilitySettings(highContrast: value);
                },
                title: 'High Contrast',
                subtitle: 'Increase contrast for better visibility',
              ),
              const SizedBox(height: SpacingConfig.lg),
              const Text(
                'Features:',
                style: TextStyle(fontWeight: FontWeight.w600),
              ),
              const SizedBox(height: SpacingConfig.sm),
              const Text('• Screen reader compatibility (VoiceOver, TalkBack)'),
              const Text('• Keyboard navigation support'),
              const Text('• Semantic labels and hints'),
              const Text('• High contrast color schemes'),
              const Text('• Reduced motion animations'),
              const Text('• Scalable text and UI elements'),
            ],
          ),
        ),
      ],
    );
  }
}
            const SizedBox(height: SpacingConfig.lg),
            _SwitchShowcase(),
            const SizedBox(height: SpacingConfig.lg),
            _AnimationShowcase(),
            const SizedBox(height: SpacingConfig.lg),
            _AccessibilityShowcase(),
          ],
        ),
      ),
    );
  }
}

class _ThemeSelector extends ConsumerWidget {
  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final themeController = ref.watch(themeControllerProvider);
    
    return PopupMenuButton<AppThemeMode>(
      onSelected: (theme) async {
        await themeController.changeTheme(theme);
      },
      itemBuilder: (context) => [
        const PopupMenuItem(
          value: AppThemeMode.kwasu,
          child: Text('KWASU Theme'),
        ),
        const PopupMenuItem(
          value: AppThemeMode.light,
          child: Text('Light Theme'),
        ),
        const PopupMenuItem(
          value: AppThemeMode.dark,
          child: Text('Dark Theme'),
        ),
        const PopupMenuItem(
          value: AppThemeMode.highContrast,
          child: Text('High Contrast'),
        ),
      ],
      child: const Icon(Icons.palette),
    );
  }
}

class _ThemeInfo extends ConsumerWidget {
  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final themeController = ref.watch(themeControllerProvider);
    final accessibility = ref.watch(accessibilitySettingsProvider);
    
    return NeomorphicCards.header(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Current Theme',
            style: Theme.of(context).textTheme.headlineSmall,
          ),
          const SizedBox(height: SpacingConfig.sm),
          Text('Mode: ${themeController.currentTheme.name}'),
          Text('Reduce Motion: ${accessibility.reduceMotion}'),
          Text('High Contrast: ${accessibility.highContrast}'),
          Text('Text Scale: ${accessibility.textScale.toStringAsFixed(1)}'),
        ],
      ),
    );
  }
}

class _ButtonShowcase extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Buttons',
          style: Theme.of(context).textTheme.titleLarge,
        ),
        const SizedBox(height: SpacingConfig.md),
        Wrap(
          spacing: SpacingConfig.md,
          runSpacing: SpacingConfig.md,
          children: [
            NeomorphicButtons.primary(
              onPressed: () {},
              child: const Text('Primary'),
            ),
            NeomorphicButtons.secondary(
              onPressed: () {},
              child: const Text('Secondary'),
            ),
            NeomorphicButtons.icon(
              onPressed: () {},
              icon: const Icon(Icons.favorite),
              tooltip: 'Like',
            ),
            NeomorphicButtons.fab(
              onPressed: () {},
              child: const Icon(Icons.add),
              tooltip: 'Add',
            ),
          ],
        ),
        const SizedBox(height: SpacingConfig.md),
        Row(
          children: [
            Expanded(
              child: NeomorphicButton(
                onPressed: () {},
                style: NeomorphicButtonStyle.elevated,
                child: const Text('Elevated'),
              ),
            ),
            const SizedBox(width: SpacingConfig.md),
            Expanded(
              child: NeomorphicButton(
                onPressed: () {},
                style: NeomorphicButtonStyle.inset,
                child: const Text('Inset'),
              ),
            ),
            const SizedBox(width: SpacingConfig.md),
            Expanded(
              child: NeomorphicButton(
                onPressed: () {},
                style: NeomorphicButtonStyle.flat,
                child: const Text('Flat'),
              ),
            ),
          ],
        ),
      ],
    );
  }
}

class _CardShowcase extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Cards',
          style: Theme.of(context).textTheme.titleLarge,
        ),
        const SizedBox(height: SpacingConfig.md),
        GridView.count(
          crossAxisCount: 2,
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          mainAxisSpacing: SpacingConfig.md,
          crossAxisSpacing: SpacingConfig.md,
          children: [
            NeomorphicCards.content(
              child: const Center(child: Text('Content Card')),
            ),
            NeomorphicCards.interactive(
              onTap: () {},
              child: const Center(child: Text('Interactive Card')),
            ),
            NeomorphicCards.dashboard(
              onTap: () {},
              child: const Center(child: Text('Dashboard Tile')),
            ),
            NeomorphicCards.status(
              child: const Center(child: Text('Status Card')),
            ),
          ],
        ),
      ],
    );
  }
}

class _InputShowcase extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Input Fields',
          style: Theme.of(context).textTheme.titleLarge,
        ),
        const SizedBox(height: SpacingConfig.md),
        NeomorphicInputs.text(
          labelText: 'Name',
          hintText: 'Enter your name',
          helperText: 'Your full name',
        ),
        const SizedBox(height: SpacingConfig.md),
        NeomorphicInputs.email(
          labelText: 'Email Address',
          hintText: 'user@kwasu.edu.ng',
        ),
        const SizedBox(height: SpacingConfig.md),
        NeomorphicInputs.password(
          labelText: 'Password',
          helperText: 'Must be at least 8 characters',
        ),
        const SizedBox(height: SpacingConfig.md),
        NeomorphicInputs.search(
          hintText: 'Search elections...',
        ),
        const SizedBox(height: SpacingConfig.md),
        NeomorphicInputs.textArea(
          labelText: 'Description',
          hintText: 'Enter description...',
          maxLines: 3,
        ),
      ],
    );
  }
}

class _SwitchShowcase extends StatefulWidget {
  @override
  State<_SwitchShowcase> createState() => _SwitchShowcaseState();
}

class _SwitchShowcaseState extends State<_SwitchShowcase> {
  bool _switch1 = false;
  bool _switch2 = true;
  bool _switch3 = false;
  int _selectedToggle = 0;
  List<bool> _toggleStates = [true, false, false];

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Switches & Toggles',
          style: Theme.of(context).textTheme.titleLarge,
        ),
        const SizedBox(height: SpacingConfig.md),
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceAround,
          children: [
            Column(
              children: [
                NeomorphicSwitch(
                  value: _switch1,
                  onChanged: (value) => setState(() => _switch1 = value),
                ),
                const SizedBox(height: SpacingConfig.xs),
                const Text('Basic'),
              ],
            ),
            Column(
              children: [
                NeomorphicSwitch(
                  value: _switch2,
                  onChanged: (value) => setState(() => _switch2 = value),
                  width: 60,
                  height: 30,
                ),
                const SizedBox(height: SpacingConfig.xs),
                const Text('Large'),
              ],
            ),
            Column(
              children: [
                NeomorphicSwitch(
                  value: _switch3,
                  onChanged: (value) => setState(() => _switch3 = value),
                  enabled: false,
                ),
                const SizedBox(height: SpacingConfig.xs),
                const Text('Disabled'),
              ],
            ),
          ],
        ),
        const SizedBox(height: SpacingConfig.lg),
        NeomorphicSwitchTile(
          value: _switch1,
          onChanged: (value) => setState(() => _switch1 = value),
          title: const Text('Enable Notifications'),
          subtitle: const Text('Receive updates about elections'),
        ),
        const SizedBox(height: SpacingConfig.md),
        NeomorphicToggleButtons(
          isSelected: _toggleStates,
          onPressed: (index) {
            setState(() {
              for (int i = 0; i < _toggleStates.length; i++) {
                _toggleStates[i] = i == index;
              }
            });
          },
          children: const [
            Text('Option 1'),
            Text('Option 2'),
            Text('Option 3'),
          ],
        ),
      ],
    );
  }
}

class _AnimationShowcase extends StatefulWidget {
  @override
  State<_AnimationShowcase> createState() => _AnimationShowcaseState();
}

class _AnimationShowcaseState extends State<_AnimationShowcase> {
  bool _isVisible = true;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Animations',
          style: Theme.of(context).textTheme.titleLarge,
        ),
        const SizedBox(height: SpacingConfig.md),
        Row(
          children: [
            AnimatedPressButton(
              onPressed: () {
                setState(() => _isVisible = !_isVisible);
              },
              child: Container(
                padding: const EdgeInsets.all(SpacingConfig.md),
                decoration: BoxDecoration(
                  color: Theme.of(context).colorScheme.primary,
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Text(
                  'Toggle Animation',
                  style: TextStyle(
                    color: Theme.of(context).colorScheme.onPrimary,
                  ),
                ),
              ),
            ),
            const Spacer(),
            AnimatedOpacity(
              opacity: _isVisible ? 1.0 : 0.0,
              duration: AnimationConfig.microDuration,
              child: NeomorphicCards.content(
                child: const Text('Fade Animation'),
              ),
            ),
          ],
        ),
        const SizedBox(height: SpacingConfig.md),
        AnimatedShimmer(
          enabled: true,
          child: Container(
            height: 60,
            decoration: BoxDecoration(
              color: Theme.of(context).colorScheme.surfaceVariant,
              borderRadius: BorderRadius.circular(8),
            ),
            child: const Center(child: Text('Shimmer Loading')),
          ),
        ),
      ],
    );
  }
}

class _AccessibilityShowcase extends ConsumerWidget {
  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final themeController = ref.watch(themeControllerProvider);
    final accessibility = ref.watch(accessibilitySettingsProvider);
    
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Accessibility',
          style: Theme.of(context).textTheme.titleLarge,
        ),
        const SizedBox(height: SpacingConfig.md),
        NeomorphicCards.content(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              NeomorphicSwitchTile(
                value: accessibility.reduceMotion,
                onChanged: (value) {
                  themeController.setAccessibilitySettings(
                    reduceMotion: value,
                  );
                },
                title: const Text('Reduce Motion'),
                subtitle: const Text('Minimize animations for better accessibility'),
              ),
              NeomorphicSwitchTile(
                value: accessibility.highContrast,
                onChanged: (value) {
                  themeController.setAccessibilitySettings(
                    highContrast: value,
                  );
                },
                title: const Text('High Contrast'),
                subtitle: const Text('Use high contrast colors'),
              ),
              const SizedBox(height: SpacingConfig.md),
              Text('Text Scale: ${accessibility.textScale.toStringAsFixed(1)}x'),
              Slider(
                value: accessibility.textScale,
                min: 0.8,
                max: 2.0,
                divisions: 12,
                onChanged: (value) {
                  themeController.setAccessibilitySettings(
                    textScaleFactor: value,
                  );
                },
              ),
            ],
          ),
        ),
      ],
    );
  }
}