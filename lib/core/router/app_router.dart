import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../providers/auth_provider.dart';
import '../../features/onboarding/onboarding_screen.dart';
import '../../features/auth/login_screen.dart';
import '../../features/auth/register_screen.dart';
import '../../features/home/main_navigation.dart';
import '../../features/feed/create_post_screen.dart';
import '../../features/feed/post_comments_screen.dart';
import '../../features/profile/profile_screen.dart';
import '../../features/profile/edit_profile_screen.dart';
import '../../features/profile/follow_list_screen.dart';
import '../../features/chat/chat_detail_screen.dart';
import '../../features/notifications/notifications_screen.dart';
import '../../features/settings/settings_screen.dart';

/// Provider tạo GoRouter, tự động refresh khi trạng thái đăng nhập thay đổi
/// để redirect vào/ra khỏi khu vực cần đăng nhập.
final appRouterProvider = Provider<GoRouter>((ref) {
  final authState = ref.watch(authStateProvider);

  return GoRouter(
    initialLocation: '/onboarding',
    redirect: (context, state) {
      final isLoggedIn = authState.value != null;
      final loc = state.matchedLocation;
      final isAuthRoute = loc == '/login' || loc == '/register' || loc == '/onboarding';

      // Chưa đăng nhập mà cố vào khu vực cần đăng nhập -> đẩy về Login.
      if (!isLoggedIn && !isAuthRoute) return '/login';
      // Đã đăng nhập mà đang ở màn Login/Register/Onboarding -> đẩy vào Home.
      if (isLoggedIn && isAuthRoute) return '/home';
      return null;
    },
    refreshListenable: GoRouterRefreshStream(ref),
    routes: [
      GoRoute(path: '/onboarding', builder: (context, state) => const OnboardingScreen()),
      GoRoute(path: '/login', builder: (context, state) => const LoginScreen()),
      GoRoute(path: '/register', builder: (context, state) => const RegisterScreen()),
      GoRoute(path: '/home', builder: (context, state) => const MainNavigation()),
      GoRoute(path: '/create-post', builder: (context, state) => const CreatePostScreen()),
      GoRoute(
        path: '/post/:postId/comments',
        builder: (context, state) => PostCommentsScreen(postId: state.pathParameters['postId']!),
      ),
      GoRoute(
        path: '/profile/edit',
        builder: (context, state) => const EditProfileScreen(),
      ),
      GoRoute(
        path: '/profile/:uid',
        builder: (context, state) => ProfileScreen(uid: state.pathParameters['uid']!),
      ),
      GoRoute(
        path: '/profile/:uid/followers',
        builder: (context, state) =>
            FollowListScreen(uid: state.pathParameters['uid']!, showFollowers: true),
      ),
      GoRoute(
        path: '/profile/:uid/following',
        builder: (context, state) =>
            FollowListScreen(uid: state.pathParameters['uid']!, showFollowers: false),
      ),
      GoRoute(
        path: '/chat/:otherUid',
        builder: (context, state) => ChatDetailScreen(otherUid: state.pathParameters['otherUid']!),
      ),
      GoRoute(path: '/chats', builder: (context, state) => const MainNavigation()),
      GoRoute(path: '/notifications', builder: (context, state) => const NotificationsScreen()),
      GoRoute(path: '/settings', builder: (context, state) => const SettingsScreen()),
    ],
  );
});

/// Cầu nối để GoRouter lắng nghe thay đổi từ Riverpod StreamProvider (authStateProvider).
class GoRouterRefreshStream extends ChangeNotifier {
  GoRouterRefreshStream(Ref ref) {
    ref.listen(authStateProvider, (_, __) => notifyListeners());
  }
}
