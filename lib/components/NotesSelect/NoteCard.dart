import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:noteschat/components/Note/NoteView.dart';
import 'package:noteschat/dtos/Note.dart';
import 'package:noteschat/login.dart';

class NoteCard extends StatelessWidget {
  final AllNote note;
  final Function removeNote;
  final String host;
  final String chatId;

  const NoteCard({super.key, required this.chatId, required this.note, required this.removeNote, required this.host});
  
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
                  builder: (context) => NoteView(allNote: note, chatId: chatId, host: host)
                )
              );
            },
            onLongPress: () {
              showDialog(
                context: context,
                builder: (context) {
                  return AlertDialog(
                    title: Text("Delete Note"),
                    content: Text("Do you really wish to delete this note?"),
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
                          await http.delete(Uri.parse("http://${host}/api/notes/storage/${chatId}/${note.id}"), headers: headers);
                          removeNote();
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
              child: Text(note.name, textAlign: TextAlign.center,),
            ),
          ),
        ),
        Divider()
      ],
    );
  }
}