import 'package:cached_network_image/cached_network_image.dart';
import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';

import '../../../app/providers.dart';
import '../../../core/config/app_config.dart';
import '../data/admin_product_repository.dart';
import '../domain/admin_product.dart';

class AdminProductsPage extends ConsumerStatefulWidget {
  const AdminProductsPage({super.key});

  @override
  ConsumerState<AdminProductsPage> createState() => _AdminProductsPageState();
}

class _AdminProductsPageState extends ConsumerState<AdminProductsPage> {
  final _searchController = TextEditingController();
  String _status = 'all';
  int _page = 1;
  bool _loading = true;
  Object? _error;
  AdminProductPage? _result;

  @override
  void initState() {
    super.initState();
    Future.microtask(_load);
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  Future<void> _load() async {
    setState(() {
      _loading = true;
      _error = null;
    });
    try {
      final value = await ref.read(adminProductRepositoryProvider).getProducts(
        page: _page,
        search: _searchController.text.trim(),
        status: _status,
      );
      if (mounted) setState(() => _result = value);
    } catch (error) {
      if (mounted) setState(() => _error = error);
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  Future<void> _openEditor([AdminProduct? product]) async {
    final saved = await showDialog<bool>(
      context: context,
      barrierDismissible: false,
      builder: (_) => _ProductDialog(product: product),
    );
    if (saved == true) {
      _page = 1;
      await _load();
      ref.invalidate(adminDashboardProvider);
    }
  }

  Future<void> _delete(AdminProduct product) async {
    final accepted = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Xóa sản phẩm?'),
        content: Text('Bạn chắc chắn muốn xóa “${product.name}”?'),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context, false), child: const Text('Hủy')),
          FilledButton(onPressed: () => Navigator.pop(context, true), child: const Text('Xóa')),
        ],
      ),
    );
    if (accepted != true) return;
    try {
      await ref.read(adminProductRepositoryProvider).deleteProduct(product.id);
      await _load();
      ref.invalidate(adminDashboardProvider);
    } catch (error) {
      if (mounted) ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('$error')));
    }
  }

  @override
  Widget build(BuildContext context) {
    final result = _result;
    return Scaffold(
      backgroundColor: const Color(0xFFF3F4F6),
      appBar: AppBar(
        leading: IconButton(onPressed: () => context.go('/admin'), icon: const Icon(Icons.arrow_back)),
        title: const Text('Quản lý sản phẩm'),
        actions: [
          FilledButton.icon(
            onPressed: () => _openEditor(),
            icon: const Icon(Icons.add),
            label: const Text('Thêm sản phẩm'),
            style: FilledButton.styleFrom(backgroundColor: Colors.black),
          ),
          const SizedBox(width: 18),
        ],
      ),
      body: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(children: [
          Row(children: [
            Expanded(
              child: TextField(
                controller: _searchController,
                onSubmitted: (_) { _page = 1; _load(); },
                decoration: InputDecoration(
                  hintText: 'Tìm theo tên hoặc slug...',
                  prefixIcon: const Icon(Icons.search),
                  suffixIcon: IconButton(onPressed: () { _page = 1; _load(); }, icon: const Icon(Icons.arrow_forward)),
                  filled: true,
                  fillColor: Colors.white,
                ),
              ),
            ),
            const SizedBox(width: 12),
            DropdownButton<String>(
              value: _status,
              items: const [
                DropdownMenuItem(value: 'all', child: Text('Tất cả')),
                DropdownMenuItem(value: 'active', child: Text('Đang bán')),
                DropdownMenuItem(value: 'inactive', child: Text('Đã ẩn')),
              ],
              onChanged: (value) { if (value != null) { _status = value; _page = 1; _load(); } },
            ),
          ]),
          const SizedBox(height: 18),
          Expanded(
            child: _loading
                ? const Center(child: CircularProgressIndicator())
                : _error != null
                    ? Center(child: Column(mainAxisSize: MainAxisSize.min, children: [Text('Không thể tải sản phẩm\n$_error', textAlign: TextAlign.center), const SizedBox(height: 12), FilledButton(onPressed: _load, child: const Text('Thử lại'))]))
                    : result == null || result.items.isEmpty
                        ? const Center(child: Text('Chưa có sản phẩm.'))
                        : ListView.separated(
                            itemCount: result.items.length,
                            separatorBuilder: (_, _) => const SizedBox(height: 10),
                            itemBuilder: (_, index) => _ProductRow(
                              product: result.items[index],
                              edit: () => _openEditor(result.items[index]),
                              toggle: () async {
                                await ref.read(adminProductRepositoryProvider).setActive(result.items[index].id, !result.items[index].isActive);
                                await _load();
                              },
                              delete: () => _delete(result.items[index]),
                            ),
                          ),
          ),
          if (result != null && result.totalPages > 1)
            Row(mainAxisAlignment: MainAxisAlignment.center, children: [
              IconButton(onPressed: result.hasPreviousPage ? () { _page--; _load(); } : null, icon: const Icon(Icons.chevron_left)),
              Text('Trang ${result.page}/${result.totalPages}'),
              IconButton(onPressed: result.hasNextPage ? () { _page++; _load(); } : null, icon: const Icon(Icons.chevron_right)),
            ]),
        ]),
      ),
    );
  }
}

class _ProductRow extends StatelessWidget {
  const _ProductRow({required this.product, required this.edit, required this.toggle, required this.delete});
  final AdminProduct product;
  final VoidCallback edit;
  final VoidCallback toggle;
  final VoidCallback delete;

  @override
  Widget build(BuildContext context) => Card(
    child: Padding(
      padding: const EdgeInsets.all(12),
      child: Row(children: [
        ClipRRect(
          borderRadius: BorderRadius.circular(12),
          child: SizedBox(
            width: 72,
            height: 72,
            child: product.primaryImage == null
                ? const ColoredBox(color: Color(0xFFE5E7EB), child: Icon(Icons.image_outlined))
                : CachedNetworkImage(imageUrl: AppConfig.resolveImageUrl(product.primaryImage), fit: BoxFit.cover, errorWidget: (_, _, _) => const Icon(Icons.broken_image_outlined)),
          ),
        ),
        const SizedBox(width: 14),
        Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          Text(product.name, style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w800)),
          Text('${product.categoryName} • Kho: ${product.stockQuantity}', style: const TextStyle(color: Color(0xFF64748B))),
          Text(NumberFormat.currency(locale: 'vi_VN', symbol: '₫', decimalDigits: 0).format(product.price), style: const TextStyle(fontWeight: FontWeight.w700)),
        ])),
        Switch(value: product.isActive, onChanged: (_) => toggle()),
        IconButton(onPressed: edit, tooltip: 'Sửa', icon: const Icon(Icons.edit_outlined)),
        IconButton(onPressed: delete, tooltip: 'Xóa', icon: const Icon(Icons.delete_outline, color: Colors.red)),
      ]),
    ),
  );
}

class _ProductDialog extends ConsumerStatefulWidget {
  const _ProductDialog({this.product});
  final AdminProduct? product;
  @override
  ConsumerState<_ProductDialog> createState() => _ProductDialogState();
}

class _ProductDialogState extends ConsumerState<_ProductDialog> {
  final _formKey = GlobalKey<FormState>();
  late final TextEditingController _name;
  late final TextEditingController _slug;
  late final TextEditingController _shortDescription;
  late final TextEditingController _description;
  late final TextEditingController _price;
  late final TextEditingController _comparePrice;
  late final TextEditingController _stock;
  int? _categoryId;
  bool _featured = false;
  bool _active = true;
  bool _saving = false;
  List<ProductUpload> _images = [];

  @override
  void initState() {
    super.initState();
    final product = widget.product;
    _name = TextEditingController(text: product?.name ?? '');
    _slug = TextEditingController(text: product?.slug ?? '');
    _shortDescription = TextEditingController(text: product?.shortDescription ?? '');
    _description = TextEditingController(text: product?.description ?? '');
    _price = TextEditingController(text: product == null ? '' : '${product.price}');
    _comparePrice = TextEditingController(text: product?.comparePrice == null ? '' : '${product!.comparePrice}');
    _stock = TextEditingController(text: '${product?.stockQuantity ?? 0}');
    _categoryId = product?.categoryId;
    _featured = product?.featured ?? false;
    _active = product?.isActive ?? true;
  }

  Future<void> _pickImages() async {
    final files = await FilePicker.pickFiles(type: FileType.image);
    final uploads = <ProductUpload>[];

    for (final file in files.take(8)) {
      uploads.add(
        (
          name: file.name,
          bytes: await file.readAsBytes(),
        ),
      );
    }

    if (mounted) {
      setState(() => _images = uploads);
    }
  }

  Future<void> _save() async {
    if (!_formKey.currentState!.validate() || _categoryId == null) return;
    setState(() => _saving = true);
    try {
      await ref.read(adminProductRepositoryProvider).save(
        id: widget.product?.id,
        input: AdminProductInput(
          categoryId: _categoryId!,
          name: _name.text.trim(),
          slug: _slug.text.trim(),
          shortDescription: _shortDescription.text.trim(),
          description: _description.text.trim(),
          price: double.parse(_price.text),
          comparePrice: _comparePrice.text.trim().isEmpty ? null : double.parse(_comparePrice.text),
          stockQuantity: int.parse(_stock.text),
          featured: _featured,
          isActive: _active,
        ),
        images: _images.map((file) => (name: file.name, bytes: file.bytes!)).toList(),
      );
      if (mounted) Navigator.pop(context, true);
    } catch (error) {
      if (mounted) ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('$error')));
    } finally {
      if (mounted) setState(() => _saving = false);
    }
  }

  String? _required(String? value) => value == null || value.trim().isEmpty ? 'Không được để trống' : null;

  @override
  Widget build(BuildContext context) {
    final categories = ref.watch(categoriesProvider);
    return AlertDialog(
      title: Text(widget.product == null ? 'Thêm sản phẩm' : 'Sửa sản phẩm'),
      content: SizedBox(
        width: 680,
        child: Form(
          key: _formKey,
          child: SingleChildScrollView(child: Column(children: [
            TextFormField(controller: _name, validator: _required, decoration: const InputDecoration(labelText: 'Tên sản phẩm')),
            TextFormField(controller: _slug, validator: _required, decoration: const InputDecoration(labelText: 'Slug, ví dụ: iphone-17-pro')),
            categories.when(
              loading: () => const LinearProgressIndicator(),
              error: (error, _) => Text('Không tải được danh mục: $error'),
              data: (items) => DropdownButtonFormField<int>(
                initialValue: items.any((item) => item.id == _categoryId) ? _categoryId : null,
                decoration: const InputDecoration(labelText: 'Danh mục'),
                items: items.map((item) => DropdownMenuItem(value: item.id, child: Text(item.name))).toList(),
                onChanged: (value) => _categoryId = value,
                validator: (value) => value == null ? 'Chọn danh mục' : null,
              ),
            ),
            TextFormField(controller: _shortDescription, decoration: const InputDecoration(labelText: 'Mô tả ngắn')),
            TextFormField(controller: _description, maxLines: 3, decoration: const InputDecoration(labelText: 'Mô tả chi tiết')),
            Row(children: [
              Expanded(child: TextFormField(controller: _price, validator: _required, keyboardType: TextInputType.number, decoration: const InputDecoration(labelText: 'Giá bán'))),
              const SizedBox(width: 12),
              Expanded(child: TextFormField(controller: _comparePrice, keyboardType: TextInputType.number, decoration: const InputDecoration(labelText: 'Giá so sánh'))),
              const SizedBox(width: 12),
              Expanded(child: TextFormField(controller: _stock, validator: _required, keyboardType: TextInputType.number, decoration: const InputDecoration(labelText: 'Tồn kho'))),
            ]),
            SwitchListTile(value: _featured, onChanged: (value) => setState(() => _featured = value), title: const Text('Sản phẩm nổi bật')),
            SwitchListTile(value: _active, onChanged: (value) => setState(() => _active = value), title: const Text('Hiển thị sản phẩm')),
            ListTile(
              contentPadding: EdgeInsets.zero,
              leading: const Icon(Icons.image_outlined),
              title: Text(_images.isEmpty ? 'Chọn hình ảnh' : 'Đã chọn ${_images.length} hình'),
              subtitle: const Text('JPG, PNG, WebP hoặc AVIF; tối đa 8 hình'),
              trailing: OutlinedButton(onPressed: _pickImages, child: const Text('Chọn file')),
            ),
          ])),
        ),
      ),
      actions: [
        TextButton(onPressed: _saving ? null : () => Navigator.pop(context), child: const Text('Hủy')),
        FilledButton(onPressed: _saving ? null : _save, style: FilledButton.styleFrom(backgroundColor: Colors.black), child: Text(_saving ? 'Đang lưu...' : 'Lưu sản phẩm')),
      ],
    );
  }
}
