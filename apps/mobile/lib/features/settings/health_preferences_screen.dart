import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../../core/app_colors.dart';
import '../../core/app_typography.dart';

class HealthPreferencesScreen extends StatefulWidget {
  const HealthPreferencesScreen({super.key});

  @override
  State<HealthPreferencesScreen> createState() => _HealthPreferencesScreenState();
}

class _HealthPreferencesScreenState extends State<HealthPreferencesScreen> {
  String _weightUnit = 'kg';
  String _heightUnit = 'cm';
  String _temperatureUnit = '°C';
  String _dateFormat = 'DD/MM/YYYY';

  @override
  void initState() {
    super.initState();
    _loadPreferences();
  }

  Future<void> _loadPreferences() async {
    final prefs = await SharedPreferences.getInstance();
    setState(() {
      _weightUnit = prefs.getString('health_weight_unit') ?? 'kg';
      _heightUnit = prefs.getString('health_height_unit') ?? 'cm';
      _temperatureUnit = prefs.getString('health_temperature_unit') ?? '°C';
      _dateFormat = prefs.getString('health_date_format') ?? 'DD/MM/YYYY';
    });
  }

  Future<void> _savePreference(String key, String value) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(key, value);
  }

  @override
  Widget build(BuildContext context) {
    final color = AppColors.textPrimaryOf(context);

    return Scaffold(
      backgroundColor: AppColors.backgroundOf(context),
      appBar: AppBar(
        backgroundColor: AppColors.surfaceOf(context),
        leading: IconButton(
          icon: Icon(Icons.arrow_back_rounded, color: color),
          onPressed: () => context.pop(),
        ),
        title: Text('Health Preferences', style: TextStyle(color: color, fontWeight: FontWeight.w800)),
        centerTitle: true,
      ),
      body: ListView(
        padding: const EdgeInsets.all(20),
        children: [
          Text('MEASUREMENT UNITS', style: AppTypography.overlineOf(context).copyWith(letterSpacing: 1.5)),
          const SizedBox(height: 12),
          _buildUnitSelector('Weight', ['kg', 'lbs'], _weightUnit, (v) { setState(() => _weightUnit = v); _savePreference('health_weight_unit', v); }),
          _buildUnitSelector('Height', ['cm', 'ft/in'], _heightUnit, (v) { setState(() => _heightUnit = v); _savePreference('health_height_unit', v); }),
          _buildUnitSelector('Temperature', ['°C', '°F'], _temperatureUnit, (v) { setState(() => _temperatureUnit = v); _savePreference('health_temperature_unit', v); }),
          const SizedBox(height: 24),
          Text('FORMAT', style: AppTypography.overlineOf(context).copyWith(letterSpacing: 1.5)),
          const SizedBox(height: 12),
          _buildUnitSelector('Date Format', ['DD/MM/YYYY', 'MM/DD/YYYY', 'YYYY-MM-DD'], _dateFormat, (v) { setState(() => _dateFormat = v); _savePreference('health_date_format', v); }),
        ],
      ),
    );
  }

  Widget _buildUnitSelector(String label, List<String> options, String selected, ValueChanged<String> onChanged) {
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.surfaceOf(context),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppColors.borderOf(context)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(label, style: TextStyle(fontSize: 14, fontWeight: FontWeight.w800, color: AppColors.textPrimaryOf(context))),
          const SizedBox(height: 12),
          Row(
            children: options.map((opt) {
              final isSelected = opt == selected;
              return Expanded(
                child: GestureDetector(
                  onTap: () => onChanged(opt),
                  child: AnimatedContainer(
                    duration: const Duration(milliseconds: 200),
                    margin: EdgeInsets.only(right: opt != options.last ? 8 : 0),
                    padding: const EdgeInsets.symmetric(vertical: 12),
                    decoration: BoxDecoration(
                      color: isSelected ? AppColors.primary.withValues(alpha: 0.1) : Colors.transparent,
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(color: isSelected ? AppColors.primary : AppColors.borderOf(context)),
                    ),
                    child: Center(
                      child: Text(opt, style: TextStyle(fontSize: 13, fontWeight: isSelected ? FontWeight.w800 : FontWeight.w600, color: isSelected ? AppColors.primary : AppColors.textSecondaryOf(context))),
                    ),
                  ),
                ),
              );
            }).toList(),
          ),
        ],
      ),
    );
  }
}
