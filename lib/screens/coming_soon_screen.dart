import 'package:flutter/material.dart';
import '../theme.dart';

class ComingSoonScreen extends StatelessWidget {
  final String title;
  final IconData icon;
  final String message;
  const ComingSoonScreen({super.key, required this.title, required this.icon, required this.message});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.bg,
      appBar: AppBar(
        title: Text(title),
        backgroundColor: AppColors.surface,
        elevation: 0,
      ),
      body: Center(
        child: Padding(
          padding: const EdgeInsets.all(32),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Container(
                width: 72,
                height: 72,
                decoration: AppDecorations.squircle(color: AppColors.accentSoft),
                child: Icon(icon, size: 36, color: AppColors.primary),
              ),
              const SizedBox(height: 20),
              Text(
                title,
                style: const TextStyle(fontSize: 18, fontWeight: FontWeight.w800, color: AppColors.ink900),
              ),
              const SizedBox(height: 8),
              Text(
                message,
                textAlign: TextAlign.center,
                style: const TextStyle(color: AppColors.ink500, fontSize: 13.5, height: 1.4),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
