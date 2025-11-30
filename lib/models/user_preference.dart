/// Model untuk user preferences
class UserPreference {
  final String theme; // 'light', 'dark', 'system'
  final String lastAddress;
  final double? lastLatitude;
  final double? lastLongitude;
  final bool notificationsEnabled;
  final String lastSelectedCity;
  final DateTime lastUpdated;

  UserPreference({
    this.theme = 'system',
    this.lastAddress = '',
    this.lastLatitude,
    this.lastLongitude,
    this.notificationsEnabled = true,
    this.lastSelectedCity = 'Jakarta',
    DateTime? lastUpdated,
  }) : lastUpdated = lastUpdated ?? DateTime.now();

  Map<String, dynamic> toJson() => {
        'theme': theme,
        'lastAddress': lastAddress,
        'lastLatitude': lastLatitude,
        'lastLongitude': lastLongitude,
        'notificationsEnabled': notificationsEnabled,
        'lastSelectedCity': lastSelectedCity,
        'lastUpdated': lastUpdated.toIso8601String(),
      };

  factory UserPreference.fromJson(Map<String, dynamic> json) {
    return UserPreference(
      theme: json['theme'] ?? 'system',
      lastAddress: json['lastAddress'] ?? '',
      lastLatitude: json['lastLatitude'],
      lastLongitude: json['lastLongitude'],
      notificationsEnabled: json['notificationsEnabled'] ?? true,
      lastSelectedCity: json['lastSelectedCity'] ?? 'Jakarta',
      lastUpdated: json['lastUpdated'] != null
          ? DateTime.parse(json['lastUpdated'])
          : DateTime.now(),
    );
  }

  UserPreference copyWith({
    String? theme,
    String? lastAddress,
    double? lastLatitude,
    double? lastLongitude,
    bool? notificationsEnabled,
    String? lastSelectedCity,
  }) {
    return UserPreference(
      theme: theme ?? this.theme,
      lastAddress: lastAddress ?? this.lastAddress,
      lastLatitude: lastLatitude ?? this.lastLatitude,
      lastLongitude: lastLongitude ?? this.lastLongitude,
      notificationsEnabled: notificationsEnabled ?? this.notificationsEnabled,
      lastSelectedCity: lastSelectedCity ?? this.lastSelectedCity,
      lastUpdated: DateTime.now(),
    );
  }
}