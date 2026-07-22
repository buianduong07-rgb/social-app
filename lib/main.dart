import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_crashlytics/firebase_crashlytics.dart';
import 'package:timeago/timeago.dart' as timeago;
import 'app.dart';
import 'firebase_options.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();

  await Firebase.initializeApp(options: DefaultFirebaseOptions.currentPlatform);
  await Supabase.initialize(
     url: 'DÁN_PROJECT_URL_CỦA_BẠN',
     anonKey: 'DÁN_ANON_KEY_CỦA_BẠN',
   );

  
  FlutterError.onError = FirebaseCrashlytics.instance.recordFlutterFatalError;

  
  timeago.setLocaleMessages('vi', timeago.ViMessages());

  runApp(const ProviderScope(child: SocialApp()));
}
