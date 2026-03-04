import 'dart:io';
import 'package:flutter/material.dart';
import 'package:minio/io.dart';
import 'package:parse_server_sdk_flutter/parse_server_sdk_flutter.dart';
import 'package:image_picker/image_picker.dart';
import 'package:minio/minio.dart';
import 'package:google_sign_in/google_sign_in.dart';

class AuthService extends ChangeNotifier {
  ParseUser? _currentUser;
  bool _isLoading = false;

  ParseUser? get currentUser => _currentUser;
  bool get isLoading => _isLoading;

  AuthService() {
    _loadCurrentUser();
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
    required String surname,
    required String firstname,
    required String patronymic,
    required String phone,
  }) async {
    _setLoading(true);
    try {
      var user = ParseUser(email, password, email);
      user.set('surname', surname);
      user.set('firstname', firstname);
      user.set('patronymic', patronymic);
      user.set('phone', phone);

      var response = await user.signUp();
      if (response.success) {
        _currentUser = response.result;
        notifyListeners();
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

  // Вход по email/паролю
  Future<String?> loginWithEmail(String email, String password) async {
    _setLoading(true);
    try {
      var user = ParseUser(email, password, email);
      var response = await user.login();
      if (response.success) {
        _currentUser = response.result;
        notifyListeners();
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

  Future<String?> loginWithGoogle() async {
    _setLoading(true);
    try {
      final GoogleSignIn googleSignIn = GoogleSignIn();
      final GoogleSignInAccount? googleUser = await googleSignIn.signIn();
      if (googleUser == null) {
        // пользователь отменил вход – возвращаем специальное значение
        return 'CANCELLED';
      }

      final GoogleSignInAuthentication googleAuth = await googleUser.authentication;

      final response = await ParseUser.loginWith(
        'google',
        {
          'id': googleUser.id,
          'id_token': googleAuth.idToken,
        },
      );

      if (response.success) {
        _currentUser = response.result;

        final currentUser = _currentUser!;
        bool needsUpdate = false;

        // Сохраняем email, если его нет
        if (currentUser.get('email') == null && googleUser.email != null) {
          currentUser.set('email', googleUser.email);
          needsUpdate = true;
        }

        // Сохраняем имя из Google, если поля пусты
        if (currentUser.get('surname') == null && currentUser.get('firstname') == null) {
          final displayName = googleUser.displayName ?? '';
          final parts = displayName.trim().split(RegExp(r'\s+'));
          if (parts.isNotEmpty) {
            if (parts.length >= 2) {
              currentUser.set('firstname', parts[0]);
              currentUser.set('surname', parts.sublist(1).join(' '));
            } else {
              currentUser.set('firstname', displayName);
            }
            needsUpdate = true;
          }
        }

        // Сохраняем фото из Google, если у пользователя ещё нет фото
        if (currentUser.get('photo') == null && googleUser.photoUrl != null) {
          currentUser.set('photo', googleUser.photoUrl);
          needsUpdate = true;
        }

        if (needsUpdate) {
          await currentUser.save();
        }

        notifyListeners();
        return null; // успех
      } else {
        return response.error!.message; // ошибка
      }
    } catch (e) {
      print('❌ Ошибка входа через Google: $e');
      return 'Ошибка входа через Google: $e';
    } finally {
      _setLoading(false);
    }
  }

  // Загрузка фото в Yandex Object Storage (Minio)
  Future<String?> uploadProfilePhoto(XFile image) async {
    if (_currentUser == null) return 'Пользователь не авторизован';
    try {
      final file = File(image.path);
      final userId = _currentUser!.objectId!;

      // --- НАСТРОЙКИ YANDEX CLOUD (ЗАМЕНИТЕ НА СВОИ) ---
      const accessKey = 'YCAJEyTjVJ5hPHjDHwCdRFvqu';
      const secretKey = 'YCPsjstQHgXYSe0ZwRRl-fKFUCSnKMAj5WtyGJ4W';
      const bucket = 'autoschoolbtgp';
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
      notifyListeners();
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
      // Выходим из Google Sign-In, чтобы при следующем входе можно было выбрать аккаунт
      final GoogleSignIn googleSignIn = GoogleSignIn();
      if (await googleSignIn.isSignedIn()) {
        await googleSignIn.signOut();
      }
      notifyListeners();
    }
  }

  void _setLoading(bool value) {
    _isLoading = value;
    notifyListeners();
  }
}