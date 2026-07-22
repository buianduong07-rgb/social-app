import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_crashlytics/firebase_crashlytics.dart';
import 'package:timeago/timeago.dart' as timeago;
import 'app.dart';
import 'firebase_options.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();

  await Firebase.initializeApp(options: DefaultFirebaseOptions.currentPlatform);

  // Bắt lỗi runtime tự động gửi lên Firebase Crashlytics (giúp theo dõi crash sau khi lên store).
  FlutterError.onError = FirebaseCrashlytics.instance.recordFlutterFatalError;

  // Đăng ký locale tiếng Việt cho timeago (hiển thị "2 giờ trước" thay vì "2 hours ago").
  timeago.setLocaleMessages('vi', timeago.ViMessages());

  runApp(const ProviderScope(child: SocialApp()));
}
