import 'package:flutter/material.dart';
import 'package:parse_server_sdk_flutter/parse_server_sdk_flutter.dart';
import 'package:provider/provider.dart';
import 'package:autoschool_btgp/login_page.dart';
import 'package:autoschool_btgp/register_page.dart';
import 'package:autoschool_btgp/photo_upload_page.dart';
import 'package:autoschool_btgp/auth_service.dart';

import 'package:autoschool_btgp/student_home_page.dart';
import 'package:autoschool_btgp/instructor_home_page.dart';
import 'package:autoschool_btgp/admin_home_page.dart';

import 'package:autoschool_btgp/theme_provider.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  const keyApplicationId = 'qCxbZic6eqme0pvScG5jLoCxDUxztB9FGuiXhEiy';
  const keyClientKey = '50yEotCNReUkwSd7nhVmhYnoZspmLcbizp1GJC3v';
  const keyServerUrl = 'https://parseapi.back4app.com';

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
        ChangeNotifierProvider(create: (_) => ThemeProvider()),
      ],
      child: Consumer<ThemeProvider>(
        builder: (context, themeProvider, child){
          return MaterialApp(
            title: 'Автошкола',
            debugShowCheckedModeBanner: false,
            theme: themeProvider.getThemeData(),
            darkTheme: ThemeData.dark(),
            themeMode: ThemeMode.system,
            initialRoute: '/',
            routes: {
              '/': (context) => AuthWrapper(),
              '/login': (context) => LoginPage(),
              '/register': (context) => RegisterPage(),
              '/photo-upload': (context) => PhotoUploadPage(),
            },
          );
        },
      ),
    );
  }
}

class AuthWrapper extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    final auth = Provider.of<AuthService>(context);

    if(auth.currentUser != null && auth.currentUser!.sessionToken != null) {
      final role = auth.currentUser!.get('role') ?? 'student';
      switch (role) {
        case 'admin':
          return AdminHomePage();
        case 'instructor':
          return InstructorHomePage();
        case 'student':
        default:
          return StudentHomePage();
      }
    }
    return LoginPage();
  }
}