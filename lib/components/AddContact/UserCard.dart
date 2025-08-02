import 'package:flutter/material.dart';
import 'package:noteschat/login.dart';

class UserCard extends StatelessWidget {
  final User user;
  final Function selectUser;
  final bool? showDivider;

  const UserCard({
    super.key,
    required this.user,
    required this.selectUser,
    this.showDivider,
  });

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
        showDivider != null && showDivider! == false ? Container() : Divider(),
      ],
    );
  }
}
