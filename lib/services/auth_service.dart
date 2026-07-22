import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:google_sign_in/google_sign_in.dart';
import '../models/user_model.dart';

/// Xử lý toàn bộ logic Đăng ký / Đăng nhập / Đăng xuất / Xóa tài khoản.
class AuthService {
  final FirebaseAuth _auth = FirebaseAuth.instance;
  final FirebaseFirestore _db = FirebaseFirestore.instance;
  final GoogleSignIn _googleSignIn = GoogleSignIn();

  User? get currentUser => _auth.currentUser;
  Stream<User?> get authStateChanges => _auth.authStateChanges();

  /// Đăng ký bằng email/mật khẩu + tạo document user trong Firestore.
  Future<UserModel> registerWithEmail({
    required String email,
    required String password,
    required String username,
    required String displayName,
  }) async {
    // Kiểm tra username đã tồn tại chưa (username phải unique)
    final existing = await _db
        .collection('usernames')
        .doc(username.toLowerCase())
        .get();
    if (existing.exists) {
      throw Exception('Tên người dùng đã tồn tại, vui lòng chọn tên khác.');
    }

    final credential = await _auth.createUserWithEmailAndPassword(
      email: email,
      password: password,
    );
    final uid = credential.user!.uid;

    final newUser = UserModel(
      uid: uid,
      username: username.toLowerCase(),
      displayName: displayName,
      createdAt: DateTime.now(),
    );

    // Dùng batch để đảm bảo tạo user + đăng ký username là 1 giao dịch atomic
    final batch = _db.batch();
    batch.set(_db.collection('users').doc(uid), newUser.toMap());
    batch.set(_db.collection('usernames').doc(username.toLowerCase()), {'uid': uid});
    await batch.commit();

    return newUser;
  }

  Future<UserCredential> loginWithEmail({
    required String email,
    required String password,
  }) {
    return _auth.signInWithEmailAndPassword(email: email, password: password);
  }

  /// Đăng nhập bằng Google, tự tạo user document nếu là user mới.
  Future<UserCredential> loginWithGoogle() async {
    final googleUser = await _googleSignIn.signIn();
    if (googleUser == null) throw Exception('Đăng nhập Google bị hủy.');

    final googleAuth = await googleUser.authentication;
    final credential = GoogleAuthProvider.credential(
      accessToken: googleAuth.accessToken,
      idToken: googleAuth.idToken,
    );
    final userCredential = await _auth.signInWithCredential(credential);
    await _ensureUserDocumentExists(userCredential.user!);
    return userCredential;
  }

  /// Nếu đăng nhập lần đầu qua social login, tự tạo document trong Firestore.
  Future<void> _ensureUserDocumentExists(User user) async {
    final doc = await _db.collection('users').doc(user.uid).get();
    if (!doc.exists) {
      final autoUsername = 'user${user.uid.substring(0, 8)}';
      final newUser = UserModel(
        uid: user.uid,
        username: autoUsername,
        displayName: user.displayName ?? 'Người dùng mới',
        avatarUrl: user.photoURL,
        createdAt: DateTime.now(),
      );
      await _db.collection('users').doc(user.uid).set(newUser.toMap());
      await _db.collection('usernames').doc(autoUsername).set({'uid': user.uid});
    }
  }

  Future<void> sendPasswordResetEmail(String email) {
    return _auth.sendPasswordResetEmail(email: email);
  }

  Future<void> signOut() async {
    await _googleSignIn.signOut();
    await _auth.signOut();
  }

  /// Xóa tài khoản: bắt buộc phải có theo chính sách App Store/Google Play.
  /// Lưu ý: đây là phần xóa tối thiểu (user doc). Trong thực tế cần Cloud Function
  /// để dọn toàn bộ dữ liệu liên quan (bài đăng, comment, chat...) tránh dữ liệu rác.
  Future<void> deleteAccount() async {
    final user = _auth.currentUser;
    if (user == null) return;
    await _db.collection('users').doc(user.uid).delete();
    await user.delete();
  }
}
