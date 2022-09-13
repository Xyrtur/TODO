import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:intl/intl.dart';
import 'package:todo/blocs/cubits.dart';
import 'package:todo/utils/centre.dart';

class MonthYearPicker extends StatelessWidget {
  MonthYearPicker({super.key});
  final PageController pc = PageController(initialPage: 2); //Only let events from 2020 onwards

  @override
  Widget build(BuildContext context) {
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
                  GestureDetector(
                    onTap: () {
                      pc.previousPage(duration: const Duration(milliseconds: 300), curve: Curves.decelerate);
                    },
                    child: Container(
                      decoration: const BoxDecoration(borderRadius: BorderRadius.all(Radius.circular(100))),
                      child: Icon(
                        Icons.chevron_left_rounded,
                        size: Centre.safeBlockVertical * 3,
                        color: Centre.secondaryColor,
                      ),
                    ),
                  ),
                  BlocBuilder<YearTrackingCubit, int>(
                      builder: (context, state) => Text(state.toString(), style: Centre.dialogText)),
                  GestureDetector(
                    onTap: () {
                      pc.nextPage(duration: const Duration(milliseconds: 300), curve: Curves.decelerate);
                    },
                    child: Container(
                      decoration: const BoxDecoration(borderRadius: BorderRadius.all(Radius.circular(100))),
                      child: Icon(
                        Icons.chevron_right_rounded,
                        size: Centre.safeBlockVertical * 3,
                        color: Centre.secondaryColor,
                      ),
                    ),
                  )
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
                            for (int i = 0; i < 6; i++)
                              Row(
                                mainAxisAlignment: MainAxisAlignment.spaceAround,
                                children: [
                                  GestureDetector(
                                      onTap: () {
                                        context
                                            .read<MonthDateCubit>()
                                            .update(DateTime(context.read<YearTrackingCubit>().state, 2 * i + 1));

                                        Navigator.pop(context);
                                      },
                                      child: Container(
                                        margin: EdgeInsets.all(Centre.safeBlockVertical * 0.8),
                                        padding: EdgeInsets.symmetric(
                                            vertical: Centre.safeBlockVertical * 0.8,
                                            horizontal: Centre.safeBlockHorizontal * 5),
                                        decoration: BoxDecoration(
                                            color: state.month == 2 * i + 1
                                                ? Centre.secondaryColor
                                                : Centre.lighterDialogColor,
                                            borderRadius: const BorderRadius.all(Radius.circular(40))),
                                        child: Text(
                                          DateFormat.MMM()
                                              .format(DateTime(context.read<YearTrackingCubit>().state, 2 * i + 1)),
                                          style: Centre.smallerDialogText,
                                        ),
                                      )),
                                  GestureDetector(
                                      onTap: () {
                                        context
                                            .read<MonthDateCubit>()
                                            .update(DateTime(context.read<YearTrackingCubit>().state, 2 * i + 2));
                                        Navigator.pop(context);
                                      },
                                      child: Container(
                                        margin: EdgeInsets.all(Centre.safeBlockVertical * 0.8),
                                        padding: EdgeInsets.symmetric(
                                            vertical: Centre.safeBlockVertical * 0.8,
                                            horizontal: Centre.safeBlockHorizontal * 5),
                                        decoration: BoxDecoration(
                                            color: state.month == 2 * i + 2
                                                ? Centre.secondaryColor
                                                : Centre.lighterDialogColor,
                                            borderRadius: const BorderRadius.all(Radius.circular(40))),
                                        child: Text(
                                          DateFormat.MMM()
                                              .format(DateTime(context.read<YearTrackingCubit>().state, 2 * i + 2)),
                                          style: Centre.smallerDialogText,
                                        ),
                                      ))
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
