import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;

class RegisterView extends StatefulWidget {
  final String host;

  RegisterView({super.key, required this.host});

  @override
  State<RegisterView> createState() => _RegisterViewState();
}

class _RegisterViewState extends State<RegisterView> {
  final formKey = GlobalKey<FormState>();

  final nameController = TextEditingController();

  final passwordController = TextEditingController();

  bool showPassword = false;

  void register(BuildContext context) async {
    if (!formKey.currentState!.validate()) {
      return;
    }

    try {
      var res = await http.post(
        Uri.parse("http://${widget.host}/api/identity/user"),
        body: jsonEncode({
          "name": nameController.text,
          "password": passwordController.text,
        }),
      );
      if (res.statusCode != 200) {
        showDialog(
          context: context,
          builder: (context) {
            return AlertDialog(
              title: Text("Registration Failed"),
              content: Text(
                res.statusCode == 400
                    ? "This Username is already taken. Please change it."
                    : "Looks like we couldn't register you in! Please try again later.",
              ),
              actions: [
                FilledButton(
                  onPressed: Navigator.of(context).pop,
                  child: Text("Ok"),
                ),
              ],
            );
          },
        );
        return;
      }
    } catch (e) {
      showDialog(
        context: context,
        builder: (context) {
          return AlertDialog(
            title: Text("Registration Error"),
            content: Text(
              "Looks like we couldn't register you in! Please try again later.\n$e",
            ),
            actions: [
              FilledButton(
                onPressed: Navigator.of(context).pop,
                child: Text("Ok"),
              ),
            ],
          );
        },
      );
      return;
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Form(
        key: formKey,
        child: Padding(
          padding: const EdgeInsets.only(left: 16.0, right: 16.0),
          child: Center(
            child: ConstrainedBox(
              constraints: BoxConstraints(maxWidth: 350.0),
              child: Column(
                children: [
                  Spacer(),
                  Container(
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(16.0),
                      color: Theme.of(context).colorScheme.surfaceContainer,
                    ),
                    padding: EdgeInsets.all(16.0),
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        TextFormField(
                          controller: nameController,
                          decoration: const InputDecoration(labelText: "Name"),
                          validator: (value) {
                            if (value == null || value.isEmpty) {
                              return "Enter your username...";
                            }
                            return null;
                          },
                        ),
                        TextFormField(
                          controller: passwordController,
                          obscureText: !showPassword,
                          decoration: InputDecoration(
                            labelText: "Password",
                            suffixIcon: IconButton(
                              icon: Icon(
                                !showPassword
                                    ? Icons.visibility
                                    : Icons.visibility_off,
                              ),
                              onPressed: () {
                                setState(() {
                                  showPassword = !showPassword;
                                });
                              },
                            ),
                          ),
                          validator: (value) {
                            if (value == null || value.isEmpty) {
                              return "Enter your password...";
                            }
                            return null;
                          },
                        ),
                        Padding(
                          padding: const EdgeInsets.only(top: 16.0),
                          child: Row(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Padding(
                                padding: const EdgeInsets.only(right: 16.0),
                                child: OutlinedButton(
                                  onPressed: () {
                                    Navigator.of(context).pop();
                                  },
                                  child: Text("Cancel"),
                                ),
                              ),
                              FilledButton(
                                onPressed: () {
                                  register(context);
                                  Navigator.of(context).pop();
                                },
                                child: Text("Register"),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),
                  Spacer(),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}
