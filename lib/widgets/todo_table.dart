import 'package:flutter/material.dart';
import 'package:todo/blocs/blocs_barrel.dart';
import 'package:todo/utils/centre.dart';
import 'package:todo/utils/datetime_ext.dart';
import 'package:todo/widgets/dialogs/add_event_dialog.dart';

class TodoTable extends StatelessWidget {
  final GlobalKey dottedOutlineKey;
  const TodoTable({super.key, required this.dottedOutlineKey});

  @override
  Widget build(BuildContext context) {
    return BlocBuilder<TodoBloc, TodoState>(buildWhen: (previousState, state) {
      return true;
    }, builder: (context, state) {
      DateTime currentDate = context.read<DateCubit>().state;
      List<Widget> schedBlockList = [];

      // Marks whether or not going through the events has passed 1600 yet or not
      // We only want to make the checks once
      bool barrierHit = false;

      // Go through each of the events in their order
      for (dynamic key in state.orderedDailyKeyList) {
        EventData event = state.dailyTableMap[key]!;

        // Marks the middle of the table schedule where it breaks to the next side
        DateTime mark16 = currentDate.add(const Duration(hours: 16));

        if (!barrierHit && event.start.isBefore(mark16) && event.end.isAfter(mark16)) {
          barrierHit = true;
          // Creates two schedule blocks for one event, one block for each side of the table

          // Want to know which block is larger, the block before 1600 or after to see which block displays the event text
          bool firstBlockLarger = mark16.difference(event.start).inMinutes >= event.end.difference(mark16).inMinutes;

          // Only wrap the split schedule blocks with the cubit so that dragging one also affects the other
          schedBlockList.add(BlocBuilder<DraggingSplitBlockCubit, bool>(
            builder: (context, state) => ScheduleBlock(
                dottedOutlineKey: dottedOutlineKey,
                event: event.copyWith(otherEnd: mark16),
                dragging: state,
                actualEvent: event,
                firstBlockLarger: firstBlockLarger,
                currentDate: currentDate.add(const Duration(hours: 7)),
                context: context),
          ));

          schedBlockList.add(BlocBuilder<DraggingSplitBlockCubit, bool>(
              builder: (context, state) => ScheduleBlock(
                  dottedOutlineKey: dottedOutlineKey,
                  firstBlockLarger: !firstBlockLarger,
                  dragging: state,
                  event: event.copyWith(otherStart: mark16),
                  actualEvent: event,
                  currentDate: currentDate.add(const Duration(hours: 7)),
                  context: context)));
        } else {
          schedBlockList.add(ScheduleBlock(
              dottedOutlineKey: dottedOutlineKey,
              event: event,
              currentDate: currentDate.add(const Duration(hours: 7)),
              context: context));
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
      required this.dottedOutlineKey,
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
  final GlobalKey dottedOutlineKey;
  double top = 0;
  double bottom = 0;
  double left = 0;
  bool firstBlockLarger;

  double middleOfTableWithBlockOffset = Centre.safeBlockHorizontal * 50 - (Centre.safeBlockHorizontal * 35) / 2;

  @override
  Widget build(BuildContext context) {
    Widget containerBlock(bool feedBack) {
      int heightInMinutes = (feedBack ? actualEvent ?? event : event)
          .end
          .difference((feedBack ? actualEvent ?? event : event).start)
          .inMinutes;
      return Material(
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
          padding: EdgeInsets.symmetric(horizontal: Centre.safeBlockHorizontal * 2),
          height: Centre.scheduleBlock * (heightInMinutes / 60),
          child: firstBlockLarger || feedBack
              ? Center(
                  child: Text(
                    event.text.replaceAll(' ', '\u00A0'),
                    maxLines: heightInMinutes > 45
                        ? 3
                        : heightInMinutes >= 30
                            ? 2
                            : 1,
                    textAlign: TextAlign.center,
                    textHeightBehavior:
                        const TextHeightBehavior(applyHeightToFirstAscent: false, applyHeightToLastDescent: false),
                    overflow: TextOverflow.ellipsis,
                    style: Centre.todoText.copyWith(
                        color: event.finished ? Centre.textColor : Colors.black,
                        height: 1,
                        decoration: event.finished ? TextDecoration.lineThrough : null),
                  ),
                )
              : const SizedBox(
                  width: 0,
                  height: 0,
                ),
        ),
      );
    }

    showDailyDialog() {
      showDialog(
          context: context,
          builder: (BuildContext dialogContext) {
            return GestureDetector(
                onTap: () {},
                child: Scaffold(
                  backgroundColor: Colors.transparent,
                  body: MultiBlocProvider(
                      providers: [
                        BlocProvider<TimeRangeCubit>(
                          create: (_) => TimeRangeCubit(TimeRangeState(
                              TimeOfDay(
                                  hour: (actualEvent ?? event).start.hour, minute: (actualEvent ?? event).start.minute),
                              TimeOfDay(
                                  hour: (actualEvent ?? event).end.hour, minute: (actualEvent ?? event).end.minute))),
                        ),
                        BlocProvider<ColorCubit>(
                          create: (_) => ColorCubit(Centre.colors.indexOf(Color((actualEvent ?? event).color))),
                        ),
                        BlocProvider.value(value: context.read<DateCubit>()),
                        BlocProvider<DailyTimeBtnsCubit>(
                          create: (_) => DailyTimeBtnsCubit(),
                        ),
                        BlocProvider.value(value: context.read<TodoBloc>()),
                        BlocProvider.value(value: context.read<UnfinishedListBloc>()),
                      ],
                      child: AddEventDialog.daily(
                        event: actualEvent ?? event,
                      )),
                ));
          });
    }

    // Get the initial position of the block on the table
    top = Centre.scheduleBlock * (event.start.difference(currentDate).inMinutes % 540 / 60);
    bottom = top + Centre.scheduleBlock * (event.end.difference(event.start).inMinutes / 60);
    left = event.start.isBefore(currentDate.add(const Duration(hours: 9))) &&
            (event.start.isAfter(currentDate) || event.start.isAtSameMomentAs(currentDate))
        ? Centre.safeBlockHorizontal * 5
        : Centre.safeBlockHorizontal * 54;

    return Positioned(
      // Add offset to top so that the box is more aligned with dotted lines
      top: top.toDouble() + 0.5,
      left: left,
      child: LongPressDraggable(
        delay: const Duration(milliseconds: 100),
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

          RenderBox box = dottedOutlineKey.currentContext!.findRenderObject() as RenderBox;
          Offset position = box.localToGlobal(Offset.zero);
          double topOfTable = position.dy;

          // Ensure the block was dragged to an appropriate spot, if not return it to its original spot
          if (drag.offset.dy < topOfTable && (drag.offset.dx <= middleOfTableWithBlockOffset) ||
              drag.offset.dy > topOfTable + Centre.scheduleBlock * 8.75 &&
                  (drag.offset.dx > middleOfTableWithBlockOffset)) {
            return;
          } else {
            // Round to the nearest 5 minutes
            top = ((drag.offset.dy - topOfTable) / (Centre.scheduleBlock * 5 / 60)).round() *
                (Centre.scheduleBlock * 5 / 60);
          }

          // Set the left side of the block
          if (drag.offset.dx > middleOfTableWithBlockOffset) {
            left = Centre.safeBlockHorizontal * 54;
          } else {
            left = Centre.safeBlockHorizontal * 5;
          }

          // Get the start and end times from the position the block was dragged to
          DateTime start = currentDate.add(Duration(
              minutes:
                  (top / Centre.scheduleBlock * 60 + (left == Centre.safeBlockHorizontal * 54 ? 540 : 0)).round()));

          DateTime end = start.add(Duration(minutes: (height / Centre.scheduleBlock * 60).round()));

          // If it adds such that the end goes past 1 am, ignore the drag
          if (end.isAfter(currentDate.add(const Duration(hours: 18)))) return;

          // Check if the event clashes/overlaps with any other events on the table
          for (EventData v in context.read<TodoBloc>().state.dailyTableMap.values) {
            if (v.key == (actualEvent?.key ?? event.key)) continue;
            if (start.isInTimeRange(v.start, v.end) ||
                end.isInTimeRange(v.start, v.end) ||
                start.enclosesOrContains(end, v.start, v.end)) {
              return;
            }
          }

          // Update the event with the new times, which rebuilds the table
          context.read<TodoBloc>().add(TodoUpdate(
              fromDailyMonthlyList: false,
              event: (actualEvent ?? event).edit(
                  fullDay: (actualEvent ?? event).fullDay,
                  start: start,
                  end: end,
                  color: (actualEvent ?? event).color,
                  text: (actualEvent ?? event).text,
                  finished: (actualEvent ?? event).finished)));
        },
        feedback: containerBlock(true),
        childWhenDragging: Container(
          color: Colors.transparent,
          width: Centre.safeBlockHorizontal * 35,
          height: Centre.scheduleBlock *
              ((actualEvent ?? event).end.difference((actualEvent ?? event).start).inMinutes / 60),
        ),
        child: GestureDetector(
          onTap: () {
            if (context.read<ToggleChecklistEditingCubit>().state) {
              showDailyDialog();
            } else {
              context
                  .read<TodoBloc>()
                  .add(TodoUpdate(fromDailyMonthlyList: false, event: (actualEvent ?? event).toggleFinished()));
            }
          },
          child: !(dragging ?? false)
              ? containerBlock(false)
              : Container(
                  color: Colors.transparent,
                  width: Centre.safeBlockHorizontal * 35,
                  //
                  height: Centre.scheduleBlock * (event.end.difference(event.start).inMinutes / 60),
                ),
        ),
      ),
    );
  }
}
