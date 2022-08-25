import 'package:hive/hive.dart';
part 'event_data.g.dart';

@HiveType(typeId: 1)
class EventData extends HiveObject {
  @HiveField(0)
  bool fullDay;
  @HiveField(1)
  String text;
  @HiveField(2)
  DateTime start;
  @HiveField(3)
  DateTime end;
  @HiveField(4)
  int color;
  @HiveField(5)
  bool finished;

  EventData(
      {required this.fullDay,
      required this.start,
      required this.end,
      required this.color,
      required this.text,
      required this.finished});

  EventData copyWith({DateTime? otherStart, DateTime? otherEnd}) {
    return EventData(
        fullDay: fullDay,
        start: otherStart ?? start,
        end: otherEnd ?? end,
        color: color,
        text: text,
        finished: finished);
  }

  EventData edit(
      {required bool fullDay,
      required DateTime start,
      required DateTime end,
      required int color,
      required String text,
      required bool finished}) {
    this.fullDay = fullDay;
    this.start = start;
    this.end = end;
    this.color = color;
    this.text = text;
    this.finished = finished;
    return this;
  }

  EventData toggleFinished() {
    finished = !finished;
    return this;
  }

  @override
  toString() {
    return {'fullDay': fullDay, 'start': start, 'end': end, 'color': color, 'text': text}.toString();
  }
}
