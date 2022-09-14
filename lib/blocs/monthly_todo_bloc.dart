import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:equatable/equatable.dart';

import 'package:todo/models/event_data.dart';
import 'package:todo/utils/hive_repository.dart';
import 'package:todo/utils/datetime_ext.dart';

abstract class MonthlyTodoEvent extends Equatable {
  const MonthlyTodoEvent();
  @override
  List<Object> get props => [];
}

class MonthlyTodoCreate extends MonthlyTodoEvent {
  final EventData event;
  final DateTime selectedDailyDay;
  const MonthlyTodoCreate({required this.event, required this.selectedDailyDay});
}

class MonthlyTodoUpdate extends MonthlyTodoEvent {
  final EventData event;
  final DateTime selectedDailyDay;
  final EventData oldEvent;
  const MonthlyTodoUpdate({required this.event, required this.selectedDailyDay, required this.oldEvent});
}

class MonthlyTodoDelete extends MonthlyTodoEvent {
  final EventData event;
  final DateTime selectedDailyDay;
  const MonthlyTodoDelete({required this.event, required this.selectedDailyDay});
}

class MonthlyTodoDateChange extends MonthlyTodoEvent {
  final DateTime date;
  const MonthlyTodoDateChange({required this.date});
}

abstract class MonthlyTodoState {
  final List<Map<dynamic, EventData>> monthlyMaps;
  final bool changedDailyList;
  const MonthlyTodoState(this.monthlyMaps, this.changedDailyList);

  List<Object> get props => [monthlyMaps];
}

class MonthlyTodoInitial extends MonthlyTodoState {
  const MonthlyTodoInitial(super.monthlyMaps, super.changedDailyList);
}

class MonthlyTodoRefreshed extends MonthlyTodoState {
  const MonthlyTodoRefreshed(super.monthlyMaps, super.changedDailyList);
}

class MonthlyTodoBloc extends Bloc<MonthlyTodoEvent, MonthlyTodoState> {
  final HiveRepository hive;

  MonthlyTodoBloc(this.hive) : super(MonthlyTodoInitial(hive.thisMonthEventsMaps, false)) {
    on<MonthlyTodoCreate>((event, emit) {
      bool containsDay = event.selectedDailyDay.isBetweenDates(event.event.start, event.event.end);
      hive.createEvent(daily: false, event: event.event, containsSelectedDay: containsDay);
      emit(MonthlyTodoRefreshed(hive.thisMonthEventsMaps, containsDay));
    });
    on<MonthlyTodoUpdate>((event, emit) {
      bool containsDay = event.selectedDailyDay.isBetweenDates(event.event.start, event.event.end);
      hive.updateEvent(daily: false, event: event.event, containsSelectedDay: containsDay, oldEvent: event.oldEvent);
      emit(MonthlyTodoRefreshed(hive.thisMonthEventsMaps, containsDay));
    });
    on<MonthlyTodoDelete>((event, emit) {
      bool containsDay = event.selectedDailyDay.isBetweenDates(event.event.start, event.event.end);
      hive.deleteEvent(daily: false, event: event.event, containsSelectedDay: containsDay);
      emit(MonthlyTodoRefreshed(hive.thisMonthEventsMaps, containsDay));
    });
    on<MonthlyTodoDateChange>((event, emit) {
      hive.getMonthlyEvents(date: event.date);
      emit(MonthlyTodoRefreshed(hive.thisMonthEventsMaps, false));
    });
  }
}
