import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:todo/blocs/cubits.dart';
import 'package:todo/blocs/monthly_todo_bloc.dart';
import 'package:todo/models/event_data.dart';
import 'package:todo/utils/datetime_ext.dart';
import 'package:todo/widgets/dialogs/day_dialog.dart';
import '../utils/centre.dart';

class MonthCalendar extends StatelessWidget {
  MonthCalendar({super.key});
  final List<String> weekdays = ["Mon", "Tue", "Wed", "Thu", "Fri", "Sat", "Sun"];
  // have the block hold the dayNum

  @override
  Widget build(BuildContext context) {
    bool faded = true;
    var currentMonthStuff = context.read<MonthDateCubit>().state;
    int dayNum = currentMonthStuff.startingMonthCalenNum();
    return Padding(
      padding: EdgeInsets.all(Centre.safeBlockVertical * 2),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Padding(
            padding: EdgeInsets.only(bottom: Centre.safeBlockVertical * 1.5),
            child: Row(
              children: weekdays
                  .map((day) => SizedBox(
                        width: Centre.safeBlockHorizontal * 13.1,
                        child: Text(
                          day,
                          style: Centre.todoText.copyWith(color: Centre.pink),
                        ),
                      ))
                  .toList(),
            ),
          ),
          BlocListener<MonthDateCubit, DateTime>(
            listener: ((context, state) {
              faded = true;
              currentMonthStuff = context.read<MonthDateCubit>().state;
              dayNum = currentMonthStuff.startingMonthCalenNum();
              context.read<MonthlyTodoBloc>().add(MonthlyTodoDateChange(date: state));
            }),
            child: BlocBuilder<MonthlyTodoBloc, MonthlyTodoState>(
              builder: (context, state) => Expanded(
                child: Table(
                  children: [
                    for (int week = 1; week < 7; week++)
                      TableRow(
                          children: weekdays.map((day) {
                        if (week == 1 && dayNum == currentMonthStuff.totalDaysInPrevMonth()) {
                          dayNum = 1;
                          faded = false;
                        } else if (dayNum == currentMonthStuff.totalDaysInMonth()) {
                          dayNum = 1;
                          faded = true;
                        } else {
                          dayNum++;
                        }

                        return GestureDetector(
                          onTap: () => !faded
                              ? showDialog(
                                  context: context,
                                  builder: (BuildContext context) => DayDialog(
                                      day: dayNum,
                                      weekday: day,
                                      dayEvents: state.monthlyMaps[dayNum - 1].values.toList()))
                              : {},
                          child: Container(
                            height: Centre.safeBlockVertical * 15,
                            color: Colors.transparent,
                            child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: dayEvents(dayNum, faded, state.monthlyMaps[dayNum - 1].values)),
                          ),
                        );
                      }).toList())
                  ],
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

List<Widget> dayEvents(int dayNum, bool faded, Iterable<EventData> dayEventsList) {
  List<Widget> list = [
    Padding(
      padding: EdgeInsets.only(left: Centre.safeBlockHorizontal * 1, bottom: Centre.safeBlockVertical * 1),
      child: Text(
        dayNum.toString(),
        style: Centre.todoText.copyWith(color: faded ? Colors.grey : Centre.textColor),
      ),
    ),
  ];
  if (!faded) {
    List<Widget> eventList = dayEventsList.map((event) {
      if (event.fullDay && !event.start.isSameDate(other: event.end, daily: false)) {
        return Padding(
          padding: EdgeInsets.only(
              left: dayNum == event.start.day ? Centre.safeBlockHorizontal : 0,
              right: dayNum == event.end.day ? Centre.safeBlockHorizontal : 0,
              bottom: Centre.safeBlockVertical * 0.5),
          child: Container(
            decoration: BoxDecoration(
                color: Color(event.color),
                borderRadius: BorderRadius.horizontal(
                  left: dayNum == event.start.day ? const Radius.circular(10) : Radius.zero,
                  right: dayNum == event.end.day ? const Radius.circular(10) : Radius.zero,
                )),
            height: Centre.safeBlockVertical,
          ),
        );
      } else {
        return Padding(
          padding: EdgeInsets.only(
              left: Centre.safeBlockHorizontal,
              right: Centre.safeBlockHorizontal,
              bottom: Centre.safeBlockVertical * 0.5),
          child: Container(
            decoration:
                BoxDecoration(color: Color(event.color), borderRadius: const BorderRadius.all(Radius.circular(10))),
            height: Centre.safeBlockVertical,
          ),
        );
      }
    }).toList();
    list.addAll(eventList);
  }
  return list;
}
