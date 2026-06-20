import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import '../../core/app_colors.dart';
import '../../core/app_typography.dart';

class LanguageRegionScreen extends StatefulWidget {
  const LanguageRegionScreen({super.key});

  @override
  State<LanguageRegionScreen> createState() => _LanguageRegionScreenState();
}

class _LanguageRegionScreenState extends State<LanguageRegionScreen> {
  String _selectedLanguage = 'English';
  String _selectedRegion = 'Nigeria';
  String _selectedCurrency = 'NGN (₦)';

  static const _languages = ['English', 'French', 'Yoruba', 'Igbo', 'Hausa', 'Swahili'];
  static const _regions = ['Nigeria', 'Ghana', 'Kenya', 'South Africa', 'United States', 'United Kingdom'];
  static const _currencies = ['NGN', 'GHS', 'KES', 'ZAR', 'USD', 'GBP'];

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
        title: Text('Language & Region', style: TextStyle(color: color, fontWeight: FontWeight.w800)),
        centerTitle: true,
      ),
      body: ListView(
        padding: const EdgeInsets.all(20),
        children: [
          Text('LANGUAGE', style: AppTypography.overlineOf(context).copyWith(letterSpacing: 1.5)),
          const SizedBox(height: 12),
          _buildSelectionCard(
            icon: Icons.language_rounded,
            color: AppColors.primary,
            title: 'App Language',
            options: _languages,
            selected: _selectedLanguage,
            onChanged: (v) => setState(() => _selectedLanguage = v),
            color2: color,
            color3: secondary,
          ),
          const SizedBox(height: 24),
          Text('REGION', style: AppTypography.overlineOf(context).copyWith(letterSpacing: 1.5)),
          const SizedBox(height: 12),
          _buildSelectionCard(
            icon: Icons.public_rounded,
            color: AppColors.success,
            title: 'Region',
            options: _regions,
            selected: _selectedRegion,
            onChanged: (v) => setState(() => _selectedRegion = v),
            color2: color,
            color3: secondary,
          ),
          const SizedBox(height: 12),
          _buildSelectionCard(
            icon: Icons.monetization_on_rounded,
            color: AppColors.warning,
            title: 'Currency',
            options: _currencies,
            selected: _selectedCurrency,
            onChanged: (v) => setState(() => _selectedCurrency = v),
            color2: color,
            color3: secondary,
          ),
        ],
      ),
    );
  }

  Widget _buildSelectionCard({required IconData icon, required Color color, required String title, required List<String> options, required String selected, required ValueChanged<String> onChanged, required Color color2, required Color color3}) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.surfaceOf(context),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: AppColors.borderOf(context)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(color: color.withValues(alpha: 0.1), borderRadius: BorderRadius.circular(10)),
                child: Icon(icon, color: color, size: 20),
              ),
              const SizedBox(width: 12),
              Text(title, style: TextStyle(fontSize: 14, fontWeight: FontWeight.w800, color: color2)),
            ],
          ),
          const SizedBox(height: 12),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: options.map((opt) {
              final isSelected = opt == selected;
              return GestureDetector(
                onTap: () => onChanged(opt),
                child: AnimatedContainer(
                  duration: const Duration(milliseconds: 200),
                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
                  decoration: BoxDecoration(
                    color: isSelected ? color.withValues(alpha: 0.1) : Colors.transparent,
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(color: isSelected ? color : AppColors.borderOf(context)),
                  ),
                  child: Text(opt, style: TextStyle(fontSize: 13, fontWeight: isSelected ? FontWeight.w800 : FontWeight.w600, color: isSelected ? color : color3)),
                ),
              );
            }).toList(),
          ),
        ],
      ),
    );
  }
}
