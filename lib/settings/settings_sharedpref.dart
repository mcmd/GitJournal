import 'package:collection/collection.dart';
import 'package:meta/meta.dart';
import 'package:shared_preferences/shared_preferences.dart';

abstract class SettingsSharedPref {
  @protected
  String get id;

  @protected
  SharedPreferences get pref;

  @protected
  String? getString(String key) {
    return pref.getString(id + '_' + key);
  }

  @protected
  bool? getBool(String key) {
    return pref.getBool(id + '_' + key);
  }

  @protected
  List<String>? getStringList(String key) {
    return pref.getStringList(id + '_' + key);
  }

  @protected
  Set<String>? getStringSet(String key) {
    return getStringList(key)?.toSet();
  }

  @protected
  int? getInt(String key) {
    return pref.getInt(id + '_' + key);
  }

  @protected
  double? getDouble(String key) {
    return pref.getDouble(id + '_' + key);
  }

  @protected
  Future<void> setString(String key, String value, String? defaultValue) async {
    key = id + '_' + key;
    if (value == defaultValue) {
      await pref.remove(key);
    } else {
      await pref.setString(key, value);
    }
  }

  @protected
  Future<void> setBool(String key, bool value, bool defaultValue) async {
    key = id + '_' + key;
    if (value == defaultValue) {
      await pref.remove(key);
    } else {
      await pref.setBool(key, value);
    }
  }

  @protected
  Future<void> setInt(String key, int value, int defaultValue) async {
    key = id + '_' + key;
    if (value == defaultValue) {
      await pref.remove(key);
    } else {
      await pref.setInt(key, value);
    }
  }

  @protected
  Future<void> setDouble(String key, double value, double defaultValue) async {
    key = id + '_' + key;
    if (value == defaultValue) {
      await pref.remove(key);
    } else {
      await pref.setDouble(key, value);
    }
  }

  @protected
  Future<void> setStringSet(
      String key, Set<String> value, Set<String> defaultValue) async {
    key = id + '_' + key;

    final bool Function(Set<dynamic>, Set<dynamic>) eq =
        const SetEquality().equals;

    if (eq(value, defaultValue)) {
      await pref.remove(key);
    } else {
      await pref.setStringList(key, value.toList());
    }
  }
}
