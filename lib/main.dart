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
     url: 'https://aaetpeavgkxbegwzxkgi.supabase.co/rest/v1/',
     anonKey: 'eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJpc3MiOiJzdXBhYmFzZSIsInJlZiI6ImFhZXRwZWF2Z2t4YmVnd3p4a2dpIiwicm9sZSI6ImFub24iLCJpYXQiOjE3ODQ3MzQ3MzUsImV4cCI6MjEwMDMxMDczNX0.fjErz82yo3DS5yKjER6l5gsaljS1eIvptpU3QyjCMLQ',
   );

  
  FlutterError.onError = FirebaseCrashlytics.instance.recordFlutterFatalError;

  
  timeago.setLocaleMessages('vi', timeago.ViMessages());

  runApp(const ProviderScope(child: SocialApp()));
}
