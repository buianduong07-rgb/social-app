import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../providers/auth_provider.dart';

class SettingsScreen extends ConsumerWidget {
  const SettingsScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return Scaffold(
      appBar: AppBar(title: const Text('Cài đặt')),
      body: ListView(
        children: [
          ListTile(
            leading: const Icon(Icons.lock_outline),
            title: const Text('Đổi mật khẩu'),
            onTap: () => _showChangePasswordDialog(context, ref),
          ),
          ListTile(
            leading: const Icon(Icons.privacy_tip_outlined),
            title: const Text('Chính sách quyền riêng tư'),
            onTap: () {
              // TODO: mở URL Privacy Policy đã host (bắt buộc trước khi nộp app lên store).
            },
          ),
          ListTile(
            leading: const Icon(Icons.description_outlined),
            title: const Text('Điều khoản sử dụng'),
            onTap: () {
              // TODO: mở URL Terms of Service.
            },
          ),
          const Divider(),
          ListTile(
            leading: const Icon(Icons.logout, color: Colors.orange),
            title: const Text('Đăng xuất', style: TextStyle(color: Colors.orange)),
            onTap: () async {
              final myUid = ref.read(authStateProvider).value?.uid;
              if (myUid != null) {
                await ref.read(notificationServiceProvider).removeCurrentToken(myUid);
              }
              await ref.read(authServiceProvider).signOut();
            },
          ),
          ListTile(
            leading: const Icon(Icons.delete_forever, color: Colors.red),
            title: const Text('Xóa tài khoản', style: TextStyle(color: Colors.red)),
            onTap: () => _showDeleteAccountDialog(context, ref),
          ),
        ],
      ),
    );
  }

  void _showChangePasswordDialog(BuildContext context, WidgetRef ref) {
    final emailCtrl = TextEditingController(text: ref.read(authServiceProvider).currentUser?.email);
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Đổi mật khẩu'),
        content: Text('Chúng tôi sẽ gửi email hướng dẫn đặt lại mật khẩu tới ${emailCtrl.text}.'),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('Hủy')),
          TextButton(
            onPressed: () async {
              await ref.read(authServiceProvider).sendPasswordResetEmail(emailCtrl.text);
              if (ctx.mounted) Navigator.pop(ctx);
            },
            child: const Text('Gửi email'),
          ),
        ],
      ),
    );
  }

  void _showDeleteAccountDialog(BuildContext context, WidgetRef ref) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Xóa tài khoản?'),
        content: const Text(
          'Toàn bộ dữ liệu tài khoản của bạn sẽ bị xóa vĩnh viễn và không thể khôi phục. '
          'Bạn có chắc chắn muốn tiếp tục?',
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('Hủy')),
          TextButton(
            onPressed: () async {
              Navigator.pop(ctx);
              await ref.read(authServiceProvider).deleteAccount();
            },
            child: const Text('Xóa tài khoản', style: TextStyle(color: Colors.red)),
          ),
        ],
      ),
    );
  }
}
