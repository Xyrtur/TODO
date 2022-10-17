import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:intl/intl.dart';

import 'package:todo/blocs/blocs_barrel.dart';
import 'package:todo/utils/centre.dart';
import 'package:todo/utils/datetime_ext.dart';

class MonthlyPanel extends StatelessWidget {
  const MonthlyPanel({super.key});

  @override
  Widget build(BuildContext context) {
    final DateTime currentMonth = context.read<MonthDateCubit>().state;
    // First Sunday of the month
    int firstEnd = 8 - currentMonth.weekday;
    // Number of week tiles to create
    // Add 1 for the first week
    // Get number of days in month excluding those in the first week
    // Add the number of full weeks and then add another week using %
    int numWeeks = 1 +
        ((currentMonth.totalDaysInMonth() - firstEnd) / 7).floor() +
        (((currentMonth.totalDaysInMonth() - firstEnd) % 7) == 0 ? 0 : 1);

    List<Widget> getWeekList(int i, List<Map<dynamic, EventData>> monthlyList) {
      List<Widget> temp = [];
      int prevMonthOffset = (currentMonth.weekday - 1);

      for (int dayIndex = i == 0 ? 1 : firstEnd + 7 * i - 6;
          dayIndex <= (i == (numWeeks - 1) ? currentMonth.totalDaysInMonth() : firstEnd + 7 * i);
          dayIndex++) {
        for (EventData event in monthlyList[dayIndex - 1 + prevMonthOffset].values) {
          // if block ensures duplicates won't appear in the week list
          // If the dayIndex is for the beginning of a week or if the event did not exist on the previous day as well (possible if ranged)
          if (dayIndex == (i == 0 ? 1 : firstEnd + 7 * i - 6) ||
              monthlyList[dayIndex - 2 + prevMonthOffset][event.key] == null) {
            temp.add(Padding(
              padding: EdgeInsets.only(bottom: Centre.safeBlockVertical),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Container(
                    margin:
                        EdgeInsets.only(left: Centre.safeBlockHorizontal * 6, right: Centre.safeBlockHorizontal * 3),
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
                      decoration: BoxDecoration(
                          color: Centre.lighterDialogColor, borderRadius: const BorderRadius.all(Radius.circular(4))),
                      height: Centre.safeBlockHorizontal * 5,
                      width:
                          event.fullDay && !event.start.toLocal().isSameDate(other: event.end.toLocal(), daily: false)
                              ? Centre.safeBlockHorizontal * 10
                              : Centre.safeBlockHorizontal * 5,
                      child: Center(
                        child: Text(
                          event.fullDay && !event.start.toLocal().isSameDate(other: event.end.toLocal(), daily: false)
                              ? "${event.start.toLocal().day}-${event.end.toLocal().day}"
                              : event.start.toLocal().day.toString(),
                          style: Centre.todoText
                              .copyWith(fontSize: Centre.safeBlockHorizontal * 3, color: Centre.textColor),
                        ),
                      ),
                    )
                  ])
                ],
              ),
            ));
          }
        }
      }
      return temp;
    }

    List<Widget> getWeekTileList(List<Map<dynamic, EventData>> monthlyList) {
      List<Widget> temp = [];
      for (int i = 0; i < numWeeks; i++) {
        List<Widget> weekList = getWeekList(i, monthlyList);

        temp.add(ExpansionTile(
            collapsedIconColor: Centre.secondaryColor,
            iconColor: Centre.textColor,
            controlAffinity: ListTileControlAffinity.leading,
            title: Text(
              firstEnd + 7 * i - 6 == currentMonth.totalDaysInMonth() || firstEnd + 7 * i == 1
                  ? '${DateFormat.MMM().format(currentMonth)} ${i == (numWeeks - 1) ? firstEnd + 7 * i - 6 : firstEnd + 7 * i}'
                  : '${DateFormat.MMM().format(currentMonth)} ${i == 0 ? 1 : firstEnd + 7 * i - 6}-${i == (numWeeks - 1) ? currentMonth.totalDaysInMonth() : firstEnd + 7 * i}',
              style: Centre.todoSemiTitle,
            ),
            children: [
              SizedBox(
                height: weekList.length >= 5
                    ? Centre.safeBlockVertical * 35
                    : weekList.length >= 3
                        ? Centre.safeBlockVertical * 21.5
                        : null,
                child: SingleChildScrollView(
                  child: Column(children: weekList),
                ),
              )
            ]));
      }

      return temp;
    }

    return SingleChildScrollView(
      child: BlocBuilder<MonthlyTodoBloc, MonthlyTodoState>(builder: (context, state) {
        return Column(
          mainAxisSize: MainAxisSize.min,
          children: getWeekTileList(state.monthlyMaps),
        );
      }),
    );
  }
}
