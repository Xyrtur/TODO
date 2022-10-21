import 'package:flutter/material.dart';
import 'package:flutter_svg/svg.dart';
import 'package:intl/intl.dart';

import 'package:todo/blocs/blocs_barrel.dart';
import 'package:todo/utils/centre.dart';
import 'package:todo/widgets/dialogs/add_event_dialog.dart';
import 'package:todo/utils/datetime_ext.dart';

class DayDialog extends StatelessWidget {
  final DateTime date;
  final DateTime currentMonth;
  DayDialog({super.key, required this.date, required this.currentMonth});
  final List<String> weekdays = ["Mon", "Tue", "Wed", "Thu", "Fri", "Sat", "Sun"];

  @override
  Widget build(BuildContext context) {
    Widget addButton = GestureDetector(
      onTap: () => showDialog(
        context: context,
        builder: (BuildContext dialogContext) {
          return GestureDetector(
              onTap: () => Navigator.pop(dialogContext),
              child: Scaffold(
                  backgroundColor: Colors.transparent,
                  body: MultiBlocProvider(
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
                      BlocProvider<DialogDatesCubit>(create: (_) => DialogDatesCubit([date])),
                      BlocProvider(create: (_) => CheckboxCubit(false)),
                      BlocProvider.value(value: context.read<MonthlyTodoBloc>()),
                      BlocProvider.value(value: context.read<DateCubit>()),
                    ],
                    child: AddEventDialog.monthly(
                      monthOrDayDate: context.read<MonthDateCubit>().state,
                    ),
                  )));
        },
      ),
      child: Container(
        margin: EdgeInsets.symmetric(horizontal: Centre.safeBlockHorizontal * 2),
        padding: EdgeInsets.all(Centre.safeBlockHorizontal * 0.5),
        height: Centre.safeBlockVertical * 5,
        width: Centre.safeBlockVertical * 6,
        child: Icon(
          Icons.add_circle_rounded,
          weight: 700,
          color: Centre.primaryColor,
          size: 45,
        ),
      ),
    );

    Widget dialogHeader = Row(
      children: [
        Padding(
          padding: EdgeInsets.only(left: Centre.safeBlockHorizontal * 3),
          child: Column(
            children: [
              Text(
                date.day.toString(),
                style: Centre.todoSemiTitle,
              ),
              Text(
                weekdays[date.weekday - 1],
                style: Centre.todoText,
              ),
            ],
          ),
        ),
        const Expanded(
            child: SizedBox(
          height: 10,
        )),
        addButton
      ],
    );

    Widget eventTile(EventData event) {
      return Padding(
        padding: EdgeInsets.only(bottom: Centre.safeBlockVertical * 1.5),
        child: Container(
          color: Colors.transparent,
          width: Centre.safeBlockHorizontal * 70,
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Container(
                margin: EdgeInsets.only(left: Centre.safeBlockHorizontal * 6, right: Centre.safeBlockHorizontal * 3),
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
                Container(
                  margin: EdgeInsets.only(top: Centre.safeBlockVertical * 0.5),
                  padding: EdgeInsets.all(Centre.safeBlockHorizontal),
                  decoration: BoxDecoration(
                      color: Centre.lighterDialogColor, borderRadius: const BorderRadius.all(Radius.circular(4))),
                  height: Centre.safeBlockHorizontal * 6,
                  child: Center(
                    child: Text(
                      !event.fullDay
                          ? "${DateFormat("HHmm").format(event.start.toLocal())}-${DateFormat("HHmm").format(event.end.toLocal())}"
                          : "All day",
                      style: Centre.todoText.copyWith(fontSize: Centre.safeBlockHorizontal * 3),
                    ),
                  ),
                )
              ])
            ],
          ),
        ),
      );
    }

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
                dialogHeader,
                Padding(
                  padding: EdgeInsets.only(top: Centre.safeBlockVertical * 1),
                  child: const Divider(
                    color: Colors.grey,
                  ),
                ),
                BlocBuilder<MonthlyTodoBloc, MonthlyTodoState>(builder: (context, state) {
                  return SizedBox(
                    height: Centre.safeBlockVertical * 41,
                    child: SingleChildScrollView(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.center,
                        children: state.monthlyMaps[date.monthlyMapDayIndex(currentMonth: currentMonth)].values
                            .toList()
                            .map((event) => GestureDetector(
                                onTap: () => showDialog(
                                      context: context,
                                      builder: (BuildContext dialogContext) {
                                        return GestureDetector(
                                            onTap: () => Navigator.pop(dialogContext),
                                            child: Scaffold(
                                                backgroundColor: Colors.transparent,
                                                body: MultiBlocProvider(
                                                    providers: [
                                                      BlocProvider<TimeRangeCubit>(
                                                        create: (_) => TimeRangeCubit((event.fullDay)
                                                            ? TimeRangeState(null, null)
                                                            : TimeRangeState(
                                                                TimeOfDay(
                                                                    hour: event.start.toLocal().hour,
                                                                    minute: event.start.toLocal().minute),
                                                                TimeOfDay(
                                                                    hour: event.end.toLocal().hour,
                                                                    minute: event.end.toLocal().minute))),
                                                      ),
                                                      BlocProvider<ColorCubit>(
                                                        create: (_) => ColorCubit(
                                                            !Centre.colors.contains(Color(event.color))
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
                                                                  !event.start
                                                                      .isSameDate(other: event.end, daily: false)
                                                              ? [event.start.toLocal(), event.end.toLocal()]
                                                              : [event.start.toLocal()])),
                                                      BlocProvider(create: (_) => CheckboxCubit(event.fullDay)),
                                                      BlocProvider.value(value: context.read<MonthlyTodoBloc>()),
                                                      BlocProvider.value(value: context.read<DateCubit>()),
                                                    ],
                                                    child: AddEventDialog.monthly(
                                                      monthOrDayDate: context.read<MonthDateCubit>().state,
                                                      event: event,
                                                    ))));
                                      },
                                    ),
                                child: eventTile(event)))
                            .toList(),
                      ),
                    ),
                  );
                })
              ],
            )));
  }
}
