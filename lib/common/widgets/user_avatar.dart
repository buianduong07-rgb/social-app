import 'package:flutter/material.dart';
import 'package:cached_network_image/cached_network_image.dart';

/// Avatar tròn dùng chung khắp app, có fallback khi chưa có ảnh.
class UserAvatar extends StatelessWidget {
  final String? avatarUrl;
  final double radius;

  const UserAvatar({super.key, this.avatarUrl, this.radius = 20});

  @override
  Widget build(BuildContext context) {
    if (avatarUrl == null || avatarUrl!.isEmpty) {
      return CircleAvatar(
        radius: radius,
        backgroundColor: Colors.grey.shade300,
        child: Icon(Icons.person, size: radius, color: Colors.grey.shade600),
      );
    }
    return CircleAvatar(
      radius: radius,
      backgroundColor: Colors.grey.shade200,
      child: ClipOval(
        child: CachedNetworkImage(
          imageUrl: avatarUrl!,
          width: radius * 2,
          height: radius * 2,
          fit: BoxFit.cover,
          placeholder: (c, u) => const CircularProgressIndicator(strokeWidth: 1.5),
          errorWidget: (c, u, e) => Icon(Icons.person, size: radius, color: Colors.grey.shade600),
        ),
      ),
    );
  }
}
