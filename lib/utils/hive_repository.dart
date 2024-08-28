import 'dart:async';
import 'dart:io';
import 'dart:ui';
import 'package:file_picker/file_picker.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:hive/hive.dart';
import 'package:hive_flutter/hive_flutter.dart';
import 'package:archive/archive_io.dart';
import 'package:path_provider/path_provider.dart';
import 'package:todo/models/future_todo.dart';
import 'centre.dart';
import 'datetime_ext.dart';
import 'package:todo/models/event_data.dart';
import 'package:share_plus/share_plus.dart';

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

    inOrderDailyTableEvents.clear();
    dailyMonthlyEvents.clear();

    // Sort based on the order the user has them in using a saved index
    futureList = futureTodosHive.values.cast<FutureTodo>().toList();
    futureList.sort((a, b) => a.index.compareTo(b.index));

    // Purge if event was finished or if its more than 7 days old
    Iterable<EventData> finished = dailyHive.values.where((event) {
      EventData e = event;
      return e.finished &&
              e.start.isBefore(DateTime(
                  DateTime.now().year,
                  DateTime.now().month,
                  DateTime.now().day -
                      (DateTime.now().hour == 0 || DateTime.now().hour == 1 && DateTime.now().minute == 0 ? 1 : 0),
                  7)) ||
          e.end.isBefore(DateTime(
                  DateTime.now().year,
                  DateTime.now().month,
                  DateTime.now().day -
                      (DateTime.now().hour == 0 || DateTime.now().hour == 1 && DateTime.now().minute == 0 ? 1 : 0),
                  7)
              .subtract(const Duration(days: 7)));
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

    // Set up the month events list

    // Clear the events from the monthly data structures
    thisMonthEvents.clear();
    for (int i = 0; i < 42; i++) {
      thisMonthEventsMaps[i].clear();
    }
    DateTime currentMonth = DateTime(DateTime.now().year, DateTime.now().month);
    for (EventData event in monthlyHive.values) {
      if (event.start.inCalendarWindow(end: event.end, currentMonth: currentMonth)) {
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
                  (DateTime.now().hour == 0 || DateTime.now().hour == 1 && DateTime.now().minute == 0 ? 1 : 0),
              7));
    }).cast();
    dailyTableEvents = dailyHive.values
        .where((event) {
          EventData e = event;
          return e.start.isSameDate(
              other: DateTime(
                  DateTime.now().year,
                  DateTime.now().month,
                  DateTime.now().day -
                      (DateTime.now().hour == 0 || DateTime.now().hour == 1 && DateTime.now().minute == 0 ? 1 : 0)),
              daily: true);
        })
        .toList()
        .cast();

    // Set up the daily list of month events
    for (EventData event in monthlyHive.values) {
      if (DateTime(
              DateTime.now().year,
              DateTime.now().month,
              DateTime.now().day -
                  (DateTime.now().hour == 0 || DateTime.now().hour == 1 && DateTime.now().minute == 0 ? 1 : 0))
          .isBetweenDates(event.start, event.end)) {
        dailyMonthlyEvents.add(event);
      }
    }

    // Set up the maps
    for (EventData event in thisMonthEvents) {
      DateTime start = event.start.dateInCalendarWindow(currentMonth: currentMonth);
      DateTime end = event.end.dateInCalendarWindow(currentMonth: currentMonth);

      while (start.isBefore(end) || start.isAtSameMomentAs(end)) {
        thisMonthEventsMaps[start.monthlyMapDayIndex(currentMonth: currentMonth)][event.key] = event;
        start = start.addDurationWithoutDST(const Duration(days: 1));
      }
    }
    unfinishedEventsMap = {for (EventData v in unfinishedEvents) v.key: v};
    dailyTableEventsMap = {for (EventData v in dailyTableEvents) v.key: v};
    dailyMonthlyEventsMap = {for (EventData v in dailyMonthlyEvents) v.key: v};

    dailyTableEvents.sort((a, b) => a.start.compareTo(b.start));
    for (EventData v in dailyTableEvents) {
      inOrderDailyTableEvents.add(v.key);
    }
    return true;
  }

  createFutureTodo({required FutureTodo todo}) {
    futureTodosHive.add(todo);

    futureList.insert(todo.index, todo);

    // Set previous todo to expandable if need be
    if (todo.index != 0 && !futureList[todo.index - 1].expandable) {
      futureList[todo.index - 1].setExpandable(true);
      futureList[todo.index - 1].save();
    }

    int i = todo.index + 1;
    while (i < futureList.length) {
      futureList[i].changeIndex(i);
      futureList[i].save();
      i++;
    }
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

  List<int> deleteFutureTodo({required FutureTodo todo}) {
    int i = todo.index + 1;
    List<int> deletedTreeIndexes = [];
    while (i < futureList.length && futureList[todo.index].indented < futureList[i].indented) {
      futureList[i].changeIndent(futureList[i].indented - 1);
      futureList[i].setCollapsed(false);
      deletedTreeIndexes.add(i - 1);
      i++;
    }
    if (futureList[todo.index].indented > 0 &&
        futureList[todo.index - 1].indented == futureList[todo.index + 1].indented &&
        futureList[todo.index - 1].expandable) {
      futureList[todo.index - 1].setExpandable(false);
    }
    futureList.removeAt(todo.index);

    for (int i = 0; i < futureList.length; i++) {
      futureTodosHive.put(futureList[i].key, futureList[i].changeIndex(i));
    }

    todo.delete();
    return deletedTreeIndexes;
  }

  undoDeletedTodo({required FutureTodo todo, required List<int> fixIndentIndices}) {
    futureTodosHive.add(todo);

    futureList.insert(todo.index, todo);
    int i = todo.index + 1;
    while (i < futureList.length) {
      if (fixIndentIndices.contains(i - 1)) {
        futureList[i].changeIndent(futureList[i].indented + 1);
      }
      futureList[i].changeIndex(i);
      futureList[i].save();
      i++;
    }
  }

  // Add the event to the proper lists/maps
  createEvent(
      {required bool daily,
      required EventData event,
      bool? containsSelectedDay,
      DateTime? currentMonth,
      DateTime? currentDailyDate}) {
    daily ? dailyHive.add(event) : monthlyHive.add(event);
    // Only update daily lists and maps if the event falls on the selected daily date
    if (daily) {
      dailyTableEvents.add(event);
      dailyTableEvents.sort((a, b) => a.start.compareTo(b.start));
      inOrderDailyTableEvents.insert(dailyTableEvents.indexOf(event), event.key);
      dailyTableEventsMap[event.key] = event;
    } else if (!daily && event.start.inCalendarWindow(end: event.end, currentMonth: currentMonth!)) {
      DateTime start = event.start.dateInCalendarWindow(currentMonth: currentMonth);
      DateTime end = event.end.dateInCalendarWindow(currentMonth: currentMonth);

      while (start.isBefore(end) || start.isAtSameMomentAs(end)) {
        thisMonthEventsMaps[start.monthlyMapDayIndex(currentMonth: currentMonth)][event.key] = event;
        start = start.addDurationWithoutDST(const Duration(days: 1));
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
    if (daily) {
      event.save();
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
      // // Check if calendar type was changed
      // bool oldEventType = oldEvent!.fullDay && !oldEvent.start.isSameDate(other: oldEvent.end, daily: false);
      // bool eventType = event.fullDay && !event.start.isSameDate(other: event.end, daily: false);
      // if( oldEventType != eventType ){

      // }else{
      event.save();
      if (oldEvent!.start.inCalendarWindow(end: oldEvent.end, currentMonth: currentMonth!)) {
        DateTime start = oldEvent.start.dateInCalendarWindow(currentMonth: currentMonth);
        DateTime end = oldEvent.end.dateInCalendarWindow(currentMonth: currentMonth);

        while (start.isBefore(end) || start.isAtSameMomentAs(end)) {
          // Remove the event from each day list that it existed in
          thisMonthEventsMaps[start.monthlyMapDayIndex(currentMonth: currentMonth)].remove(event.key);
          start = start.addDurationWithoutDST(const Duration(days: 1));
        }
      }
      if (event.start.inCalendarWindow(end: event.end, currentMonth: currentMonth)) {
        DateTime start = event.start.dateInCalendarWindow(currentMonth: currentMonth);
        DateTime end = event.end.dateInCalendarWindow(currentMonth: currentMonth);

        while (start.isBefore(end) || start.isAtSameMomentAs(end)) {
          // Add the new event back into the day lists
          thisMonthEventsMaps[start.monthlyMapDayIndex(currentMonth: currentMonth)][event.key] = event;
          start = start.addDurationWithoutDST(const Duration(days: 1));
        }
      }

      dailyMonthlyEventsMap.remove(event.key);
      // }
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
      if (event.start.inCalendarWindow(end: event.end, currentMonth: currentMonth!)) {
        DateTime start = event.start.dateInCalendarWindow(currentMonth: currentMonth);
        DateTime end = event.end.dateInCalendarWindow(currentMonth: currentMonth);

        while (start.isBefore(end) || start.isAtSameMomentAs(end)) {
          thisMonthEventsMaps[start.monthlyMapDayIndex(currentMonth: currentMonth)].remove(event.key);
          start = start.addDurationWithoutDST(const Duration(days: 1));
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
    // Remove from the unfinished list
    unfinishedEventsMap.remove(event.key);

    // Add to the daily table as well as the in order list
    dailyTableEvents.add(event);
    dailyTableEvents.sort((a, b) => a.start.compareTo(b.start));
    inOrderDailyTableEvents.insert(dailyTableEvents.indexOf(event), event.key);
    dailyTableEventsMap[event.key] = event;

    // Save in the hive
    event.save();
  }

  addDailyToUnfinished({required EventData event}) {
    // Add to unfinished and remove from daily
    unfinishedEventsMap[event.key] = event;
    dailyTableEvents.remove(event);
    inOrderDailyTableEvents.remove(event.key);

    dailyTableEventsMap.remove(event.key);

    event.save();
  }

  updateUnfinishedListOnResume() {
    // Set up the unfinished list
    unfinishedEvents = dailyHive.values.where((event) {
      EventData e = event;

      return !e.finished &&
          e.end.isBefore(DateTime(
              DateTime.now().year,
              DateTime.now().month,
              DateTime.now().day -
                  (DateTime.now().hour == 0 || DateTime.now().hour == 1 && DateTime.now().minute == 0 ? 1 : 0),
              7));
    }).cast();

    unfinishedEventsMap = {for (EventData v in unfinishedEvents) v.key: v};
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
      if (DateTime(date.year, date.month, date.day).isBetweenDates(event.start, event.end)) {
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
      if (event.start.inCalendarWindow(end: event.end, currentMonth: date)) {
        thisMonthEvents.add(event);
      }
    }

    for (EventData event in thisMonthEvents) {
      // If the start or end fall outside of the calendar window, just set it the the start/end of the calendar window
      DateTime start = event.start.dateInCalendarWindow(currentMonth: date);
      DateTime end = event.end.dateInCalendarWindow(currentMonth: date);

      // Add the event to each day that the event exists on
      while (start.isBefore(end) || start.isAtSameMomentAs(end)) {
        thisMonthEventsMaps[start.monthlyMapDayIndex(currentMonth: date)][event.key] = event;
        start = start.addDurationWithoutDST(const Duration(days: 1));
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

    // Get the user to pick a zip file
    FilePicker.platform.clearTemporaryFiles();
    FilePickerResult? result = await FilePicker.platform
        .pickFiles(dialogTitle: "Choose zip file", type: FileType.custom, allowedExtensions: ['zip']);

    if (result != null) {
      await monthlyHive.close();
      await dailyHive.close();
      await futureTodosHive.close();

      final inputStream = InputFileStream(result.files.single.path!);
      final archive = ZipDecoder().decodeBuffer(inputStream);

      // For all of the entries in the archive
      final firstStream = OutputFileStream(firstBoxPath);
      final secondStream = OutputFileStream(secondBoxPath);
      final thirdStream = OutputFileStream(thirdBoxPath);

      // Ensure there are only 3 files in the zip
      if (archive.files.length != 3) return false;

      // If the files aren't hive files, not sure how to stop the user from inputting those
      // Checking file names doesn't matter because a user can just rename their input files to contain the right strings and extensions
      // Not sure what to do

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
    // Permission.storage.request();
    // if (await Permission.storage.request().isGranted) {
    //   {
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
      Share.shareXFiles([XFile("$selectedDirectory/todo_data.zip", name: "todo_data.zip")],
          sharePositionOrigin: Rect.fromLTWH(0, 0, Centre.size.width, Centre.size.height / 2),
          subject: 'Todo app backup file');

      monthlyHive = await Hive.openBox<EventData>('monthEventBox');
      dailyHive = await Hive.openBox<EventData>('dailyEventBox');
      futureTodosHive = await Hive.openBox<FutureTodo>('futureTodosBox');

      return selectedDirectory;
    }
  }
}
