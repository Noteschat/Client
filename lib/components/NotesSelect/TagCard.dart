import 'package:flutter/material.dart';

class TagCard extends StatelessWidget {
  final String tag;
  final Function selectTag;
  final bool? showDivider;

  const TagCard({
    super.key,
    required this.tag,
    required this.selectTag,
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
              selectTag();
            },
            child: Padding(
              padding: const EdgeInsets.only(top: 8.0, bottom: 8.0),
              child: Text(tag, textAlign: TextAlign.center),
            ),
          ),
        ),
        showDivider != null && showDivider! == false ? Container() : Divider(),
      ],
    );
  }
}
