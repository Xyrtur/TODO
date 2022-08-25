import 'dart:io';
import 'datetime_ext.dart';
import 'package:flutter/material.dart';
import 'package:todo/models/event_data.dart';
import 'package:hive/hive.dart';
import 'package:hive_flutter/hive_flutter.dart';
import 'package:archive/archive_io.dart';
import 'package:file_picker/file_picker.dart';

class HiveRepository {
  late final Box monthlyHive;
  late final Box dailyHive;
  final List<Map<dynamic, EventData>> thisMonthEventsMaps = List.filled(31, <dynamic, EventData>{});
  late final Map<dynamic, EventData> unfinishedEventsMap;
  late final Map<dynamic, EventData> dailyMonthlyEventsMap;
  late final Map<dynamic, EventData> dailyTableEventsMap;
  Iterable<EventData> thisMonthEvents = [];
  Iterable<EventData> unfinishedEvents = [];
  List<EventData> dailyTableEvents = [];
  Iterable<EventData> dailyMonthlyEvents = [];
  List<dynamic> inOrderDailyTableEvents = [];

  HiveRepository() {
    cacheInitialData();
  }
  cacheInitialData() {
    monthlyHive = Hive.box<EventData>('monthEventBox');
    dailyHive = Hive.box<EventData>('dailyEventBox');
    // Purge if event was finished or if its more than 7 days old
    Iterable<EventData> finished = dailyHive.values
        .where((event) =>
            event.finished && !event.start.isSameDate(DateTime.now()) ||
            event.end.isBefore(DateTime.now().subtract(const Duration(days: 7))))
        .cast();
    for (EventData event in finished) {
      event.delete();
    }
    thisMonthEvents = monthlyHive.values
        .where((event) => (event.start.isSameMonthYear(DateTime.now()) || event.end.isSameMonthYear(DateTime.now())))
        .cast();
    unfinishedEvents = dailyHive.values
        .where((event) => !event.finished && !event.end.isSameDate(other: DateTime.now(), daily: true))
        .cast();
    dailyTableEvents =
        dailyHive.values.where((event) => event.start.isSameDate(other: DateTime.now(), daily: true)).toList().cast();
    dailyMonthlyEvents =
        monthlyHive.values.where((event) => DateTime.now().isBetweenDates(event.start, event.end)).cast();

    for (EventData v in thisMonthEvents) {
      int start = v.start.day;
      while (start <= v.end.day) {
        thisMonthEventsMaps[start - 1][v.key] = v;
        start++;
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

  createEvent({required bool daily, required EventData event, bool? containsSelectedDay}) {
    daily ? dailyHive.add(event) : monthlyHive.add(event);
    if (daily) {
      dailyTableEvents.add(event);
      dailyTableEvents.sort((a, b) => a.start.compareTo(b.start));
      inOrderDailyTableEvents.insert(dailyTableEvents.indexOf(event), event.key);
      dailyTableEventsMap[event.key] = event;
    } else {
      int start = event.start.day;
      while (start <= event.end.day) {
        thisMonthEventsMaps[start - 1][event.key] = event;
        start++;
      }
    }
    bool inDay = containsSelectedDay ?? false;
    if (!daily && inDay) {
      dailyMonthlyEventsMap[event.key] = event;
    }
  }

  updateEvent({required bool daily, required EventData event, bool? containsSelectedDay, EventData? oldEvent}) {
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
      int start = oldEvent!.start.day;
      while (start <= oldEvent.end.day) {
        thisMonthEventsMaps[start - 1].remove(oldEvent.key);
        start++;
      }
      start = event.start.day;
      while (start <= event.end.day) {
        thisMonthEventsMaps[start - 1][event.key] = event;
        start++;
      }
      dailyMonthlyEventsMap.remove(oldEvent.key);
    }

    bool inDay = containsSelectedDay ?? false;
    if (!daily && inDay) {
      dailyMonthlyEventsMap[event.key] = event;
    }
  }

  deleteEvent({required bool daily, required EventData event, bool? containsSelectedDay}) {
    if (daily) {
      if (unfinishedEventsMap[event.key] != null) {
        unfinishedEventsMap.remove(event.key);
      } else {
        dailyTableEvents.remove(event);
        inOrderDailyTableEvents.remove(event.key);

        dailyTableEventsMap.remove(event.key);
      }
    } else {
      int start = event.start.day;
      while (start <= event.end.day) {
        thisMonthEventsMaps[start - 1].remove(event.key);
        start++;
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
    dailyTableEvents =
        dailyHive.values.where((event) => event.start.isSameDate(other: date, daily: true)).toList().cast();
    dailyTableEventsMap = {for (EventData v in dailyTableEvents) v.key: v};
    dailyMonthlyEvents = monthlyHive.values.where((event) => date.isBetweenDates(event.start, event.end)).cast();
  }

  // For a new month
  getMonthlyEvents({required DateTime date}) {
    thisMonthEvents = monthlyHive.values
        .where((event) => (event.start.isSameMonthYear(date) || event.end.isSameMonthYear(date)))
        .cast();
    for (int i = 0; i < 31; i++) {
      thisMonthEventsMaps[i].clear();
    }
    for (EventData v in thisMonthEvents) {
      int start = v.start.day;
      while (start > v.end.day) {
        thisMonthEventsMaps[start - 1][v.key] = v;
        start++;
      }
    }
  }

  importFile() async {
    String firstBoxPath = monthlyHive.path!;
    String secondBoxPath = dailyHive.path!;
    if (monthlyHive.isNotEmpty || dailyHive.isNotEmpty) {
      // ask them to pick a directory for backups
      String? selectedDirectory = await FilePicker.platform.getDirectoryPath(dialogTitle: "Choose Backup directory");

      if (selectedDirectory == null) {
        return;
      }
      var encoder = ZipFileEncoder();
      encoder.create("$selectedDirectory/todo_data.zip");
      await monthlyHive.close();
      await dailyHive.close();

      encoder.addFile(await (File(firstBoxPath).copy(selectedDirectory + "/firstHive.hive")));
      encoder.addFile(await (File(secondBoxPath).copy(selectedDirectory + "/secondHive.hive")));
      encoder.close();
      await Hive.openBox<EventData>('monthEventBox');
      await Hive.openBox<EventData>('dailyEventBox');
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
    }
  }

  exportFile() async {
    // ask them to pick a directory
    String? selectedDirectory = await FilePicker.platform.getDirectoryPath(dialogTitle: "Choose Export directory");

    if (selectedDirectory != null) {
      var encoder = ZipFileEncoder();
      encoder.create("$selectedDirectory/todo_data.zip");
      String firstBoxPath = monthlyHive.path!;
      String secondBoxPath = dailyHive.path!;

      await monthlyHive.close();
      await dailyHive.close();

      encoder.addFile(await (File(firstBoxPath).copy(selectedDirectory + "/firstHive.hive")));
      encoder.addFile(await (File(secondBoxPath).copy(selectedDirectory + "/secondHive.hive")));
      encoder.close();

      await Hive.openBox<EventData>('monthEventBox');
      await Hive.openBox<EventData>('dailyEventBox');
      //show a little alert dialog -> Saved "filename"
    }
  }
}
