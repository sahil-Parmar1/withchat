import 'personchat.dart';
import 'providers.dart';
import 'signinup.dart';
import 'package:flutter/material.dart';
import 'package:firebase_core/firebase_core.dart';
import 'homescreen.dart';
import 'usersettings.dart' as usersettings;
import 'package:provider/provider.dart';
import 'package:hive/hive.dart';
import 'package:hive_flutter/hive_flutter.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'providers.dart' as providers;
import 'firebase_options.dart';

// ...


void main() async{
    await WidgetsFlutterBinding.ensureInitialized();
    await Firebase.initializeApp(
    options: DefaultFirebaseOptions.currentPlatform,
    );
    runApp(
      MultiProvider(providers: [
        ChangeNotifierProvider(
          create: (_) => usersettings.ThemeProvider(),
        ),
        ChangeNotifierProvider(
          create: (_) => providers.ismessage(),
        ),


      ],
        child: MyApp(),
      ),

    );
}

class MyApp extends StatefulWidget {
  @override
  State<MyApp> createState() => _MyAppState();
}

class _MyAppState extends State<MyApp> {
  @override
  Widget build(BuildContext context) {
    return Consumer<usersettings.ThemeProvider>(
        builder: (context,themeProvider,child) {
          return MaterialApp(
            title: 'Flutter Google Sign-In',
            theme: themeProvider.isDarkMode ? ThemeData.dark() : ThemeData.light(),
            home: AuthCheckScreen(),
          );
        }
    );
  }
}







class AuthCheckScreen extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return FutureBuilder<User?>(
      future: _checkCurrentUser(),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return Center(child: CircularProgressIndicator());
        } else if (snapshot.hasData && snapshot.data != null) {
          //return HomeScreen();
          return PersonChatScreen(name: "sahil", phoneNumber: "92");
        } else {
          //return PersonChatScreen(name: "sahil", phoneNumber: "92");
          return HomeScreen();
          //return PhoneAuthScreen();
        }
      },
    );
  }

  Future<User?> _checkCurrentUser() async {
    return FirebaseAuth.instance.currentUser;
  }
}



