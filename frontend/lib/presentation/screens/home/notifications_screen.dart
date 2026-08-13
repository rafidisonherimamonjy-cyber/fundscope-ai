import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../core/utils/formatters.dart';
import '../../providers/favorites_notifications_provider.dart';
import '../../providers/repository_providers.dart';
import '../../widgets/app_bottom_nav.dart';
import '../../widgets/common_widgets.dart';

class NotificationsScreen extends ConsumerWidget {
  const NotificationsScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final notificationsAsync = ref.watch(notificationsListProvider);

    return Scaffold(
      appBar: AppBar(
        title: const Text("Notifications"),
        actions: [
          TextButton(
            onPressed: () async {
              await ref.read(notificationRepositoryProvider).markAllAsRead();
              ref.invalidate(notificationsListProvider);
            },
            child: const Text("Tout marquer comme lu"),
          ),
        ],
      ),
      bottomNavigationBar: const AppBottomNav(currentIndex: 2),
      body: notificationsAsync.when(
        data: (notifications) {
          if (notifications.isEmpty) {
            return const EmptyState(
              icon: Icons.notifications_none,
              title: "Aucune notification",
              message: "Vous serez averti dès qu'une opportunité correspond à votre profil.",
            );
          }
          return ListView.separated(
            itemCount: notifications.length,
            separatorBuilder: (_, __) => const Divider(height: 1),
            itemBuilder: (context, index) {
              final notif = notifications[index];
              return ListTile(
                leading: CircleAvatar(
                  backgroundColor: notif.isRead ? Colors.transparent : Theme.of(context).colorScheme.primaryContainer,
                  child: Icon(
                    Icons.auto_awesome,
                    color: notif.isRead ? Theme.of(context).colorScheme.outline : Theme.of(context).colorScheme.primary,
                  ),
                ),
                title: Text(notif.title, style: TextStyle(fontWeight: notif.isRead ? FontWeight.normal : FontWeight.w700)),
                subtitle: Text("${notif.body}\n${Formatters.date(notif.createdAt)}"),
                isThreeLine: true,
                onTap: () async {
                  if (!notif.isRead) {
                    await ref.read(notificationRepositoryProvider).markAsRead(notif.id);
                    ref.invalidate(notificationsListProvider);
                  }
                  if (notif.fundingCallId != null && context.mounted) {
                    context.push("/opportunity/${notif.fundingCallId}");
                  }
                },
              );
            },
          );
        },
        loading: () => const LoadingView(),
        error: (e, _) => ErrorView(message: "$e", onRetry: () => ref.invalidate(notificationsListProvider)),
      ),
    );
  }
}
