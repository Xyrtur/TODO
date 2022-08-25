import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:todo/models/event_data.dart';
import 'package:todo/utils/hive_repository.dart';

class CheckboxCubit extends Cubit<bool> {
  CheckboxCubit() : super(false);

  //Toggles
  void toggle() => emit(!state);
}

class ToggleEditingCubit extends Cubit<bool> {
  ToggleEditingCubit() : super(false);

  //Toggles
  void toggle() => emit(!state);
}

class DateCubit extends Cubit<DateTime> {
  DateCubit() : super(DateTime(DateTime.now().year, DateTime.now().month, DateTime.now().day));

  //Keep track of date chosen
  void nextDay() => emit(state.add(const Duration(days: 1)));
  void prevDay() => emit(state.subtract(const Duration(days: 1)));
}

class MonthDateCubit extends Cubit<DateTime> {
  MonthDateCubit() : super(DateTime(DateTime.now().year, DateTime.now().month));
  void update(DateTime date) => emit(date);
}

class YearTrackingCubit extends Cubit<int> {
  final int year;
  YearTrackingCubit(this.year) : super(year);
  void update(int year) => emit(year);
}

enum CalendarType { single, ranged, multi }

class CalendarTypeCubit extends Cubit<CalendarType> {
  final CalendarType? editType;
  CalendarTypeCubit(this.editType) : super(editType ?? CalendarType.single);
  void pressed(CalendarType type) => emit(type);
}

class DailyMonthlyListCubit extends Cubit<List<EventData>> {
  final HiveRepository hive;
  DailyMonthlyListCubit(this.hive) : super(hive.dailyMonthlyEventsMap.values.toList());
  void update() => emit(hive.dailyMonthlyEventsMap.values.toList());
}

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

class ColorCubit extends Cubit<int> {
  final int? color;
  ColorCubit(this.color) : super(color ?? 0);
  void update(int index) => emit(index);
}

class DialogDatesCubit extends Cubit<List<DateTime?>?> {
  final List<DateTime?>? dateResults;
  DialogDatesCubit(this.dateResults) : super(dateResults);
  void update(List<DateTime?>? dateResults) => emit(dateResults);
}
