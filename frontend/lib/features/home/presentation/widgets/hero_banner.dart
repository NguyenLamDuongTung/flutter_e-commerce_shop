import 'dart:async';

import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../../app/providers.dart';
import '../../../../core/config/app_config.dart';
import '../../domain/hero_slide.dart';

class HeroBanner extends ConsumerStatefulWidget {
  const HeroBanner({super.key});

  @override
  ConsumerState<HeroBanner> createState() => _HeroBannerState();
}

class _HeroBannerState extends ConsumerState<HeroBanner> {
  final PageController _controller = PageController();

  Timer? _timer;
  int _currentIndex = 0;
  int _itemCount = 0;

  @override
  void initState() {
    super.initState();

    _timer = Timer.periodic(const Duration(seconds: 4), (_) {
      if (!mounted || _itemCount < 2 || !_controller.hasClients) {
        return;
      }

      final nextIndex = (_currentIndex + 1) % _itemCount;

      _controller.animateToPage(
        nextIndex,
        duration: const Duration(milliseconds: 650),
        curve: Curves.easeInOutCubic,
      );
    });
  }

  @override
  void dispose() {
    _timer?.cancel();
    _controller.dispose();
    super.dispose();
  }

  void _goTo(int index) {
    _controller.animateToPage(
      index,
      duration: const Duration(milliseconds: 500),
      curve: Curves.easeInOutCubic,
    );
  }

  @override
  Widget build(BuildContext context) {
    final slides = ref.watch(heroSlidesProvider);
    final isMobile = MediaQuery.sizeOf(context).width < 720;

    return SizedBox(
      height: isMobile ? 620 : 510,
      child: slides.when(
        loading: () => const ColoredBox(
          color: Color(0xFFF0F0F2),
          child: Center(child: CircularProgressIndicator()),
        ),
        error: (error, stackTrace) => Center(
          child: TextButton.icon(
            onPressed: () {
              ref.invalidate(heroSlidesProvider);
            },
            icon: const Icon(Icons.refresh),
            label: const Text('Tải lại banner'),
          ),
        ),
        data: (items) {
          if (items.isEmpty) {
            return const Center(child: Text('Chưa có banner được hiển thị.'));
          }

          _itemCount = items.length;

          if (_currentIndex >= items.length) {
            _currentIndex = 0;
          }

          return Stack(
            children: [
              PageView.builder(
                controller: _controller,
                itemCount: items.length,
                onPageChanged: (index) {
                  setState(() {
                    _currentIndex = index;
                  });
                },
                itemBuilder: (context, index) {
                  return _HeroSlideView(slide: items[index]);
                },
              ),
              if (items.length > 1) ...[
                Positioned(
                  left: 18,
                  top: 0,
                  bottom: 0,
                  child: Center(
                    child: IconButton.filledTonal(
                      onPressed: () {
                        _goTo(
                          (_currentIndex - 1 + items.length) % items.length,
                        );
                      },
                      icon: const Icon(Icons.chevron_left),
                    ),
                  ),
                ),
                Positioned(
                  right: 18,
                  top: 0,
                  bottom: 0,
                  child: Center(
                    child: IconButton.filledTonal(
                      onPressed: () {
                        _goTo((_currentIndex + 1) % items.length);
                      },
                      icon: const Icon(Icons.chevron_right),
                    ),
                  ),
                ),
                Positioned(
                  left: 0,
                  right: 0,
                  bottom: 18,
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: List.generate(
                      items.length,
                      (index) => GestureDetector(
                        onTap: () => _goTo(index),
                        child: AnimatedContainer(
                          duration: const Duration(milliseconds: 250),
                          width: index == _currentIndex ? 28 : 8,
                          height: 8,
                          margin: const EdgeInsets.symmetric(horizontal: 4),
                          decoration: BoxDecoration(
                            color: index == _currentIndex
                                ? Colors.black
                                : Colors.black26,
                            borderRadius: BorderRadius.circular(10),
                          ),
                        ),
                      ),
                    ),
                  ),
                ),
              ],
            ],
          );
        },
      ),
    );
  }
}

class _HeroSlideView extends StatelessWidget {
  const _HeroSlideView({required this.slide});

  final HeroSlide slide;

  @override
  Widget build(BuildContext context) {
    final isMobile = MediaQuery.sizeOf(context).width < 720;

    final content = Padding(
      padding: const EdgeInsets.symmetric(horizontal: 46, vertical: 32),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Text(
            slide.title,
            textAlign: TextAlign.center,
            style: TextStyle(
              fontSize: isMobile ? 34 : 44,
              fontWeight: FontWeight.w900,
              letterSpacing: -1,
            ),
          ),
          const SizedBox(height: 12),
          Text(
            slide.subtitle,
            textAlign: TextAlign.center,
            maxLines: 3,
            overflow: TextOverflow.ellipsis,
            style: TextStyle(fontSize: isMobile ? 17 : 22, height: 1.4),
          ),
          const SizedBox(height: 26),
          OutlinedButton(
            onPressed: () {
              context.go('/products/${slide.productSlug}');
            },
            child: Text(slide.buttonText),
          ),
        ],
      ),
    );

    final image = Container(
      color: const Color(0xFFE6E6E8),
      padding: const EdgeInsets.all(26),
      child: slide.imageUrl == null || slide.imageUrl!.trim().isEmpty
          ? const Center(child: Icon(Icons.devices, size: 170))
          : CachedNetworkImage(
              imageUrl: AppConfig.resolveImageUrl(slide.imageUrl),
              fit: BoxFit.contain,
              placeholder: (context, url) =>
                  const Center(child: CircularProgressIndicator()),
              errorWidget: (context, url, error) => const Center(
                child: Icon(Icons.broken_image_outlined, size: 70),
              ),
            ),
    );

    return ColoredBox(
      color: const Color(0xFFF6F6F8),
      child: isMobile
          ? Column(
              children: [
                Expanded(child: content),
                Expanded(child: image),
              ],
            )
          : Row(
              children: [
                Expanded(child: content),
                Expanded(child: image),
              ],
            ),
    );
  }
}
