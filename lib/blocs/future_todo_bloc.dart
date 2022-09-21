import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:equatable/equatable.dart';

import 'package:todo/models/future_todo.dart';
import 'package:todo/utils/hive_repository.dart';

abstract class FutureTodoEvent extends Equatable {
  const FutureTodoEvent();
  @override
  List<Object> get props => [];
}

class FutureTodoCreate extends FutureTodoEvent {
  final FutureTodo event;
  const FutureTodoCreate({required this.event});
}

class FutureTodoUpdate extends FutureTodoEvent {
  final List<FutureTodo> eventList;
  const FutureTodoUpdate({required this.eventList});
}

class FutureTodoDelete extends FutureTodoEvent {
  final FutureTodo event;
  const FutureTodoDelete({required this.event});
}

abstract class FutureTodoState {
  final List<FutureTodo> futureList;
  const FutureTodoState(this.futureList);

  List<Object> get props => [futureList];
}

class FutureTodoInitial extends FutureTodoState {
  const FutureTodoInitial(super.futureList);
}

class FutureTodoRefreshed extends FutureTodoState {
  const FutureTodoRefreshed(super.futureList);
}

class FutureTodoBloc extends Bloc<FutureTodoEvent, FutureTodoState> {
  final HiveRepository hive;

/*
 * Keeps track of the changes in future todo's
 * Possible events: 
 *    - Create
 *    - Update
 *    - Delete
 *  Returns the same state each time as each event updates the same list of data.
 */
  FutureTodoBloc(this.hive) : super(FutureTodoInitial(hive.futureList)) {
    on<FutureTodoCreate>((event, emit) {
      hive.createFutureTodo(todo: event.event);
      emit(FutureTodoRefreshed(hive.futureList));
    });

    on<FutureTodoUpdate>((event, emit) {
      hive.updateFutureTodo(todoList: event.eventList);
      emit(FutureTodoRefreshed(hive.futureList));
    });
    on<FutureTodoDelete>((event, emit) {
      hive.deleteFutureTodo(todo: event.event);
      emit(FutureTodoRefreshed(hive.futureList));
    });
  }
}
