import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:todo/blocs/cubits.dart';
import 'package:todo/blocs/monthly_todo_bloc.dart';
import 'package:todo/models/event_data.dart';
import 'package:todo/utils/centre.dart';
import 'package:intl/intl.dart';
import 'package:todo/utils/datetime_ext.dart';

class MonthlyPanel extends StatelessWidget {
  const MonthlyPanel({super.key});

  List<Widget> getWeekTileList(
      BuildContext context, int numWeeks, int firstEnd, List<Map<dynamic, EventData>> monthlyList) {
    List<Widget> temp = [];
    for (int i = 0; i < numWeeks; i++) {
      List<Widget> weekList = getWeekList(firstEnd, i, numWeeks, context, monthlyList);

      temp.add(ExpansionTile(
          collapsedIconColor: Centre.secondaryColor,
          iconColor: Centre.textColor,
          controlAffinity: ListTileControlAffinity.leading,
          title: Text(
            '${DateFormat.MMM().format(context.read<MonthDateCubit>().state)} ${i == 0 ? 1 : firstEnd + 7 * i - 6}-${i == (numWeeks - 1) ? context.read<MonthDateCubit>().state.totalDaysInMonth() : firstEnd + 7 * i}',
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

  List<Widget> getWeekList(
      int firstEnd, int i, int numWeeks, BuildContext context, List<Map<dynamic, EventData>> monthlyList) {
    List<Widget> temp = [];
    for (int dayIndex = i == 0 ? 1 : firstEnd + 7 * i - 6;
        dayIndex <= (i == (numWeeks - 1) ? context.read<MonthDateCubit>().state.totalDaysInMonth() : firstEnd + 7 * i);
        dayIndex++) {
      for (EventData event in monthlyList[dayIndex - 1].values) {
        if (dayIndex == (i == 0 ? 1 : firstEnd + 7 * i - 6) || monthlyList[dayIndex - 2][event.key] == null) {
          temp.add(Padding(
            padding: EdgeInsets.only(bottom: Centre.safeBlockVertical),
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
                    decoration: BoxDecoration(
                        color: Centre.lighterDialogColor, borderRadius: const BorderRadius.all(Radius.circular(4))),
                    height: Centre.safeBlockHorizontal * 5,
                    width: event.fullDay && !event.start.isSameDate(other: event.end, daily: false)
                        ? Centre.safeBlockHorizontal * 10
                        : Centre.safeBlockHorizontal * 5,
                    child: Center(
                      child: Text(
                        event.fullDay && !event.start.isSameDate(other: event.end, daily: false)
                            ? "${event.start.day}-${event.end.day}"
                            : event.start.day.toString(),
                        style:
                            Centre.todoText.copyWith(fontSize: Centre.safeBlockHorizontal * 3, color: Centre.textColor),
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

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      child: BlocBuilder<MonthlyTodoBloc, MonthlyTodoState>(builder: (context, state) {
        int firstEnd = 8 - context.read<MonthDateCubit>().state.weekday;
        int numWeeks = 1 +
            ((DateTime.utc(2022, 7 + 1, 0).day - firstEnd) / 7).floor() +
            (((DateTime.utc(2022, 7 + 1, 0).day - firstEnd) % 7) == 0 ? 0 : 1);
        List<int> listLengths = List.filled(numWeeks, 0);
        for (int i = 0; i < numWeeks; i++) {
          for (int j = (i == 0 ? 1 : firstEnd + 7 * i - 6);
              j <= (i == (numWeeks - 1) ? context.read<MonthDateCubit>().state.totalDaysInMonth() : firstEnd + 7 * i);
              j++) {
            listLengths[i] += state.monthlyMaps[j - 1].length;
          }
        }

        return Column(
          mainAxisSize: MainAxisSize.min,
          children: getWeekTileList(context, numWeeks, firstEnd, state.monthlyMaps),
        );
      }),
    );
  }
}
