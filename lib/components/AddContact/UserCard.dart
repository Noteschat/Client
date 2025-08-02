import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:noteschat/components/Chat/ChatView.dart';
import 'package:noteschat/dtos/Chat.dart';
import 'package:noteschat/login.dart';

class UserCard extends StatelessWidget {
  final User user;
  final Function selectUser;

  const UserCard({super.key, required this.user, required this.selectUser});

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        FractionallySizedBox(
          widthFactor: 1,
          child: GestureDetector(
            onTap: () {
              selectUser();
            },
            child: Padding(
              padding: const EdgeInsets.only(top: 8.0, bottom: 8.0),
              child: Text(user.name, textAlign: TextAlign.center),
            ),
          ),
        ),
        Divider(),
      ],
    );
  }
}
