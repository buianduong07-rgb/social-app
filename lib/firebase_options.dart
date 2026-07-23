// File này PHẢI được tạo tự động bằng công cụ FlutterFire CLI, KHÔNG tự sửa tay.
//
// Cách tạo file thật (chạy trong thư mục gốc dự án, sau khi đã cài Firebase CLI + FlutterFire CLI):
//   1. npm install -g firebase-tools
//   2. dart pub global activate flutterfire_cli
//   3. firebase login
//   4. flutterfire configure
//      -> chọn Firebase project của bạn (hoặc tạo mới)
//      -> chọn nền tảng: iOS, Android
//
// Lệnh trên sẽ TỰ ĐỘNG ghi đè file này với thông tin thật (apiKey, appId, projectId...)
// và tự thêm google-services.json (Android) + GoogleService-Info.plist (iOS) vào đúng nơi.
//
// Placeholder bên dưới chỉ để code có thể biên dịch trước khi bạn chạy flutterfire configure.
// Nếu chạy app ngay bây giờ mà chưa thay file này, Firebase.initializeApp() sẽ báo lỗi.

import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/foundation.dart' show defaultTargetPlatform, kIsWeb, TargetPlatform;

class DefaultFirebaseOptions {
  static FirebaseOptions get currentPlatform {
    if (kIsWeb) {
      throw UnsupportedError('Web chưa được cấu hình. Chạy `flutterfire configure` để thêm.');
    }
    switch (defaultTargetPlatform) {
      case TargetPlatform.android:
        return android;
      case TargetPlatform.iOS:
        return ios;
      default:
        throw UnsupportedError('Nền tảng chưa được hỗ trợ trong file này.');
    }
  }

  static const FirebaseOptions android = FirebaseOptions(
    apiKey: 'AIzaSyBZybkCFvx6fCTeWPLu1c_aW573FLcj8jE',
    appId: '1:998306233395:android:3c5864426c5920c652f746',
    messagingSenderId: '998306233395',
    projectId: 'social-app-7153c',
    storageBucket: 'social-app-7153c.firebasestorage.app',
  );

  static const FirebaseOptions ios = FirebaseOptions(
    apiKey: 'AIzaSyBZybkCFvx6fCTeWPLu1c_aW573FLcj8jE',
    appId: '1:998306233395:android:3c5864426c5920c652f746',
    messagingSenderId: '998306233395',
    projectId: 'social-app-7153c',
    storageBucket: 'social-app-7153c.firebasestorage.app',
    iosBundleId: 'com.yourcompany.socialapp',
  );
}
