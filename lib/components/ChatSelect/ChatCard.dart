import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:noteschat/components/Chat/ChatView.dart';
import 'package:noteschat/dtos/Chat.dart';
import 'package:noteschat/login.dart';

class ChatCard extends StatelessWidget {
  final Chat chat;
  final Function removeChat;
  final String host;

  const ChatCard({super.key, required this.chat, required this.removeChat, required this.host});
  
  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        FractionallySizedBox(
          widthFactor: 1,
          child: GestureDetector(
            onTap: () {
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (context) => ChatView(chatId: chat.id, host: host,)
                )
              );
            },
            onLongPress: () {
              showDialog(
                context: context,
                builder: (context) {
                  return AlertDialog(
                    title: Text("Delete Chat"),
                    content: Text("Do you really wish to delete this chat?"),
                    actions: [
                      OutlinedButton(
                        onPressed: () {
                          Navigator.of(context).pop();
                        },
                        child: Text(
                          "Cancel", 
                          style: TextStyle(
                            color: Theme.of(context).colorScheme.onSurfaceVariant
                          ),
                        )
                      ),
                      FilledButton(
                        style: ButtonStyle(
                          backgroundColor: WidgetStateColor.resolveWith((states) {
                            if (states.contains(WidgetState.pressed)) {
                              return Theme.of(context).colorScheme.error.withValues(alpha: 0.7); // Error color when pressed
                            }
                            return Theme.of(context).colorScheme.error; // Default error color
                          }),
                        ),
                        onPressed: () async {
                          await http.delete(Uri.parse("http://${host}/api/chat/storage/${chat.id}"), headers: headers);
                          removeChat();
                          Navigator.of(context).pop();
                        }, 
                        child: Text(
                          "Delete",
                          style: TextStyle(
                            color: Theme.of(context).colorScheme.onError
                          ),
                        )
                      )
                    ],
                  );
                }
              );
            },
            child: Padding(
              padding: const EdgeInsets.only(top: 8.0, bottom: 8.0),
              child: Text(chat.name, textAlign: TextAlign.center,),
            ),
          ),
        ),
        Divider()
      ],
    );
  }
}