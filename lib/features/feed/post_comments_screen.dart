import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:timeago/timeago.dart' as timeago;
import '../../models/post_model.dart';
import '../../providers/auth_provider.dart';
import '../../providers/feed_provider.dart';
import '../../common/widgets/user_avatar.dart';
import '../../common/widgets/loading_view.dart';

final postCommentsProvider = StreamProvider.family((ref, String postId) {
  return ref.watch(postRepositoryProvider).watchComments(postId);
});

/// Lấy thông tin bài viết (để biết authorId khi gửi thông báo bình luận mới).
final singlePostProvider = StreamProvider.family<PostModel?, String>((ref, postId) {
  return FirebaseFirestore.instance.collection('posts').doc(postId).snapshots().map(
      (doc) => doc.exists ? PostModel.fromMap(doc.data()!, doc.id) : null);
});

/// Màn hình xem + thêm bình luận cho 1 bài viết.
class PostCommentsScreen extends ConsumerStatefulWidget {
  final String postId;
  const PostCommentsScreen({super.key, required this.postId});

  @override
  ConsumerState<PostCommentsScreen> createState() => _PostCommentsScreenState();
}

class _PostCommentsScreenState extends ConsumerState<PostCommentsScreen> {
  final _controller = TextEditingController();

  Future<void> _submit(String postAuthorId) async {
    final content = _controller.text.trim();
    if (content.isEmpty) return;
    final me = ref.read(currentUserProvider).value;
    if (me == null) return;

    _controller.clear();
    await ref.read(postRepositoryProvider).addComment(
          postId: widget.postId,
          postAuthorId: postAuthorId,
          authorId: me.uid,
          authorUsername: me.username,
          authorAvatarUrl: me.avatarUrl,
          content: content,
        );
  }

  @override
  Widget build(BuildContext context) {
    final commentsAsync = ref.watch(postCommentsProvider(widget.postId));
    final postAsync = ref.watch(singlePostProvider(widget.postId));

    return Scaffold(
      appBar: AppBar(title: const Text('Bình luận')),
      body: Column(
        children: [
          Expanded(
            child: commentsAsync.when(
              data: (comments) {
                if (comments.isEmpty) {
                  return const EmptyView(message: 'Chưa có bình luận nào. Hãy là người đầu tiên!');
                }
                return ListView.builder(
                  itemCount: comments.length,
                  itemBuilder: (context, i) {
                    final c = comments[i];
                    return ListTile(
                      leading: UserAvatar(avatarUrl: c.authorAvatarUrl, radius: 18),
                      title: Text('@${c.authorUsername}', style: const TextStyle(fontWeight: FontWeight.w600)),
                      subtitle: Text(c.content),
                      trailing: Text(timeago.format(c.createdAt, locale: 'vi'),
                          style: const TextStyle(fontSize: 11)),
                    );
                  },
                );
              },
              loading: () => const LoadingView(),
              error: (_, __) => const ErrorView(),
            ),
          ),
          SafeArea(
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 6),
              child: Row(
                children: [
                  Expanded(
                    child: TextField(
                      controller: _controller,
                      decoration: const InputDecoration(hintText: 'Viết bình luận...'),
                    ),
                  ),
                  IconButton(
                    onPressed: () => _submit(postAsync.value?.authorId ?? ''),
                    icon: const Icon(Icons.send),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}
