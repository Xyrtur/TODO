import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:equatable/equatable.dart';

import '../models/future_todo.dart';

abstract class ExpandableEvent extends Equatable {
  final List<FutureTodo> todoList;
  final int? indexTapped;
  final bool expanding;
  const ExpandableEvent(this.todoList, this.indexTapped, this.expanding);
  @override
  List<Object> get props => [];
}

class ExpandableUpdate extends ExpandableEvent {
  const ExpandableUpdate(super.todoList, super.indexTapped, super.expanding);
}

abstract class ExpandableState {
  final List<int> indexesToBeExpandedCollapsed;
  final bool expanding;

  const ExpandableState(this.indexesToBeExpandedCollapsed, this.expanding);

  List<Object> get props => [indexesToBeExpandedCollapsed, expanding];
}

class ExpandableInitial extends ExpandableState {
  const ExpandableInitial(super.indexesToBeExpandedCollapsed, super.expanding);
}

class ExpandableUpdated extends ExpandableState {
  const ExpandableUpdated(super.indexesToBeExpandedCollapsed, super.expanding);
}

/*
 * Keeps track of the todo's in the unfinished list
 * Updates the list if one is deleted from the list or taken out to add into the daily todo list
 */
class ExpandableBloc extends Bloc<ExpandableEvent, ExpandableState> {
  ExpandableBloc() : super(const ExpandableInitial([], true)) {
    on<ExpandableUpdate>((event, emit) async {
      int? indexTapped = event.indexTapped;
      List<int> toBeExpandedCollapsedIndexes = [];

      if (indexTapped != null) {
        for (int i = indexTapped + 1;
            i < event.todoList.length && event.todoList[indexTapped].indented < event.todoList[i].indented;
            i++) {
          if (event.expanding && event.todoList[i].indented == event.todoList[indexTapped].indented + 1) {
            toBeExpandedCollapsedIndexes.add(i);
          } else if (!event.expanding) {
            toBeExpandedCollapsedIndexes.add(i);
          }
        }
      }
      emit(ExpandableUpdated(toBeExpandedCollapsedIndexes, event.expanding));
    });
  }
}
