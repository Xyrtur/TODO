import 'package:hive/hive.dart';
part 'future_todo.g.dart';

@HiveType(typeId: 2)
class FutureTodo extends HiveObject {
  @HiveField(0)
  String text;
  @HiveField(1)
  bool finished;
  @HiveField(2)
  bool indented;
  @HiveField(3)
  int index;
  @HiveField(4)
  bool todoTextEditing;

/*
 * Indented: Whether the event is indented by the user (only one indent allowed; Need more? change this implementation)
 * Text: the name of the event
 * Finished: Whether the user has crossed it off or not
 * Index: Where the user put it in the list
 */
  FutureTodo(
      {required this.indented,
      required this.text,
      required this.finished,
      required this.index,
      required this.todoTextEditing});

  FutureTodo toggleFinished() {
    finished = !finished;
    return this;
  }

  FutureTodo toggleEditing() {
    todoTextEditing = !todoTextEditing;
    return this;
  }

  FutureTodo changeName(String newText) {
    text = newText;
    return this;
  }

  FutureTodo toggleIndent() {
    indented = !indented;
    return this;
  }

  FutureTodo changeIndex(int newIndex) {
    index = newIndex;
    return this;
  }

  @override
  toString() {
    return {'text': text, 'finished': finished, 'indented': indented, 'editing': todoTextEditing}.toString();
  }
}
