import '../../../core/network/api_client.dart';
import '../../../core/network/api_exception.dart';
import '../../../core/storage/auth_storage.dart';
import '../domain/app_user.dart';

class ApiAuthRepository {
  const ApiAuthRepository({
    required ApiClient apiClient,
    required AuthStorage authStorage,
  }) : _apiClient = apiClient,
       _authStorage = authStorage;

  final ApiClient _apiClient;
  final AuthStorage _authStorage;

  Future<AppUser?> restoreSession() async {
    final token = await _authStorage.readToken();

    if (token == null || token.isEmpty) {
      return null;
    }

    try {
      final response = await _apiClient.get('/auth/me', authenticated: true);

      final data = response['data'] as Map<String, dynamic>;

      return AppUser.fromJson(data['user'] as Map<String, dynamic>);
    } on ApiException catch (error) {
      if (error.statusCode == 401 || error.statusCode == 403) {
        await _authStorage.clearToken();
        return null;
      }

      rethrow;
    }
  }

  Future<AppUser> login({
    required String email,
    required String password,
  }) async {
    final response = await _apiClient.post(
      '/auth/login',
      body: {'email': email.trim(), 'password': password},
    );

    return _saveSession(response);
  }

  Future<AppUser> register({
    required String fullName,
    required String email,
    required String password,
    String phone = '',
  }) async {
    final response = await _apiClient.post(
      '/auth/register',
      body: {
        'fullName': fullName.trim(),
        'email': email.trim(),
        'password': password,
        'phone': phone.trim(),
      },
    );

    return _saveSession(response);
  }

  Future<AppUser> updateProfile({
    required String fullName,
    String? phone,
    String? address,
  }) async {
    final response = await _apiClient.put(
      '/auth/profile',
      authenticated: true,
      body: {
        'fullName': fullName.trim(),
        'phone': phone?.trim(),
        'address': address?.trim(),
      },
    );

    final data = response['data'] as Map<String, dynamic>;

    return AppUser.fromJson(data['user'] as Map<String, dynamic>);
  }

  Future<void> logout() {
    return _authStorage.clearToken();
  }

  Future<AppUser> _saveSession(Map<String, dynamic> response) async {
    final data = response['data'] as Map<String, dynamic>;

    final token = data['token']?.toString();

    if (token == null || token.isEmpty) {
      throw const ApiException('The server did not return an access token.');
    }

    await _authStorage.saveToken(token);

    return AppUser.fromJson(data['user'] as Map<String, dynamic>);
  }
}
