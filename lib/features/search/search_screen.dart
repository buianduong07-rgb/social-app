import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'dart:async';
import '../../models/user_model.dart';
import '../../providers/auth_provider.dart';
import '../../common/widgets/user_avatar.dart';
import '../../common/widgets/loading_view.dart';

class SearchScreen extends ConsumerStatefulWidget {
  const SearchScreen({super.key});
  @override
  ConsumerState<SearchScreen> createState() => _SearchScreenState();
}

class _SearchScreenState extends ConsumerState<SearchScreen> {
  final _controller = TextEditingController();
  Timer? _debounce;
  List<UserModel> _results = [];
  bool _isSearching = false;

  void _onChanged(String query) {
    _debounce?.cancel();
    _debounce = Timer(const Duration(milliseconds: 400), () async {
      if (query.trim().isEmpty) {
        setState(() => _results = []);
        return;
      }
      setState(() => _isSearching = true);
      final results = await ref.read(userRepositoryProvider).searchUsers(query.trim());
      if (mounted) setState(() { _results = results; _isSearching = false; });
    });
  }

  @override
  void dispose() {
    _debounce?.cancel();
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: TextField(
          controller: _controller,
          autofocus: true,
          onChanged: _onChanged,
          decoration: const InputDecoration(
            hintText: 'Tìm kiếm người dùng theo username...',
            border: InputBorder.none,
          ),
        ),
      ),
      body: _isSearching
          ? const LoadingView()
          : _results.isEmpty
              ? EmptyView(message: _controller.text.isEmpty ? 'Nhập tên để tìm kiếm.' : 'Không tìm thấy kết quả.')
              : ListView.builder(
                  itemCount: _results.length,
                  itemBuilder: (context, i) {
                    final u = _results[i];
                    return ListTile(
                      leading: UserAvatar(avatarUrl: u.avatarUrl, radius: 22),
                      title: Text(u.displayName),
                      subtitle: Text('@${u.username}'),
                      onTap: () => context.push('/profile/${u.uid}'),
                    );
                  },
                ),
    );
  }
}
