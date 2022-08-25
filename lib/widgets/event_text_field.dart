import 'package:flutter/material.dart';
import 'package:todo/utils/centre.dart';

class EventNameTextField extends StatefulWidget {
  final TextEditingController controller;
  const EventNameTextField({super.key, required this.controller});
  @override
  State<EventNameTextField> createState() => _EventNameTextFieldState();
}

class _EventNameTextFieldState extends State<EventNameTextField> {
  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: EdgeInsets.fromLTRB(Centre.safeBlockHorizontal * 4, Centre.safeBlockVertical * 2, 0, Centre.safeBlockVertical * 2),
      child: SizedBox(
        width: Centre.safeBlockHorizontal * 60,
        child: TextField(
          style: Centre.dialogText.copyWith(fontSize: Centre.safeBlockHorizontal * 5),
          decoration: InputDecoration(
            hintText: "Event name",
            hintStyle: Centre.dialogText.copyWith(color: Colors.grey, fontSize: Centre.safeBlockHorizontal * 5),
            border: OutlineInputBorder(borderSide: BorderSide(color: Colors.white), borderRadius: BorderRadius.circular(5)),
            focusedBorder: OutlineInputBorder(borderSide: BorderSide(color: Colors.white), borderRadius: BorderRadius.circular(5)),
            enabledBorder: OutlineInputBorder(borderSide: BorderSide(color: Colors.white), borderRadius: BorderRadius.circular(5)),
            isDense: true,
          ),
        ),
      ),
    );
  }
}
