import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:oshovaani/providers/active_theme_providers.dart';
import 'package:oshovaani/widgets/theme_switch.dart';

class MyAppBar extends StatelessWidget implements PreferredSizeWidget {
  const MyAppBar({super.key});

  @override
  Widget build(BuildContext context) {
    return AppBar(
      title: Text(
        "OSHOवाणी",
        style: TextStyle(
          color: Theme.of(context).colorScheme.onPrimary,
          fontWeight: FontWeight.bold,
          fontStyle: FontStyle.italic,
        ),
      ),
      centerTitle: true,
      //elevation: 1,

      actions: [
        Row(
          children: [
            Consumer(builder: (context, ref, child) {
              return Icon(
                ref.watch(activeThemeProvider) == Themes.dark
                    ? Icons.dark_mode
                    : Icons.light_mode,
              );
            }),
            const SizedBox(
              width: 8,
            ),
            const ThemeSwitch(),
          ],
        ),
      ],
    );
  }

  @override
  Size get preferredSize => const Size.fromHeight(60);
}
