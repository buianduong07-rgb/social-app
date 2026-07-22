import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../services/auth_service.dart';
import '../services/user_repository.dart';
import '../services/notification_service.dart';
import '../models/user_model.dart';

final authServiceProvider = Provider((ref) => AuthService());
final userRepositoryProvider = Provider((ref) => UserRepository());
final notificationServiceProvider = Provider((ref) => NotificationService());

/// Stream trạng thái đăng nhập (null = chưa đăng nhập).
final authStateProvider = StreamProvider<User?>((ref) {
  return ref.watch(authServiceProvider).authStateChanges;
});

/// Thông tin đầy đủ của user hiện tại (từ Firestore), tự cập nhật real-time.
final currentUserProvider = StreamProvider<UserModel?>((ref) {
  final authState = ref.watch(authStateProvider);
  return authState.when(
    data: (user) {
      if (user == null) return Stream.value(null);
      return ref.watch(userRepositoryProvider).watchUser(user.uid);
    },
    loading: () => Stream.value(null),
    error: (_, __) => Stream.value(null),
  );
});
