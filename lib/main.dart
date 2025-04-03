import 'package:flutter/material.dart';
import 'package:oshovaani/chat_screen.dart';
import 'package:oshovaani/constraints/themes.dart';
import 'package:oshovaani/home_screen.dart';
import 'package:oshovaani/providers/active_theme_providers.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'dart:io';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  final prefs = await SharedPreferences.getInstance();
  final String? bearerToken = prefs.getString('bearer_token');
  final String? userEmail = prefs.getString('userEmail');

  // If we have both a bearer token and email, user is logged in
  final bool isLoggedIn = bearerToken != null && userEmail != null;

  runApp(
    ProviderScope(
      child: MyApp(
        initialScreen: isLoggedIn ? const ChatScreen() : const HomeScreen(),
      ),
    ),
  );
}

class MyApp extends ConsumerWidget {
  final Widget initialScreen;
  const MyApp({super.key, required this.initialScreen});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final activeTheme = ref.watch(activeThemeProvider);
    return MaterialApp(
      theme: lightTheme,
      darkTheme: darkTheme,
      debugShowCheckedModeBanner: false,
      themeMode: activeTheme == Themes.dark ? ThemeMode.dark : ThemeMode.light,
      home: WillPopScope(
        onWillPop: () async {
          if (Platform.isAndroid) {
            try {
              final result = await showDialog<bool>(
                context: context,
                barrierDismissible: false,
                builder: (BuildContext context) {
                  return AlertDialog(
                    title: const Text('Exit App'),
                    content: const Text('Are you sure you want to exit?'),
                    actions: [
                      TextButton(
                        onPressed: () => Navigator.of(context).pop(false),
                        child: const Text('No'),
                      ),
                      TextButton(
                        onPressed: () => Navigator.of(context).pop(true),
                        child: const Text('Yes'),
                      ),
                    ],
                  );
                },
              );

              if (result == true) {
                exit(0);
              }
              return false;
            } catch (e) {
              return false;
            }
          }
          return true;
        },
        child: Scaffold(
          body: HomeScreen(),
        ),
      ),
    );
  }
}
