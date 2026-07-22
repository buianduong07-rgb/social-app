import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../models/user_model.dart';
import 'auth_provider.dart';

/// Xem profile của 1 user bất kỳ theo uid (dùng cho cả trang profile của mình lẫn người khác).
final userByIdProvider = StreamProvider.family<UserModel?, String>((ref, uid) {
  return ref.watch(userRepositoryProvider).watchUser(uid);
});

final isFollowingProvider = StreamProvider.family<bool, ({String myUid, String targetUid})>((ref, args) {
  return ref.watch(userRepositoryProvider).isFollowing(myUid: args.myUid, targetUid: args.targetUid);
});

final followersProvider = StreamProvider.family((ref, String uid) {
  return ref.watch(userRepositoryProvider).watchFollowers(uid);
});

final followingProvider = StreamProvider.family((ref, String uid) {
  return ref.watch(userRepositoryProvider).watchFollowing(uid);
});
