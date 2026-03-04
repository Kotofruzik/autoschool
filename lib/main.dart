import 'package:flutter/material.dart';
import 'package:parse_server_sdk_flutter/parse_server_sdk_flutter.dart';
import 'package:provider/provider.dart';
import 'package:autoschool_btgp/login_page.dart';
import 'package:autoschool_btgp/register_page.dart';
import 'package:autoschool_btgp/photo_upload_page.dart';
import 'package:autoschool_btgp/home_page.dart';
import 'package:autoschool_btgp/auth_service.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // --- КЛЮЧИ Back4App (ваши) ---
  const keyApplicationId = 'qCxbZic6eqme0pvScG5jLoCxDUxztB9FGuiXhEiy';
  const keyClientKey = '50yEotCNReUkwSd7nhVmhYnoZspmLcbizp1GJC3v';
  const keyServerUrl = 'https://parseapi.back4app.com';
  // ------------------------------

  await Parse().initialize(
    keyApplicationId,
    keyServerUrl,
    clientKey: keyClientKey,
    autoSendSessionId: true,
    debug: true,
  );

  runApp(MyApp());
}

class MyApp extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return MultiProvider(
      providers: [
        ChangeNotifierProvider(create: (_) => AuthService()),
      ],
      child: MaterialApp(
        title: 'Автошкола',
        debugShowCheckedModeBanner: false,
        theme: ThemeData(primarySwatch: Colors.blue),
        initialRoute: '/',
        routes: {
          '/': (context) => AuthWrapper(),
          '/login': (context) => LoginPage(),
          '/register': (context) => RegisterPage(),
          '/photo-upload': (context) => PhotoUploadPage(),
          '/home': (context) => HomePage(),
        },
      ),
    );
  }
}

class AuthWrapper extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    final auth = Provider.of<AuthService>(context);

    // Синхронная проверка – если пользователь уже залогинен, сразу на HomePage
    if (auth.currentUser != null && auth.currentUser!.sessionToken != null) {
      return HomePage();
    }

    // Иначе страница входа
    return LoginPage();
  }
}