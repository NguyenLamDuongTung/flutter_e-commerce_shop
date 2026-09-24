import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../app/providers.dart';
import '../../../core/config/app_config.dart';
import '../../products/presentation/widgets/product_card.dart';
import '../../products/presentation/widgets/product_skeleton.dart';

class ShopHomePage extends ConsumerStatefulWidget {
  const ShopHomePage({super.key});

  @override
  ConsumerState<ShopHomePage> createState() => _ShopHomePageState();
}

class _ShopHomePageState extends ConsumerState<ShopHomePage> {
  final _searchController = TextEditingController();
  final _scrollController = ScrollController();

  String _search = '';

  @override
  void dispose() {
    _searchController.dispose();
    _scrollController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final categories = ref.watch(categoriesProvider);
    final user = ref.watch(authControllerProvider).value;

    return Scaffold(
      backgroundColor: const Color(0xFFF5F5F7),
      body: SafeArea(
        child: Column(
          children: [
            _StoreHeader(
              searchController: _searchController,
              userName: user?.fullName,
              onSearch: () {
                setState(() {
                  _search = _searchController.text.trim();
                });
              },
              onLogin: () => context.go('/login'),
              onLogout: () async {
                await ref.read(authControllerProvider.notifier).logout();
              },
            ),
            Expanded(
              child: RefreshIndicator(
                onRefresh: () async {
                  ref.invalidate(categoriesProvider);
                },
                child: ListView(
                  controller: _scrollController,
                  children: [
                    const _HeroBanner(),
                    const SizedBox(height: 42),
                    if (_search.isNotEmpty)
                      _ProductSection(
                        title: 'Kết quả tìm kiếm',
                        request: (
                          category: null,
                          search: _search,
                          featured: null,
                          limit: 12,
                        ),
                      )
                    else
                      categories.when(
                        loading: () => const Column(
                          children: [
                            _LoadingSection(),
                            _LoadingSection(),
                            _LoadingSection(),
                          ],
                        ),
                        error: (error, stackTrace) => _LoadError(
                          onRetry: () {
                            ref.invalidate(categoriesProvider);
                          },
                        ),
                        data: (items) => Column(
                          children: [
                            for (final category in items.take(6))
                              _ProductSection(
                                title: category.name,
                                request: (
                                  category: category.slug,
                                  search: '',
                                  featured: null,
                                  limit: 4,
                                ),
                              ),
                          ],
                        ),
                      ),
                    const _NewsSection(),
                    const _StoreFooter(),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
      floatingActionButton: FloatingActionButton.small(
        backgroundColor: const Color(0xFF444446),
        foregroundColor: Colors.white,
        onPressed: () {
          _scrollController.animateTo(
            0,
            duration: const Duration(milliseconds: 450),
            curve: Curves.easeOut,
          );
        },
        child: const Icon(Icons.arrow_upward),
      ),
    );
  }
}

class _StoreHeader extends StatelessWidget {
  const _StoreHeader({
    required this.searchController,
    required this.userName,
    required this.onSearch,
    required this.onLogin,
    required this.onLogout,
  });

  final TextEditingController searchController;
  final String? userName;
  final VoidCallback onSearch;
  final VoidCallback onLogin;
  final VoidCallback onLogout;

  @override
  Widget build(BuildContext context) {
    return Container(
      color: const Color(0xFF515154),
      child: Center(
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 1500),
          child: Column(
            children: [
              Padding(
                padding: const EdgeInsets.fromLTRB(22, 14, 22, 10),
                child: Row(
                  children: [
                    const Text(
                      'NOVA',
                      style: TextStyle(
                        color: Colors.white,
                        fontSize: 25,
                        letterSpacing: 4,
                        fontWeight: FontWeight.w900,
                      ),
                    ),
                    const SizedBox(width: 28),
                    Expanded(
                      child: TextField(
                        controller: searchController,
                        onSubmitted: (_) => onSearch(),
                        decoration: InputDecoration(
                          hintText: 'Bạn tìm gì...',
                          fillColor: Colors.white,
                          prefixIcon: const Icon(Icons.search),
                          suffixIcon: IconButton(
                            onPressed: onSearch,
                            icon: const Icon(Icons.arrow_forward),
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(width: 22),
                    TextButton.icon(
                      onPressed: () {},
                      icon: const Icon(
                        Icons.shopping_cart_outlined,
                        color: Colors.white,
                      ),
                      label: const Text(
                        'Giỏ hàng',
                        style: TextStyle(color: Colors.white),
                      ),
                    ),
                    const SizedBox(width: 12),
                    TextButton.icon(
                      onPressed: userName == null ? onLogin : onLogout,
                      icon: const Icon(
                        Icons.person_outline,
                        color: Colors.white,
                      ),
                      label: Text(
                        userName ?? 'Tài khoản',
                        style: const TextStyle(color: Colors.white),
                      ),
                    ),
                  ],
                ),
              ),
              SizedBox(
                height: 58,
                child: ListView(
                  scrollDirection: Axis.horizontal,
                  padding: const EdgeInsets.symmetric(horizontal: 16),
                  children: const [
                    _HeaderItem(icon: Icons.menu, label: 'Dịch vụ'),
                    _HeaderItem(label: 'Điện thoại'),
                    _HeaderItem(label: 'Máy tính'),
                    _HeaderItem(label: 'Máy tính bảng'),
                    _HeaderItem(label: 'Đồng hồ'),
                    _HeaderItem(label: 'Phụ kiện'),
                    _HeaderItem(label: 'Âm thanh'),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _HeaderItem extends StatelessWidget {
  const _HeaderItem({required this.label, this.icon});

  final String label;
  final IconData? icon;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 8),
      child: TextButton.icon(
        onPressed: () {},
        icon: icon == null
            ? const SizedBox.shrink()
            : Icon(icon, color: Colors.white),
        label: Text(
          label,
          style: const TextStyle(color: Colors.white, fontSize: 16),
        ),
      ),
    );
  }
}

class _HeroBanner extends ConsumerWidget {
  const _HeroBanner();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final products = ref.watch(
      productsProvider((category: null, search: '', featured: true, limit: 1)),
    );

    return Container(
      height: 510,
      color: const Color(0xFFF6F6F8),
      child: products.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (error, stackTrace) => const Center(child: Text('NOVA STORE')),
        data: (items) {
          final product = items.isEmpty ? null : items.first;

          return Padding(
            padding: const EdgeInsets.symmetric(horizontal: 50),
            child: Row(
              children: [
                Expanded(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Text(
                        product?.name ?? 'Thiết bị mới',
                        textAlign: TextAlign.center,
                        style: const TextStyle(
                          fontSize: 42,
                          fontWeight: FontWeight.w800,
                        ),
                      ),
                      const SizedBox(height: 10),
                      Text(
                        product?.shortDescription ??
                            'Công nghệ, đơn giản và đẹp.',
                        textAlign: TextAlign.center,
                        style: const TextStyle(fontSize: 22),
                      ),
                      const SizedBox(height: 26),
                      OutlinedButton(
                        onPressed: () {},
                        child: const Text('Khám phá ngay'),
                      ),
                    ],
                  ),
                ),
                Expanded(
                  child: product?.primaryImage == null
                      ? const Icon(Icons.devices, size: 220)
                      : Image.network(
                          AppConfig.resolveImageUrl(product!.primaryImage),
                          fit: BoxFit.contain,
                        ),
                ),
              ],
            ),
          );
        },
      ),
    );
  }
}

class _ProductSection extends ConsumerWidget {
  const _ProductSection({required this.title, required this.request});

  final String title;
  final ProductRequest request;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final products = ref.watch(productsProvider(request));

    return Padding(
      padding: const EdgeInsets.fromLTRB(24, 0, 24, 50),
      child: Center(
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 1500),
          child: Column(
            children: [
              Text(
                title,
                style: const TextStyle(
                  fontSize: 32,
                  fontWeight: FontWeight.w800,
                ),
              ),
              const SizedBox(height: 24),
              products.when(
                loading: () => const _ProductGrid(
                  children: [
                    ProductSkeleton(),
                    ProductSkeleton(),
                    ProductSkeleton(),
                    ProductSkeleton(),
                  ],
                ),
                error: (error, stackTrace) =>
                    const Text('Không thể tải sản phẩm.'),
                data: (items) {
                  if (items.isEmpty) {
                    return const Padding(
                      padding: EdgeInsets.all(30),
                      child: Text('Chưa có sản phẩm trong danh mục.'),
                    );
                  }

                  return _ProductGrid(
                    children: [
                      for (final product in items)
                        ProductCard(product: product, onPressed: () {}),
                    ],
                  );
                },
              ),
              const SizedBox(height: 26),
              OutlinedButton.icon(
                onPressed: () {},
                label: Text('Xem tất cả $title'),
                icon: const Icon(Icons.chevron_right),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _ProductGrid extends StatelessWidget {
  const _ProductGrid({required this.children});

  final List<Widget> children;

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final columns = constraints.maxWidth >= 1150
            ? 4
            : constraints.maxWidth >= 720
            ? 2
            : 1;

        return GridView.count(
          crossAxisCount: columns,
          crossAxisSpacing: 22,
          mainAxisSpacing: 22,
          childAspectRatio: 0.76,
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          children: children,
        );
      },
    );
  }
}

class _LoadingSection extends StatelessWidget {
  const _LoadingSection();

  @override
  Widget build(BuildContext context) {
    return const Padding(
      padding: EdgeInsets.all(24),
      child: _ProductGrid(
        children: [
          ProductSkeleton(),
          ProductSkeleton(),
          ProductSkeleton(),
          ProductSkeleton(),
        ],
      ),
    );
  }
}

class _LoadError extends StatelessWidget {
  const _LoadError({required this.onRetry});

  final VoidCallback onRetry;

  @override
  Widget build(BuildContext context) {
    return Center(
      child: FilledButton(
        onPressed: onRetry,
        child: const Text('Tải lại sản phẩm'),
      ),
    );
  }
}

class _NewsSection extends StatelessWidget {
  const _NewsSection();

  @override
  Widget build(BuildContext context) {
    const news = [
      ('Thiết bị mới cho công việc và sáng tạo', Icons.auto_awesome),
      ('Cách chọn điện thoại phù hợp', Icons.phone_iphone),
      ('Tối ưu hệ sinh thái thiết bị của bạn', Icons.devices_other),
    ];

    return Padding(
      padding: const EdgeInsets.fromLTRB(24, 16, 24, 70),
      child: Center(
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 1500),
          child: Column(
            children: [
              const Text(
                'Newsfeed',
                style: TextStyle(fontSize: 30, fontWeight: FontWeight.w800),
              ),
              const SizedBox(height: 24),
              Wrap(
                spacing: 22,
                runSpacing: 22,
                children: [
                  for (final item in news)
                    Container(
                      width: 450,
                      height: 250,
                      padding: const EdgeInsets.all(28),
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(14),
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Icon(item.$2, size: 64),
                          const Spacer(),
                          Text(
                            item.$1,
                            style: const TextStyle(
                              fontSize: 20,
                              fontWeight: FontWeight.w700,
                            ),
                          ),
                          const SizedBox(height: 12),
                          const Text('21/09/2026'),
                        ],
                      ),
                    ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _StoreFooter extends StatelessWidget {
  const _StoreFooter();

  @override
  Widget build(BuildContext context) {
    return Container(
      color: const Color(0xFF1D1D1F),
      padding: const EdgeInsets.symmetric(horizontal: 30, vertical: 64),
      child: Center(
        child: ConstrainedBox(
          constraints: BoxConstraints(maxWidth: 1500),
          child: Wrap(
            spacing: 90,
            runSpacing: 40,
            children: [
              SizedBox(
                width: 380,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'NOVA',
                      style: TextStyle(
                        color: Colors.white,
                        fontSize: 26,
                        letterSpacing: 4,
                        fontWeight: FontWeight.w900,
                      ),
                    ),
                    SizedBox(height: 20),
                    Text(
                      'Cửa hàng thiết bị công nghệ với trải nghiệm mua sắm đơn giản, nhanh chóng và hiện đại.',
                      style: TextStyle(color: Colors.white70, height: 1.7),
                    ),
                  ],
                ),
              ),
              _FooterColumn(
                title: 'Thông tin',
                items: [
                  'Giới thiệu',
                  'Tin tức',
                  'Phương thức thanh toán',
                  'Bảo hành',
                ],
              ),
              _FooterColumn(
                title: 'Chính sách',
                items: [
                  'Giao hàng',
                  'Đổi trả',
                  'Bảo mật',
                  'Giải quyết khiếu nại',
                ],
              ),
              _FooterColumn(
                title: 'Liên hệ',
                items: [
                  'Tài khoản của tôi',
                  'Đơn đặt hàng',
                  'Hotline: 1900 0000',
                  'support@novastore.vn',
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _FooterColumn extends StatelessWidget {
  const _FooterColumn({required this.title, required this.items});

  final String title;
  final List<String> items;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: 220,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            title,
            style: const TextStyle(
              color: Colors.white,
              fontSize: 17,
              fontWeight: FontWeight.w700,
            ),
          ),
          const SizedBox(height: 16),
          for (final item in items)
            Padding(
              padding: const EdgeInsets.only(bottom: 12),
              child: Text(item, style: const TextStyle(color: Colors.white60)),
            ),
        ],
      ),
    );
  }
}
