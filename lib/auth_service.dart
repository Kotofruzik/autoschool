import 'dart:io';
import 'package:flutter/material.dart';
import 'package:minio/io.dart';
import 'package:parse_server_sdk_flutter/parse_server_sdk_flutter.dart';
import 'package:image_picker/image_picker.dart';
import 'package:minio/minio.dart';

class AuthService extends ChangeNotifier {
  ParseUser? _currentUser;
  bool _isLoading = false;

  ParseUser? get currentUser => _currentUser;
  bool get isLoading => _isLoading;

  AuthService() {
    _loadCurrentUser(); // загружаем пользователя при старте
  }

  void setCurrentUser(ParseUser user) {
    _currentUser = user;
    notifyListeners();
  }

  Future<void> _loadCurrentUser() async {
    _currentUser = await ParseUser.currentUser() as ParseUser?;
    notifyListeners();
  }

  Future<ParseUser?> getCurrentUser() async {
    return await ParseUser.currentUser() as ParseUser?;
  }

  // Регистрация (без фото)
  Future<String?> registerWithEmail({
    required String email,
    required String password,
    required String name,
    required String phone,
  }) async {
    _setLoading(true);
    try {
      var user = ParseUser(email, password, email);
      user.set('name', name);
      user.set('phone', phone);

      var response = await user.signUp();
      if (response.success) {
        _currentUser = response.result;
        notifyListeners(); // <-- обязательно уведомляем
        return null;
      } else {
        return response.error!.message;
      }
    } catch (e) {
      return 'Ошибка: $e';
    } finally {
      _setLoading(false);
    }
  }

  // Вход
  Future<String?> loginWithEmail(String email, String password) async {
    _setLoading(true);
    try {
      var user = ParseUser(email, password, email);
      var response = await user.login();
      if (response.success) {
        _currentUser = response.result;
        notifyListeners(); // <-- обязательно уведомляем
        return null;
      } else {
        return response.error!.message;
      }
    } catch (e) {
      return 'Ошибка: $e';
    } finally {
      _setLoading(false);
    }
  }

  // Загрузка фото в Yandex Object Storage (Minio 3.5.8)
  Future<String?> uploadProfilePhoto(XFile image) async {
    if (_currentUser == null) return 'Пользователь не авторизован';
    try {
      final file = File(image.path);
      final userId = _currentUser!.objectId!;

      // --- НАСТРОЙКИ YANDEX CLOUD (ЗАМЕНИТЕ НА СВОИ) ---
      const accessKey = 'YCAJEyTjVJ5hPHjDHwCdRFvqu';          // Access Key ID
      const secretKey = 'YCPsjstQHgXYSe0ZwRRl-fKFUCSnKMAj5WtyGJ4W';          // Secret Key
      const bucket = 'autoschoolbtgp';              // имя вашего бакета
      const region = 'ru-central1';
      const endpoint = 'storage.yandexcloud.net';
      // ---------------------------------------------

      final minio = Minio(
        endPoint: endpoint,
        port: 443,
        useSSL: true,
        accessKey: accessKey,
        secretKey: secretKey,
        region: region,
      );

      final key = 'users/$userId/${DateTime.now().millisecondsSinceEpoch}.jpg';

      await minio.fPutObject(
        bucket,
        key,
        file.path,
        metadata: {'Content-Type': 'image/jpeg'},
      );

      final photoUrl = 'https://$endpoint/$bucket/$key';
      print('✅ Фото успешно загружено: $photoUrl');

      _currentUser!.set('photo', photoUrl);
      await _currentUser!.save();
      notifyListeners(); // уведомляем HomePage об обновлении фото
      return null;
    } catch (e) {
      print('❌ Ошибка загрузки фото: $e');
      return 'Ошибка загрузки фото: $e';
    }
  }

  // Выход
  Future<void> signOut() async {
    if (_currentUser != null) {
      await _currentUser!.logout();
      _currentUser = null;
      notifyListeners();
    }
  }

  void _setLoading(bool value) {
    _isLoading = value;
    notifyListeners();
  }
}