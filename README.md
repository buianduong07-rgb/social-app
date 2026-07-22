# Social App — Flutter + Firebase (MVP)

Đây là codebase khởi tạo (scaffold) cho ứng dụng mạng xã hội, đúng theo kiến trúc trong
kế hoạch 12 tuần đã lập. Code **chạy được thật** (không phải mock), nhưng bạn cần hoàn tất
vài bước cấu hình bên dưới trước khi build lần đầu.

## 1. Các module đã có

- ✅ Đăng ký / Đăng nhập (Email + Google), quên mật khẩu, xóa tài khoản
- ✅ Onboarding 3 màn hình
- ✅ Profile: xem, chỉnh sửa, avatar, follower/following
- ✅ Feed: đăng bài (text + ảnh), like, comment, xóa bài
- ✅ Follow / Unfollow
- ✅ Chat 1-1 real-time (text + ảnh)
- ✅ Thông báo trong app (follow/like/comment/message)
- ✅ Tìm kiếm người dùng
- ✅ Cài đặt, chặn/báo cáo người dùng và bài viết
- ✅ Firestore Security Rules cơ bản
- ✅ Điều hướng tự động theo trạng thái đăng nhập (go_router)

## 2. Việc BẠN cần tự làm (không thể làm thay vì cần tài khoản/thiết bị của bạn)

### Bước 1 — Tạo project Flutter thật
```bash
flutter create social_app
```
Sau đó **copy toàn bộ thư mục `lib/` và file `pubspec.yaml`** trong gói này, ghi đè lên project vừa tạo.

### Bước 2 — Cài dependencies
```bash
cd social_app
flutter pub get
```

### Bước 3 — Kết nối Firebase (bắt buộc, app sẽ crash nếu bỏ qua)
```bash
npm install -g firebase-tools
dart pub global activate flutterfire_cli
firebase login
flutterfire configure
```
Lệnh cuối sẽ hỏi bạn chọn Firebase project (hoặc tạo mới) và chọn nền tảng iOS/Android.
Nó sẽ **tự động ghi đè** `lib/firebase_options.dart` (hiện đang là placeholder) bằng thông tin thật.

### Bước 4 — Bật các dịch vụ Firebase cần dùng
Trong [Firebase Console](https://console.firebase.google.com), vào project của bạn và bật:
- **Authentication** → bật Email/Password và Google Sign-In
- **Firestore Database** → tạo database (chọn chế độ Production)
- **Storage** → bật Cloud Storage
- **Cloud Messaging** → không cần bật thủ công, tự có sẵn khi bật Auth+Firestore

### Bước 5 — Deploy Firestore Security Rules
```bash
firebase deploy --only firestore:rules
```
(File `firestore.rules` đã có sẵn trong gói này, đặt ở thư mục gốc project)

### Bước 6 — Chạy thử
```bash
flutter run
```

## 3. Việc CẦN LÀM TIẾP để hoàn thiện (đã note bằng comment `TODO` trong code)

1. **Push notification thật**: code hiện tại mới lưu token & tạo document thông báo trong app.
   Để thực sự bắn push notification xuống điện thoại, bạn cần viết 1 Cloud Function (xem
   hướng dẫn chi tiết trong comment ở cuối file `lib/services/notification_service.dart`).
2. **Xóa dữ liệu liên quan khi xóa tài khoản/bài viết**: hiện chỉ xóa document chính.
   Nên viết Cloud Function dọn dẹp comments, likes, ảnh trong Storage để tránh rác dữ liệu.
3. **Kiểm duyệt nội dung**: MVP mới có chặn/báo cáo thủ công. Cân nhắc thêm Cloud Function
   quét nội dung vi phạm (ví dụ dùng Google Cloud Vision SafeSearch cho ảnh).
4. **Link Privacy Policy & Terms of Service**: 2 chỗ `TODO` trong `settings_screen.dart` — bắt
   buộc phải có URL thật trước khi nộp app lên App Store/Google Play.
5. **App icon, splash screen**: chưa có trong gói này — dùng package `flutter_launcher_icons`
   và `flutter_native_splash` để tạo nhanh.
6. **Xử lý lỗi "requires-recent-login"**: Firebase Auth có thể từ chối xóa tài khoản nếu người
   dùng đăng nhập đã lâu — cần bắt lỗi này và yêu cầu đăng nhập lại trước khi xóa.
7. **Unit test / widget test**: chưa có, nên bổ sung dần cho các hàm quan trọng (AuthService,
   PostRepository) theo đúng kế hoạch Phase 5 (Tuần 10).

## 4. Cấu trúc thư mục

```
lib/
├── main.dart                  # Entry point, khởi tạo Firebase
├── app.dart                   # MaterialApp.router + theme
├── firebase_options.dart      # Placeholder — sẽ bị flutterfire configure ghi đè
├── core/
│   ├── theme/app_theme.dart   # Bảng màu, style dùng chung
│   └── router/app_router.dart # Toàn bộ định tuyến (go_router) + redirect theo login state
├── models/                    # UserModel, PostModel, CommentModel, ConversationModel, MessageModel, NotificationModel
├── services/                  # AuthService, UserRepository, PostRepository, ChatRepository,
│                               # NotificationService, StorageService — toàn bộ logic Firebase
├── providers/                 # Riverpod providers nối service <-> UI
├── common/widgets/            # UserAvatar, LoadingView, ErrorView, EmptyView
└── features/                  # Từng màn hình, chia theo module (auth, feed, profile, chat, ...)
```

## 5. Gợi ý bước tiếp theo

Bám theo đúng "Tuần 5-9" trong kế hoạch: chạy thử từng module một (Auth trước, rồi Profile,
rồi Feed...), test kỹ trên thiết bị thật trước khi ghép module tiếp theo, thay vì code hết
rồi mới test — sẽ dễ định vị lỗi hơn rất nhiều.
