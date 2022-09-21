import 'package:flutter/material.dart';
import 'package:todo/utils/centre.dart';

class UnorderedPage extends StatelessWidget {
  const UnorderedPage({super.key});

  @override
  Widget build(BuildContext context) {
    Centre().init(context);
    return SafeArea(
        child: Scaffold(
      body: Column(
        children: [
          Text(
            "Near Future",
            style: Centre.todoSemiTitle,
          ),
          ReorderableListView(children: [], onReorder: (int old, int news) {})
        ],
      ),
    ));
  }
}
