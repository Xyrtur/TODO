import 'package:flutter/material.dart';
import 'package:todo/blocs/blocs_barrel.dart';
import 'package:todo/utils/centre.dart';
import 'package:todo/utils/datetime_ext.dart';
import 'package:todo/widgets/dialogs/add_event_dialog.dart';

class TodoTable extends StatelessWidget {
  const TodoTable({super.key});

  @override
  Widget build(BuildContext context) {
    return BlocBuilder<TodoBloc, TodoState>(buildWhen: (previousState, state) {
      return true;
    }, builder: (context, state) {
      DateTime currentDate = context.read<DateCubit>().state;
      List<Widget> schedBlockList = [];
      bool barrierHit = false;
      for (dynamic key in state.orderedDailyKeyList) {
        EventData event = state.dailyTableMap[key]!;
        DateTime mark16 = currentDate.add(const Duration(hours: 16));
        if (!barrierHit && event.start.isBefore(mark16) && event.end.isAfter(mark16)) {
          barrierHit = true;
          bool firstBlockLarger = mark16.difference(event.start).inMinutes >= event.end.difference(mark16).inMinutes;

          schedBlockList.add(BlocBuilder<DraggingSplitBlockCubit, bool>(
            builder: (context, state) => ScheduleBlock(
                event: event.copyWith(otherEnd: mark16),
                dragging: state,
                actualEvent: event,
                firstBlockLarger: firstBlockLarger,
                currentDate: currentDate.add(const Duration(hours: 7)),
                context: context),
          ));

          schedBlockList.add(BlocBuilder<DraggingSplitBlockCubit, bool>(
              builder: (context, state) => ScheduleBlock(
                  firstBlockLarger: !firstBlockLarger,
                  dragging: state,
                  event: event.copyWith(otherStart: mark16),
                  actualEvent: event,
                  currentDate: currentDate.add(const Duration(hours: 7)),
                  context: context)));
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
      this.dragging,
      this.firstBlockLarger = true});
  final BuildContext context;
  final DateTime currentDate;
  final bool? dragging;
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
    left = event.start.hour < 16 && event.start.hour >= 7
        ? Centre.safeBlockHorizontal * 5
        : Centre.safeBlockHorizontal * 54;
    return Positioned(
      top: top.toDouble(),
      left: left,
      child: LongPressDraggable(
        delay: const Duration(milliseconds: 50),
        onDragCompleted: () {
          if (actualEvent != null) {
            context.read<DraggingSplitBlockCubit>().letGo();
          }
        },
        onDragStarted: () {
          if (actualEvent != null) {
            context.read<DraggingSplitBlockCubit>().grabbedSplit();
          }
        },
        onDraggableCanceled: (velocity, offset) {
          if (actualEvent != null) {
            context.read<DraggingSplitBlockCubit>().letGo();
          }
        },
        onDragEnd: (drag) {
          double height = Centre.scheduleBlock *
              ((actualEvent ?? event).end.difference((actualEvent ?? event).start).inMinutes / 60);
          if (drag.offset.dy < Centre.safeBlockVertical * 16.2 &&
                  (drag.offset.dx <= (Centre.safeBlockHorizontal * 50 - (Centre.safeBlockHorizontal * 35) / 2)) ||
              drag.offset.dy > Centre.safeBlockVertical * 16.2 + Centre.scheduleBlock * 8.75 &&
                  (drag.offset.dx > (Centre.safeBlockHorizontal * 50 - (Centre.safeBlockHorizontal * 35) / 2))) {
            return;
          } else {
            top = ((drag.offset.dy - Centre.safeBlockVertical * 16.2) / (Centre.scheduleBlock * 5 / 60)).round() *
                (Centre.scheduleBlock * 5 / 60);
          }
          if (drag.offset.dx > Centre.safeBlockHorizontal * 50 - (Centre.safeBlockHorizontal * 35) / 2) {
            left = Centre.safeBlockHorizontal * 54;
          } else {
            left = Centre.safeBlockHorizontal * 5;
          }
          DateTime start = currentDate.add(Duration(
              minutes:
                  (top / Centre.scheduleBlock * 60 + (left == Centre.safeBlockHorizontal * 54 ? 540 : 0)).round()));
          DateTime end = start.add(Duration(minutes: (height / Centre.scheduleBlock * 60).round()));
          if (end.isAfter(currentDate.add(const Duration(hours: 18)))) return;
          for (EventData v in context.read<TodoBloc>().state.dailyTableMap.values) {
            if (v.key == (actualEvent?.key ?? event.key)) continue;
            if (start.isInTimeRange(v.start, v.end) ||
                end.isInTimeRange(v.start, v.end) ||
                start.enclosesOrContains(end, v.start, v.end)) {
              return;
            }
          }

          context.read<TodoBloc>().add(TodoUpdate(
              event: (actualEvent ?? event).edit(
                  fullDay: (actualEvent ?? event).fullDay,
                  start: start,
                  end: end,
                  color: (actualEvent ?? event).color,
                  text: (actualEvent ?? event).text,
                  finished: (actualEvent ?? event).finished)));
        },
        feedback: Material(
          color: Colors.transparent,
          child: Container(
            decoration: BoxDecoration(
                borderRadius: const BorderRadius.all(Radius.circular(5)),
                color: event.finished ? Colors.transparent : Color(event.color),
                border: event.finished
                    ? Border.all(
                        color: Color(event.color),
                        width: Centre.safeBlockHorizontal * 0.5,
                      )
                    : Border.all(width: 0)),
            width: Centre.safeBlockHorizontal * 35,
            height: Centre.scheduleBlock *
                ((actualEvent ?? event).end.difference((actualEvent ?? event).start).inMinutes / 60),
            child: Center(
              child: Text(
                event.text,
                style: Centre.todoText.copyWith(
                    color: event.finished ? Centre.textColor : Colors.black,
                    decoration: event.finished ? TextDecoration.lineThrough : null),
              ),
            ),
          ),
        ),
        childWhenDragging: Container(
          color: Colors.transparent,
          width: Centre.safeBlockHorizontal * 35,
          height: Centre.scheduleBlock *
              ((actualEvent ?? event).end.difference((actualEvent ?? event).start).inMinutes / 60),
        ),
        child: GestureDetector(
          onTap: () {
            if (context.read<ToggleChecklistEditingCubit>().state) {
              showDialog(
                  context: context,
                  builder: (BuildContext tcontext) => Scaffold(
                        backgroundColor: Colors.transparent,
                        body: MultiBlocProvider(
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
                              BlocProvider.value(value: context.read<DateCubit>()),
                              BlocProvider.value(value: context.read<TodoBloc>()),
                              BlocProvider.value(value: context.read<UnfinishedListBloc>()),
                            ],
                            child: AddEventDialog.daily(
                              event: actualEvent ?? event,
                            )),
                      ));
            } else {
              context.read<TodoBloc>().add(TodoUpdate(event: (actualEvent ?? event).toggleFinished()));
            }
          },
          child: !(dragging ?? false)
              ? Container(
                  decoration: BoxDecoration(
                      borderRadius: const BorderRadius.all(Radius.circular(5)),
                      color: event.finished ? Colors.transparent : Color(event.color),
                      border: event.finished
                          ? Border.all(
                              color: Color(event.color),
                              width: Centre.safeBlockHorizontal * 0.5,
                            )
                          : null),
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
                )
              : Container(
                  color: Colors.transparent,
                  width: Centre.safeBlockHorizontal * 35,
                  height: Centre.scheduleBlock * (event.end.difference(event.start).inMinutes / 60),
                ),
        ),
      ),
    );
  }
}
