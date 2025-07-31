import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../theme/global_theme.dart';

class ProfileHeader extends ConsumerWidget {
  final bool showNotification;

  const ProfileHeader({super.key, this.showNotification = true});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return Row(
      children: [
        // Simple avatar
        CircleAvatar(
          radius: 22,
          backgroundColor: GlobalTheme.primaryNeon,
          child: const Icon(Icons.person, color: Colors.black, size: 24),
        ),
        const SizedBox(width: 12),

        // User info
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Fitness User',
                style: Theme.of(context).textTheme.titleMedium?.copyWith(
                  color: GlobalTheme.textPrimary,
                  fontWeight: FontWeight.w600,
                ),
              ),
              Text(
                'Ready to run!',
                style: Theme.of(context).textTheme.bodySmall?.copyWith(
                  color: GlobalTheme.textSecondary,
                ),
              ),
            ],
          ),
        ),

        // Notification icon
        if (showNotification)
          IconButton(
            onPressed: () {},
            icon: const Icon(Icons.notifications_outlined, size: 24),
            style: IconButton.styleFrom(
              foregroundColor: GlobalTheme.textSecondary,
              backgroundColor: GlobalTheme.surfaceCard,
            ),
          ),
      ],
    );
  }
}
