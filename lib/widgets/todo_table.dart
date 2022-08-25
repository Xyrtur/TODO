import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:todo/blocs/cubits.dart';
import 'package:todo/blocs/daily_todo_bloc.dart';
import 'package:todo/models/event_data.dart';
import 'package:todo/utils/centre.dart';
import 'package:todo/widgets/dialogs/add_event_dialog.dart';
import '../utils/datetime_ext.dart';

class TodoTable extends StatelessWidget {
  const TodoTable({super.key, required this.currentDate});
  final DateTime currentDate;

  @override
  Widget build(BuildContext context) {
    return BlocBuilder<TodoBloc, TodoState>(builder: (context, state) {
      List<ScheduleBlock> schedBlockList = [];
      bool barrierHit = false;
      for (dynamic key in state.orderedDailyKeyList) {
        EventData event = state.dailyTableMap[key]!;
        DateTime mark16 = currentDate.add(const Duration(hours: 16));
        if (!barrierHit && event.start.isBefore(mark16) && event.end.isAfter(mark16)) {
          barrierHit = true;
          bool firstBlockLarger = mark16.difference(event.start).inMinutes >= event.end.difference(mark16).inMinutes;

          schedBlockList.add(ScheduleBlock(
              event: event.copyWith(otherEnd: mark16),
              actualEvent: event,
              firstBlockLarger: firstBlockLarger,
              currentDate: currentDate.add(const Duration(hours: 7)),
              context: context));

          schedBlockList.add(ScheduleBlock(
              firstBlockLarger: !firstBlockLarger,
              event: event.copyWith(otherStart: mark16),
              actualEvent: event,
              currentDate: currentDate.add(const Duration(hours: 7)),
              context: context));
        } else {
          schedBlockList.add(
              ScheduleBlock(event: event, currentDate: currentDate.add(const Duration(hours: 7)), context: context));
        }
      }
      return Stack(children: schedBlockList);
    });
  }
}

// ignore: must_be_immutable
class ScheduleBlock extends StatelessWidget {
  ScheduleBlock(
      {super.key,
      this.actualEvent,
      required this.event,
      required this.currentDate,
      required this.context,
      this.firstBlockLarger = true});
  final BuildContext context;
  final DateTime currentDate;
  final EventData event;
  final EventData? actualEvent;
  double top = 0;
  double bottom = 0;
  double left = 0;
  bool firstBlockLarger;

  @override
  Widget build(BuildContext context) {
    top = Centre.scheduleBlock * (event.start.difference(currentDate).inMinutes % 540 / 60);
    bottom = top + Centre.scheduleBlock * (event.end.difference(event.start).inMinutes / 60);
    left = event.start.hour >= 16 ? Centre.safeBlockHorizontal * 54 : Centre.safeBlockHorizontal * 5;
    return Positioned(
      top: top,
      left: left,
      child: Draggable(
        onDragEnd: (drag) {
          double height = Centre.scheduleBlock * (event.end.difference(event.start).inMinutes / 60);
          if (drag.offset.dy < Centre.safeBlockVertical * 15 ||
              drag.offset.dy > Centre.safeBlockVertical * 15.5 + Centre.scheduleBlock * 8.75) {
          } else {
            top = ((drag.offset.dy - Centre.safeBlockVertical * 15) / (Centre.scheduleBlock * 5 / 60)).roundToDouble() *
                (Centre.scheduleBlock * 5 / 60);
          }
          if (drag.offset.dx > Centre.safeBlockHorizontal * 50 - (Centre.safeBlockHorizontal * 35) / 2) {
            left = Centre.safeBlockHorizontal * 54;
          } else {
            left = Centre.safeBlockHorizontal * 5;
          }

          //TODO: convert to minutes and new start time and end time
          DateTime start = DateTime.now();
          DateTime end = DateTime.now();
          for (EventData v in context.read<TodoBloc>().state.dailyTableMap.values) {
            if (start.isInTimeRange(v.start, v.end) ||
                end.isInTimeRange(v.start, v.end) ||
                start.enclosesOrContains(end, v.start, v.end)) {
              return;
            }
          }

          // TODO: send to bloc the new time and end tiem
        },
        feedback: Container(
          decoration: BoxDecoration(
            borderRadius: const BorderRadius.all(Radius.circular(5)),
            color: event.finished ? Colors.transparent : Color(event.color),
          ),
          width: Centre.safeBlockHorizontal * 35,
          height: Centre.scheduleBlock * (event.end.difference(event.start).inMinutes / 60),
          child: Center(
            child: Text(
              event.text,
              style: Centre.todoText.copyWith(
                  color: event.finished ? Centre.textColor : Colors.black,
                  decoration: event.finished ? TextDecoration.lineThrough : null),
            ),
          ),
        ),
        childWhenDragging: Container(
          color: Colors.transparent,
          width: Centre.safeBlockHorizontal * 35,
          height: Centre.scheduleBlock * (event.end.difference(event.start).inMinutes / 60),
        ),
        child: GestureDetector(
          onTap: () {
            if (context.read<ToggleEditingCubit>().state) {
              showDialog(
                  context: context,
                  builder: (BuildContext context) => MultiBlocProvider(
                          providers: [
                            BlocProvider<TimeRangeCubit>(
                              create: (_) => TimeRangeCubit(TimeRangeState(
                                  TimeOfDay(
                                      hour: (actualEvent ?? event).start.hour,
                                      minute: (actualEvent ?? event).start.minute),
                                  TimeOfDay(
                                      hour: (actualEvent ?? event).end.hour,
                                      minute: (actualEvent ?? event).end.minute))),
                            ),
                            BlocProvider<ColorCubit>(
                              create: (_) => ColorCubit(Centre.colors.indexOf(Color((actualEvent ?? event).color))),
                            ),
                          ],
                          child: AddEventDialog.daily(
                            monthOrDayDate: currentDate,
                            orderedDailyKeyList: context.read<TodoBloc>().state.orderedDailyKeyList,
                            dailyTableMap: context.read<TodoBloc>().state.dailyTableMap,
                            event: actualEvent ?? event,
                          )));
            } else {
              context.read<TodoBloc>().add(TodoUpdate(event: (actualEvent ?? event).toggleFinished()));
            }
          },
          child: Container(
            decoration: BoxDecoration(
              borderRadius: const BorderRadius.all(Radius.circular(5)),
              color: event.finished ? Colors.transparent : Color(event.color),
            ),
            width: Centre.safeBlockHorizontal * 35,
            height: Centre.scheduleBlock * (event.end.difference(event.start).inMinutes / 60),
            child: firstBlockLarger
                ? Center(
                    child: Text(
                      event.text,
                      style: Centre.todoText.copyWith(
                          color: event.finished ? Centre.textColor : Colors.black,
                          decoration: event.finished ? TextDecoration.lineThrough : null),
                    ),
                  )
                : null,
          ),
        ),
      ),
    );
  }
}
