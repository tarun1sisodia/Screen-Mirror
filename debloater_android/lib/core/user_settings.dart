// User settings management

class UserSettings {
  bool notificationsEnabled;
  String theme;

  UserSettings({this.notificationsEnabled = true, this.theme = 'light'});

  Map<String, dynamic> toJson() {
    return {'notificationsEnabled': notificationsEnabled, 'theme': theme};
  }

  static UserSettings fromJson(Map<String, dynamic> json) {
    return UserSettings(
      notificationsEnabled: json['notificationsEnabled'] ?? true,
      theme: json['theme'] ?? 'light',
    );
  }
}
