import 'package:flutter/material.dart';
import 'package:oshovaani/chat_screen.dart';
import 'package:oshovaani/constraints/themes.dart';
import 'package:oshovaani/home_screen.dart';
import 'package:oshovaani/providers/active_theme_providers.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  final prefs = await SharedPreferences.getInstance();
  final String? userName = prefs.getString('userName');
  runApp(
    ProviderScope(
      child: MyApp(
        initialScreen:
            userName == null ? const HomeScreen() : const ChatScreen(),
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
      home: initialScreen,
    );
  }
}
