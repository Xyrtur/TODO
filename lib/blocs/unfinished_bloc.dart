import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:equatable/equatable.dart';

import 'package:todo/models/event_data.dart';
import 'package:todo/utils/hive_repository.dart';

abstract class UnfinishedListEvent extends Equatable {
  const UnfinishedListEvent();
  @override
  List<Object> get props => [];
}

class UnfinishedListUpdate extends UnfinishedListEvent {
  const UnfinishedListUpdate();
}

class UnfinishedListResume extends UnfinishedListEvent {
  const UnfinishedListResume();
}

class UnfinishedListRemove extends UnfinishedListEvent {
  final EventData event;
  const UnfinishedListRemove({required this.event});
}

abstract class UnfinishedListState {
  final List<EventData> unfinishedList;
  const UnfinishedListState(this.unfinishedList);

  List<Object> get props => [unfinishedList];
}

class UnfinishedListInitial extends UnfinishedListState {
  const UnfinishedListInitial(super.unfinishedList);
}

class UnfinishedListUpdated extends UnfinishedListState {
  const UnfinishedListUpdated(super.unfinishedList);
}

/*
 * Keeps track of the todo's in the unfinished list
 * Updates the list if one is deleted from the list or taken out to add into the daily todo list
 */
class UnfinishedListBloc extends Bloc<UnfinishedListEvent, UnfinishedListState> {
  final HiveRepository hive;

  UnfinishedListBloc(this.hive) : super(UnfinishedListInitial(hive.unfinishedEventsMap.values.toList())) {
    on<UnfinishedListUpdate>((event, emit) async {
      emit(UnfinishedListUpdated(hive.unfinishedEventsMap.values.toList()));
    });
    on<UnfinishedListRemove>((event, emit) async {
      hive.deleteEvent(daily: true, event: event.event);
      emit(UnfinishedListUpdated(hive.unfinishedEventsMap.values.toList()));
    });
    on<UnfinishedListResume>((event, emit) async {
      hive.updateUnfinishedListOnResume();
      emit(UnfinishedListUpdated(hive.unfinishedEventsMap.values.toList()));
    });
  }
}
