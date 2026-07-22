import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:image_picker/image_picker.dart';
import '../../providers/auth_provider.dart';
import '../../providers/chat_provider.dart';
import '../../providers/profile_provider.dart';
import '../../services/storage_service.dart';
import '../../common/widgets/user_avatar.dart';
import '../../common/widgets/loading_view.dart';

/// Màn hình chat chi tiết với 1 người dùng, xác định qua [otherUid].
class ChatDetailScreen extends ConsumerStatefulWidget {
  final String otherUid;
  const ChatDetailScreen({super.key, required this.otherUid});

  @override
  ConsumerState<ChatDetailScreen> createState() => _ChatDetailScreenState();
}

class _ChatDetailScreenState extends ConsumerState<ChatDetailScreen> {
  final _textCtrl = TextEditingController();
  String? _conversationId;

  Future<void> _ensureConversation() async {
    final me = ref.read(currentUserProvider).value;
    final other = ref.read(userByIdProvider(widget.otherUid)).value;
    if (me == null || other == null) return;

    final conversation = await ref.read(chatRepositoryProvider).getOrCreateConversation(
          myUid: me.uid,
          myName: me.displayName,
          myAvatarUrl: me.avatarUrl,
          targetUid: other.uid,
          targetName: other.displayName,
          targetAvatarUrl: other.avatarUrl,
        );
    setState(() => _conversationId = conversation.id);
    await ref.read(chatRepositoryProvider).markConversationAsRead(conversation.id, me.uid);
  }

  Future<void> _sendText() async {
    final text = _textCtrl.text.trim();
    if (text.isEmpty || _conversationId == null) return;
    final me = ref.read(currentUserProvider).value;
    if (me == null) return;

    _textCtrl.clear();
    await ref.read(chatRepositoryProvider).sendMessage(
          conversationId: _conversationId!,
          senderId: me.uid,
          receiverId: widget.otherUid,
          senderName: me.displayName,
          senderAvatarUrl: me.avatarUrl,
          text: text,
        );
  }

  Future<void> _sendImage() async {
    if (_conversationId == null) return;
    final picker = ImagePicker();
    final picked = await picker.pickImage(source: ImageSource.gallery, imageQuality: 85);
    if (picked == null) return;

    final me = ref.read(currentUserProvider).value;
    if (me == null) return;

    final url = await StorageService().uploadChatImage(_conversationId!, File(picked.path));
    await ref.read(chatRepositoryProvider).sendMessage(
          conversationId: _conversationId!,
          senderId: me.uid,
          receiverId: widget.otherUid,
          senderName: me.displayName,
          senderAvatarUrl: me.avatarUrl,
          imageUrl: url,
        );
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (_conversationId == null) _ensureConversation();
  }

  @override
  Widget build(BuildContext context) {
    final otherAsync = ref.watch(userByIdProvider(widget.otherUid));
    final myUid = ref.watch(authStateProvider).value?.uid;

    return Scaffold(
      appBar: AppBar(
        title: otherAsync.when(
          data: (u) => Row(children: [
            UserAvatar(avatarUrl: u?.avatarUrl, radius: 16),
            const SizedBox(width: 8),
            Text(u?.displayName ?? ''),
          ]),
          loading: () => const SizedBox.shrink(),
          error: (_, __) => const SizedBox.shrink(),
        ),
      ),
      body: Column(
        children: [
          Expanded(
            child: _conversationId == null
                ? const LoadingView()
                : Consumer(builder: (context, ref, _) {
                    final messagesAsync = ref.watch(messagesProvider(_conversationId!));
                    return messagesAsync.when(
                      data: (messages) => ListView.builder(
                        reverse: true,
                        padding: const EdgeInsets.all(12),
                        itemCount: messages.length,
                        itemBuilder: (context, i) {
                          final m = messages[i];
                          final isMe = m.senderId == myUid;
                          return Align(
                            alignment: isMe ? Alignment.centerRight : Alignment.centerLeft,
                            child: Container(
                              margin: const EdgeInsets.symmetric(vertical: 4),
                              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
                              constraints: BoxConstraints(maxWidth: MediaQuery.of(context).size.width * 0.7),
                              decoration: BoxDecoration(
                                color: isMe ? Theme.of(context).colorScheme.primary : Colors.grey.shade200,
                                borderRadius: BorderRadius.circular(16),
                              ),
                              child: m.imageUrl != null
                                  ? ClipRRect(
                                      borderRadius: BorderRadius.circular(10),
                                      child: Image.network(m.imageUrl!, width: 180),
                                    )
                                  : Text(
                                      m.text ?? '',
                                      style: TextStyle(color: isMe ? Colors.white : Colors.black),
                                    ),
                            ),
                          );
                        },
                      ),
                      loading: () => const LoadingView(),
                      error: (_, __) => const ErrorView(),
                    );
                  }),
          ),
          SafeArea(
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 6),
              child: Row(
                children: [
                  IconButton(onPressed: _sendImage, icon: const Icon(Icons.image_outlined)),
                  Expanded(
                    child: TextField(
                      controller: _textCtrl,
                      decoration: const InputDecoration(
                        hintText: 'Nhập tin nhắn...',
                        border: OutlineInputBorder(borderRadius: BorderRadius.all(Radius.circular(24))),
                        contentPadding: EdgeInsets.symmetric(horizontal: 16),
                      ),
                      onSubmitted: (_) => _sendText(),
                    ),
                  ),
                  IconButton(onPressed: _sendText, icon: const Icon(Icons.send)),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}
