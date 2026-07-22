import 'package:cloud_firestore/cloud_firestore.dart';

/// Model 1 cuộc hội thoại (chat 1-1).
/// Lưu ở collection: conversations/{conversationId}
/// conversationId được sinh bằng cách ghép 2 uid theo thứ tự alphabet, ví dụ: "uidA_uidB"
class ConversationModel {
  final String id;
  final List<String> participantIds;
  final Map<String, String> participantNames; // uid -> displayName
  final Map<String, String?> participantAvatars; // uid -> avatarUrl
  final String? lastMessage;
  final DateTime? lastMessageAt;
  final String? lastMessageSenderId;
  final Map<String, int> unreadCount; // uid -> số tin chưa đọc

  ConversationModel({
    required this.id,
    required this.participantIds,
    required this.participantNames,
    required this.participantAvatars,
    this.lastMessage,
    this.lastMessageAt,
    this.lastMessageSenderId,
    this.unreadCount = const {},
  });

  factory ConversationModel.fromMap(Map<String, dynamic> map, String id) {
    return ConversationModel(
      id: id,
      participantIds: List<String>.from(map['participantIds'] ?? []),
      participantNames: Map<String, String>.from(map['participantNames'] ?? {}),
      participantAvatars: Map<String, String?>.from(map['participantAvatars'] ?? {}),
      lastMessage: map['lastMessage'],
      lastMessageAt: (map['lastMessageAt'] as Timestamp?)?.toDate(),
      lastMessageSenderId: map['lastMessageSenderId'],
      unreadCount: Map<String, int>.from(map['unreadCount'] ?? {}),
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'participantIds': participantIds,
      'participantNames': participantNames,
      'participantAvatars': participantAvatars,
      'lastMessage': lastMessage,
      'lastMessageAt': lastMessageAt != null ? Timestamp.fromDate(lastMessageAt!) : null,
      'lastMessageSenderId': lastMessageSenderId,
      'unreadCount': unreadCount,
    };
  }

  String otherParticipantId(String myUid) =>
      participantIds.firstWhere((id) => id != myUid, orElse: () => '');
}

/// Model 1 tin nhắn. Lưu ở subcollection: conversations/{conversationId}/messages/{messageId}
class MessageModel {
  final String id;
  final String senderId;
  final String? text;
  final String? imageUrl;
  final DateTime createdAt;
  final bool seen;

  MessageModel({
    required this.id,
    required this.senderId,
    this.text,
    this.imageUrl,
    required this.createdAt,
    this.seen = false,
  });

  factory MessageModel.fromMap(Map<String, dynamic> map, String id) {
    return MessageModel(
      id: id,
      senderId: map['senderId'] ?? '',
      text: map['text'],
      imageUrl: map['imageUrl'],
      createdAt: (map['createdAt'] as Timestamp?)?.toDate() ?? DateTime.now(),
      seen: map['seen'] ?? false,
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'senderId': senderId,
      'text': text,
      'imageUrl': imageUrl,
      'createdAt': Timestamp.fromDate(createdAt),
      'seen': seen,
    };
  }
}
