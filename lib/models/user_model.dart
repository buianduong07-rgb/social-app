import 'package:cloud_firestore/cloud_firestore.dart';

/// Model đại diện cho 1 người dùng trong hệ thống.
/// Lưu ở collection: users/{uid}
class UserModel {
  final String uid;
  final String username;
  final String displayName;
  final String? bio;
  final String? avatarUrl;
  final String? coverUrl;
  final int followerCount;
  final int followingCount;
  final int postCount;
  final DateTime createdAt;
  final List<String> blockedUserIds;

  UserModel({
    required this.uid,
    required this.username,
    required this.displayName,
    this.bio,
    this.avatarUrl,
    this.coverUrl,
    this.followerCount = 0,
    this.followingCount = 0,
    this.postCount = 0,
    required this.createdAt,
    this.blockedUserIds = const [],
  });

  factory UserModel.fromMap(Map<String, dynamic> map, String uid) {
    return UserModel(
      uid: uid,
      username: map['username'] ?? '',
      displayName: map['displayName'] ?? '',
      bio: map['bio'],
      avatarUrl: map['avatarUrl'],
      coverUrl: map['coverUrl'],
      followerCount: map['followerCount'] ?? 0,
      followingCount: map['followingCount'] ?? 0,
      postCount: map['postCount'] ?? 0,
      createdAt: (map['createdAt'] as Timestamp?)?.toDate() ?? DateTime.now(),
      blockedUserIds: List<String>.from(map['blockedUserIds'] ?? []),
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'username': username,
      'displayName': displayName,
      'bio': bio,
      'avatarUrl': avatarUrl,
      'coverUrl': coverUrl,
      'followerCount': followerCount,
      'followingCount': followingCount,
      'postCount': postCount,
      'createdAt': Timestamp.fromDate(createdAt),
      'blockedUserIds': blockedUserIds,
    };
  }

  UserModel copyWith({
    String? displayName,
    String? bio,
    String? avatarUrl,
    String? coverUrl,
    int? followerCount,
    int? followingCount,
    int? postCount,
  }) {
    return UserModel(
      uid: uid,
      username: username,
      displayName: displayName ?? this.displayName,
      bio: bio ?? this.bio,
      avatarUrl: avatarUrl ?? this.avatarUrl,
      coverUrl: coverUrl ?? this.coverUrl,
      followerCount: followerCount ?? this.followerCount,
      followingCount: followingCount ?? this.followingCount,
      postCount: postCount ?? this.postCount,
      createdAt: createdAt,
      blockedUserIds: blockedUserIds,
    );
  }
}
