import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../models/chat_model.dart';
import '../services/chat_repository.dart';
import 'auth_provider.dart';

final chatRepositoryProvider = Provider((ref) => ChatRepository());

final conversationsProvider = StreamProvider<List<ConversationModel>>((ref) {
  final authState = ref.watch(authStateProvider);
  return authState.when(
    data: (user) {
      if (user == null) return Stream.value(<ConversationModel>[]);
      return ref.watch(chatRepositoryProvider).watchConversations(user.uid);
    },
    loading: () => Stream.value(<ConversationModel>[]),
    error: (_, __) => Stream.value(<ConversationModel>[]),
  );
});

final messagesProvider = StreamProvider.family((ref, String conversationId) {
  return ref.watch(chatRepositoryProvider).watchMessages(conversationId);
});
