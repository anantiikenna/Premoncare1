import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:url_launcher/url_launcher.dart';
import '../../core/app_colors.dart';
import '../../core/app_typography.dart';

class AboutScreen extends StatelessWidget {
  const AboutScreen({super.key});

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
        title: Text('About Premon Care', style: TextStyle(color: color, fontWeight: FontWeight.w800)),
        centerTitle: true,
      ),
      body: ListView(
        padding: const EdgeInsets.all(20),
        children: [
          Center(
            child: Column(
              children: [
                Image.asset('assets/logo.png', height: 80, errorBuilder: (_, _, _) => Container(
                  width: 80, height: 80,
                  decoration: BoxDecoration(color: AppColors.primary.withValues(alpha: 0.1), shape: BoxShape.circle),
                  child: const Icon(Icons.medical_services_rounded, color: AppColors.primary, size: 40),
                )),
                const SizedBox(height: 16),
                Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Text('Premon', style: TextStyle(color: AppColors.primary, fontSize: 24, fontWeight: FontWeight.w900)),
                    Text('Care', style: TextStyle(color: AppColors.success, fontSize: 24, fontWeight: FontWeight.w900)),
                  ],
                ),
                const SizedBox(height: 4),
                Text('Version 2.4.1', style: AppTypography.bodySmallOf(context)),
              ],
            ),
          ),
          const SizedBox(height: 40),
          _buildInfoTile(context, icon: Icons.info_outline_rounded, color: AppColors.primary, title: 'About', subtitle: 'Premon Care is a telemedicine platform connecting patients with licensed healthcare providers across Nigeria and Africa.'),
          _buildInfoTile(context, icon: Icons.code_rounded, color: AppColors.success, title: 'Built With', subtitle: 'Flutter, Supabase, Firebase'),
          _buildInfoTile(context, icon: Icons.favorite_rounded, color: AppColors.error, title: 'Our Mission', subtitle: 'To make quality healthcare accessible to everyone, everywhere through technology.'),
          _buildTappableTile(
            context,
            icon: Icons.public_rounded,
            color: AppColors.primary,
            title: 'Website',
            subtitle: 'www.premoncare.com',
            url: 'https://www.premoncare.com',
          ),
          _buildTappableTile(
            context,
            icon: Icons.email_outlined,
            color: AppColors.warning,
            title: 'Contact',
            subtitle: 'hello@premoncare.com',
            url: 'mailto:hello@premoncare.com',
          ),
          const SizedBox(height: 24),
          Center(
            child: Text(
              'Made with care in Nigeria',
              style: AppTypography.captionOf(context),
            ),
          ),
          const SizedBox(height: 40),
        ],
      ),
    );
  }

  Widget _buildInfoTile(BuildContext context, {required IconData icon, required Color color, required String title, required String subtitle}) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 16),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            padding: const EdgeInsets.all(10),
            decoration: BoxDecoration(color: color.withValues(alpha: 0.1), borderRadius: BorderRadius.circular(12)),
            child: Icon(icon, color: color, size: 22),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(title, style: TextStyle(fontSize: 14, fontWeight: FontWeight.w800, color: AppColors.textPrimaryOf(context))),
                const SizedBox(height: 4),
                Text(subtitle, style: TextStyle(fontSize: 13, color: AppColors.textSecondaryOf(context))),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildTappableTile(BuildContext context, {required IconData icon, required Color color, required String title, required String subtitle, required String url}) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 16),
      child: GestureDetector(
        onTap: () async {
          final uri = Uri.parse(url);
          if (await canLaunchUrl(uri)) {
            await launchUrl(uri);
          }
        },
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Container(
              padding: const EdgeInsets.all(10),
              decoration: BoxDecoration(color: color.withValues(alpha: 0.1), borderRadius: BorderRadius.circular(12)),
              child: Icon(icon, color: color, size: 22),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(title, style: TextStyle(fontSize: 14, fontWeight: FontWeight.w800, color: AppColors.textPrimaryOf(context))),
                  const SizedBox(height: 4),
                  Text(subtitle, style: TextStyle(fontSize: 13, color: AppColors.primary, decoration: TextDecoration.underline, decorationColor: AppColors.primary)),
                ],
              ),
            ),
            Icon(Icons.open_in_new_rounded, color: AppColors.textTertiaryOf(context), size: 16),
          ],
        ),
      ),
    );
  }
}
