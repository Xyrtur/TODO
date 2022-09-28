import 'dart:io';
import 'package:intl/number_symbols_data.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:hive/hive.dart';
import 'package:hive_flutter/hive_flutter.dart';
import 'package:archive/archive_io.dart';
import 'package:file_picker/file_picker.dart';
import 'package:path_provider/path_provider.dart';
import 'package:todo/models/future_todo.dart';
import 'datetime_ext.dart';
import 'package:todo/models/event_data.dart';

class HiveRepository {
  late Box monthlyHive;
  late Box dailyHive;
  late Box futureTodosHive;
  final List<Map<dynamic, EventData>> thisMonthEventsMaps = List.generate(42, (index) => <dynamic, EventData>{});
  late Map<dynamic, EventData> unfinishedEventsMap;
  Map<dynamic, EventData> dailyMonthlyEventsMap = {};
  late Map<dynamic, EventData> dailyTableEventsMap;
  List<EventData> thisMonthEvents = [];
  Iterable<EventData> unfinishedEvents = [];
  List<EventData> dailyTableEvents = [];
  List<EventData> dailyMonthlyEvents = [];
  List<dynamic> inOrderDailyTableEvents = [];
  List<FutureTodo> futureList = [];

  HiveRepository();

  cacheInitialData() {
    monthlyHive = Hive.box<EventData>('monthEventBox');
    dailyHive = Hive.box<EventData>('dailyEventBox');
    futureTodosHive = Hive.box<FutureTodo>('futureTodosBox');

    // Sort based on the order the user has them in using a saved index
    futureList = futureTodosHive.values.cast<FutureTodo>().toList();
    futureList.sort((a, b) => a.index.compareTo(b.index));

    // Purge if event was finished or if its more than 7 days old
    Iterable<EventData> finished = dailyHive.values.where((event) {
      EventData e = event;
      return e.finished && !e.start.isSameDate(other: DateTime.now(), daily: true) ||
          e.end.isBefore(DateTime.now().subtract(const Duration(days: 7)));
    }).cast();
    for (EventData event in finished) {
      event.delete();
    }

    // Purge if event is older than 3 years
    DateTime cutOffDate = DateTime(DateTime.now().year, DateTime.now().month).subtract(const Duration(days: 365 * 3));
    Iterable<EventData> tooOld = monthlyHive.values.where((event) {
      EventData e = event;
      return e.end.isBefore(cutOffDate);
    }).cast();
    for (EventData event in tooOld) {
      event.delete();
    }
    DateTime currentMonth = DateTime(DateTime.now().year, DateTime.now().month);
    for (EventData event in monthlyHive.values) {
      if (event.start.isBetweenDates(currentMonth.startingMonthCalenNum(),
              currentMonth.startingMonthCalenNum().add(const Duration(days: 41))) ||
          event.end.isBetweenDates(currentMonth.startingMonthCalenNum(),
              currentMonth.startingMonthCalenNum().add(const Duration(days: 41)))) {
        thisMonthEvents.add(event);
      }
    }
    unfinishedEvents = dailyHive.values.where((event) {
      EventData e = event;
      return !e.finished && e.end.isBeforeDate(other: DateTime.now());
    }).cast();
    dailyTableEvents = dailyHive.values
        .where((event) {
          EventData e = event;
          return e.start.isSameDate(other: DateTime.now(), daily: true);
        })
        .toList()
        .cast();

    for (EventData event in monthlyHive.values) {
      if (DateTime.now().isBetweenDates(event.start, event.end)) {
        dailyMonthlyEvents.add(event);
      }
    }

    for (EventData event in thisMonthEvents) {
      DateTime start = event.start.isBetweenDates(
              currentMonth.startingMonthCalenNum(), currentMonth.startingMonthCalenNum().add(const Duration(days: 41)))
          ? event.start
          : currentMonth.startingMonthCalenNum();
      DateTime end = event.end.isBetweenDates(
              currentMonth.startingMonthCalenNum(), currentMonth.startingMonthCalenNum().add(const Duration(days: 41)))
          ? event.end
          : currentMonth.startingMonthCalenNum().add(const Duration(days: 41));
      while (start.isBefore(end) || start.isSameDate(other: end, daily: false)) {
        thisMonthEventsMaps[start.isBefore(currentMonth)
            ? start.day - currentMonth.startingMonthCalenNum().day
            : start.isAfter(currentMonth.add(Duration(days: currentMonth.totalDaysInMonth() - 1)))
                ? (currentMonth.weekday - 1) + currentMonth.totalDaysInMonth() + start.day - 1
                : start.day - 1 + (currentMonth.weekday - 1)][event.key] = event;
        start = start.add(const Duration(days: 1));
      }
    }
    unfinishedEventsMap = {for (EventData v in unfinishedEvents) v.key: v};
    dailyTableEventsMap = {for (EventData v in dailyTableEvents) v.key: v};
    dailyMonthlyEventsMap = {for (EventData v in dailyMonthlyEvents) v.key: v};

    dailyTableEvents.sort((a, b) => a.start.compareTo(b.start));
    for (EventData v in dailyTableEvents) {
      inOrderDailyTableEvents.add(v.key);
    }
  }

  createFutureTodo({required FutureTodo todo}) {
    futureTodosHive.add(todo);
    futureList.insert(todo.index, todo);
  }

  updateFutureTodo({FutureTodo? todo, List<FutureTodo>? todoList}) {
    if (todo == null) {
      for (FutureTodo i in todoList!) {
        i.save();
      }
      futureList = todoList;
    } else {
      todo.save();
      futureList[todo.index] = todo;
    }
  }

  deleteFutureTodo({required FutureTodo todo}) {
    futureList.removeAt(todo.index);
    todo.delete();
  }

  createEvent({required bool daily, required EventData event, bool? containsSelectedDay, DateTime? currentMonth}) {
    daily ? dailyHive.add(event) : monthlyHive.add(event);
    if (daily) {
      dailyTableEvents.add(event);
      dailyTableEvents.sort((a, b) => a.start.compareTo(b.start));
      inOrderDailyTableEvents.insert(dailyTableEvents.indexOf(event), event.key);
      dailyTableEventsMap[event.key] = event;
    } else if (event.start.isBetweenDates(currentMonth!.startingMonthCalenNum(),
            currentMonth.startingMonthCalenNum().add(const Duration(days: 41))) ||
        event.end.isBetweenDates(
            currentMonth.startingMonthCalenNum(), currentMonth.startingMonthCalenNum().add(const Duration(days: 41)))) {
      DateTime start = event.start.isBetweenDates(
              currentMonth.startingMonthCalenNum(), currentMonth.startingMonthCalenNum().add(const Duration(days: 41)))
          ? event.start
          : currentMonth.startingMonthCalenNum();
      DateTime end = event.end.isBetweenDates(
              currentMonth.startingMonthCalenNum(), currentMonth.startingMonthCalenNum().add(const Duration(days: 41)))
          ? event.end
          : currentMonth.startingMonthCalenNum().add(const Duration(days: 41));
      while (start.isBefore(end) || start.isSameDate(other: end, daily: false)) {
        thisMonthEventsMaps[start.isBefore(currentMonth)
            ? start.day - currentMonth.startingMonthCalenNum().day
            : start.isAfter(currentMonth.add(Duration(days: currentMonth.totalDaysInMonth() - 1)))
                ? (currentMonth.weekday - 1) + currentMonth.totalDaysInMonth() + start.day - 1
                : start.day - 1 + (currentMonth.weekday - 1)][event.key] = event;
        start = start.add(const Duration(days: 1));
      }
    }
    bool inDay = containsSelectedDay ?? false;
    if (!daily && inDay) {
      dailyMonthlyEventsMap[event.key] = event;
    }
  }

  updateEvent(
      {required bool daily,
      required EventData event,
      bool? containsSelectedDay,
      EventData? oldEvent,
      DateTime? currentMonth}) {
    event.save();
    if (daily) {
      for (int i = 0; i < inOrderDailyTableEvents.length; i++) {
        if (inOrderDailyTableEvents[i] == event.key) {
          inOrderDailyTableEvents.removeAt(i);
          dailyTableEvents.removeAt(i);
          dailyTableEvents.add(event);
          dailyTableEvents.sort((a, b) => a.start.compareTo(b.start));
          inOrderDailyTableEvents.insert(dailyTableEvents.indexOf(event), event.key);
          break;
        }
      }
      dailyTableEventsMap[event.key] = event;
    } else {
      if (oldEvent!.start.isBetweenDates(currentMonth!.startingMonthCalenNum(),
              currentMonth.startingMonthCalenNum().add(const Duration(days: 41))) ||
          oldEvent.end.isBetweenDates(currentMonth.startingMonthCalenNum(),
              currentMonth.startingMonthCalenNum().add(const Duration(days: 41)))) {
        DateTime start = oldEvent.start.isBetweenDates(currentMonth.startingMonthCalenNum(),
                currentMonth.startingMonthCalenNum().add(const Duration(days: 41)))
            ? oldEvent.start
            : currentMonth.startingMonthCalenNum();
        DateTime end = oldEvent.end.isBetweenDates(currentMonth.startingMonthCalenNum(),
                currentMonth.startingMonthCalenNum().add(const Duration(days: 41)))
            ? oldEvent.end
            : currentMonth.startingMonthCalenNum().add(const Duration(days: 41));
        while (start.isBefore(end) || start.isSameDate(other: end, daily: false)) {
          thisMonthEventsMaps[start.isBefore(currentMonth)
                  ? start.day - currentMonth.startingMonthCalenNum().day
                  : start.isAfter(currentMonth.add(Duration(days: currentMonth.totalDaysInMonth() - 1)))
                      ? (currentMonth.weekday - 1) + currentMonth.totalDaysInMonth() + start.day - 1
                      : start.day - 1 + (currentMonth.weekday - 1)]
              .remove(oldEvent.key);
          start = start.add(const Duration(days: 1));
        }
      }
      if (event.start.isBetweenDates(currentMonth.startingMonthCalenNum(),
              currentMonth.startingMonthCalenNum().add(const Duration(days: 41))) ||
          event.end.isBetweenDates(currentMonth.startingMonthCalenNum(),
              currentMonth.startingMonthCalenNum().add(const Duration(days: 41)))) {
        DateTime start = event.start.isBetweenDates(currentMonth.startingMonthCalenNum(),
                currentMonth.startingMonthCalenNum().add(const Duration(days: 41)))
            ? event.start
            : currentMonth.startingMonthCalenNum();
        DateTime end = event.end.isBetweenDates(currentMonth.startingMonthCalenNum(),
                currentMonth.startingMonthCalenNum().add(const Duration(days: 41)))
            ? event.end
            : currentMonth.startingMonthCalenNum().add(const Duration(days: 41));
        while (start.isBefore(end) || start.isSameDate(other: end, daily: false)) {
          thisMonthEventsMaps[start.isBefore(currentMonth)
              ? start.day - currentMonth.startingMonthCalenNum().day
              : start.isAfter(currentMonth.add(Duration(days: currentMonth.totalDaysInMonth() - 1)))
                  ? (currentMonth.weekday - 1) + currentMonth.totalDaysInMonth() + start.day - 1
                  : start.day - 1 + (currentMonth.weekday - 1)][event.key] = event;
          start = start.add(const Duration(days: 1));
        }
      }

      dailyMonthlyEventsMap.remove(oldEvent.key);
    }

    bool inDay = containsSelectedDay ?? false;
    if (!daily && inDay) {
      dailyMonthlyEventsMap[event.key] = event;
    }
  }

  deleteEvent({required bool daily, required EventData event, bool? containsSelectedDay, DateTime? currentMonth}) {
    if (daily) {
      if (unfinishedEventsMap[event.key] != null) {
        unfinishedEventsMap.remove(event.key);
      } else {
        dailyTableEvents.remove(event);
        inOrderDailyTableEvents.remove(event.key);

        dailyTableEventsMap.remove(event.key);
      }
    } else {
      if (event.start.isBetweenDates(currentMonth!.startingMonthCalenNum(),
              currentMonth.startingMonthCalenNum().add(const Duration(days: 41))) ||
          event.end.isBetweenDates(currentMonth.startingMonthCalenNum(),
              currentMonth.startingMonthCalenNum().add(const Duration(days: 41)))) {
        DateTime start = event.start.isBetweenDates(currentMonth.startingMonthCalenNum(),
                currentMonth.startingMonthCalenNum().add(const Duration(days: 41)))
            ? event.start
            : currentMonth.startingMonthCalenNum();
        DateTime end = event.end.isBetweenDates(currentMonth.startingMonthCalenNum(),
                currentMonth.startingMonthCalenNum().add(const Duration(days: 41)))
            ? event.end
            : currentMonth.startingMonthCalenNum().add(const Duration(days: 41));
        while (start.isBefore(end) || start.isSameDate(other: end, daily: false)) {
          print("deleting a thing ${thisMonthEventsMaps}");
          thisMonthEventsMaps[start.isBefore(currentMonth)
                  ? start.day - currentMonth.startingMonthCalenNum().day
                  : start.isAfter(currentMonth.add(Duration(days: currentMonth.totalDaysInMonth() - 1)))
                      ? (currentMonth.weekday - 1) + currentMonth.totalDaysInMonth() + start.day - 1
                      : start.day - 1 + (currentMonth.weekday - 1)]
              .remove(event.key);
          print("deleted a thing ${thisMonthEventsMaps}");
          start = start.add(const Duration(days: 1));
        }
      }
    }
    bool inDay = containsSelectedDay ?? false;
    if (!daily && inDay) {
      dailyMonthlyEventsMap.remove(event.key);
    }
    event.delete();
  }

  // For adding from the unfinished list to the day
  addUnfinishedEvent({required EventData event}) {
    unfinishedEventsMap.remove(event.key);
    dailyTableEvents.add(event);
    dailyTableEvents.sort((a, b) => a.start.compareTo(b.start));
    inOrderDailyTableEvents.insert(dailyTableEvents.indexOf(event), event.key);
    dailyTableEventsMap[event.key] = event;
    event.save();
  }

  // For a new day
  getDailyEvents({required DateTime date}) {
    dailyTableEvents = dailyHive.values
        .where((event) {
          EventData e = event;
          return e.start.isSameDate(other: date, daily: true);
        })
        .toList()
        .cast();
    dailyTableEventsMap.clear();
    dailyTableEventsMap.addAll({for (EventData v in dailyTableEvents) v.key: v});
    inOrderDailyTableEvents.clear();
    for (EventData v in dailyTableEvents) {
      inOrderDailyTableEvents.add(v.key);
    }

    dailyMonthlyEvents.clear();
    for (EventData event in monthlyHive.values) {
      if (date.isBetweenDates(event.start, event.end)) {
        dailyMonthlyEvents.add(event);
      }
    }
    dailyMonthlyEventsMap = {for (EventData v in dailyMonthlyEvents) v.key: v};
  }

  // For a new month
  getMonthlyEvents({required DateTime date}) {
    thisMonthEvents.clear();
    for (EventData event in monthlyHive.values) {
      if (event.start.isBetweenDates(
              date.startingMonthCalenNum(), date.startingMonthCalenNum().add(const Duration(days: 41))) ||
          event.end.isBetweenDates(
              date.startingMonthCalenNum(), date.startingMonthCalenNum().add(const Duration(days: 41)))) {
        thisMonthEvents.add(event);
      }
    }

    for (int i = 0; i < 42; i++) {
      thisMonthEventsMaps[i].clear();
    }

    for (EventData event in thisMonthEvents) {
      DateTime start = event.start
              .isBetweenDates(date.startingMonthCalenNum(), date.startingMonthCalenNum().add(const Duration(days: 41)))
          ? event.start
          : date.startingMonthCalenNum();
      DateTime end = event.end
              .isBetweenDates(date.startingMonthCalenNum(), date.startingMonthCalenNum().add(const Duration(days: 41)))
          ? event.end
          : date.startingMonthCalenNum().add(const Duration(days: 41));
      while (start.isBefore(end) || start.isSameDate(other: end, daily: false)) {
        thisMonthEventsMaps[start.isBefore(date)
            ? start.day - date.startingMonthCalenNum().day
            : start.isAfter(date.add(Duration(days: date.totalDaysInMonth() - 1)))
                ? (date.weekday - 1) + date.totalDaysInMonth() + start.day - 1
                : start.day - 1 + (date.weekday - 1)][event.key] = event;
        start = start.add(const Duration(days: 1));
      }
    }
  }

  Future<bool> importFile(bool isAndroid) async {
    String firstBoxPath = monthlyHive.path!;
    String secondBoxPath = dailyHive.path!;
    if (monthlyHive.isNotEmpty || dailyHive.isNotEmpty) {
      // String? selectedDirectory = await FilePicker.platform.getDirectoryPath(dialogTitle: "Choose Backup directory");
      String? selectedDirectory =
          isAndroid ? (await getExternalStorageDirectory())?.path : (await getApplicationDocumentsDirectory()).path;

      if (selectedDirectory == null) {
        return false;
      }
      var encoder = ZipFileEncoder();
      encoder.create("$selectedDirectory/todo_data.zip");
      await monthlyHive.close();
      await dailyHive.close();

      encoder.addFile(await (File(firstBoxPath).copy("$selectedDirectory/firstHive.hive")));
      encoder.addFile(await (File(secondBoxPath).copy("$selectedDirectory/secondHive.hive")));
      encoder.close();
      await Hive.openBox<EventData>('monthEventBox');
      await Hive.openBox<EventData>('dailyEventBox');
      monthlyHive = Hive.box<EventData>('monthEventBox');
      dailyHive = Hive.box<EventData>('dailyEventBox');
    }

    // Get the user to pick a  zip file
    FilePickerResult? result = await FilePicker.platform
        .pickFiles(dialogTitle: "Choose zip file", type: FileType.custom, allowedExtensions: ['zip']);

    if (result != null) {
      await monthlyHive.close();
      await dailyHive.close();

      final inputStream = InputFileStream(result.files.single.path!);
      final archive = ZipDecoder().decodeBuffer(inputStream);
      // For all of the entries in the archive
      final firstStream = OutputFileStream(firstBoxPath);
      archive.files[0].writeContent(firstStream);
      firstStream.close();

      final secondStream = OutputFileStream(secondBoxPath);
      archive.files[1].writeContent(secondStream);
      secondStream.close();
      await Hive.openBox<EventData>('monthEventBox');
      await Hive.openBox<EventData>('dailyEventBox');
      monthlyHive = Hive.box<EventData>('monthEventBox');
      dailyHive = Hive.box<EventData>('dailyEventBox');
      return true;
    }
    return false;
  }

  Future<String?> exportFile(bool isAndroid) async {
    if (await Permission.storage.request().isGranted) {
      {
        String? selectedDirectory =
            isAndroid ? (await getExternalStorageDirectory())?.path : (await getApplicationDocumentsDirectory()).path;
        if (selectedDirectory != null) {
          var encoder = ZipFileEncoder();
          encoder.create("$selectedDirectory/todo_data.zip");
          String firstBoxPath = monthlyHive.path!;
          String secondBoxPath = dailyHive.path!;

          await monthlyHive.close();
          await dailyHive.close();

          encoder.addFile(await (File(firstBoxPath).copy("$selectedDirectory/firstHive.hive")));
          encoder.addFile(await (File(secondBoxPath).copy("$selectedDirectory/secondHive.hive")));
          encoder.close();

          await Hive.openBox<EventData>('monthEventBox');
          await Hive.openBox<EventData>('dailyEventBox');
          monthlyHive = Hive.box<EventData>('monthEventBox');
          dailyHive = Hive.box<EventData>('dailyEventBox');
          return selectedDirectory;
        }
      }
      return null;
    }
    return null;
  }
}
