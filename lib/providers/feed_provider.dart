import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../models/post_model.dart';
import '../services/post_repository.dart';
import 'auth_provider.dart';

final postRepositoryProvider = Provider((ref) => PostRepository());

/// Danh sách uid mà user hiện tại đang follow (để build feed).
final followingIdsProvider = StreamProvider<List<String>>((ref) {
  final authState = ref.watch(authStateProvider);
  return authState.when(
    data: (user) {
      if (user == null) return Stream.value(<String>[]);
      return FirebaseFirestore.instance
          .collection('users')
          .doc(user.uid)
          .collection('following')
          .snapshots()
          .map((snap) => snap.docs.map((d) => d.id).toList());
    },
    loading: () => Stream.value(<String>[]),
    error: (_, __) => Stream.value(<String>[]),
  );
});

/// Feed = bài viết của những người đang follow + bài viết của chính mình.
final feedProvider = StreamProvider<List<PostModel>>((ref) {
  final followingAsync = ref.watch(followingIdsProvider);
  final authState = ref.watch(authStateProvider);

  final myUid = authState.value?.uid;
  final following = followingAsync.value ?? [];

  if (myUid == null) return Stream.value(<PostModel>[]);

  final idsToWatch = [...following, myUid];
  return ref.watch(postRepositoryProvider).watchFeed(idsToWatch);
});

final userPostsProvider = StreamProvider.family<List<PostModel>, String>((ref, uid) {
  return ref.watch(postRepositoryProvider).watchUserPosts(uid);
});
