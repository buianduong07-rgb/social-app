import 'dart:io';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:flutter_image_compress/flutter_image_compress.dart';
import 'package:uuid/uuid.dart';
import 'package:path_provider/path_provider.dart';

/// Nén ảnh trước khi upload để tiết kiệm dung lượng Storage & băng thông.
class StorageService {
  final FirebaseStorage _storage = FirebaseStorage.instance;
  final _uuid = const Uuid();

  Future<File> _compressImage(File file) async {
    final dir = await getTemporaryDirectory();
    final targetPath = '${dir.path}/${_uuid.v4()}.jpg';

    final result = await FlutterImageCompress.compressAndGetFile(
      file.absolute.path,
      targetPath,
      quality: 75,
      minWidth: 1080,
      minHeight: 1080,
    );

    return result != null ? File(result.path) : file;
  }

  Future<String> uploadAvatar(String uid, File file) async {
    final compressed = await _compressImage(file);
    final ref = _storage.ref('avatars/$uid.jpg');
    await ref.putFile(compressed);
    return ref.getDownloadURL();
  }

  Future<String> uploadCoverPhoto(String uid, File file) async {
    final compressed = await _compressImage(file);
    final ref = _storage.ref('covers/$uid.jpg');
    await ref.putFile(compressed);
    return ref.getDownloadURL();
  }

  /// Upload nhiều ảnh cho 1 bài đăng, trả về danh sách URL.
  Future<List<String>> uploadPostImages(String postId, List<File> files) async {
    final urls = <String>[];
    for (var i = 0; i < files.length; i++) {
      final compressed = await _compressImage(files[i]);
      final ref = _storage.ref('posts/$postId/image_$i.jpg');
      await ref.putFile(compressed);
      urls.add(await ref.getDownloadURL());
    }
    return urls;
  }

  Future<String> uploadChatImage(String conversationId, File file) async {
    final compressed = await _compressImage(file);
    final ref = _storage.ref('chats/$conversationId/${_uuid.v4()}.jpg');
    await ref.putFile(compressed);
    return ref.getDownloadURL();
  }
}
