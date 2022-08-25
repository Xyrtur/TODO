import 'package:flutter/material.dart';
import 'package:flutter_svg/svg.dart';
import 'package:intl/intl.dart';
import 'package:todo/models/event_data.dart';
import 'package:todo/utils/centre.dart';
import 'package:todo/widgets/dialogs/add_event_dialog.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:todo/blocs/cubits.dart';
import '../../utils/datetime_ext.dart';

class DayDialog extends StatelessWidget {
  final int day;
  final String weekday;
  final List<EventData> dayEvents;
  const DayDialog({super.key, required this.day, required this.weekday, required this.dayEvents});

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
        shape: const RoundedRectangleBorder(borderRadius: BorderRadius.all(Radius.circular(40))),
        backgroundColor: Centre.dialogBgColor,
        elevation: 5,
        content: SizedBox(
            height: Centre.safeBlockVertical * 50,
            width: Centre.safeBlockHorizontal * 80,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Padding(
                      padding: EdgeInsets.only(left: Centre.safeBlockHorizontal * 3),
                      child: Column(
                        children: [
                          Text(
                            day.toString(),
                            style: Centre.todoSemiTitle,
                          ),
                          Text(
                            weekday,
                            style: Centre.todoText,
                          ),
                        ],
                      ),
                    ),
                    const Expanded(
                        child: SizedBox(
                      height: 10,
                    )),
                    GestureDetector(
                      onTap: () => showDialog(
                          context: context,
                          builder: (BuildContext context) => MultiBlocProvider(
                                providers: [
                                  BlocProvider<TimeRangeCubit>(
                                    create: (_) => TimeRangeCubit(TimeRangeState(null, null)),
                                  ),
                                  BlocProvider<ColorCubit>(
                                    create: (_) => ColorCubit(null),
                                  ),
                                  BlocProvider<CalendarTypeCubit>(
                                    create: (_) => CalendarTypeCubit(null),
                                  ),
                                  BlocProvider<DialogDatesCubit>(
                                      create: (_) => DialogDatesCubit(
                                          [context.read<MonthDateCubit>().state.add(Duration(days: day))])),
                                  BlocProvider(create: (_) => CheckboxCubit())
                                ],
                                child: AddEventDialog.monthly(
                                  monthOrDayDate: context.read<MonthDateCubit>().state,
                                ),
                              )),
                      child: Container(
                        margin: EdgeInsets.symmetric(horizontal: Centre.safeBlockHorizontal * 2),
                        padding: EdgeInsets.all(Centre.safeBlockHorizontal * 0.5),
                        height: Centre.safeBlockVertical * 5,
                        width: Centre.safeBlockVertical * 6,
                        child: SvgPicture.asset(
                          "assets/icons/add.svg",
                          color: Centre.colors[3],
                        ),
                      ),
                    ),
                  ],
                ),
                Padding(
                  padding: EdgeInsets.only(top: Centre.safeBlockVertical * 1),
                  child: const Divider(
                    color: Colors.grey,
                  ),
                ),
                SingleChildScrollView(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.center,
                    children: dayEvents
                        .map((event) => GestureDetector(
                              onTap: () => showDialog(
                                  context: context,
                                  builder: (BuildContext context) => MultiBlocProvider(
                                          providers: [
                                            BlocProvider<TimeRangeCubit>(
                                              create: (_) => TimeRangeCubit((event.fullDay)
                                                  ? TimeRangeState(null, null)
                                                  : TimeRangeState(
                                                      TimeOfDay(hour: event.start.hour, minute: event.start.minute),
                                                      TimeOfDay(hour: event.end.hour, minute: event.end.minute))),
                                            ),
                                            BlocProvider<ColorCubit>(
                                              create: (_) => ColorCubit(!Centre.colors.contains(Color(event.color))
                                                  ? null
                                                  : Centre.colors.indexOf(Color(event.color))),
                                            ),
                                            BlocProvider<CalendarTypeCubit>(
                                              create: (_) => CalendarTypeCubit(event.fullDay &&
                                                      !event.start.isSameDate(other: event.end, daily: false)
                                                  ? CalendarType.ranged
                                                  : CalendarType.single),
                                            ),
                                            BlocProvider<DialogDatesCubit>(
                                                create: (_) => DialogDatesCubit(event.fullDay &&
                                                        !event.start.isSameDate(other: event.end, daily: false)
                                                    ? [event.start, event.end]
                                                    : [event.start])),
                                            BlocProvider(create: (_) => CheckboxCubit())
                                          ],
                                          child: AddEventDialog.monthly(
                                            monthOrDayDate: DateTime(context.read<MonthDateCubit>().state.year,
                                                context.read<MonthDateCubit>().state.month, day),
                                            event: event,
                                          ))),
                              child: Padding(
                                padding: EdgeInsets.only(bottom: Centre.safeBlockVertical * 2),
                                child: Row(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Container(
                                      margin: EdgeInsets.only(
                                          left: Centre.safeBlockHorizontal * 6, right: Centre.safeBlockHorizontal * 3),
                                      height: Centre.safeBlockVertical * 3.5,
                                      width: Centre.safeBlockVertical * 3.5,
                                      child: SvgPicture.asset(
                                        "assets/icons/squiggle.svg",
                                        color: Color(event.color),
                                      ),
                                    ),
                                    Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                                      Text(
                                        event.text,
                                        style: Centre.dialogText,
                                      ),
                                      event.fullDay
                                          ? SizedBox(
                                              width: 0,
                                              height: 0,
                                            )
                                          : Container(
                                              margin: EdgeInsets.only(top: Centre.safeBlockVertical * 0.5),
                                              padding: EdgeInsets.all(Centre.safeBlockHorizontal),
                                              decoration: BoxDecoration(
                                                  color: Colors.grey,
                                                  borderRadius: BorderRadius.all(Radius.circular(4))),
                                              height: Centre.safeBlockHorizontal * 5,
                                              child: Center(
                                                child: Text(
                                                  "${DateFormat("HHmm").format(event.start)}-${DateFormat("HHmm").format(event.end)}",
                                                  style: Centre.todoText
                                                      .copyWith(fontSize: Centre.safeBlockHorizontal * 3),
                                                ),
                                              ),
                                            )
                                    ])
                                  ],
                                ),
                              ),
                            ))
                        .toList(),
                  ),
                )
              ],
            )));
  }
}
