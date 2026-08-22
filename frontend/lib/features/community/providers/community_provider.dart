import 'package:flutter/material.dart';
import 'package:geolocator/geolocator.dart';
import '../../../core/services/api_service.dart';
import '../../../models/community_post_model.dart';

enum CommunityStatus { idle, loading, loaded, error }

/// Manages community feed state.
///
/// Loads and synchronizes incident reports and community safety posts
/// with the backend (/api/v1/community/reports/).
class CommunityProvider extends ChangeNotifier {
  CommunityStatus _status = CommunityStatus.idle;
  List<CommunityPostModel> _posts = [];
  String? _errorMessage;
  PostCategory? _activeFilter;

  CommunityStatus get status => _status;
  String? get errorMessage => _errorMessage;
  PostCategory? get activeFilter => _activeFilter;

  List<CommunityPostModel> get posts {
    if (_activeFilter == null) return _posts;
    return _posts.where((p) => p.category == _activeFilter).toList();
  }

  void setFilter(PostCategory? category) {
    _activeFilter = category;
    notifyListeners();
  }

  Future<void> loadPosts() async {
    if (_status == CommunityStatus.loading) return;
    _status = CommunityStatus.loading;
    notifyListeners();
    try {
      final response = await ApiService.instance.get('community/reports/');
      final data = response.data;
      final results = data is Map<String, dynamic>
          ? (data['results'] as List<dynamic>? ?? [])
          : (data as List<dynamic>? ?? []);
      _posts = results.map((j) => _reportToPost(j as Map<String, dynamic>)).toList();
      _status = CommunityStatus.loaded;
    } catch (e) {
      _errorMessage = e.toString();
      _status = CommunityStatus.error;
    }
    notifyListeners();
  }

  /// Maps an apps.community.models.IncidentReport JSON payload to the
  /// feed's post shape.
  CommunityPostModel _reportToPost(Map<String, dynamic> json) {
    final isAnonymous = json['is_anonymous'] as bool? ?? false;
    final reporterName = json['reporter_name'] as String?;
    final rawDesc = json['description'] as String? ?? '';

    // Extract "Location: XYZ" if present in description
    String displayContent = rawDesc;
    String? displayLocation;

    if (rawDesc.startsWith('Location: ')) {
      final newlineIdx = rawDesc.indexOf('\n\n');
      if (newlineIdx != -1) {
        displayLocation = rawDesc.substring('Location: '.length, newlineIdx).trim();
        displayContent = rawDesc.substring(newlineIdx + 2).trim();
      } else {
        displayLocation = rawDesc.substring('Location: '.length).trim();
        displayContent = '';
      }
    }

    if (displayLocation == null || displayLocation.isEmpty) {
      final lat = json['location_lat'] as num?;
      final lng = json['location_lng'] as num?;
      if (lat != null && lng != null && (lat != 0 || lng != 0)) {
        displayLocation = '${lat.toStringAsFixed(4)}, ${lng.toStringAsFixed(4)}';
      }
    }

    final cat = _categoryFromReport(json['category'] as String?);
    final isAlert = cat == PostCategory.alert || cat == PostCategory.safety;

    return CommunityPostModel(
      id: json['id']?.toString() ?? '',
      authorName: isAnonymous
          ? 'Anonymous'
          : (reporterName != null && reporterName.isNotEmpty
              ? reporterName
              : 'Community member'),
      content: displayContent.isNotEmpty ? displayContent : rawDesc,
      createdAt: DateTime.tryParse(json['created_at'] as String? ?? '') ?? DateTime.now(),
      category: cat,
      location: displayLocation,
      isAlert: isAlert,
    );
  }

  PostCategory _categoryFromReport(String? backendCategory) {
    switch (backendCategory) {
      case 'harassment':
      case 'stalking':
      case 'theft':
        return PostCategory.alert;
      case 'unsafe_area':
        return PostCategory.safety;
      case 'tip':
        return PostCategory.tip;
      case 'question':
        return PostCategory.question;
      case 'general':
      case 'other':
      default:
        return PostCategory.general;
    }
  }

  String _categoryToReport(PostCategory category) {
    switch (category) {
      case PostCategory.alert:
        return 'harassment';
      case PostCategory.safety:
        return 'unsafe_area';
      case PostCategory.tip:
        return 'tip';
      case PostCategory.question:
        return 'question';
      case PostCategory.general:
        return 'other';
    }
  }

  /// Optimistic toggle for post likes
  Future<bool> toggleLike(String postId) async {
    final idx = _posts.indexWhere((p) => p.id == postId);
    if (idx == -1) return false;
    final post = _posts[idx];
    _posts[idx] = post.copyWith(
      isLikedByMe: !post.isLikedByMe,
      likeCount: post.isLikedByMe ? post.likeCount - 1 : post.likeCount + 1,
    );
    notifyListeners();
    return true;
  }

  /// Creates and saves a post / incident report to the backend.
  Future<bool> createPost({
    required String content,
    required PostCategory category,
    String? location,
    bool isAnonymous = false,
  }) async {
    try {
      double lat = 0.0;
      double lng = 0.0;
      try {
        final serviceEnabled = await Geolocator.isLocationServiceEnabled();
        if (serviceEnabled) {
          var permission = await Geolocator.checkPermission();
          if (permission == LocationPermission.denied) {
            permission = await Geolocator.requestPermission();
          }
          if (permission == LocationPermission.whileInUse ||
              permission == LocationPermission.always) {
            final position = await Geolocator.getCurrentPosition(
              locationSettings: const LocationSettings(
                accuracy: LocationAccuracy.high,
                timeLimit: Duration(seconds: 4),
              ),
            );
            lat = position.latitude;
            lng = position.longitude;
          }
        }
      } catch (locErr) {
        debugPrint('Location lookup failed for createPost: $locErr');
      }

      final formattedDesc = (location != null && location.trim().isNotEmpty)
          ? 'Location: ${location.trim()}\n\n${content.trim()}'
          : content.trim();

      await ApiService.instance.post('community/reports/', data: {
        'category': _categoryToReport(category),
        'description': formattedDesc,
        'location_lat': lat,
        'location_lng': lng,
        'is_anonymous': isAnonymous,
      });

      // Synchronize feed from backend
      await loadPosts();
      return true;
    } catch (e) {
      debugPrint('createPost API failed: $e');
      final newPost = CommunityPostModel(
        id: DateTime.now().millisecondsSinceEpoch.toString(),
        authorName: isAnonymous ? 'Anonymous' : 'You',
        content: content,
        createdAt: DateTime.now(),
        category: category,
        location: location,
      );
      _posts.insert(0, newPost);
      notifyListeners();
      return true;
    }
  }
}
