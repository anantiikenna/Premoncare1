import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../../core/app_colors.dart';
import '../../core/app_typography.dart';

class AccessibilitySettingsScreen extends StatefulWidget {
  const AccessibilitySettingsScreen({super.key});

  @override
  State<AccessibilitySettingsScreen> createState() => _AccessibilitySettingsScreenState();
}

class _AccessibilitySettingsScreenState extends State<AccessibilitySettingsScreen> {
  double _textScale = 1.0;
  bool _highContrast = false;
  bool _reduceAnimations = false;
  bool _screenReaderHints = true;

  @override
  void initState() {
    super.initState();
    _loadPreferences();
  }

  Future<void> _loadPreferences() async {
    final prefs = await SharedPreferences.getInstance();
    setState(() {
      _textScale = prefs.getDouble('access_text_scale') ?? 1.0;
      _highContrast = prefs.getBool('access_high_contrast') ?? false;
      _reduceAnimations = prefs.getBool('access_reduce_animations') ?? false;
      _screenReaderHints = prefs.getBool('access_screen_reader') ?? true;
    });
  }

  Future<void> _saveDouble(String key, double value) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setDouble(key, value);
  }

  Future<void> _saveBool(String key, bool value) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool(key, value);
  }

  @override
  Widget build(BuildContext context) {
    final color = AppColors.textPrimaryOf(context);
    final secondary = AppColors.textSecondaryOf(context);

    return Scaffold(
      backgroundColor: AppColors.backgroundOf(context),
      appBar: AppBar(
        backgroundColor: AppColors.surfaceOf(context),
        leading: IconButton(
          icon: Icon(Icons.arrow_back_rounded, color: color),
          onPressed: () => context.pop(),
        ),
        title: Text('Accessibility', style: TextStyle(color: color, fontWeight: FontWeight.w800)),
        centerTitle: true,
      ),
      body: ListView(
        padding: const EdgeInsets.all(20),
        children: [
          Text('TEXT SIZE', style: AppTypography.overlineOf(context).copyWith(letterSpacing: 1.5)),
          const SizedBox(height: 12),
          Container(
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(
              color: AppColors.surfaceOf(context),
              borderRadius: BorderRadius.circular(20),
              border: Border.all(color: AppColors.borderOf(context)),
            ),
            child: Column(
              children: [
                Text('Preview', style: TextStyle(fontSize: 16 * _textScale, fontWeight: FontWeight.w800, color: color)),
                const SizedBox(height: 4),
                Text('This is how text will appear.', style: TextStyle(fontSize: 14 * _textScale, color: secondary)),
                const SizedBox(height: 16),
                Slider(
                  value: _textScale,
                  min: 0.8,
                  max: 1.5,
                  divisions: 7,
                  activeColor: AppColors.primary,
                  onChanged: (v) {
                    setState(() => _textScale = v);
                    _saveDouble('access_text_scale', v);
                  },
                ),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text('A', style: TextStyle(fontSize: 12, color: secondary)),
                    Text('A', style: TextStyle(fontSize: 20, color: secondary)),
                  ],
                ),
              ],
            ),
          ),
          const SizedBox(height: 24),
          Text('DISPLAY', style: AppTypography.overlineOf(context).copyWith(letterSpacing: 1.5)),
          const SizedBox(height: 12),
          _buildToggle(icon: Icons.contrast_rounded, color: AppColors.primary, title: 'High Contrast', subtitle: 'Increase contrast for better visibility', value: _highContrast, onChanged: (v) { setState(() => _highContrast = v); _saveBool('access_high_contrast', v); }),
          _buildToggle(icon: Icons.animation_rounded, color: AppColors.warning, title: 'Reduce Animations', subtitle: 'Minimize motion effects', value: _reduceAnimations, onChanged: (v) { setState(() => _reduceAnimations = v); _saveBool('access_reduce_animations', v); }),
          _buildToggle(icon: Icons.accessibility_new_rounded, color: AppColors.success, title: 'Screen Reader Hints', subtitle: 'Add extra labels for screen readers', value: _screenReaderHints, onChanged: (v) { setState(() => _screenReaderHints = v); _saveBool('access_screen_reader', v); }),
        ],
      ),
    );
  }

  Widget _buildToggle({required IconData icon, required Color color, required String title, required String subtitle, required bool value, required ValueChanged<bool> onChanged}) {
    return Container(
      margin: const EdgeInsets.only(bottom: 8),
      child: ListTile(
        contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
        leading: Container(
          padding: const EdgeInsets.all(10),
          decoration: BoxDecoration(color: color.withValues(alpha: 0.1), borderRadius: BorderRadius.circular(12)),
          child: Icon(icon, color: color, size: 22),
        ),
        title: Text(title, style: TextStyle(fontSize: 14, fontWeight: FontWeight.w800, color: AppColors.textPrimaryOf(context))),
        subtitle: Text(subtitle, style: TextStyle(fontSize: 11, color: AppColors.textSecondaryOf(context))),
        trailing: Switch(value: value, onChanged: onChanged, activeThumbColor: AppColors.primary),
      ),
    );
  }
}
