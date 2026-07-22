import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:timeago/timeago.dart' as timeago;
import '../../models/notification_model.dart';
import '../../providers/auth_provider.dart';
import '../../common/widgets/user_avatar.dart';
import '../../common/widgets/loading_view.dart';

final notificationsProvider = StreamProvider((ref) {
  final myUid = ref.watch(authStateProvider).value?.uid;
  if (myUid == null) return Stream.value(<NotificationModel>[]);
  return ref.watch(notificationServiceProvider).watchNotifications(myUid);
});

class NotificationsScreen extends ConsumerWidget {
  const NotificationsScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final notificationsAsync = ref.watch(notificationsProvider);
    final myUid = ref.watch(authStateProvider).value?.uid;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Thông báo'),
        actions: [
          TextButton(
            onPressed: myUid == null
                ? null
                : () => ref.read(notificationServiceProvider).markAllAsRead(myUid),
            child: const Text('Đánh dấu đã đọc'),
          ),
        ],
      ),
      body: notificationsAsync.when(
        data: (items) {
          if (items.isEmpty) {
            return const EmptyView(message: 'Chưa có thông báo nào.', icon: Icons.notifications_none);
          }
          return ListView.builder(
            itemCount: items.length,
            itemBuilder: (context, i) {
              final n = items[i];
              return ListTile(
                tileColor: n.isRead ? null : Colors.deepPurple.withOpacity(0.05),
                leading: UserAvatar(avatarUrl: n.actorAvatarUrl, radius: 20),
                title: Text(n.message),
                subtitle: Text(timeago.format(n.createdAt, locale: 'vi')),
                onTap: () {
                  if (myUid != null) {
                    ref.read(notificationServiceProvider).markAsRead(myUid, n.id);
                  }
                  if (n.type == NotificationType.message) {
                    context.push('/chat/${n.actorId}');
                  } else if (n.postId != null) {
                    context.push('/post/${n.postId}/comments');
                  } else {
                    context.push('/profile/${n.actorId}');
                  }
                },
              );
            },
          );
        },
        loading: () => const LoadingView(),
        error: (_, __) => const ErrorView(),
      ),
    );
  }
}
