import 'package:cloud_firestore/cloud_firestore.dart';

/// Model bài đăng. Lưu ở collection: posts/{postId}
class PostModel {
  final String id;
  final String authorId;
  final String authorUsername;
  final String? authorAvatarUrl;
  final String content;
  final List<String> imageUrls;
  final int likeCount;
  final int commentCount;
  final DateTime createdAt;
  final bool isEdited;

  PostModel({
    required this.id,
    required this.authorId,
    required this.authorUsername,
    this.authorAvatarUrl,
    required this.content,
    this.imageUrls = const [],
    this.likeCount = 0,
    this.commentCount = 0,
    required this.createdAt,
    this.isEdited = false,
  });

  factory PostModel.fromMap(Map<String, dynamic> map, String id) {
    return PostModel(
      id: id,
      authorId: map['authorId'] ?? '',
      authorUsername: map['authorUsername'] ?? '',
      authorAvatarUrl: map['authorAvatarUrl'],
      content: map['content'] ?? '',
      imageUrls: List<String>.from(map['imageUrls'] ?? []),
      likeCount: map['likeCount'] ?? 0,
      commentCount: map['commentCount'] ?? 0,
      createdAt: (map['createdAt'] as Timestamp?)?.toDate() ?? DateTime.now(),
      isEdited: map['isEdited'] ?? false,
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'authorId': authorId,
      'authorUsername': authorUsername,
      'authorAvatarUrl': authorAvatarUrl,
      'content': content,
      'imageUrls': imageUrls,
      'likeCount': likeCount,
      'commentCount': commentCount,
      'createdAt': Timestamp.fromDate(createdAt),
      'isEdited': isEdited,
    };
  }
}

/// Model bình luận. Lưu ở subcollection: posts/{postId}/comments/{commentId}
class CommentModel {
  final String id;
  final String postId;
  final String authorId;
  final String authorUsername;
  final String? authorAvatarUrl;
  final String content;
  final DateTime createdAt;

  CommentModel({
    required this.id,
    required this.postId,
    required this.authorId,
    required this.authorUsername,
    this.authorAvatarUrl,
    required this.content,
    required this.createdAt,
  });

  factory CommentModel.fromMap(Map<String, dynamic> map, String id, String postId) {
    return CommentModel(
      id: id,
      postId: postId,
      authorId: map['authorId'] ?? '',
      authorUsername: map['authorUsername'] ?? '',
      authorAvatarUrl: map['authorAvatarUrl'],
      content: map['content'] ?? '',
      createdAt: (map['createdAt'] as Timestamp?)?.toDate() ?? DateTime.now(),
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'authorId': authorId,
      'authorUsername': authorUsername,
      'authorAvatarUrl': authorAvatarUrl,
      'content': content,
      'createdAt': Timestamp.fromDate(createdAt),
    };
  }
}
