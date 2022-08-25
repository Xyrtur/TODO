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
  const TodoCreate({required this.event});
}

class TodoAddUnfinished extends TodoEvent {
  final EventData event;
  const TodoAddUnfinished({required this.event});
}

class TodoUpdate extends TodoEvent {
  final EventData event;
  const TodoUpdate({required this.event});
}

class TodoDelete extends TodoEvent {
  final EventData event;
  const TodoDelete({required this.event});
}

class TodoDateChange extends TodoEvent {
  final DateTime date;
  const TodoDateChange({required this.date});
}

abstract class TodoState extends Equatable {
  final List<dynamic> orderedDailyKeyList;
  final Map<dynamic, EventData> dailyTableMap;
  const TodoState(this.orderedDailyKeyList, this.dailyTableMap);
  @override
  List<Object> get props => [orderedDailyKeyList, dailyTableMap];
}

class TodoInitial extends TodoState {
  const TodoInitial(super.orderedDailyKeyList, super.dailyTableMap);
}

class TodoRefreshed extends TodoState {
  const TodoRefreshed(super.orderedDailyKeyList, super.dailyTableMap);
}

class TodoBloc extends Bloc<TodoEvent, TodoState> {
  final HiveRepository hive;

  TodoBloc(this.hive) : super(TodoInitial(hive.inOrderDailyTableEvents, hive.dailyTableEventsMap)) {
    on<TodoCreate>((event, emit) {
      hive.createEvent(daily: true, event: event.event);
      emit(TodoRefreshed(hive.inOrderDailyTableEvents, hive.dailyTableEventsMap));
    });
    on<TodoAddUnfinished>((event, emit) {
      hive.addUnfinishedEvent(event: event.event);
      emit(TodoRefreshed(hive.inOrderDailyTableEvents, hive.dailyTableEventsMap));
    });
    on<TodoUpdate>((event, emit) {
      hive.updateEvent(daily: true, event: event.event);
      emit(TodoRefreshed(hive.inOrderDailyTableEvents, hive.dailyTableEventsMap));
    });
    on<TodoDelete>((event, emit) {
      hive.deleteEvent(daily: true, event: event.event);
      emit(TodoRefreshed(hive.inOrderDailyTableEvents, hive.dailyTableEventsMap));
    });
    on<TodoDateChange>((event, emit) {
      hive.getDailyEvents(date: event.date);
      emit(TodoRefreshed(hive.inOrderDailyTableEvents, hive.dailyTableEventsMap));
    });
  }
}
