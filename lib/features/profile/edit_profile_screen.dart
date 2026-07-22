import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:image_picker/image_picker.dart';
import 'package:go_router/go_router.dart';
import '../../providers/auth_provider.dart';
import '../../services/storage_service.dart';
import '../../common/widgets/user_avatar.dart';

class EditProfileScreen extends ConsumerStatefulWidget {
  const EditProfileScreen({super.key});
  @override
  ConsumerState<EditProfileScreen> createState() => _EditProfileScreenState();
}

class _EditProfileScreenState extends ConsumerState<EditProfileScreen> {
  final _displayNameCtrl = TextEditingController();
  final _bioCtrl = TextEditingController();
  File? _newAvatar;
  bool _isSaving = false;
  bool _initialized = false;

  Future<void> _pickAvatar() async {
    final picker = ImagePicker();
    final picked = await picker.pickImage(source: ImageSource.gallery, imageQuality: 85);
    if (picked != null) setState(() => _newAvatar = File(picked.path));
  }

  Future<void> _save(String uid) async {
    setState(() => _isSaving = true);
    try {
      String? avatarUrl;
      if (_newAvatar != null) {
        avatarUrl = await StorageService().uploadAvatar(uid, _newAvatar!);
      }
      await ref.read(userRepositoryProvider).updateProfile(
            uid,
            displayName: _displayNameCtrl.text.trim(),
            bio: _bioCtrl.text.trim(),
            avatarUrl: avatarUrl,
          );
      if (mounted) context.pop();
    } finally {
      if (mounted) setState(() => _isSaving = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final userAsync = ref.watch(currentUserProvider);

    return userAsync.when(
      data: (user) {
        if (user == null) return const Scaffold(body: SizedBox.shrink());
        if (!_initialized) {
          _displayNameCtrl.text = user.displayName;
          _bioCtrl.text = user.bio ?? '';
          _initialized = true;
        }
        return Scaffold(
          appBar: AppBar(
            title: const Text('Chỉnh sửa hồ sơ'),
            actions: [
              TextButton(
                onPressed: _isSaving ? null : () => _save(user.uid),
                child: _isSaving
                    ? const SizedBox(width: 16, height: 16, child: CircularProgressIndicator(strokeWidth: 2))
                    : const Text('Lưu'),
              ),
            ],
          ),
          body: Padding(
            padding: const EdgeInsets.all(20),
            child: Column(
              children: [
                Center(
                  child: GestureDetector(
                    onTap: _pickAvatar,
                    child: Stack(
                      children: [
                        _newAvatar != null
                            ? CircleAvatar(radius: 48, backgroundImage: FileImage(_newAvatar!))
                            : UserAvatar(avatarUrl: user.avatarUrl, radius: 48),
                        const Positioned(
                          bottom: 0,
                          right: 0,
                          child: CircleAvatar(radius: 14, child: Icon(Icons.edit, size: 14)),
                        ),
                      ],
                    ),
                  ),
                ),
                const SizedBox(height: 24),
                TextField(
                  controller: _displayNameCtrl,
                  decoration: const InputDecoration(labelText: 'Tên hiển thị'),
                ),
                const SizedBox(height: 16),
                TextField(
                  controller: _bioCtrl,
                  maxLines: 3,
                  maxLength: 150,
                  decoration: const InputDecoration(labelText: 'Giới thiệu bản thân (bio)'),
                ),
              ],
            ),
          ),
        );
      },
      loading: () => const Scaffold(body: Center(child: CircularProgressIndicator())),
      error: (_, __) => const Scaffold(body: Center(child: Text('Có lỗi xảy ra'))),
    );
  }
}
