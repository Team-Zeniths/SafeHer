/// Represents a community safety post/alert.
///
/// TODO: Sync field names with backend `/community/posts` endpoint.
class CommunityPostModel {
  const CommunityPostModel({
    required this.id,
    required this.authorName,
    required this.content,
    required this.createdAt,
    this.authorAvatarUrl,
    this.category = PostCategory.safety,
    this.likeCount = 0,
    this.commentCount = 0,
    this.isLikedByMe = false,
    this.location,
    this.imageUrl,
    this.isAlert = false,
  });

  final String id;
  final String authorName;
  final String content;
  final DateTime createdAt;
  final String? authorAvatarUrl;
  final PostCategory category;
  final int likeCount;
  final int commentCount;
  final bool isLikedByMe;
  final String? location;
  final String? imageUrl;
  final bool isAlert;

  factory CommunityPostModel.fromJson(Map<String, dynamic> json) {
    return CommunityPostModel(
      id: json['id']?.toString() ?? '',
      authorName: json['authorName'] as String? ?? 'Anonymous',
      content: json['content'] as String? ?? '',
      createdAt: DateTime.tryParse(json['createdAt'] as String? ?? '') ?? DateTime.now(),
      authorAvatarUrl: json['authorAvatarUrl'] as String?,
      category: PostCategory.values.firstWhere(
        (c) => c.name == json['category'],
        orElse: () => PostCategory.safety,
      ),
      likeCount: json['likeCount'] as int? ?? 0,
      commentCount: json['commentCount'] as int? ?? 0,
      isLikedByMe: json['isLikedByMe'] as bool? ?? false,
      location: json['location'] as String?,
      imageUrl: json['imageUrl'] as String?,
      isAlert: json['isAlert'] as bool? ?? false,
    );
  }

  Map<String, dynamic> toJson() => {
        'id': id,
        'authorName': authorName,
        'content': content,
        'createdAt': createdAt.toIso8601String(),
        'authorAvatarUrl': authorAvatarUrl,
        'category': category.name,
        'likeCount': likeCount,
        'commentCount': commentCount,
        'isLikedByMe': isLikedByMe,
        'location': location,
        'imageUrl': imageUrl,
        'isAlert': isAlert,
      };

  CommunityPostModel copyWith({
    int? likeCount,
    int? commentCount,
    bool? isLikedByMe,
  }) {
    return CommunityPostModel(
      id: id,
      authorName: authorName,
      content: content,
      createdAt: createdAt,
      authorAvatarUrl: authorAvatarUrl,
      category: category,
      likeCount: likeCount ?? this.likeCount,
      commentCount: commentCount ?? this.commentCount,
      isLikedByMe: isLikedByMe ?? this.isLikedByMe,
      location: location,
      imageUrl: imageUrl,
      isAlert: isAlert,
    );
  }
}

enum PostCategory { safety, alert, tip, question, general }

extension PostCategoryExtension on PostCategory {
  String get label {
    switch (this) {
      case PostCategory.safety:
        return 'Safety';
      case PostCategory.alert:
        return '🚨 Alert';
      case PostCategory.tip:
        return '💡 Tip';
      case PostCategory.question:
        return '❓ Question';
      case PostCategory.general:
        return 'General';
    }
  }
}
