import 'package:flutter/material.dart';
import 'package:todo/blocs/blocs_barrel.dart';

import 'package:todo/utils/datetime_ext.dart';
import 'package:todo/utils/centre.dart';
import 'package:todo/widgets/dialogs/day_dialog.dart';

class MonthCalendar extends StatelessWidget {
  final DateTime date;
  final List<Map<dynamic, EventData>> monthList;
  MonthCalendar({super.key, required this.date, required this.monthList});
  List<List<EventData?>> monthListCopy = List<List<EventData?>>.filled(42, []);

  final List<String> weekdays = [
    "Mon",
    "Tue",
    "Wed",
    "Thu",
    "Fri",
    "Sat",
    "Sun"
  ];

  @override
  Widget build(BuildContext context) {
    List<bool> fadedList = List.filled(42, true);

    var currentMonthStuff = date;
    DateTime dayNum = currentMonthStuff.startingMonthCalenNum();
    bool inMonth = dayNum.day == 1;
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
    return Padding(
      padding: EdgeInsets.all(Centre.safeBlockVertical * 2),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Padding(
            padding: EdgeInsets.only(bottom: Centre.safeBlockVertical * 1.5),
            // Weekday strings to display across the top of calendar
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
              // Listen for when the month date is changed and update the calendar
              currentMonthStuff = date;
              dayNum = currentMonthStuff.startingMonthCalenNum();

              // Make a list that tracks if the day is considered faded or not
              fadedList = List.filled(42, true);
              bool inMonth = dayNum.day == 1;
              int fakeDayNum = dayNum.day;
              for (int i = 0; i < 42; i++) {
                if (fakeDayNum > currentMonthStuff.totalDaysInPrevMonth() &&
                    !inMonth) {
                  inMonth = true;
                  fakeDayNum = 1;
                  fadedList[i] = false;
                } else if (inMonth &&
                    fakeDayNum > currentMonthStuff.totalDaysInMonth()) {
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
                  weekEndingNums.add(dayNum.add(Duration(days: 6 + i * 7)));
                }

                dayNum = dayNum.subtract(const Duration(days: 1));

                // Month calendar table
                return Expanded(
                  child: Table(
                    children: [
                      for (int week = 1; week < 7; week++)
                        TableRow(
                            children: weekdays.map((day) {
                          dayNum = dayNum.add(const Duration(hours: 24));
                          DateTime loopDayNum = dayNum;

                          return GestureDetector(
                            onTap: () {
                              if (!fadedList[
                                  (week - 1) * 7 + weekdays.indexOf(day)]) {
                                showDialog(
                                    context: context,
                                    builder: (BuildContext tcontext) =>
                                        MultiBlocProvider(
                                            providers: [
                                              BlocProvider.value(
                                                  value: context
                                                      .read<MonthlyTodoBloc>()),
                                              BlocProvider.value(
                                                  value: context
                                                      .read<DateCubit>()),
                                              BlocProvider.value(
                                                  value: context
                                                      .read<MonthDateCubit>()),
                                            ],
                                            child: DayDialog(
                                              date: loopDayNum,
                                              currentMonth: date,
                                            )));
                              }
                            },
                            child: Container(
                              height: Centre.safeBlockVertical * 15,
                              color: Colors.transparent,
                              child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: dayEvents(
                                      fadedList[(week - 1) * 7 +
                                          weekdays.indexOf(day)],
                                      dayNum,
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

  // Returns the list of event bars to display on each day of the calendar
  List<Widget> dayEvents(bool faded, DateTime dayNum,
      List<DateTime> weekStartingNums, List<DateTime> weekEndingNums) {
    List<Widget> list = [
      // Start the list with the day number in the top left always
      Padding(
        padding: EdgeInsets.only(
            left: Centre.safeBlockHorizontal * 1,
            bottom: Centre.safeBlockVertical * 0.5),
        child: Container(
          padding: EdgeInsets.fromLTRB(Centre.safeBlockVertical * 0.3, 0,
              Centre.safeBlockVertical * 0.3, Centre.safeBlockVertical * 0.3),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(5),
            color: dayNum.isSameDate(
                    other: DateTime.utc(DateTime.now().year,
                        DateTime.now().month, DateTime.now().day),
                    daily: false)
                ? Centre.secondaryColor
                : Colors.transparent,
          ),
          child: Text(
            dayNum.day.toString(),
            style: Centre.todoText.copyWith(
                color: faded
                    ? Colors.grey
                    : dayNum.isSameDate(
                            other: DateTime.utc(DateTime.now().year,
                                DateTime.now().month, DateTime.now().day),
                            daily: false)
                        ? Centre.bgColor
                        : Centre.textColor),
          ),
        ),
      ),
    ];

    // Sort the list to ensure the ranged event bars stay together across the calendar
    // Ensure that ranged events come first and then sort by time

    // This index logic ensure the correct for the day is grabbed since the list
    // contains events starting from the previous month into the next month afterwards as well
    int index = dayNum.monthlyMapDayIndex(currentMonth: date);

    monthListCopy[index] = monthList[index].values.toList();
    monthListCopy[index].sort((a, b) {
      if (a!.fullDay && !a.start.isSameDate(other: a.end, daily: false)) {
        if (!(b!.fullDay && !b.start.isSameDate(other: b.end, daily: false))) {
          return -1;
        } else {
          return a.start.compareTo(b.start);
        }
      }
      if (b!.fullDay && !b.start.isSameDate(other: b.end, daily: false)) {
        if (!(a.fullDay && !a.start.isSameDate(other: a.end, daily: false))) {
          return 1;
        } else {
          return a.start.compareTo(b.start);
        }
      }
      return a.start.compareTo(b.start);
    });

    // Deals with ranged event collisions
    List<EventData?> tempList = List<EventData?>.filled(7, null);
    // If not at the beginning of the monthCalen
    if (index != 0) {
      for (EventData? event in monthListCopy[index]) {
        // If event is ranged and currently not at beginning of the event, match the event with the index it was already assigned previouly
        if (event!.fullDay &&
            !event.start.isSameDate(other: event.end, daily: false) &&
            !dayNum.isSameDate(other: event.start, daily: false)) {
          tempList[monthListCopy[index - 1].indexOf(event)] = event;
        }
      }
    }
    for (EventData? event in monthListCopy[index]) {
      // If at the beginning of monthCalen OR the event is not ranged OR the event is ranged and are currently at beginning of event
      if (index == 0 ||
          event!.start.isSameDate(other: event.end, daily: false) ||
          event.fullDay &&
              !event.start.isSameDate(other: event.end, daily: false) &&
              dayNum.isSameDate(other: event.start, daily: false)) {
        // Look for first available spot, if not taken, take it as the future spots at that same index will not be taken
        for (int i = 0; i < 7; i++) {
          if (tempList[i] == null) {
            tempList[i] = event;
            break;
          }
        }
      }
    }
    monthListCopy[index] = tempList;

    // Creates the event widgets in the list
    List<Widget> eventList = monthListCopy[index].map((event) {
      if (event == null) {
        return SizedBox(
          height: Centre.safeBlockVertical * 1.6,
        );
      }
      // If the event is ranged
      if (event.fullDay &&
          !event.start.isSameDate(other: event.end, daily: false)) {
        return Container(
          // Margin and border logic to make the event look seamless across days on the calendar
          margin: EdgeInsets.only(
              left: dayNum.isSameDate(other: event.start, daily: false)
                  ? Centre.safeBlockHorizontal * 0.7
                  : 0,
              right: dayNum.isSameDate(other: event.end, daily: false)
                  ? Centre.safeBlockHorizontal * 0.7
                  : 0,
              bottom: Centre.safeBlockVertical * 0.3),
          padding: EdgeInsets.symmetric(
              horizontal: Centre.safeBlockHorizontal * 0.2),
          decoration: BoxDecoration(
              color: Color(event.color),
              borderRadius: BorderRadius.horizontal(
                left: dayNum.isSameDate(other: event.start, daily: false) ||
                        weekStartingNums.contains(dayNum)
                    ? const Radius.circular(10)
                    : Radius.zero,
                right: dayNum.isSameDate(other: event.end, daily: false) ||
                        weekEndingNums.contains(dayNum)
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
                  style: Centre.todoText.copyWith(
                      fontSize: Centre.safeBlockHorizontal * 2,
                      color: Centre.darkerBgColor),
                ))
              : null,
        );
      } else {
        return Container(
          margin: EdgeInsets.only(
              left: Centre.safeBlockHorizontal * 0.7,
              right: Centre.safeBlockHorizontal * 0.7,
              bottom: Centre.safeBlockVertical * 0.3),
          padding: EdgeInsets.symmetric(
              horizontal: Centre.safeBlockHorizontal * 0.2),
          decoration: BoxDecoration(
              color: Color(event.color),
              borderRadius: const BorderRadius.all(Radius.circular(10))),
          height: Centre.safeBlockVertical * 1.3,
          child: Center(
              child: Text(
            event.text.replaceAll(' ', '\u00A0'),
            overflow: TextOverflow.ellipsis,
            maxLines: 1,
            style: Centre.todoText.copyWith(
                fontSize: Centre.safeBlockHorizontal * 2,
                color: Centre.darkerBgColor),
          )),
        );
      }
    }).toList();
    list.addAll(eventList);

    // Only shows a max of 7 events on the calendar per day
    return list.length > 7 ? list.getRange(0, 8).toList() : list;
  }
}
