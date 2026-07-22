import 'package:cloud_firestore/cloud_firestore.dart';
import '../models/chat_model.dart';
import '../models/notification_model.dart';

class ChatRepository {
  final FirebaseFirestore _db = FirebaseFirestore.instance;

  /// Sinh id hội thoại cố định cho 2 người, không phụ thuộc thứ tự truyền vào.
  String conversationIdFor(String uidA, String uidB) {
    final ids = [uidA, uidB]..sort();
    return '${ids[0]}_${ids[1]}';
  }

  Future<ConversationModel> getOrCreateConversation({
    required String myUid,
    required String myName,
    String? myAvatarUrl,
    required String targetUid,
    required String targetName,
    String? targetAvatarUrl,
  }) async {
    final id = conversationIdFor(myUid, targetUid);
    final ref = _db.collection('conversations').doc(id);
    final doc = await ref.get();

    if (doc.exists) {
      return ConversationModel.fromMap(doc.data()!, doc.id);
    }

    final conversation = ConversationModel(
      id: id,
      participantIds: [myUid, targetUid],
      participantNames: {myUid: myName, targetUid: targetName},
      participantAvatars: {myUid: myAvatarUrl, targetUid: targetAvatarUrl},
      unreadCount: {myUid: 0, targetUid: 0},
    );
    await ref.set(conversation.toMap());
    return conversation;
  }

  Stream<List<ConversationModel>> watchConversations(String myUid) {
    return _db
        .collection('conversations')
        .where('participantIds', arrayContains: myUid)
        .orderBy('lastMessageAt', descending: true)
        .snapshots()
        .map((snap) =>
            snap.docs.map((d) => ConversationModel.fromMap(d.data(), d.id)).toList());
  }

  Stream<List<MessageModel>> watchMessages(String conversationId, {int limit = 50}) {
    return _db
        .collection('conversations')
        .doc(conversationId)
        .collection('messages')
        .orderBy('createdAt', descending: true)
        .limit(limit)
        .snapshots()
        .map((snap) => snap.docs.map((d) => MessageModel.fromMap(d.data(), d.id)).toList());
  }

  Future<void> sendMessage({
    required String conversationId,
    required String senderId,
    required String receiverId,
    required String senderName,
    String? senderAvatarUrl,
    String? text,
    String? imageUrl,
  }) async {
    final messageRef = _db
        .collection('conversations')
        .doc(conversationId)
        .collection('messages')
        .doc();

    final message = MessageModel(
      id: messageRef.id,
      senderId: senderId,
      text: text,
      imageUrl: imageUrl,
      createdAt: DateTime.now(),
    );

    final batch = _db.batch();
    batch.set(messageRef, message.toMap());
    batch.update(_db.collection('conversations').doc(conversationId), {
      'lastMessage': text ?? '[Hình ảnh]',
      'lastMessageAt': FieldValue.serverTimestamp(),
      'lastMessageSenderId': senderId,
      'unreadCount.$receiverId': FieldValue.increment(1),
    });

    final notifRef = _db.collection('users').doc(receiverId).collection('notifications').doc();
    batch.set(notifRef, NotificationModel(
      id: notifRef.id,
      type: NotificationType.message,
      actorId: senderId,
      actorUsername: senderName,
      actorAvatarUrl: senderAvatarUrl,
      createdAt: DateTime.now(),
    ).toMap());

    await batch.commit();
  }

  Future<void> markConversationAsRead(String conversationId, String myUid) async {
    await _db.collection('conversations').doc(conversationId).update({
      'unreadCount.$myUid': 0,
    });
  }
}
