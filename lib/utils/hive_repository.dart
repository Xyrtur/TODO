import 'dart:io';
import 'package:permission_handler/permission_handler.dart';
import 'package:hive/hive.dart';
import 'package:hive_flutter/hive_flutter.dart';
import 'package:archive/archive_io.dart';
import 'package:file_picker/file_picker.dart';
import 'package:path_provider/path_provider.dart';
import 'datetime_ext.dart';
import 'package:todo/models/event_data.dart';

class HiveRepository {
  late Box monthlyHive;
  late Box dailyHive;
  final List<Map<dynamic, EventData>> thisMonthEventsMaps = List.generate(31, (index) => <dynamic, EventData>{});
  late Map<dynamic, EventData> unfinishedEventsMap;
  Map<dynamic, EventData> dailyMonthlyEventsMap = {};
  late Map<dynamic, EventData> dailyTableEventsMap;
  List<EventData> thisMonthEvents = [];
  Iterable<EventData> unfinishedEvents = [];
  List<EventData> dailyTableEvents = [];
  List<EventData> dailyMonthlyEvents = [];
  List<dynamic> inOrderDailyTableEvents = [];

  HiveRepository();

  cacheInitialData() {
    monthlyHive = Hive.box<EventData>('monthEventBox');
    dailyHive = Hive.box<EventData>('dailyEventBox');

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

    for (EventData event in monthlyHive.values) {
      if (event.start.isSameMonthYear(DateTime.now()) || event.end.isSameMonthYear(DateTime.now())) {
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
      if ((event.start.isSameMonthYear(date) || event.end.isSameMonthYear(date))) {
        thisMonthEvents.add(event);
      }
    }

    for (int i = 0; i < 31; i++) {
      thisMonthEventsMaps[i].clear();
    }

    for (EventData v in thisMonthEvents) {
      int start = v.start.day;
      while (start <= v.end.day) {
        thisMonthEventsMaps[start - 1][v.key] = v;
        start++;
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
