import 'dart:io';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:flutter_image_compress/flutter_image_compress.dart';
import 'package:uuid/uuid.dart';
import 'package:path_provider/path_provider.dart';

/// Nén ảnh trước khi upload để tiết kiệm dung lượng Storage & băng thông.
class StorageService {
  final SupabaseClient _supabase = Supabase.instance.client;
  final _uuid = const Uuid();
  static const _bucket = 'media';

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

  Future<String> _uploadAndGetUrl(String path, File file) async {
    await _supabase.storage.from(_bucket).upload(
          path,
          file,
          fileOptions: const FileOptions(upsert: true),
        );
    return _supabase.storage.from(_bucket).getPublicUrl(path);
  }

  Future<String> uploadAvatar(String uid, File file) async {
    final compressed = await _compressImage(file);
    return _uploadAndGetUrl('avatars/$uid.jpg', compressed);
  }

  Future<String> uploadCoverPhoto(String uid, File file) async {
    final compressed = await _compressImage(file);
    return _uploadAndGetUrl('covers/$uid.jpg', compressed);
  }

  /// Upload nhiều ảnh cho 1 bài đăng, trả về danh sách URL.
  Future<List<String>> uploadPostImages(String postId, List<File> files) async {
    final urls = <String>[];
    for (var i = 0; i < files.length; i++) {
      final compressed = await _compressImage(files[i]);
      final url = await _uploadAndGetUrl('posts/$postId/image_$i.jpg', compressed);
      urls.add(url);
    }
    return urls;
  }

  Future<String> uploadChatImage(String conversationId, File file) async {
    final compressed = await _compressImage(file);
    return _uploadAndGetUrl('chats/$conversationId/${_uuid.v4()}.jpg', compressed);
  }
}
