import 'package:cloud_firestore/cloud_firestore.dart';

enum NotificationType { follow, like, comment, message }

/// Model thông báo. Lưu ở subcollection: users/{uid}/notifications/{id}
class NotificationModel {
  final String id;
  final NotificationType type;
  final String actorId; // người gây ra hành động (người follow/like/comment)
  final String actorUsername;
  final String? actorAvatarUrl;
  final String? postId; // nếu liên quan tới 1 bài đăng
  final DateTime createdAt;
  final bool isRead;

  NotificationModel({
    required this.id,
    required this.type,
    required this.actorId,
    required this.actorUsername,
    this.actorAvatarUrl,
    this.postId,
    required this.createdAt,
    this.isRead = false,
  });

  factory NotificationModel.fromMap(Map<String, dynamic> map, String id) {
    return NotificationModel(
      id: id,
      type: NotificationType.values.firstWhere(
        (e) => e.name == map['type'],
        orElse: () => NotificationType.follow,
      ),
      actorId: map['actorId'] ?? '',
      actorUsername: map['actorUsername'] ?? '',
      actorAvatarUrl: map['actorAvatarUrl'],
      postId: map['postId'],
      createdAt: (map['createdAt'] as Timestamp?)?.toDate() ?? DateTime.now(),
      isRead: map['isRead'] ?? false,
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'type': type.name,
      'actorId': actorId,
      'actorUsername': actorUsername,
      'actorAvatarUrl': actorAvatarUrl,
      'postId': postId,
      'createdAt': Timestamp.fromDate(createdAt),
      'isRead': isRead,
    };
  }

  String get message {
    switch (type) {
      case NotificationType.follow:
        return '$actorUsername đã bắt đầu theo dõi bạn';
      case NotificationType.like:
        return '$actorUsername đã thích bài viết của bạn';
      case NotificationType.comment:
        return '$actorUsername đã bình luận về bài viết của bạn';
      case NotificationType.message:
        return '$actorUsername đã gửi tin nhắn cho bạn';
    }
  }
}
