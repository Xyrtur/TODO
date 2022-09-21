import 'package:flutter/material.dart';
import 'package:todo/blocs/blocs_barrel.dart';

import 'package:todo/utils/datetime_ext.dart';
import 'package:todo/utils/centre.dart';
import 'package:todo/widgets/dialogs/day_dialog.dart';

class MonthCalendar extends StatelessWidget {
  MonthCalendar({super.key});
  final List<String> weekdays = ["Mon", "Tue", "Wed", "Thu", "Fri", "Sat", "Sun"];

  @override
  Widget build(BuildContext context) {
    List<bool> fadedList = List.filled(42, true);

    var currentMonthStuff = context.read<MonthDateCubit>().state;
    DateTime dayNum = currentMonthStuff.startingMonthCalenNum();
    bool inMonth = false;
    int fakeDayNum = dayNum.day;
    for (int i = 0; i < 42; i++) {
      if (fakeDayNum > currentMonthStuff.totalDaysInPrevMonth()) {
        inMonth = true;
        fakeDayNum = 1;
        fadedList[i] = false;
      } else if (inMonth && fakeDayNum > currentMonthStuff.totalDaysInMonth()) {
        break;
      } else if (inMonth) {
        fadedList[i] = false;
      }

      fakeDayNum++;
    }
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
              currentMonthStuff = state;
              dayNum = currentMonthStuff.startingMonthCalenNum();
              context.read<MonthlyTodoBloc>().add(MonthlyTodoDateChange(date: state));
              fadedList = List.filled(42, true);
              bool inMonth = false;
              int fakeDayNum = dayNum.day;
              for (int i = 0; i < 42; i++) {
                if (fakeDayNum > currentMonthStuff.totalDaysInPrevMonth() && !inMonth) {
                  inMonth = true;
                  fakeDayNum = 1;
                  fadedList[i] = false;
                } else if (inMonth && fakeDayNum > currentMonthStuff.totalDaysInMonth()) {
                  break;
                } else if (inMonth) {
                  fadedList[i] = false;
                }

                fakeDayNum++;
              }
            }),
            child: BlocBuilder<MonthlyTodoBloc, MonthlyTodoState>(
              builder: (context, state) {
                dayNum = currentMonthStuff.startingMonthCalenNum();
                List<DateTime> weekStartingNums = [];
                List<DateTime> weekEndingNums = [];
                for (int i = 0; i < 6; i++) {
                  weekStartingNums.add(dayNum.add(Duration(days: i * 7)));
                  weekEndingNums.add(dayNum.add(Duration(days: i * 6)));
                }

                return Expanded(
                  child: Table(
                    children: [
                      for (int week = 1; week < 7; week++)
                        TableRow(
                            children: weekdays.map((day) {
                          DateTime loopDayNum = dayNum;

                          return GestureDetector(
                            onTap: () {
                              if (!fadedList[(week - 1) * 7 + weekdays.indexOf(day)]) {
                                showDialog(
                                    context: context,
                                    builder: (BuildContext tcontext) => MultiBlocProvider(
                                            providers: [
                                              BlocProvider.value(value: context.read<MonthlyTodoBloc>()),
                                              BlocProvider.value(value: context.read<DateCubit>()),
                                              BlocProvider.value(value: context.read<MonthDateCubit>()),
                                            ],
                                            child: DayDialog(
                                                day: loopDayNum.day,
                                                weekday: day,
                                                dayEvents: state
                                                    .monthlyMaps[loopDayNum.isBefore(currentMonthStuff)
                                                        ? loopDayNum.day - currentMonthStuff.startingMonthCalenNum().day
                                                        : loopDayNum.isAfter(currentMonthStuff)
                                                            ? (currentMonthStuff.weekday - 1) +
                                                                currentMonthStuff.totalDaysInMonth() +
                                                                loopDayNum.day -
                                                                1
                                                            : loopDayNum.day - 1 + (currentMonthStuff.weekday - 1)]
                                                    .values
                                                    .toList())));
                              }
                            },
                            child: Container(
                              height: Centre.safeBlockVertical * 15,
                              color: Colors.transparent,
                              child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: dayEvents(
                                      state
                                          .monthlyMaps[dayNum.isBefore(currentMonthStuff)
                                              ? dayNum.day - currentMonthStuff.startingMonthCalenNum().day
                                              : dayNum.isAfter(currentMonthStuff)
                                                  ? (currentMonthStuff.weekday - 1) +
                                                      currentMonthStuff.totalDaysInMonth() +
                                                      dayNum.day -
                                                      1
                                                  : dayNum.day - 1 + (currentMonthStuff.weekday - 1)]
                                          .values,
                                      fadedList[(week - 1) * 7 + weekdays.indexOf(day)],
                                      dayNum.add(const Duration(days: 1)),
                                      weekStartingNums,
                                      weekEndingNums)),
                            ),
                          );
                        }).toList())
                    ],
                  ),
                );
              },
            ),
          ),
        ],
      ),
    );
  }
}

List<Widget> dayEvents(Iterable<EventData> dayEventsList, bool faded, DateTime dayNum, List<DateTime> weekStartingNums,
    List<DateTime> weekEndingNums) {
  List<Widget> list = [
    Padding(
      padding: EdgeInsets.only(left: Centre.safeBlockHorizontal * 1, bottom: Centre.safeBlockVertical * 1),
      child: Text(
        dayNum.toString(),
        style: Centre.todoText.copyWith(color: faded ? Colors.grey : Centre.textColor),
      ),
    ),
  ];
  List<EventData> sortedList = dayEventsList.toList();
  sortedList.sort((a, b) {
    if (a.fullDay && !a.start.isSameDate(other: a.end, daily: false)) {
      if (!(b.fullDay && !b.start.isSameDate(other: b.end, daily: false))) {
        return -1;
      } else {
        return a.start.compareTo(b.start);
      }
    }
    if (b.fullDay && !b.start.isSameDate(other: b.end, daily: false)) {
      if (!(a.fullDay && !a.start.isSameDate(other: a.end, daily: false))) {
        return 1;
      } else {
        return a.start.compareTo(b.start);
      }
    }
    return a.start.compareTo(b.start);
  });
  List<Widget> eventList = sortedList.map((event) {
    if (event.fullDay && !event.start.isSameDate(other: event.end, daily: false)) {
      return Container(
        margin: EdgeInsets.only(
            left: dayNum.isSameDate(other: event.start, daily: false) ? Centre.safeBlockHorizontal * 0.7 : 0,
            right: dayNum.isSameDate(other: event.end, daily: false) ? Centre.safeBlockHorizontal * 0.7 : 0,
            bottom: Centre.safeBlockVertical * 0.3),
        padding: EdgeInsets.symmetric(horizontal: Centre.safeBlockHorizontal * 0.2),
        decoration: BoxDecoration(
            color: Color(event.color),
            borderRadius: BorderRadius.horizontal(
              left: dayNum.isSameDate(other: event.start, daily: false) || weekStartingNums.contains(dayNum)
                  ? const Radius.circular(10)
                  : Radius.zero,
              right: dayNum.isSameDate(other: event.end, daily: false) || weekEndingNums.contains(dayNum)
                  ? const Radius.circular(10)
                  : Radius.zero,
            )),
        height: Centre.safeBlockVertical * 1.3,
        child: dayNum.isSameDate(other: event.start, daily: false)
            ? Center(
                child: Text(
                event.text.replaceAll(' ', '\u00A0'),
                maxLines: 1,
                overflow: TextOverflow.clip,
                style: Centre.todoText.copyWith(fontSize: Centre.safeBlockHorizontal * 2, color: Centre.darkerBgColor),
              ))
            : null,
      );
    } else {
      return Container(
        margin: EdgeInsets.only(
            left: Centre.safeBlockHorizontal * 0.7,
            right: Centre.safeBlockHorizontal * 0.7,
            bottom: Centre.safeBlockVertical * 0.3),
        padding: EdgeInsets.symmetric(horizontal: Centre.safeBlockHorizontal * 0.2),
        decoration: BoxDecoration(color: Color(event.color), borderRadius: const BorderRadius.all(Radius.circular(10))),
        height: Centre.safeBlockVertical * 1.3,
        child: Center(
            child: Text(
          event.text.replaceAll(' ', '\u00A0'),
          overflow: TextOverflow.ellipsis,
          maxLines: 1,
          style: Centre.todoText.copyWith(fontSize: Centre.safeBlockHorizontal * 2, color: Centre.darkerBgColor),
        )),
      );
    }
  }).toList();
  list.addAll(eventList);

  return list.length > 7 ? list.getRange(0, 8).toList() : list;
}
