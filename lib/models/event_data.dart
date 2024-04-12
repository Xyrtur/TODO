import 'package:hive/hive.dart';
part 'event_data.g.dart';

// Allows Comparable to be used like a mixin, and can now sort lists of EventData
mixin Compare<T> implements Comparable<T> {
  bool operator <=(T other) => compareTo(other) <= 0;
  bool operator >=(T other) => compareTo(other) >= 0;
  bool operator <(T other) => compareTo(other) < 0;
  bool operator >(T other) => compareTo(other) > 0;
}

@HiveType(typeId: 1)
class EventData extends HiveObject with Compare<EventData> {
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
/*
 * Full day: Whether the event spans the whole day or not (Only an optino for monthly events) 
 * Start: the starting DateTime of an event
 * End: the ending DateTime of an event
 * Color: the color chosen by the user
 * Text: the name of the event
 * Finished: Whether the user has crossed it off or not
 */
  EventData(
      {required this.fullDay,
      required this.start,
      required this.end,
      required this.color,
      required this.text,
      required this.finished});

/*
 * Used to create a new Event rather than editing the actual one and specifically is used 
 * when creating a split schedule block 
 * The original is kept intact and two new events are created with 
 * different start and end times to split the original event
 */
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
  int compareTo(EventData other) {
    return start.compareTo(other.start);
  }

  @override
  toString() {
    return {
      'fullDay': fullDay,
      'start': start,
      'end': end,
      'color': color,
      'text': text
    }.toString();
  }
}
