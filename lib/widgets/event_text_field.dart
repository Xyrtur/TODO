import 'package:flutter/material.dart';
import 'package:todo/utils/centre.dart';

class EventNameTextField extends StatefulWidget {
  final TextEditingController controller;
  final GlobalKey formKey;
  const EventNameTextField(
      {super.key, required this.controller, required this.formKey});
  @override
  State<EventNameTextField> createState() => _EventNameTextFieldState();
}

class _EventNameTextFieldState extends State<EventNameTextField> {
  OutlineInputBorder border = OutlineInputBorder(
      borderSide: const BorderSide(color: Colors.white),
      borderRadius: BorderRadius.circular(5));
  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: EdgeInsets.fromLTRB(
          Centre.safeBlockHorizontal * 4, Centre.safeBlockVertical * 2, 0, 0),
      child: SizedBox(
        width: Centre.safeBlockHorizontal * 60,
        child: Form(
          key: widget.formKey,
          child: TextFormField(
            controller: widget.controller,
            autovalidateMode: AutovalidateMode.onUserInteraction,
            validator: (text) {
              if (text == null || text.isEmpty) {
                return 'Can\'t be empty';
              } else if (text.length > 100) {
                return 'Too long';
              }
              return null;
            },
            style: Centre.dialogText
                .copyWith(fontSize: Centre.safeBlockHorizontal * 5),
            decoration: InputDecoration(
              errorStyle: TextStyle(height: 0.5),
              hintText: "Event name",
              hintStyle: Centre.dialogText.copyWith(
                  color: Colors.grey, fontSize: Centre.safeBlockHorizontal * 5),
              border: border,
              focusedBorder: border,
              enabledBorder: border,
              isDense: true,
            ),
          ),
        ),
      ),
    );
  }
}
