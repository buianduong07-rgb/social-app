import 'package:cloud_firestore/cloud_firestore.dart';
import '../models/user_model.dart';
import '../models/notification_model.dart';

class UserRepository {
  final FirebaseFirestore _db = FirebaseFirestore.instance;

  Stream<UserModel> watchUser(String uid) {
    return _db.collection('users').doc(uid).snapshots().map(
        (doc) => UserModel.fromMap(doc.data() ?? {}, doc.id));
  }

  Future<UserModel?> getUser(String uid) async {
    final doc = await _db.collection('users').doc(uid).get();
    if (!doc.exists) return null;
    return UserModel.fromMap(doc.data()!, doc.id);
  }

  Future<void> updateProfile(String uid, {
    String? displayName,
    String? bio,
    String? avatarUrl,
    String? coverUrl,
  }) async {
    final data = <String, dynamic>{};
    if (displayName != null) data['displayName'] = displayName;
    if (bio != null) data['bio'] = bio;
    if (avatarUrl != null) data['avatarUrl'] = avatarUrl;
    if (coverUrl != null) data['coverUrl'] = coverUrl;
    await _db.collection('users').doc(uid).update(data);
  }

  /// Tìm kiếm user theo username (đơn giản, khớp tiền tố).
  /// Với MVP dùng Firestore là đủ; nếu app lớn hơn nên chuyển sang Algolia/Typesense.
  Future<List<UserModel>> searchUsers(String query) async {
    if (query.trim().isEmpty) return [];
    final lower = query.toLowerCase();
    final snapshot = await _db
        .collection('users')
        .where('username', isGreaterThanOrEqualTo: lower)
        .where('username', isLessThanOrEqualTo: '$lower\uf8ff')
        .limit(20)
        .get();
    return snapshot.docs.map((d) => UserModel.fromMap(d.data(), d.id)).toList();
  }

  /// Follow: dùng batch để cập nhật 3 chỗ cùng lúc (atomic):
  /// - following/{targetUid} dưới user hiện tại
  /// - followers/{myUid} dưới user đích
  /// - counter followerCount/followingCount
  Future<void> followUser({
    required String myUid,
    required String myUsername,
    String? myAvatarUrl,
    required String targetUid,
  }) async {
    final batch = _db.batch();

    batch.set(
      _db.collection('users').doc(myUid).collection('following').doc(targetUid),
      {'createdAt': FieldValue.serverTimestamp()},
    );
    batch.set(
      _db.collection('users').doc(targetUid).collection('followers').doc(myUid),
      {'createdAt': FieldValue.serverTimestamp()},
    );
    batch.update(_db.collection('users').doc(myUid), {
      'followingCount': FieldValue.increment(1),
    });
    batch.update(_db.collection('users').doc(targetUid), {
      'followerCount': FieldValue.increment(1),
    });

    // Tạo thông báo cho người được follow
    final notifRef = _db
        .collection('users')
        .doc(targetUid)
        .collection('notifications')
        .doc();
    batch.set(notifRef, NotificationModel(
      id: notifRef.id,
      type: NotificationType.follow,
      actorId: myUid,
      actorUsername: myUsername,
      actorAvatarUrl: myAvatarUrl,
      createdAt: DateTime.now(),
    ).toMap());

    await batch.commit();
  }

  Future<void> unfollowUser({required String myUid, required String targetUid}) async {
    final batch = _db.batch();
    batch.delete(_db.collection('users').doc(myUid).collection('following').doc(targetUid));
    batch.delete(_db.collection('users').doc(targetUid).collection('followers').doc(myUid));
    batch.update(_db.collection('users').doc(myUid), {
      'followingCount': FieldValue.increment(-1),
    });
    batch.update(_db.collection('users').doc(targetUid), {
      'followerCount': FieldValue.increment(-1),
    });
    await batch.commit();
  }

  Stream<bool> isFollowing({required String myUid, required String targetUid}) {
    return _db
        .collection('users')
        .doc(myUid)
        .collection('following')
        .doc(targetUid)
        .snapshots()
        .map((doc) => doc.exists);
  }

  Stream<List<UserModel>> watchFollowers(String uid) {
    return _db
        .collection('users')
        .doc(uid)
        .collection('followers')
        .orderBy('createdAt', descending: true)
        .snapshots()
        .asyncMap((snap) async {
      final users = <UserModel>[];
      for (final doc in snap.docs) {
        final u = await getUser(doc.id);
        if (u != null) users.add(u);
      }
      return users;
    });
  }

  Stream<List<UserModel>> watchFollowing(String uid) {
    return _db
        .collection('users')
        .doc(uid)
        .collection('following')
        .orderBy('createdAt', descending: true)
        .snapshots()
        .asyncMap((snap) async {
      final users = <UserModel>[];
      for (final doc in snap.docs) {
        final u = await getUser(doc.id);
        if (u != null) users.add(u);
      }
      return users;
    });
  }

  /// Chặn người dùng — bắt buộc phải có theo chính sách UGC của Apple/Google.
  Future<void> blockUser({required String myUid, required String targetUid}) async {
    await _db.collection('users').doc(myUid).update({
      'blockedUserIds': FieldValue.arrayUnion([targetUid]),
    });
  }

  Future<void> unblockUser({required String myUid, required String targetUid}) async {
    await _db.collection('users').doc(myUid).update({
      'blockedUserIds': FieldValue.arrayRemove([targetUid]),
    });
  }

  /// Báo cáo user hoặc bài đăng vi phạm — lưu vào collection reports để admin xử lý.
  Future<void> reportContent({
    required String reporterId,
    required String targetType, // 'user' hoặc 'post'
    required String targetId,
    required String reason,
  }) async {
    await _db.collection('reports').add({
      'reporterId': reporterId,
      'targetType': targetType,
      'targetId': targetId,
      'reason': reason,
      'createdAt': FieldValue.serverTimestamp(),
      'status': 'pending',
    });
  }
}
