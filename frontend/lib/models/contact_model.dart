/// Represents a trusted emergency contact.
///
/// TODO: Sync field names with backend `/contacts` endpoint once finalized.
class ContactModel {
  const ContactModel({
    required this.id,
    required this.name,
    required this.phone,
    this.email,
    this.avatarUrl,
    this.relationship,
    this.isPrimary = false,
    this.isNotifyOnSOS = true,
    this.isNotifyOnJourney = true,
  });

  final String id;
  final String name;
  final String phone;
  final String? email;
  final String? avatarUrl;
  final String? relationship;
  final bool isPrimary;
  final bool isNotifyOnSOS;
  final bool isNotifyOnJourney;

  factory ContactModel.fromJson(Map<String, dynamic> json) {
    return ContactModel(
      id: json['id']?.toString() ?? '',
      name: json['name'] as String? ?? '',
      phone: json['phone'] as String? ?? '',
      email: json['email'] as String?,
      avatarUrl: json['avatarUrl'] as String?,
      relationship: json['relationship'] as String?,
      isPrimary: json['isPrimary'] as bool? ?? false,
      isNotifyOnSOS: json['isNotifyOnSOS'] as bool? ?? true,
      isNotifyOnJourney: json['isNotifyOnJourney'] as bool? ?? true,
    );
  }

  Map<String, dynamic> toJson() => {
        'id': id,
        'name': name,
        'phone': phone,
        'email': email,
        'avatarUrl': avatarUrl,
        'relationship': relationship,
        'isPrimary': isPrimary,
        'isNotifyOnSOS': isNotifyOnSOS,
        'isNotifyOnJourney': isNotifyOnJourney,
      };

  ContactModel copyWith({
    String? name,
    String? phone,
    String? email,
    String? avatarUrl,
    String? relationship,
    bool? isPrimary,
    bool? isNotifyOnSOS,
    bool? isNotifyOnJourney,
  }) {
    return ContactModel(
      id: id,
      name: name ?? this.name,
      phone: phone ?? this.phone,
      email: email ?? this.email,
      avatarUrl: avatarUrl ?? this.avatarUrl,
      relationship: relationship ?? this.relationship,
      isPrimary: isPrimary ?? this.isPrimary,
      isNotifyOnSOS: isNotifyOnSOS ?? this.isNotifyOnSOS,
      isNotifyOnJourney: isNotifyOnJourney ?? this.isNotifyOnJourney,
    );
  }

  String get initials {
    final parts = name.trim().split(' ');
    if (parts.length >= 2) return '${parts[0][0]}${parts[1][0]}'.toUpperCase();
    return name[0].toUpperCase();
  }
}
