import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import 'package:todo/models/event_data.dart';
import 'package:todo/utils/hive_repository.dart';

/*
 * Keeps track of the Full Day checkbox state (and any future checkboxes)
 */
class CheckboxCubit extends Cubit<bool> {
  final bool fullDay;
  CheckboxCubit(this.fullDay) : super(fullDay);

  void toggle() => emit(!state);
}

/*
 * Keeps track of the toggle button on the daily page
 * Starts out in the checklist state as opposed to the editing state
 */
class ToggleChecklistEditingCubit extends Cubit<bool> {
  ToggleChecklistEditingCubit() : super(false);

  void toggle() => emit(!state);
}

/*
 * Keeps track of what date is selected on the daily page
 * Needed in monthly page as well to know if the day has any monthly events
 */
class DateCubit extends Cubit<DateTime> {
  DateCubit()
      : super(DateTime.utc(
            DateTime.now().year,
            DateTime.now().month,
            DateTime.now().day -
                (DateTime.now().hour == 0 || DateTime.now().hour == 1 && DateTime.now().minute == 0
                    ? 1
                    : 0)));

  //Keep track of date chosen
  void changeDay(DateTime date) => emit(date);
  void setToCurrentDayOnResume() => emit(DateTime.utc(
      DateTime.now().year,
      DateTime.now().month,
      DateTime.now().day -
          (DateTime.now().hour == 0 || DateTime.now().hour == 1 && DateTime.now().minute == 0 ? 1 : 0)));
}

/*
 * Keeps track of what date is selected on the monthly page
 * On starting the app, the current month is chosen
 */
class MonthDateCubit extends Cubit<DateTime> {
  MonthDateCubit() : super(DateTime.utc(DateTime.now().year, DateTime.now().month));
  void update(DateTime date) => emit(date);
}

/*
 * Keeps track of what year is selected in the year month picker dialog as the user swipes
 */
class YearTrackingCubit extends Cubit<int> {
  final int year;
  YearTrackingCubit(this.year) : super(year);
  void update(int year) => emit(year);
}

/*
 * Keeps track of which calendar type is selected in the AddEditEvent dialog 
 */
enum CalendarType { single, ranged, multi }

class CalendarTypeCubit extends Cubit<CalendarType> {
  final CalendarType? editType;
  CalendarTypeCubit(this.editType) : super(editType ?? CalendarType.single);
  void pressed(CalendarType type) => emit(type);
}

/*
 * Holds an updated list of the monthly events for the date currently selected on the daily page
 * Used in the Daily Panel
 */
class DailyMonthlyListCubit extends Cubit<List<EventData>> {
  final HiveRepository hive;
  DailyMonthlyListCubit(this.hive) : super(hive.dailyMonthlyEventsMap.values.toList());
  void update() {
    return emit(hive.dailyMonthlyEventsMap.values.toList());
  }
}

/*
 * When an event is before as well as after 16:00, the event is split and 
 * this cubit helps to control both split schedule blocks if one is dragged
 */
class DraggingSplitBlockCubit extends Cubit<bool> {
  DraggingSplitBlockCubit() : super(false);
  void grabbedSplit() {
    return emit(true);
  }

  void letGo() {
    return emit(false);
  }
}

/*
 * Keeps track of the time ranges chosen in the AddEditEvent dialog
 */
class TimeRangeState {
  TimeOfDay? endResult;
  TimeOfDay? startResult;
  TimeRangeState(this.startResult, this.endResult);
}

class TimeRangeCubit extends Cubit<TimeRangeState> {
  final TimeRangeState range;
  TimeRangeCubit(this.range) : super(range);
  void update(TimeOfDay? start, TimeOfDay? end) => emit(TimeRangeState(start, end));
}

/*
 * Keeps track of the color chosen in the AddEditEvent dialog
 */
class ColorCubit extends Cubit<int> {
  final int? color;
  ColorCubit(this.color) : super(color ?? 0);
  void update(int index) => emit(index);
}

/*
 * Keeps track of the dates chosen in the AddEditEvent dialog
 */
class DialogDatesCubit extends Cubit<List<DateTime?>?> {
  final List<DateTime?>? dateResults;
  DialogDatesCubit(this.dateResults) : super(dateResults);
  void update(List<DateTime?>? dateResults) => emit(dateResults);
}

class CachingCubit extends Cubit<bool> {
  final bool finishedCaching;
  CachingCubit(this.finishedCaching) : super(finishedCaching);
  void update(bool finishedCaching) => emit(finishedCaching);
}

class ToggleTodoEditingCubit extends Cubit<bool> {
  ToggleTodoEditingCubit() : super(false);
  void toggle() => emit(!state);
}

class TodoTextEditingCubit extends Cubit<int?> {
  final int? indexEditing = null;
  TodoTextEditingCubit() : super(null);
  void update(int? indexEditing) => emit(indexEditing);
}

class Integer {
  int? value;

  Integer(this.value);
}

class TodoTileAddCubit extends Cubit<List<int>> {
  TodoTileAddCubit() : super([]);
  // [x,y,z]
  // x = index, y = indents, z = removing
  void update(List<int> tileInfo) {
    print("updating this shit??");
    emit(tileInfo);
  }
}

class TodoRecentlyAddedCubit extends Cubit<List<int>> {
  TodoRecentlyAddedCubit() : super([]);
  // [x,y]
  // x = index, y = dealt with: 1 = yes, 0 = no
  void update(List<int> recentInfo) => emit(recentInfo);
}

class FirstDailyDateBtnCubit extends Cubit<DateTime> {
  FirstDailyDateBtnCubit()
      : super(DateTime.utc(
            DateTime.now().year,
            DateTime.now().month,
            DateTime.now().day -
                (DateTime.now().hour == 0 || DateTime.now().hour == 1 && DateTime.now().minute == 0
                    ? 1
                    : 0)));
  // [x,y]
  // x = index, y = dealt with: 1 = yes, 0 = no
  void update(DateTime date) => emit(date);
}
