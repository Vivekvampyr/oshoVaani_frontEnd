import 'package:flutter/material.dart';
import 'package:oshovaani/chat_screen.dart';
import 'package:oshovaani/constraints/themes.dart';
import 'package:oshovaani/providers/active_theme_providers.dart';
import 'package:oshovaani/widgets/my_app_bar.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

void main() {
  runApp(
    const ProviderScope(
      child: MyApp(),
    ),
  );
}

class MyApp extends ConsumerWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final activeTheme = ref.watch(activeThemeProvider);
    return MaterialApp(
      theme: lightTheme,
      darkTheme: darkTheme,
      debugShowCheckedModeBanner: false,
      themeMode: activeTheme == Themes.dark ? ThemeMode.dark : ThemeMode.light,
      home: const Scaffold(
        appBar: MyAppBar(),
        body: ChatScreen(),
      ),
    );
  }
}
