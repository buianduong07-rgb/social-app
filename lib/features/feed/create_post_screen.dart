import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:image_picker/image_picker.dart';
import 'package:go_router/go_router.dart';
import '../../providers/auth_provider.dart';
import '../../providers/feed_provider.dart';
import '../../services/storage_service.dart';

class CreatePostScreen extends ConsumerStatefulWidget {
  const CreatePostScreen({super.key});
  @override
  ConsumerState<CreatePostScreen> createState() => _CreatePostScreenState();
}

class _CreatePostScreenState extends ConsumerState<CreatePostScreen> {
  final _contentCtrl = TextEditingController();
  final List<File> _selectedImages = [];
  bool _isPosting = false;

  Future<void> _pickImages() async {
    final picker = ImagePicker();
    final picked = await picker.pickMultiImage(imageQuality: 85, limit: 4);
    setState(() {
      _selectedImages
        ..clear()
        ..addAll(picked.map((x) => File(x.path)));
    });
  }

  Future<void> _submitPost() async {
    final me = ref.read(currentUserProvider).value;
    if (me == null) return;
    if (_contentCtrl.text.trim().isEmpty && _selectedImages.isEmpty) return;

    setState(() => _isPosting = true);
    try {
      final postRepo = ref.read(postRepositoryProvider);
      // Tạo post trước để lấy postId, rồi upload ảnh theo id đó, cuối cùng update lại imageUrls.
      final postId = await postRepo.createPost(
        authorId: me.uid,
        authorUsername: me.username,
        authorAvatarUrl: me.avatarUrl,
        content: _contentCtrl.text.trim(),
      );

      if (_selectedImages.isNotEmpty) {
        final urls = await StorageService().uploadPostImages(postId, _selectedImages);
        // markEdited: false vì đây là bước hoàn tất tạo bài, không phải người dùng chỉnh sửa sau này.
        await postRepo.updatePost(postId, imageUrls: urls, markEdited: false);
      }

      if (mounted) context.pop();
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Đăng bài thất bại: $e')),
        );
      }
    } finally {
      if (mounted) setState(() => _isPosting = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Bài viết mới'),
        actions: [
          TextButton(
            onPressed: _isPosting ? null : _submitPost,
            child: _isPosting
                ? const SizedBox(width: 16, height: 16, child: CircularProgressIndicator(strokeWidth: 2))
                : const Text('Đăng'),
          ),
        ],
      ),
      body: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            TextField(
              controller: _contentCtrl,
              maxLines: 6,
              maxLength: 500,
              decoration: const InputDecoration(
                hintText: 'Bạn đang nghĩ gì?',
                border: InputBorder.none,
              ),
            ),
            if (_selectedImages.isNotEmpty)
              SizedBox(
                height: 90,
                child: ListView.separated(
                  scrollDirection: Axis.horizontal,
                  itemCount: _selectedImages.length,
                  separatorBuilder: (_, __) => const SizedBox(width: 8),
                  itemBuilder: (context, i) => ClipRRect(
                    borderRadius: BorderRadius.circular(8),
                    child: Image.file(_selectedImages[i], width: 90, height: 90, fit: BoxFit.cover),
                  ),
                ),
              ),
            const Spacer(),
            IconButton(
              onPressed: _pickImages,
              icon: const Icon(Icons.image_outlined, size: 28),
            ),
          ],
        ),
      ),
    );
  }
}
