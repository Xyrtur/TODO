import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:equatable/equatable.dart';

import 'package:todo/models/event_data.dart';
import 'package:todo/utils/hive_repository.dart';

abstract class TodoEvent extends Equatable {
  const TodoEvent();
  @override
  List<Object> get props => [];
}

class TodoCreate extends TodoEvent {
  final EventData event;
  final DateTime? date;
  const TodoCreate({required this.event, this.date});
}

class TodoFromUnfinished extends TodoEvent {
  final EventData event;
  const TodoFromUnfinished({required this.event});
}

class TodoToUnfinished extends TodoEvent {
  final EventData event;
  const TodoToUnfinished({required this.event});
}

class TodoUpdate extends TodoEvent {
  final EventData event;
  final bool fromDailyMonthlyList;
  const TodoUpdate({required this.event, required this.fromDailyMonthlyList});
}

class TodoDelete extends TodoEvent {
  final EventData event;
  const TodoDelete({required this.event});
}

class TodoDateChange extends TodoEvent {
  final DateTime date;
  const TodoDateChange({required this.date});
}

abstract class TodoState {
  final List<dynamic> orderedDailyKeyList;
  final Map<dynamic, EventData> dailyTableMap;
  final bool dateChanged;
  const TodoState(this.orderedDailyKeyList, this.dailyTableMap, this.dateChanged);

  List<Object> get props => [orderedDailyKeyList, dailyTableMap, dateChanged];
}

class TodoInitial extends TodoState {
  const TodoInitial(super.orderedDailyKeyList, super.dailyTableMap, super.dateChanged);
}

class TodoRefreshed extends TodoState {
  const TodoRefreshed(super.orderedDailyKeyList, super.dailyTableMap, super.dateChanged);
}


class TodoBloc extends Bloc<TodoEvent, TodoState> {
  final HiveRepository hive;

/*
 * Keeps track of the changes in daily todo's
 * Possible events: 
 *    - Create
 *    - Update
 *    - Delete
 *    - Date Changed
 *    - Add Unfinished (if it's in the unfinished list, the event already exists in the box so another event should not be created)
 *  Returns the same state each time as each event updates the same list of data.
 */
  TodoBloc(this.hive) : super(TodoInitial(hive.inOrderDailyTableEvents, hive.dailyTableEventsMap, false)) {
    on<TodoCreate>((event, emit) {
      hive.createEvent(daily: true, event: event.event, currentDailyDate: event.date);
      emit(TodoRefreshed(hive.inOrderDailyTableEvents, hive.dailyTableEventsMap, false));
    });
    on<TodoFromUnfinished>((event, emit) {
      hive.addUnfinishedEvent(event: event.event);
      emit(TodoRefreshed(hive.inOrderDailyTableEvents, hive.dailyTableEventsMap, false));
    });
    on<TodoToUnfinished>((event, emit) {
      hive.addDailyToUnfinished(event: event.event);
      emit(TodoRefreshed(hive.inOrderDailyTableEvents, hive.dailyTableEventsMap, false));
    });
    on<TodoUpdate>((event, emit) {
      // if on the dailymonthly list, create a new event for the daily hive since an object cant be stored in two boxes at a time
      if (event.fromDailyMonthlyList) {
        hive.createEvent(daily: true, event: event.event);
        emit(TodoRefreshed(hive.inOrderDailyTableEvents, hive.dailyTableEventsMap, false));
        return;
      }
      hive.updateEvent(daily: true, event: event.event);
      emit(TodoRefreshed(hive.inOrderDailyTableEvents, hive.dailyTableEventsMap, false));
    });
    on<TodoDelete>((event, emit) {
      hive.deleteEvent(daily: true, event: event.event);
      emit(TodoRefreshed(hive.inOrderDailyTableEvents, hive.dailyTableEventsMap, false));
    });
    on<TodoDateChange>((event, emit) {
      hive.getDailyEvents(date: event.date);
      emit(TodoRefreshed(hive.inOrderDailyTableEvents, hive.dailyTableEventsMap, true));
    });
  }
}
