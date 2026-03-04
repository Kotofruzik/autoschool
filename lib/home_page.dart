import 'package:flutter/material.dart';
import 'package:parse_server_sdk_flutter/parse_server_sdk_flutter.dart';
import 'package:provider/provider.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:autoschool_btgp/auth_service.dart';

class HomePage extends StatelessWidget {
  Future<void> _signOut(BuildContext context) async {
    final auth = Provider.of<AuthService>(context, listen: false);
    await auth.signOut();
    Navigator.pushReplacementNamed(context, '/login');
  }

  String _getFullName(ParseUser? user) {
    if (user == null) return 'Без имени';
    String surname = user.get('surname') ?? '';
    String firstname = user.get('firstname') ?? '';
    String patronymic = user.get('patronymic') ?? '';
    // Собираем ФИО, пропуская пустые части
    List<String> parts = [surname, firstname, patronymic].where((s) => s.isNotEmpty).toList();
    return parts.isNotEmpty ? parts.join(' ') : 'Без имени';
  }

  @override
  Widget build(BuildContext context) {
    final auth = Provider.of<AuthService>(context);
    final ParseUser? user = auth.currentUser;
    final String? photoUrl = user?.get('photo');

    return Scaffold(
      appBar: AppBar(
        title: const Text('Профиль'),
        actions: [
          IconButton(
            icon: const Icon(Icons.exit_to_app),
            onPressed: () => _signOut(context),
          ),
        ],
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            const SizedBox(height: 20),
            Center(
              child: Container(
                width: 120,
                height: 120,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  border: Border.all(color: Colors.blue, width: 2),
                ),
                child: ClipOval(
                  child: photoUrl != null
                      ? CachedNetworkImage(
                    imageUrl: photoUrl,
                    fit: BoxFit.cover,
                    placeholder: (context, url) => Container(
                      color: Colors.grey[200],
                      child: const Icon(Icons.person, size: 60, color: Colors.grey),
                    ),
                    errorWidget: (context, url, error) => Container(
                      color: Colors.grey[200],
                      child: const Icon(Icons.broken_image, size: 60, color: Colors.grey),
                    ),
                  )
                      : Container(
                    color: Colors.grey[200],
                    child: const Icon(Icons.person, size: 60, color: Colors.grey),
                  ),
                ),
              ),
            ),
            const SizedBox(height: 20),
            Text(
              _getFullName(user),
              style: const TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 10),
            Card(
              child: ListTile(
                leading: const Icon(Icons.email),
                title: const Text('Email'),
                subtitle: Text(user?.get('email') ?? ''),
              ),
            ),
            Card(
              child: ListTile(
                leading: const Icon(Icons.phone),
                title: const Text('Телефон'),
                subtitle: Text(user?.get('phone') ?? 'Не указан'),
              ),
            ),
            if (user?.createdAt != null)
              Card(
                child: ListTile(
                  leading: const Icon(Icons.calendar_today),
                  title: const Text('Дата регистрации'),
                  subtitle: Text(
                      '${user!.createdAt!.day}.${user.createdAt!.month}.${user.createdAt!.year}'),
                ),
              ),
          ],
        ),
      ),
    );
  }
}