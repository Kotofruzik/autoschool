import 'package:flutter/material.dart';
import 'package:parse_server_sdk/parse_server_sdk.dart';

class UsersProvider extends ChangeNotifier {
  List<ParseUser> _users = [];
  bool _isLoading = false;
  String? _error;

  List<ParseUser> get users => _users;
  bool get isLoading => _isLoading;
  String? get error => _error;

  Future<void> loadUsers({String? roleFilter, String? searchQuery, bool useCloud = false}) async {
    _setLoading(true);
    try {
      List<ParseUser>? loadedUsers;
      if (useCloud) {
        loadedUsers = await _fetchAllUsersViaCloud();
        if (roleFilter != null && roleFilter.isNotEmpty) {
          loadedUsers = loadedUsers.where((u) => u.get('role') == roleFilter).toList();
        }
        if (searchQuery != null && searchQuery.isNotEmpty) {
          final queryLower = searchQuery.toLowerCase();
          loadedUsers = loadedUsers.where((u) {
            final surname = (u.get('surname') ?? '').toString().toLowerCase();
            final firstname = (u.get('firstname') ?? '').toString().toLowerCase();
            final email = (u.get('email') ?? '').toString().toLowerCase();
            return surname.contains(queryLower) || firstname.contains(queryLower) || email.contains(queryLower);
          }).toList();
        }
      } else {
        final query = QueryBuilder<ParseUser>(ParseUser.forQuery());
        if (roleFilter != null && roleFilter.isNotEmpty) {
          query.whereEqualTo('role', roleFilter);
        }
        if (searchQuery != null && searchQuery.isNotEmpty) {
          query.whereContains('surname', searchQuery);
        }
        final response = await query.query();
        if (response.success && response.results != null) {
          loadedUsers = response.results!.cast<ParseUser>();
        } else {
          _error = response.error?.message ?? 'ошибка загрузки';
        }
      }
      if (loadedUsers != null) {
        _users = loadedUsers;
        _error = null;
      }
    } catch (e) {
      _error = e.toString();
    } finally {
      _setLoading(false);
    }
  }


  Future<List<ParseUser>> _fetchAllUsersViaCloud() async {
    final function = ParseCloudFunction('getAllUsers');
    final response = await function.execute();
    if (response.success && response.result != null) {
      final List<dynamic> results = response.result as List<dynamic>;
      return results.map((json) {
        final user = ParseUser(null, null, null);
        user.objectId = json['id'];
        user.set('email', json['email']);
        user.set('surname', json['surname']);
        user.set('firstname', json['firstname']);
        user.set('patronymic', json['patronymic']);
        user.set('phone', json['phone']);
        user.set('role', json['role']);
        user.set('photo', json['photo']);
        return user;
      }).toList();
    } else {
      throw Exception(response.error?.message ?? 'Ошибка облачной функции');
    }
  }

  Future<bool> deleteUserViaCloud(String userId) async {
    try {
      final function = ParseCloudFunction('deleteUser');
      final response = await function.execute(parameters: {'userId': userId});
      if (response.success) {
        _users.removeWhere((u) => u.objectId == userId);
        notifyListeners();
        return true;
      } else {
        _error = response.error?.message;
        return false;
      }
    } catch (e) {
      _error = (e).toString();
      return false;
    }
  }

  Future<bool> updateUserRoleViaCloud(String userId, String newRole) async {
    try {
      final function = ParseCloudFunction('updateUserRole');
      final response = await function.execute(parameters: {'userId': userId, 'newRole': newRole});
      if (response.success) {
        final index = _users.indexWhere((u) => u.objectId == userId);
        if (index != -1) {
          _users[index].set('role', newRole);
        }
        notifyListeners();
        return true;
      } else {
        _error = response.error?.message;
        return false;
      }
    } catch (e) {
      _error = (e).toString();
      return false;
    }
  }

  Future<bool> createUser ({
    required String email,
    required String password,
    required String surname,
    required String firstname,
    required String patronymic,
    required String phone,
    required String role,
}) async {
    try {
      final user = ParseUser(email, password, email);
      user.set('surname', surname);
      user.set('firstname', firstname);
      user.set('patronymic', patronymic);
      user.set('phone', phone);
      user.set('role', role);

      final response = await user.signUp();
      if (response.success) {
        _users.add(response.result);
        notifyListeners();
        return true;
      } else {
        _error = response.error?.message;
        return false;
      }
    } catch (e) {
      _error = e.toString();
      return false;
    }
  }
  void _setLoading(bool value) {
    _isLoading = value;
    notifyListeners();
  }

  void clearError() {
    _error = null;
  }
}
