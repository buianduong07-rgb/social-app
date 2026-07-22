import 'package:cloud_firestore/cloud_firestore.dart';
import '../models/post_model.dart';
import '../models/notification_model.dart';

class PostRepository {
  final FirebaseFirestore _db = FirebaseFirestore.instance;

  /// Tạo bài đăng mới, đồng thời tăng postCount của tác giả.
  Future<String> createPost({
    required String authorId,
    required String authorUsername,
    String? authorAvatarUrl,
    required String content,
    List<String> imageUrls = const [],
  }) async {
    final docRef = _db.collection('posts').doc();
    final post = PostModel(
      id: docRef.id,
      authorId: authorId,
      authorUsername: authorUsername,
      authorAvatarUrl: authorAvatarUrl,
      content: content,
      imageUrls: imageUrls,
      createdAt: DateTime.now(),
    );

    final batch = _db.batch();
    batch.set(docRef, post.toMap());
    batch.update(_db.collection('users').doc(authorId), {
      'postCount': FieldValue.increment(1),
    });
    await batch.commit();
    return docRef.id;
  }

  Future<void> updatePost(String postId, {String? content, List<String>? imageUrls, bool markEdited = true}) async {
    final data = <String, dynamic>{};
    if (markEdited) data['isEdited'] = true;
    if (content != null) data['content'] = content;
    if (imageUrls != null) data['imageUrls'] = imageUrls;
    await _db.collection('posts').doc(postId).update(data);
  }

  Future<void> deletePost(String postId, String authorId) async {
    final batch = _db.batch();
    batch.delete(_db.collection('posts').doc(postId));
    batch.update(_db.collection('users').doc(authorId), {
      'postCount': FieldValue.increment(-1),
    });
    await batch.commit();
    // Lưu ý: trong thực tế nên dùng Cloud Function để dọn luôn comments + ảnh trong Storage.
  }

  /// Feed: lấy bài đăng của những người mình đang follow + bài của chính mình.
  /// Với MVP: query trực tiếp theo danh sách followingIds (giới hạn "whereIn" 30 phần tử/lần
  /// của Firestore). App lớn hơn nên dùng mô hình fan-out-on-write (ghi feed riêng cho mỗi user).
  Stream<List<PostModel>> watchFeed(List<String> followingIds, {int limit = 20}) {
    final ids = followingIds.isEmpty ? ['__none__'] : followingIds.take(30).toList();
    return _db
        .collection('posts')
        .where('authorId', whereIn: ids)
        .orderBy('createdAt', descending: true)
        .limit(limit)
        .snapshots()
        .map((snap) => snap.docs.map((d) => PostModel.fromMap(d.data(), d.id)).toList());
  }

  Stream<List<PostModel>> watchUserPosts(String uid, {int limit = 30}) {
    return _db
        .collection('posts')
        .where('authorId', isEqualTo: uid)
        .orderBy('createdAt', descending: true)
        .limit(limit)
        .snapshots()
        .map((snap) => snap.docs.map((d) => PostModel.fromMap(d.data(), d.id)).toList());
  }

  Stream<bool> isLikedByMe(String postId, String myUid) {
    return _db
        .collection('posts')
        .doc(postId)
        .collection('likes')
        .doc(myUid)
        .snapshots()
        .map((doc) => doc.exists);
  }

  Future<void> likePost({
    required String postId,
    required String postAuthorId,
    required String myUid,
    required String myUsername,
    String? myAvatarUrl,
  }) async {
    final batch = _db.batch();
    batch.set(
      _db.collection('posts').doc(postId).collection('likes').doc(myUid),
      {'createdAt': FieldValue.serverTimestamp()},
    );
    batch.update(_db.collection('posts').doc(postId), {
      'likeCount': FieldValue.increment(1),
    });

    if (postAuthorId != myUid) {
      final notifRef = _db
          .collection('users')
          .doc(postAuthorId)
          .collection('notifications')
          .doc();
      batch.set(notifRef, NotificationModel(
        id: notifRef.id,
        type: NotificationType.like,
        actorId: myUid,
        actorUsername: myUsername,
        actorAvatarUrl: myAvatarUrl,
        postId: postId,
        createdAt: DateTime.now(),
      ).toMap());
    }

    await batch.commit();
  }

  Future<void> unlikePost({required String postId, required String myUid}) async {
    final batch = _db.batch();
    batch.delete(_db.collection('posts').doc(postId).collection('likes').doc(myUid));
    batch.update(_db.collection('posts').doc(postId), {
      'likeCount': FieldValue.increment(-1),
    });
    await batch.commit();
  }

  Future<void> addComment({
    required String postId,
    required String postAuthorId,
    required String authorId,
    required String authorUsername,
    String? authorAvatarUrl,
    required String content,
  }) async {
    final commentRef = _db.collection('posts').doc(postId).collection('comments').doc();
    final comment = CommentModel(
      id: commentRef.id,
      postId: postId,
      authorId: authorId,
      authorUsername: authorUsername,
      authorAvatarUrl: authorAvatarUrl,
      content: content,
      createdAt: DateTime.now(),
    );

    final batch = _db.batch();
    batch.set(commentRef, comment.toMap());
    batch.update(_db.collection('posts').doc(postId), {
      'commentCount': FieldValue.increment(1),
    });

    if (postAuthorId != authorId) {
      final notifRef = _db
          .collection('users')
          .doc(postAuthorId)
          .collection('notifications')
          .doc();
      batch.set(notifRef, NotificationModel(
        id: notifRef.id,
        type: NotificationType.comment,
        actorId: authorId,
        actorUsername: authorUsername,
        actorAvatarUrl: authorAvatarUrl,
        postId: postId,
        createdAt: DateTime.now(),
      ).toMap());
    }

    await batch.commit();
  }

  Stream<List<CommentModel>> watchComments(String postId) {
    return _db
        .collection('posts')
        .doc(postId)
        .collection('comments')
        .orderBy('createdAt', descending: false)
        .snapshots()
        .map((snap) =>
            snap.docs.map((d) => CommentModel.fromMap(d.data(), d.id, postId)).toList());
  }

  Future<void> deleteComment(String postId, String commentId) async {
    final batch = _db.batch();
    batch.delete(_db.collection('posts').doc(postId).collection('comments').doc(commentId));
    batch.update(_db.collection('posts').doc(postId), {
      'commentCount': FieldValue.increment(-1),
    });
    await batch.commit();
  }
}
