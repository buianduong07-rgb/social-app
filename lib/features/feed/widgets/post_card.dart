import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:timeago/timeago.dart' as timeago;
import 'package:go_router/go_router.dart';
import '../../../models/post_model.dart';
import '../../../providers/auth_provider.dart';
import '../../../providers/feed_provider.dart';
import '../../../common/widgets/user_avatar.dart';

/// Widget hiển thị 1 bài đăng trong Feed hoặc trang Profile.
class PostCard extends ConsumerWidget {
  final PostModel post;
  const PostCard({super.key, required this.post});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final myUid = ref.watch(authStateProvider).value?.uid;
    final isLikedAsync = myUid == null
        ? const AsyncValue.data(false)
        : ref.watch(_isLikedProvider((postId: post.id, myUid: myUid)));

    return Container(
      margin: const EdgeInsets.only(bottom: 8),
      color: Colors.white,
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              GestureDetector(
                onTap: () => context.push('/profile/${post.authorId}'),
                child: UserAvatar(avatarUrl: post.authorAvatarUrl, radius: 18),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text('@${post.authorUsername}', style: const TextStyle(fontWeight: FontWeight.w600)),
                    Text(
                      timeago.format(post.createdAt, locale: 'vi') + (post.isEdited ? ' · đã chỉnh sửa' : ''),
                      style: TextStyle(fontSize: 12, color: Colors.grey.shade600),
                    ),
                  ],
                ),
              ),
              if (myUid == post.authorId)
                PopupMenuButton<String>(
                  onSelected: (value) => _handleMenuAction(context, ref, value),
                  itemBuilder: (context) => [
                    const PopupMenuItem(value: 'delete', child: Text('Xóa bài viết')),
                  ],
                )
              else
                PopupMenuButton<String>(
                  onSelected: (value) => _handleMenuAction(context, ref, value),
                  itemBuilder: (context) => [
                    const PopupMenuItem(value: 'report', child: Text('Báo cáo bài viết')),
                  ],
                ),
            ],
          ),
          const SizedBox(height: 12),
          if (post.content.isNotEmpty) Text(post.content, style: const TextStyle(fontSize: 15)),
          if (post.imageUrls.isNotEmpty) ...[
            const SizedBox(height: 12),
            ClipRRect(
              borderRadius: BorderRadius.circular(12),
              child: CachedNetworkImage(
                imageUrl: post.imageUrls.first,
                fit: BoxFit.cover,
                width: double.infinity,
                placeholder: (c, u) => Container(height: 200, color: Colors.grey.shade200),
              ),
            ),
          ],
          const SizedBox(height: 12),
          Row(
            children: [
              isLikedAsync.when(
                data: (liked) => IconButton(
                  onPressed: myUid == null ? null : () => _toggleLike(ref, myUid, liked),
                  icon: Icon(liked ? Icons.favorite : Icons.favorite_border,
                      color: liked ? Colors.red : null),
                ),
                loading: () => const IconButton(onPressed: null, icon: Icon(Icons.favorite_border)),
                error: (_, __) => const IconButton(onPressed: null, icon: Icon(Icons.favorite_border)),
              ),
              Text('${post.likeCount}'),
              const SizedBox(width: 16),
              IconButton(
                onPressed: () => context.push('/post/${post.id}/comments'),
                icon: const Icon(Icons.mode_comment_outlined),
              ),
              Text('${post.commentCount}'),
            ],
          ),
        ],
      ),
    );
  }

  void _toggleLike(WidgetRef ref, String myUid, bool currentlyLiked) {
    final repo = ref.read(postRepositoryProvider);
    if (currentlyLiked) {
      repo.unlikePost(postId: post.id, myUid: myUid);
    } else {
      final me = ref.read(currentUserProvider).value;
      repo.likePost(
        postId: post.id,
        postAuthorId: post.authorId,
        myUid: myUid,
        myUsername: me?.username ?? '',
        myAvatarUrl: me?.avatarUrl,
      );
    }
  }

  void _handleMenuAction(BuildContext context, WidgetRef ref, String action) {
    final myUid = ref.read(authStateProvider).value?.uid;
    if (myUid == null) return;

    if (action == 'delete') {
      showDialog(
        context: context,
        builder: (ctx) => AlertDialog(
          title: const Text('Xóa bài viết?'),
          content: const Text('Hành động này không thể hoàn tác.'),
          actions: [
            TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('Hủy')),
            TextButton(
              onPressed: () {
                ref.read(postRepositoryProvider).deletePost(post.id, post.authorId);
                Navigator.pop(ctx);
              },
              child: const Text('Xóa', style: TextStyle(color: Colors.red)),
            ),
          ],
        ),
      );
    } else if (action == 'report') {
      ref.read(userRepositoryProvider).reportContent(
            reporterId: myUid,
            targetType: 'post',
            targetId: post.id,
            reason: 'Người dùng báo cáo từ Feed',
          );
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Đã gửi báo cáo, cảm ơn bạn.')),
      );
    }
  }
}

final _isLikedProvider = StreamProvider.family<bool, ({String postId, String myUid})>((ref, args) {
  return ref.watch(postRepositoryProvider).isLikedByMe(args.postId, args.myUid);
});
