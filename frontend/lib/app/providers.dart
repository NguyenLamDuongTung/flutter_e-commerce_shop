import 'dart:async';

import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../core/network/api_client.dart';
import '../core/storage/auth_storage.dart';
import '../features/auth/data/api_auth_repository.dart';
import '../features/auth/domain/app_user.dart';
import '../features/admin/data/admin_dashboard_repository.dart';
import '../features/admin/data/admin_product_repository.dart';
import '../features/products/data/api_product_repository.dart';
import '../features/products/domain/product.dart';

final authStorageProvider = Provider<AuthStorage>((ref) {
  return AuthStorage();
});

final apiClientProvider = Provider<ApiClient>((ref) {
  final client = ApiClient(authStorage: ref.watch(authStorageProvider));

  ref.onDispose(client.dispose);

  return client;
});

final productRepositoryProvider = Provider<ApiProductRepository>((ref) {
  return ApiProductRepository(ref.watch(apiClientProvider));
});

final adminDashboardRepositoryProvider = Provider<AdminDashboardRepository>((ref) {
  return AdminDashboardRepository(ref.watch(apiClientProvider));
});

final adminDashboardProvider = FutureProvider<AdminDashboardData>((ref) {
  return ref.watch(adminDashboardRepositoryProvider).getDashboard();
});

final adminProductRepositoryProvider = Provider<AdminProductRepository>((ref) {
  return AdminProductRepository(ref.watch(apiClientProvider));
});

final categoriesProvider = FutureProvider<List<ProductCategory>>((ref) {
  return ref.watch(productRepositoryProvider).getCategories();
});

typedef ProductRequest = ({
  String? category,
  String search,
  bool? featured,
  int limit,
});

final productsProvider = FutureProvider.family<List<Product>, ProductRequest>((
  ref,
  request,
) {
  return ref
      .watch(productRepositoryProvider)
      .getProducts(
        category: request.category,
        search: request.search,
        featured: request.featured,
        limit: request.limit,
      );
});

final authRepositoryProvider = Provider<ApiAuthRepository>((ref) {
  return ApiAuthRepository(
    apiClient: ref.watch(apiClientProvider),
    authStorage: ref.watch(authStorageProvider),
  );
});

final authControllerProvider = AsyncNotifierProvider<AuthController, AppUser?>(
  AuthController.new,
);

class AuthController extends AsyncNotifier<AppUser?> {
  ApiAuthRepository get _repository => ref.read(authRepositoryProvider);

  @override
  FutureOr<AppUser?> build() {
    return _repository.restoreSession();
  }

  Future<bool> login({
    required String email,
    required String password,
    bool requireAdmin = false,
  }) async {
    state = const AsyncLoading();

    try {
      final user = await _repository.login(email: email, password: password);

      if (requireAdmin && !user.isAdmin) {
        await _repository.logout();

        throw Exception('This account does not have admin permission.');
      }

      state = AsyncData(user);
      return true;
    } catch (error, stackTrace) {
      state = AsyncError(error, stackTrace);
      return false;
    }
  }

  Future<bool> register({
    required String fullName,
    required String email,
    required String password,
    String phone = '',
  }) async {
    state = const AsyncLoading();

    try {
      final user = await _repository.register(
        fullName: fullName,
        email: email,
        password: password,
        phone: phone,
      );

      state = AsyncData(user);
      return true;
    } catch (error, stackTrace) {
      state = AsyncError(error, stackTrace);
      return false;
    }
  }

  Future<void> updateProfile({
    required String fullName,
    String? phone,
    String? address,
  }) async {
    final currentUser = state.value;

    if (currentUser == null) {
      return;
    }

    try {
      final user = await _repository.updateProfile(
        fullName: fullName,
        phone: phone,
        address: address,
      );

      state = AsyncData(user);
    } catch (error, stackTrace) {
      state = AsyncError(error, stackTrace);
    }
  }

  Future<void> logout() async {
    await _repository.logout();
    state = const AsyncData(null);
  }

  void clearError() {
    if (state.hasError) {
      state = const AsyncData(null);
    }
  }
}
