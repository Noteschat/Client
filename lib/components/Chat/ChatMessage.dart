
import 'package:flutter/material.dart';
import 'package:noteschat/dtos/ServerMessage.dart';
import 'package:noteschat/login.dart';

class Message extends StatelessWidget {
  final ServerMessage data;
  final Function(ServerMessage message) onPressed;

  const Message({super.key, required this.data, required this.onPressed});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: EdgeInsets.only(top: 8.0),
      child: GestureDetector(
        onLongPress: () => onPressed(data),
        child: Row(
          mainAxisAlignment: data.userId == user.id ? MainAxisAlignment.end : MainAxisAlignment.start,
          children: [
            Flexible( // Allows the container to be constrained within available space
              child: ConstrainedBox(
                constraints: BoxConstraints(
                  maxWidth: MediaQuery.of(context).size.width * 0.8, // Maximum width is 80% of screen width
                ),
                child: Container(
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.only(
                      topLeft: data.userId == user.id ? Radius.circular(20) : Radius.circular(0), 
                      topRight: data.userId == user.id ? Radius.circular(0) : Radius.circular(20), 
                      bottomLeft: Radius.circular(20), 
                      bottomRight: Radius.circular(20)
                    ),
                    color: data.userId == user.id
                        ? Theme.of(context).colorScheme.secondaryContainer
                        : Theme.of(context).colorScheme.tertiaryContainer,
                  ),
                  padding: const EdgeInsets.all(16.0), // Adds padding around the text
                  child: Text(
                    data.content,
                    textAlign: TextAlign.left,
                  ),
                ),
              ),
            ),
          ],
        ),
      )
    );
  }
}
