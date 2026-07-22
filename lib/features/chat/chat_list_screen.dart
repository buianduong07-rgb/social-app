import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:timeago/timeago.dart' as timeago;
import '../../providers/auth_provider.dart';
import '../../providers/chat_provider.dart';
import '../../common/widgets/user_avatar.dart';
import '../../common/widgets/loading_view.dart';

class ChatListScreen extends ConsumerWidget {
  const ChatListScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final myUid = ref.watch(authStateProvider).value?.uid;
    final conversationsAsync = ref.watch(conversationsProvider);

    return Scaffold(
      appBar: AppBar(title: const Text('Tin nhắn')),
      body: conversationsAsync.when(
        data: (conversations) {
          if (conversations.isEmpty) {
            return const EmptyView(message: 'Chưa có cuộc trò chuyện nào.', icon: Icons.chat_bubble_outline);
          }
          return ListView.builder(
            itemCount: conversations.length,
            itemBuilder: (context, i) {
              final c = conversations[i];
              final otherUid = c.otherParticipantId(myUid ?? '');
              final unread = c.unreadCount[myUid] ?? 0;
              return ListTile(
                leading: UserAvatar(avatarUrl: c.participantAvatars[otherUid], radius: 24),
                title: Text(c.participantNames[otherUid] ?? 'Người dùng'),
                subtitle: Text(
                  c.lastMessage ?? '',
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(fontWeight: unread > 0 ? FontWeight.bold : FontWeight.normal),
                ),
                trailing: Column(
                  crossAxisAlignment: CrossAxisAlignment.end,
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    if (c.lastMessageAt != null)
                      Text(timeago.format(c.lastMessageAt!, locale: 'vi'),
                          style: TextStyle(fontSize: 11, color: Colors.grey.shade600)),
                    if (unread > 0) ...[
                      const SizedBox(height: 4),
                      CircleAvatar(radius: 9, backgroundColor: Theme.of(context).colorScheme.primary,
                          child: Text('$unread', style: const TextStyle(fontSize: 10, color: Colors.white))),
                    ]
                  ],
                ),
                onTap: () => context.push('/chat/$otherUid'),
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
