import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

/// Màn hình giới thiệu app khi mở lần đầu, trước khi vào màn Đăng nhập.
class OnboardingScreen extends StatefulWidget {
  const OnboardingScreen({super.key});
  @override
  State<OnboardingScreen> createState() => _OnboardingScreenState();
}

class _OnboardingScreenState extends State<OnboardingScreen> {
  final _pageController = PageController();
  int _currentPage = 0;

  final _pages = const [
    _OnboardingPage(
      icon: Icons.groups_outlined,
      title: 'Kết nối với mọi người',
      description: 'Theo dõi bạn bè, chia sẻ khoảnh khắc và khám phá những điều thú vị mỗi ngày.',
    ),
    _OnboardingPage(
      icon: Icons.dynamic_feed_outlined,
      title: 'Chia sẻ câu chuyện của bạn',
      description: 'Đăng ảnh, viết cảm nghĩ và để mọi người biết bạn đang làm gì.',
    ),
    _OnboardingPage(
      icon: Icons.chat_bubble_outline,
      title: 'Trò chuyện riêng tư',
      description: 'Nhắn tin trực tiếp với bạn bè một cách nhanh chóng và an toàn.',
    ),
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: SafeArea(
        child: Column(
          children: [
            Expanded(
              child: PageView(
                controller: _pageController,
                onPageChanged: (i) => setState(() => _currentPage = i),
                children: _pages,
              ),
            ),
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: List.generate(
                _pages.length,
                (i) => AnimatedContainer(
                  duration: const Duration(milliseconds: 200),
                  margin: const EdgeInsets.symmetric(horizontal: 4),
                  width: _currentPage == i ? 20 : 8,
                  height: 8,
                  decoration: BoxDecoration(
                    color: _currentPage == i ? Theme.of(context).colorScheme.primary : Colors.grey.shade300,
                    borderRadius: BorderRadius.circular(4),
                  ),
                ),
              ),
            ),
            Padding(
              padding: const EdgeInsets.all(24),
              child: ElevatedButton(
                onPressed: () {
                  if (_currentPage < _pages.length - 1) {
                    _pageController.nextPage(
                        duration: const Duration(milliseconds: 300), curve: Curves.ease);
                  } else {
                    context.go('/login');
                  }
                },
                child: Text(_currentPage < _pages.length - 1 ? 'Tiếp tục' : 'Bắt đầu'),
              ),
            ),
            TextButton(
              onPressed: () => context.go('/login'),
              child: const Text('Bỏ qua'),
            ),
          ],
        ),
      ),
    );
  }
}

class _OnboardingPage extends StatelessWidget {
  final IconData icon;
  final String title;
  final String description;
  const _OnboardingPage({required this.icon, required this.title, required this.description});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.all(32),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(icon, size: 100, color: Theme.of(context).colorScheme.primary),
          const SizedBox(height: 32),
          Text(title, style: const TextStyle(fontSize: 24, fontWeight: FontWeight.bold), textAlign: TextAlign.center),
          const SizedBox(height: 12),
          Text(description, style: TextStyle(color: Colors.grey.shade600, fontSize: 15), textAlign: TextAlign.center),
        ],
      ),
    );
  }
}
