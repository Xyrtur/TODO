import 'package:hive/hive.dart';
part 'future_todo.g.dart';

@HiveType(typeId: 2)
class FutureTodo extends HiveObject {
  @HiveField(0)
  String text;
  @HiveField(1)
  bool finished;
  @HiveField(2)
  int indents;
  @HiveField(3)
  int index;

/*
 * Full day: Whether the event spans the whole day or not (Only an optino for monthly events) 
 * Start: the starting DateTime of an event
 * End: the ending DateTime of an event
 * Color: the color chosen by the user
 * Text: the name of the event
 * Finished: Whether the user has crossed it off or not
 */
  FutureTodo({required this.indents, required this.text, required this.finished, required this.index});

  FutureTodo toggleFinished() {
    finished = !finished;
    return this;
  }

  FutureTodo changeName(String newText) {
    text = newText;
    return this;
  }

  FutureTodo indent(bool forwardIndent) {
    indents += (forwardIndent ? 1 : -1);
    return this;
  }

  FutureTodo changeIndex(int newIndex) {
    index = newIndex;
    return this;
  }

  @override
  toString() {
    return {'text': text, 'finished': finished, 'indents': indents}.toString();
  }
}
