import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:noteschat/register.dart';
import 'package:shared_preferences/shared_preferences.dart';

String sessionId = "";
var headers = <String, String>{"Cookie": "sessionId=$sessionId"};

late User user;

void logout() {
  sessionId = "";
  user = User(id: "", name: "");
}

class LoginView extends StatefulWidget {
  final Function(BuildContext context) onLogin;
  final String host;

  LoginView({super.key, required this.onLogin, required this.host});

  @override
  State<LoginView> createState() => _LoginViewState();
}

class _LoginViewState extends State<LoginView> {
  final formKey = GlobalKey<FormState>();

  final nameController = TextEditingController();

  final passwordController = TextEditingController();

  bool showPassword = false;
  bool loadingData = true;

  LoginData? loginData;

  _LoginViewState() {
    fetchData();
  }

  void fetchData() async {
    loginData = await loadLoginData();

    if (loginData != null) {
      setState(() {
        nameController.text = loginData!.name;
        passwordController.text = loginData!.password;
      });
    }

    setState(() {
      loadingData = false;
    });
  }

  void login(BuildContext context) async {
    if (!formKey.currentState!.validate()) {
      return;
    }

    loginData = LoginData(
      password: passwordController.text,
      name: nameController.text,
    );

    try {
      var res = await http.post(
        Uri.parse("http://${widget.host}/api/identity/login"),
        body: jsonEncode({
          "name": loginData!.name,
          "password": loginData!.password,
        }),
      );
      if (res.statusCode != 200) {
        showDialog(
          context: context,
          builder: (context) {
            return AlertDialog(
              title: Text("Login Failed"),
              content: Text(
                "Your Username and/or Password are incorrect. Please check them and try again.",
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
      var cookie = res.headers['set-cookie'];
      sessionId = cookie?.split('sessionId=')[1].split(';')[0] ?? "";

      loginData!.save();
    } catch (e) {
      showDialog(
        context: context,
        builder: (context) {
          return AlertDialog(
            title: Text("Login Error"),
            content: Text(
              "Looks like we couldn't log you in! Please try again later.\n$e",
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

    try {
      var userRes = await http.get(
        Uri.parse("http://${widget.host}/api/identity/login/valid"),
        headers: headers,
      );
      if (userRes.statusCode != 200) {
        showDialog(
          context: context,
          builder: (context) {
            return AlertDialog(
              title: Text("Login Failed"),
              content: Text(
                "Looks like your login data was correct, but we couldn't fetch your user data! Please contact your administrator.",
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
      user = User.fromJson(jsonDecode(userRes.body));
      widget.onLogin(context);
    } catch (e) {
      showDialog(
        context: context,
        builder: (context) {
          return AlertDialog(
            title: Text("Login Error"),
            content: Text(
              "Looks like we couldn't fetch your user data! Please try again later.\n$e",
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
      body:
          loadingData
              ? Center(child: Text("Loading..."))
              : Form(
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
                              color:
                                  Theme.of(
                                    context,
                                  ).colorScheme.surfaceContainer,
                            ),
                            padding: EdgeInsets.all(16.0),
                            child: Column(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                TextFormField(
                                  controller: nameController,
                                  decoration: const InputDecoration(
                                    labelText: "Name",
                                  ),
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
                                        padding: const EdgeInsets.only(
                                          right: 16.0,
                                        ),
                                        child: OutlinedButton(
                                          onPressed: () {
                                            Navigator.push(
                                              context,
                                              MaterialPageRoute(
                                                builder:
                                                    (context) => RegisterView(
                                                      host: widget.host,
                                                    ),
                                              ),
                                            );
                                          },
                                          child: Text("Register"),
                                        ),
                                      ),
                                      FilledButton(
                                        onPressed: () {
                                          login(context);
                                        },
                                        child: Text("Login"),
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

class User {
  final String id;
  final String name;

  User({required this.id, required this.name});

  factory User.fromJson(Map<String, dynamic> json) {
    return User(id: json['id'], name: json['name']);
  }

  Map<String, dynamic> toJson() {
    return {'id': id, 'name': name};
  }

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    return other is User && other.id == id && other.name == name;
  }

  @override
  int get hashCode => Object.hash(id, name);
}

class LoginData {
  final String password;
  final String name;

  LoginData({required this.password, required this.name});

  factory LoginData.fromJson(Map<String, dynamic> json) {
    return LoginData(password: json['password'], name: json['name']);
  }

  Map<String, dynamic> toJson() {
    return {'password': password, 'name': name};
  }

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    return other is LoginData &&
        other.password == password &&
        other.name == name;
  }

  @override
  int get hashCode => Object.hash(password, name);

  Future<void> save() async {
    final prefs = await SharedPreferences.getInstance();
    prefs.setString('notesChatLoginData', jsonEncode(this));
  }
}

Future<LoginData?> loadLoginData() async {
  final prefs = await SharedPreferences.getInstance();
  final String? json = prefs.getString('notesChatLoginData');
  if (json != null) {
    final LoginData loginData = LoginData.fromJson(jsonDecode(json));
    return loginData;
  }

  return null;
}
