import 'dart:async';
import 'dart:io';
import 'package:file_picker/file_picker.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:hive/hive.dart';
import 'package:hive_flutter/hive_flutter.dart';
import 'package:archive/archive_io.dart';
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
      return e.finished &&
              e.start.toLocal().isBefore(DateTime.utc(
                  DateTime.now().year,
                  DateTime.now().month,
                  DateTime.now().day -
                      (DateTime.now().hour == 0 || DateTime.now().hour == 1 && DateTime.now().minute <= 59 ? 1 : 0),
                  7)) ||
          e.end.isBefore(DateTime.utc(
                  DateTime.now().year,
                  DateTime.now().month,
                  DateTime.now().day -
                      (DateTime.now().hour == 0 || DateTime.now().hour == 1 && DateTime.now().minute <= 59 ? 1 : 0),
                  7)
              .subtract(const Duration(days: 7)));
    }).cast();
    for (EventData event in finished) {
      event.delete();
    }

    // Purge if event is older than 3 years
    DateTime cutOffDate =
        DateTime.utc(DateTime.now().year, DateTime.now().month).subtract(const Duration(days: 365 * 3));
    Iterable<EventData> tooOld = monthlyHive.values.where((event) {
      EventData e = event;
      return e.end.isBefore(cutOffDate);
    }).cast();
    for (EventData event in tooOld) {
      event.delete();
    }

    // Set up the month events list

    // Clear the events from the monthly data structures
    thisMonthEvents.clear();
    for (int i = 0; i < 42; i++) {
      thisMonthEventsMaps[i].clear();
    }
    DateTime currentMonth = DateTime.utc(DateTime.now().year, DateTime.now().month);
    for (EventData event in monthlyHive.values) {
      if (event.start.toLocal().inCalendarWindow(end: event.end.toLocal(), currentMonth: currentMonth)) {
        thisMonthEvents.add(event);
      }
    }

    // Set up the unfinished list
    unfinishedEvents = dailyHive.values.where((event) {
      EventData e = event;

      return !e.finished &&
          e.end.isBefore(DateTime(
                  DateTime.now().year,
                  DateTime.now().month,
                  DateTime.now().day -
                      (DateTime.now().hour == 0 || DateTime.now().hour == 1 && DateTime.now().minute <= 59 ? 1 : 0),
                  7)
              .toUtc());
    }).cast();
    dailyTableEvents = dailyHive.values
        .where((event) {
          EventData e = event;
          return e.start.toLocal().isSameDate(
              other: DateTime.utc(
                  DateTime.now().year,
                  DateTime.now().month,
                  DateTime.now().day -
                      (DateTime.now().hour == 0 || DateTime.now().hour == 1 && DateTime.now().minute <= 59 ? 1 : 0)),
              daily: true);
        })
        .toList()
        .cast();

    // Set up the daily list of month events
    for (EventData event in monthlyHive.values) {
      if (DateTime.now().isBetweenDates(event.start.toLocal(), event.end.toLocal())) {
        dailyMonthlyEvents.add(event);
      }
    }

    // Set up the maps
    for (EventData event in thisMonthEvents) {
      DateTime start = event.start.toLocal().dateInCalendarWindow(currentMonth: currentMonth).toUtc();
      DateTime end = event.end.toLocal().dateInCalendarWindow(currentMonth: currentMonth).toUtc();

      while (start.isBefore(end) || start.isAtSameMomentAs(end)) {
        thisMonthEventsMaps[start.toLocal().monthlyMapDayIndex(currentMonth: currentMonth)][event.key] = event;
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
        futureTodosHive.put(i.key, i);
      }
      futureList = todoList;
    } else {
      todo.save();
      futureList[todo.index] = todo;
    }
  }

  deleteFutureTodo({required FutureTodo todo}) {
    futureList.removeAt(todo.index);
    for (int i = 0; i < futureList.length; i++) {
      futureTodosHive.put(futureList[i].key, futureList[i].changeIndex(i));
    }
    todo.delete();
  }

  // Add the event to the proper lists/maps
  createEvent(
      {required bool daily,
      required EventData event,
      bool? containsSelectedDay,
      DateTime? currentMonth,
      DateTime? currentDailyDate}) {
    Duration localTimeDiff = DateTime.now().timeZoneOffset;
    event.start = event.start.subtract(localTimeDiff);
    event.end = event.end.subtract(localTimeDiff);
    daily ? dailyHive.add(event) : monthlyHive.add(event);
    // Only update daily lists and maps if the event falls on the selected daily date
    if (daily && event.start.toLocal().isSameDate(other: currentDailyDate ?? event.start.toLocal(), daily: daily)) {
      dailyTableEvents.add(event);
      dailyTableEvents.sort((a, b) => a.start.compareTo(b.start));
      inOrderDailyTableEvents.insert(dailyTableEvents.indexOf(event), event.key);
      dailyTableEventsMap[event.key] = event;
    } else if (!daily &&
        event.start.toLocal().inCalendarWindow(end: event.end.toLocal(), currentMonth: currentMonth!)) {
      DateTime start = event.start.toLocal().dateInCalendarWindow(currentMonth: currentMonth);
      DateTime end = event.end.toLocal().dateInCalendarWindow(currentMonth: currentMonth);

      while (start.isBefore(end) || start.isAtSameMomentAs(end)) {
        thisMonthEventsMaps[start.toLocal().monthlyMapDayIndex(currentMonth: currentMonth)][event.key] = event;
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
    Duration localTimeDiff = DateTime.now().timeZoneOffset;
    event.start = event.start.subtract(localTimeDiff);
    event.end = event.end.subtract(localTimeDiff);

    if (daily) {
      dailyHive.put(event.key, event);
      // Find the event in the in order list and remove it
      // Add the event back in and insert in the right spot
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
      monthlyHive.put(event.key, event);
      if (oldEvent!.start.toLocal().inCalendarWindow(end: oldEvent.end.toLocal(), currentMonth: currentMonth!)) {
        DateTime start = oldEvent.start.toLocal().dateInCalendarWindow(currentMonth: currentMonth);
        DateTime end = oldEvent.end.toLocal().dateInCalendarWindow(currentMonth: currentMonth);

        while (start.isBefore(end) || start.isAtSameMomentAs(end)) {
          // Remove the event from each day list that it existed in
          thisMonthEventsMaps[start.toLocal().monthlyMapDayIndex(currentMonth: currentMonth)].remove(oldEvent.key);
          start = start.add(const Duration(days: 1));
        }
      }
      if (event.start.toLocal().inCalendarWindow(end: event.end.toLocal(), currentMonth: currentMonth)) {
        DateTime start = event.start.toLocal().dateInCalendarWindow(currentMonth: currentMonth);
        DateTime end = event.end.toLocal().dateInCalendarWindow(currentMonth: currentMonth);

        while (start.isBefore(end) || start.isAtSameMomentAs(end)) {
          // Add the new event back into the day lists
          thisMonthEventsMaps[start.toLocal().monthlyMapDayIndex(currentMonth: currentMonth)][event.key] = event;
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
      // Remove from either the unfinished list or the daily table and inorder list.
      // The event cannot exist in both
      if (unfinishedEventsMap[event.key] != null) {
        unfinishedEventsMap.remove(event.key);
      } else {
        dailyTableEvents.remove(event);
        inOrderDailyTableEvents.remove(event.key);

        dailyTableEventsMap.remove(event.key);
      }
    } else {
      if (event.start.toLocal().inCalendarWindow(end: event.end.toLocal(), currentMonth: currentMonth!)) {
        DateTime start = event.start.toLocal().dateInCalendarWindow(currentMonth: currentMonth);
        DateTime end = event.end.toLocal().dateInCalendarWindow(currentMonth: currentMonth);

        while (start.isBefore(end) || start.isAtSameMomentAs(end)) {
          thisMonthEventsMaps[start.toLocal().monthlyMapDayIndex(currentMonth: currentMonth)].remove(event.key);
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
    Duration localTimeDiff = DateTime.now().timeZoneOffset;
    event.start = event.start.subtract(localTimeDiff);
    event.end = event.end.subtract(localTimeDiff);

    // Remove from the unfinished list
    unfinishedEventsMap.remove(event.key);

    // Add to the daily table as well as the in order list
    dailyTableEvents.add(event);
    dailyTableEvents.sort((a, b) => a.start.compareTo(b.start));
    inOrderDailyTableEvents.insert(dailyTableEvents.indexOf(event), event.key);
    dailyTableEventsMap[event.key] = event;

    // Save in the hive
    dailyHive.put(event.key, event);
  }

  // For a new day
  getDailyEvents({required DateTime date}) {
    dailyTableEvents = dailyHive.values
        .where((event) {
          EventData e = event;
          return e.start.toLocal().isSameDate(other: date, daily: true);
        })
        .toList()
        .cast();

    // Clear the map and add the daily table events
    dailyTableEventsMap.clear();
    dailyTableEventsMap.addAll({for (EventData v in dailyTableEvents) v.key: v});

    // Clear the in order list and add the stuff in order
    dailyTableEvents.sort((a, b) => a.start.compareTo(b.start));
    inOrderDailyTableEvents.clear();
    for (EventData v in dailyTableEvents) {
      inOrderDailyTableEvents.add(v.key);
    }

    // Get the monthly events that fall on the day
    dailyMonthlyEvents.clear();
    for (EventData event in monthlyHive.values) {
      if (DateTime(date.year, date.month, date.day).isBetweenDates(event.start.toLocal(), event.end.toLocal())) {
        dailyMonthlyEvents.add(event);
      }
    }
    dailyMonthlyEventsMap = {for (EventData v in dailyMonthlyEvents) v.key: v};
  }

  // For a new month
  getMonthlyEvents({required DateTime date}) {
    // Clear the events from the monthly data structures
    thisMonthEvents.clear();
    for (int i = 0; i < 42; i++) {
      thisMonthEventsMaps[i].clear();
    }

    // If either the start or end of the event fall within the calendar windoww, add it
    // The calendar window consists of the 6 weeks surrounding the current month
    for (EventData event in monthlyHive.values) {
      if (event.start.toLocal().inCalendarWindow(end: event.end.toLocal(), currentMonth: date)) {
        thisMonthEvents.add(event);
      }
    }

    for (EventData event in thisMonthEvents) {
      // If the start or end fall outside of the calendar window, just set it the the start/end of the calendar window
      DateTime start = event.start.toLocal().dateInCalendarWindow(currentMonth: date);
      DateTime end = event.end.toLocal().dateInCalendarWindow(currentMonth: date);

      // Add the event to each day that the event exists on
      while (start.isBefore(end) || start.isAtSameMomentAs(end)) {
        thisMonthEventsMaps[start.toLocal().monthlyMapDayIndex(currentMonth: date)][event.key] = event;
        start = start.add(const Duration(days: 1));
      }
    }
  }

  // Create a backup of current data and import data from the selected zip file
  Future<bool> importFile(bool isAndroid) async {
    // Get the paths to each of the box files
    String firstBoxPath = monthlyHive.path!;
    String secondBoxPath = dailyHive.path!;
    String thirdBoxPath = futureTodosHive.path!;

    // If any data is present in the app, export a backup for the user
    if (monthlyHive.isNotEmpty || dailyHive.isNotEmpty || futureTodosHive.isNotEmpty) {
      // Get a directory to export to
      String? selectedDirectory =
          isAndroid ? (await getExternalStorageDirectory())?.path : (await getApplicationDocumentsDirectory()).path;

      if (selectedDirectory == null) {
        return false;
      }

      // Create a zip file
      var encoder = ZipFileEncoder();
      encoder.create("$selectedDirectory/back_up_todo_data.zip");

      // Close the hives first
      await monthlyHive.close();
      await dailyHive.close();
      await futureTodosHive.close();

      // Add the box files to the zip
      encoder.addFile((File(firstBoxPath)));
      encoder.addFile((File(secondBoxPath)));
      encoder.addFile((File(thirdBoxPath)));
      encoder.close();

      // Re-open the boxes
      monthlyHive = await Hive.openBox<EventData>('monthEventBox');
      dailyHive = await Hive.openBox<EventData>('dailyEventBox');
      futureTodosHive = await Hive.openBox<FutureTodo>('futureTodosBox');
    }

    // Get the user to pick a  zip file
    FilePicker.platform.clearTemporaryFiles();
    FilePickerResult? result = await FilePicker.platform
        .pickFiles(dialogTitle: "Choose zip file", type: FileType.custom, allowedExtensions: ['zip']);

    if (result != null) {
      await monthlyHive.close();
      await dailyHive.close();
      await futureTodosHive.close();
//
      final inputStream = InputFileStream(result.files.single.path!);
      final archive = ZipDecoder().decodeBuffer(inputStream);

      // For all of the entries in the archive
      final firstStream = OutputFileStream(firstBoxPath);
      final secondStream = OutputFileStream(secondBoxPath);
      final thirdStream = OutputFileStream(thirdBoxPath);

      for (int i = 0; i < 3; i++) {
        if (archive.files[i].name.contains('month')) {
          archive.files[i].writeContent(firstStream);
          firstStream.close();
        } else if (archive.files[i].name.contains('daily')) {
          archive.files[i].writeContent(secondStream);
          secondStream.close();
        } else {
          archive.files[i].writeContent(thirdStream);
          thirdStream.close();
        }
      }

      monthlyHive = await Hive.openBox<EventData>('monthEventBox');
      dailyHive = await Hive.openBox<EventData>('dailyEventBox');
      futureTodosHive = await Hive.openBox<FutureTodo>('futureTodosBox');

      return true;
    }
    return false;
  }

  // Export the data in the app to a zip file
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
          String thirdBoxPath = futureTodosHive.path!;

          await monthlyHive.close();
          await dailyHive.close();
          await futureTodosHive.close();

          await encoder.addFile((File(firstBoxPath)));
          await encoder.addFile((File(secondBoxPath)));
          await encoder.addFile((File(thirdBoxPath)));
          encoder.close();

          monthlyHive = await Hive.openBox<EventData>('monthEventBox');
          dailyHive = await Hive.openBox<EventData>('dailyEventBox');
          futureTodosHive = await Hive.openBox<FutureTodo>('futureTodosBox');

          return selectedDirectory;
        }
      }
      return null;
    }
    return null;
  }
}
