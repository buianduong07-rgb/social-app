import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import '../models/notification_model.dart';

/// Quản lý push notification (FCM) + danh sách thông báo trong app.
class NotificationService {
  final FirebaseFirestore _db = FirebaseFirestore.instance;
  final FirebaseMessaging _messaging = FirebaseMessaging.instance;

  /// Gọi hàm này sau khi đăng nhập thành công để xin quyền + lưu device token.
  Future<void> initPushNotifications(String uid) async {
    await _messaging.requestPermission(
      alert: true,
      badge: true,
      sound: true,
    );

    final token = await _messaging.getToken();
    if (token != null) {
      await _db.collection('users').doc(uid).update({
        'fcmTokens': FieldValue.arrayUnion([token]),
      });
    }

    // Cập nhật lại token mỗi khi Firebase refresh (ví dụ sau khi cài lại app)
    _messaging.onTokenRefresh.listen((newToken) async {
      await _db.collection('users').doc(uid).update({
        'fcmTokens': FieldValue.arrayUnion([newToken]),
      });
    });
  }

  /// Gỡ token khi đăng xuất để không nhận nhầm thông báo trên thiết bị dùng chung.
  Future<void> removeCurrentToken(String uid) async {
    final token = await _messaging.getToken();
    if (token != null) {
      await _db.collection('users').doc(uid).update({
        'fcmTokens': FieldValue.arrayRemove([token]),
      });
    }
  }

  Stream<List<NotificationModel>> watchNotifications(String uid, {int limit = 50}) {
    return _db
        .collection('users')
        .doc(uid)
        .collection('notifications')
        .orderBy('createdAt', descending: true)
        .limit(limit)
        .snapshots()
        .map((snap) =>
            snap.docs.map((d) => NotificationModel.fromMap(d.data(), d.id)).toList());
  }

  Future<void> markAsRead(String uid, String notificationId) async {
    await _db
        .collection('users')
        .doc(uid)
        .collection('notifications')
        .doc(notificationId)
        .update({'isRead': true});
  }

  Future<void> markAllAsRead(String uid) async {
    final unread = await _db
        .collection('users')
        .doc(uid)
        .collection('notifications')
        .where('isRead', isEqualTo: false)
        .get();
    final batch = _db.batch();
    for (final doc in unread.docs) {
      batch.update(doc.reference, {'isRead': true});
    }
    await batch.commit();
  }
}

/*
LƯU Ý QUAN TRỌNG VỀ GỬI PUSH NOTIFICATION THẬT:
Việc TẠO document thông báo (ở trên) chỉ để hiển thị trong app (in-app notification).
Để thực sự BẮN push notification xuống điện thoại người nhận, bạn cần viết 1 Cloud Function
(Node.js) chạy ở server, lắng nghe sự kiện tạo document trong
`users/{uid}/notifications/{id}`, sau đó lấy `fcmTokens` của user đó và gọi
Firebase Admin SDK để gửi qua FCM. Ví dụ Cloud Function (đặt trong functions/index.js):

exports.sendPushOnNotification = functions.firestore
  .document('users/{uid}/notifications/{notifId}')
  .onCreate(async (snap, context) => {
    const notif = snap.data();
    const userDoc = await admin.firestore().collection('users').doc(context.params.uid).get();
    const tokens = userDoc.data().fcmTokens || [];
    if (tokens.length === 0) return;
    await admin.messaging().sendEachForMulticast({
      tokens,
      notification: { title: 'Thông báo mới', body: notif.actorUsername + ' ...' },
    });
  });
*/
