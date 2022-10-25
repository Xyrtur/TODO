import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:todo/blocs/cubits.dart';
import 'package:todo/utils/centre.dart';

class MonthYearPicker extends StatelessWidget {
  const MonthYearPicker({super.key});

  @override
  Widget build(BuildContext context) {
    final PageController pc =
        PageController(initialPage: context.read<YearTrackingCubit>().state - 2020); //Only let events from 2020 onwards
    Widget arrowButton(int direction) {
      return GestureDetector(
        onTap: () {
          if (direction == 0) {
            pc.previousPage(duration: const Duration(milliseconds: 300), curve: Curves.decelerate);
          } else {
            pc.nextPage(duration: const Duration(milliseconds: 300), curve: Curves.decelerate);
          }
        },
        child: Container(
          decoration: const BoxDecoration(borderRadius: BorderRadius.all(Radius.circular(100))),
          child: Icon(
            direction == 0 ? Icons.chevron_left_rounded : Icons.chevron_right_rounded,
            size: Centre.safeBlockVertical * 3,
            color: Centre.secondaryColor,
          ),
        ),
      );
    }

    Widget monthBtn(int monthNum, DateTime selectedMonth, int pageIndex) {
      return GestureDetector(
          onTap: () {
            context.read<MonthDateCubit>().update(DateTime.utc(context.read<YearTrackingCubit>().state, monthNum));
            Navigator.pop(context);
          },
          child: Container(
            margin: EdgeInsets.all(Centre.safeBlockVertical * 0.8),
            padding: EdgeInsets.symmetric(
                vertical: Centre.safeBlockVertical * 0.8, horizontal: Centre.safeBlockHorizontal * 5),
            decoration: BoxDecoration(
                color: selectedMonth.month == monthNum &&
                        (pc.position.haveDimensions ? (pageIndex + 2020) : context.read<YearTrackingCubit>().state) ==
                            selectedMonth.year
                    ? Centre.secondaryColor
                    : Centre.lighterDialogColor,
                borderRadius: const BorderRadius.all(Radius.circular(40))),
            child: Text(
              DateFormat.MMM().format(DateTime(context.read<YearTrackingCubit>().state, monthNum)),
              style: Centre.smallerDialogText,
            ),
          ));
    }

    return Material(
      color: Centre.dialogBgColor,
      borderRadius: const BorderRadius.all(Radius.circular(20)),
      child: SizedBox(
        height: Centre.safeBlockVertical * 39,
        width: Centre.safeBlockHorizontal * 50,
        child: Column(
          children: [
            Padding(
              padding: EdgeInsets.only(
                  top: Centre.safeBlockVertical,
                  left: Centre.safeBlockHorizontal * 2,
                  right: Centre.safeBlockHorizontal * 2),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  arrowButton(0),
                  BlocBuilder<YearTrackingCubit, int>(
                      builder: (context, state) => Text(state.toString(), style: Centre.dialogText)),
                  arrowButton(1)
                ],
              ),
            ),
            SizedBox(
              height: Centre.safeBlockVertical,
            ),
            SizedBox(
              height: Centre.safeBlockVertical * 33.5,
              child: PageView.builder(
                  controller: pc,
                  onPageChanged: (index) {
                    context.read<YearTrackingCubit>().update(2020 + index);
                  },
                  itemBuilder: (context, index) {
                    return SizedBox(
                      height: Centre.safeBlockVertical * 33.5,
                      child: BlocBuilder<MonthDateCubit, DateTime>(
                        builder: (context, state) => Column(
                          children: [
                            // Generate 6 rows of months
                            for (int i = 0; i < 6; i++)
                              Row(
                                mainAxisAlignment: MainAxisAlignment.spaceAround,
                                children: [
                                  monthBtn(2 * i + 1, state, index),
                                  monthBtn(2 * i + 2, state, index),
                                ],
                              ),
                          ],
                        ),
                      ),
                    );
                  }),
            ),
          ],
        ),
      ),
    );
  }
}
