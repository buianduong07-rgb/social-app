import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../providers/auth_provider.dart';
import '../../providers/profile_provider.dart';
import '../../providers/feed_provider.dart';
import '../../common/widgets/user_avatar.dart';
import '../../common/widgets/loading_view.dart';
import '../feed/widgets/post_card.dart';

/// Trang hồ sơ. Nếu [uid] == uid của mình -> hiện nút "Chỉnh sửa hồ sơ" + Cài đặt.
/// Nếu là người khác -> hiện nút Follow/Unfollow, Nhắn tin, Chặn/Báo cáo.
class ProfileScreen extends ConsumerWidget {
  final String uid;
  const ProfileScreen({super.key, required this.uid});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final myUid = ref.watch(authStateProvider).value?.uid;
    final userAsync = ref.watch(userByIdProvider(uid));
    final postsAsync = ref.watch(userPostsProvider(uid));
    final isMe = myUid == uid;

    return Scaffold(
      appBar: AppBar(
        title: userAsync.when(
          data: (u) => Text(u?.displayName ?? ''),
          loading: () => const SizedBox.shrink(),
          error: (_, __) => const SizedBox.shrink(),
        ),
        actions: [
          if (isMe)
            IconButton(icon: const Icon(Icons.settings_outlined), onPressed: () => context.push('/settings'))
          else
            PopupMenuButton<String>(
              onSelected: (value) => _handleMenu(context, ref, value),
              itemBuilder: (context) => [
                const PopupMenuItem(value: 'block', child: Text('Chặn người dùng')),
                const PopupMenuItem(value: 'report', child: Text('Báo cáo người dùng')),
              ],
            ),
        ],
      ),
      body: userAsync.when(
        data: (user) {
          if (user == null) return const ErrorView(message: 'Không tìm thấy người dùng.');
          return RefreshIndicator(
            onRefresh: () async {
              ref.invalidate(userByIdProvider(uid));
              ref.invalidate(userPostsProvider(uid));
            },
            child: ListView(
              children: [
                _ProfileHeader(user: user, isMe: isMe, myUid: myUid),
                const Divider(height: 1),
                postsAsync.when(
                  data: (posts) => posts.isEmpty
                      ? const Padding(
                          padding: EdgeInsets.all(32),
                          child: EmptyView(message: 'Chưa có bài viết nào.'),
                        )
                      : Column(children: posts.map((p) => PostCard(post: p)).toList()),
                  loading: () => const Padding(padding: EdgeInsets.all(32), child: LoadingView()),
                  error: (_, __) => const ErrorView(),
                ),
              ],
            ),
          );
        },
        loading: () => const LoadingView(),
        error: (_, __) => const ErrorView(),
      ),
    );
  }

  void _handleMenu(BuildContext context, WidgetRef ref, String action) {
    final myUid = ref.read(authStateProvider).value?.uid;
    if (myUid == null) return;
    final repo = ref.read(userRepositoryProvider);

    if (action == 'block') {
      repo.blockUser(myUid: myUid, targetUid: uid);
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Đã chặn người dùng này.')),
      );
    } else if (action == 'report') {
      repo.reportContent(reporterId: myUid, targetType: 'user', targetId: uid, reason: 'Báo cáo từ trang cá nhân');
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Đã gửi báo cáo, cảm ơn bạn.')),
      );
    }
  }
}

class _ProfileHeader extends ConsumerWidget {
  final dynamic user; // UserModel
  final bool isMe;
  final String? myUid;
  const _ProfileHeader({required this.user, required this.isMe, required this.myUid});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return Padding(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              UserAvatar(avatarUrl: user.avatarUrl, radius: 40),
              const SizedBox(width: 20),
              Expanded(
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                  children: [
                    _StatColumn(label: 'Bài viết', value: user.postCount),
                    GestureDetector(
                      onTap: () => context.push('/profile/${user.uid}/followers'),
                      child: _StatColumn(label: 'Người theo dõi', value: user.followerCount),
                    ),
                    GestureDetector(
                      onTap: () => context.push('/profile/${user.uid}/following'),
                      child: _StatColumn(label: 'Đang theo dõi', value: user.followingCount),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Text('@${user.username}', style: TextStyle(color: Colors.grey.shade600)),
          if (user.bio != null && user.bio!.isNotEmpty) ...[
            const SizedBox(height: 6),
            Text(user.bio!),
          ],
          const SizedBox(height: 16),
          if (isMe)
            OutlinedButton(
              onPressed: () => context.push('/profile/edit'),
              child: const Text('Chỉnh sửa hồ sơ'),
            )
          else if (myUid != null)
            _FollowAndMessageButtons(myUid: myUid!, targetUid: user.uid, targetUser: user),
        ],
      ),
    );
  }
}

class _StatColumn extends StatelessWidget {
  final String label;
  final int value;
  const _StatColumn({required this.label, required this.value});
  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Text('$value', style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
        Text(label, style: TextStyle(fontSize: 12, color: Colors.grey.shade600)),
      ],
    );
  }
}

class _FollowAndMessageButtons extends ConsumerWidget {
  final String myUid;
  final String targetUid;
  final dynamic targetUser;
  const _FollowAndMessageButtons({required this.myUid, required this.targetUid, required this.targetUser});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final isFollowingAsync = ref.watch(isFollowingProvider((myUid: myUid, targetUid: targetUid)));
    final me = ref.watch(currentUserProvider).value;

    return Row(
      children: [
        Expanded(
          child: isFollowingAsync.when(
            data: (isFollowing) => ElevatedButton(
              onPressed: () {
                final repo = ref.read(userRepositoryProvider);
                if (isFollowing) {
                  repo.unfollowUser(myUid: myUid, targetUid: targetUid);
                } else {
                  repo.followUser(
                    myUid: myUid,
                    myUsername: me?.username ?? '',
                    myAvatarUrl: me?.avatarUrl,
                    targetUid: targetUid,
                  );
                }
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: isFollowing ? Colors.grey.shade200 : null,
                foregroundColor: isFollowing ? Colors.black : null,
              ),
              child: Text(isFollowing ? 'Đang theo dõi' : 'Theo dõi'),
            ),
            loading: () => const SizedBox(height: 40),
            error: (_, __) => const SizedBox.shrink(),
          ),
        ),
        const SizedBox(width: 8),
        Expanded(
          child: OutlinedButton(
            onPressed: () => context.push('/chat/$targetUid'),
            child: const Text('Nhắn tin'),
          ),
        ),
      ],
    );
  }
}
