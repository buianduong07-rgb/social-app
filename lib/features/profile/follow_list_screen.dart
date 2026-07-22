import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../providers/profile_provider.dart';
import '../../common/widgets/user_avatar.dart';
import '../../common/widgets/loading_view.dart';

/// Dùng chung cho cả 2 màn "Người theo dõi" và "Đang theo dõi".
class FollowListScreen extends ConsumerWidget {
  final String uid;
  final bool showFollowers; // true = followers, false = following

  const FollowListScreen({super.key, required this.uid, required this.showFollowers});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final listAsync = showFollowers
        ? ref.watch(followersProvider(uid))
        : ref.watch(followingProvider(uid));

    return Scaffold(
      appBar: AppBar(title: Text(showFollowers ? 'Người theo dõi' : 'Đang theo dõi')),
      body: listAsync.when(
        data: (users) {
          if (users.isEmpty) {
            return EmptyView(message: showFollowers ? 'Chưa có người theo dõi.' : 'Chưa theo dõi ai.');
          }
          return ListView.builder(
            itemCount: users.length,
            itemBuilder: (context, i) {
              final u = users[i];
              return ListTile(
                leading: UserAvatar(avatarUrl: u.avatarUrl, radius: 22),
                title: Text(u.displayName),
                subtitle: Text('@${u.username}'),
                onTap: () => context.push('/profile/${u.uid}'),
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
