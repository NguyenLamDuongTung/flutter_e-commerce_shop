import '../../../core/network/api_client.dart';
import '../domain/hero_slide.dart';

class HeroSlideRepository {
  const HeroSlideRepository(this._apiClient);

  final ApiClient _apiClient;

  Future<List<HeroSlide>> getPublicSlides() async {
    final response = await _apiClient.get('/hero-slides');
    return _parse(response['data']);
  }

  Future<List<HeroSlide>> getAdminSlides() async {
    final response = await _apiClient.get(
      '/admin/hero-slides',
      authenticated: true,
    );

    return _parse(response['data']);
  }

  Future<void> save({
    int? id,
    required HeroSlideInput input,
  }) async {
    if (id == null) {
      await _apiClient.post(
        '/admin/hero-slides',
        authenticated: true,
        body: input.toJson(),
      );
      return;
    }

    await _apiClient.put(
      '/admin/hero-slides/$id',
      authenticated: true,
      body: input.toJson(),
    );
  }

  Future<void> setActive(int id, bool isActive) async {
    await _apiClient.patch(
      '/admin/hero-slides/$id/status',
      authenticated: true,
      body: {'isActive': isActive},
    );
  }

  Future<void> delete(int id) async {
    await _apiClient.delete(
      '/admin/hero-slides/$id',
      authenticated: true,
    );
  }

  List<HeroSlide> _parse(dynamic rawData) {
    return (rawData as List? ?? const [])
        .whereType<Map>()
        .map(
          (item) => HeroSlide.fromJson(
            Map<String, dynamic>.from(item),
          ),
        )
        .toList();
  }
}