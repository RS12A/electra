import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../core/theme/theme_config.dart';
import '../core/theme/theme_controller.dart';
import '../core/theme/animations.dart';
import 'components/index.dart';

/// Theme showcase widget for development and testing
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
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(SpacingConfig.md),
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