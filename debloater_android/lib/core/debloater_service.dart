// This file will contain the core logic for debloating functionality.

import 'package:device_apps/device_apps.dart';
import 'package:flutter/material.dart';
import 'dart:convert';
import 'package:path/path.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'adb.dart';
import 'config.dart';
import 'save.dart';
import 'sync.dart';
import 'theme.dart';
import 'uad_lists.dart';
import 'update.dart';
import 'utils.dart';
import 'user_settings.dart';

class DebloaterService {
  List<Application> installedApps = [];
  final ADB adb = ADB();
  final Config config = Config();
  final Save save = Save();
  final Sync sync = Sync();
  final ThemeManager themeManager = ThemeManager();
  final UadLists uadLists = UadLists();
  final Update update = Update();

  // Method to list installed applications
  Future<List<Application>> listInstalledApps() async {
    try {
      installedApps = await DeviceApps.getInstalledApplications();
      return installedApps;
    } catch (e) {
      // Handle error
      print('Error fetching installed applications: $e');
      return [];
    }
  }

  // Method to debloat a specific application
  Future<void> debloatApp(String packageName) async {
    try {
      adb.uninstallApp(packageName);
    } catch (e) {
      // Handle error
      print('Error debloating application: $e');
    }
  }

  // Method to save user settings
  Future<void> saveUserSettings(UserSettings settings) async {
    await save.backupData(); // Example usage of save
  }

  // Method to load user settings
  Future<UserSettings> loadUserSettings() async {
    // Load configuration and return UserSettings
    UserSettings settings =
        config.loadConfiguration(); // Call to load configuration
    return settings; // Return the loaded UserSettings
  }
}

class Package {
  final String appName;
  final String packageName;

  Package({required this.appName, required this.packageName});
}

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

// Method to save user settings
Future<void> saveUserSettings(UserSettings settings) async {
  final prefs = await SharedPreferences.getInstance();
  prefs.setString('user_settings', jsonEncode(settings.toJson()));
}

// Method to load user settings
Future<UserSettings> loadUserSettings() async {
  final prefs = await SharedPreferences.getInstance();
  final settingsString = prefs.getString('user_settings');
  if (settingsString != null) {
    return UserSettings.fromJson(jsonDecode(settingsString));
  }
  return UserSettings();
}
