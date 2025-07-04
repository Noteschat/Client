// ignore_for_file: avoid_print
import 'package:flutter/material.dart';
import 'package:dynamic_color/dynamic_color.dart';
import 'package:noteschat/components/ChatSelect/ChatSelect.dart';
import 'package:noteschat/login.dart';

String host = "localhost";

void main() {
  WidgetsFlutterBinding.ensureInitialized();

  runApp(NotesChat());
}

class NotesChat extends StatelessWidget {
  const NotesChat({super.key});

  @override
  Widget build(BuildContext context) {
    return DynamicColorBuilder(
      builder: (ColorScheme? lightDynamic, ColorScheme? darkDynamic) {
        ColorScheme lightColorScheme;
        ColorScheme darkColorScheme;

        if (lightDynamic != null && darkDynamic != null) {
          lightColorScheme = lightDynamic;
          darkColorScheme = darkDynamic;
        } else {
          lightColorScheme = ColorScheme.fromSeed(seedColor: Colors.blue);
          darkColorScheme = ColorScheme.fromSeed(
            seedColor: Colors.blue,
            brightness: Brightness.dark,
          );
        }

        return MaterialApp(
          title: 'Chat Notes',
          theme: ThemeData(colorScheme: lightColorScheme, useMaterial3: true),
          darkTheme: ThemeData(
            colorScheme: darkColorScheme,
            useMaterial3: true,
          ),
          home: LoginView(
            onLogin: (context) {
              Navigator.pushReplacement(
                context,
                MaterialPageRoute(
                  builder: (context) => ChatSelect(host: host,)
                )
              );
            },
            host: host
          ),
        );
      },
    );
  }
}