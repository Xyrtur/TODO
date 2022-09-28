// ignore_for_file: non_constant_identifier_names

import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:todo/blocs/cubits.dart';
import 'package:todo/blocs/daily_todo_bloc.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:todo/blocs/unfinished_bloc.dart';

import 'package:todo/models/event_data.dart';
import 'package:todo/utils/centre.dart';
import 'package:fading_edge_scrollview/fading_edge_scrollview.dart';
import 'package:todo/widgets/dialogs/add_event_dialog.dart';
import 'package:todo/widgets/dialogs/delete_confirmation_dialog.dart';

class DailyPanel extends StatelessWidget {
  DailyPanel({
    super.key,
  });
  final unfin_controller = ScrollController();
  final monthly_controller = ScrollController();

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Expanded(
            child: Column(
          children: [
            Padding(
              padding: EdgeInsets.only(top: Centre.safeBlockVertical * 3, bottom: Centre.safeBlockVertical * 2),
              child: Text("Unfinished", style: Centre.todoSemiTitle),
            ),
            Padding(
              padding: EdgeInsets.symmetric(horizontal: Centre.safeBlockHorizontal * 3),
              child: Divider(
                color: Centre.pink,
                thickness: 2,
              ),
            ),
            Expanded(
                child: ScrollConfiguration(
              behavior: MyBehavior(),
              child: BlocBuilder<UnfinishedListBloc, UnfinishedListState>(builder: (context, state) {
                return FadingEdgeScrollView.fromScrollView(
                    child: ListView.builder(
                  controller: unfin_controller,
                  itemCount: state.unfinishedList.length,
                  itemBuilder: (context, index) {
                    return Row(
                      children: [
                        GestureDetector(
                          onTap: () async {
                            await showDialog(
                                context: context,
                                builder: (BuildContext tcontext) {
                                  return BlocProvider.value(
                                    value: context.read<UnfinishedListBloc>(),
                                    child: DeleteConfirmationDialog(
                                        type: DeletingFrom.unfinishedList, event: state.unfinishedList[index]),
                                  );
                                });
                          },
                          child: Container(
                            margin: EdgeInsets.only(
                                bottom: Centre.safeBlockVertical * 1.5,
                                left: Centre.safeBlockHorizontal * 5,
                                right: Centre.safeBlockHorizontal * 3),
                            height: Centre.safeBlockVertical * 3.5,
                            width: Centre.safeBlockVertical * 3.5,
                            child: Icon(
                              Icons.delete_rounded,
                              color: Color(state.unfinishedList[index].color),
                            ),
                          ),
                        ),
                        GestureDetector(
                          onTap: () async {
                            await showDialog<EventData>(
                                context: context,
                                builder: (BuildContext tcontext) {
                                  return Scaffold(
                                    backgroundColor: Colors.transparent,
                                    body: MultiBlocProvider(
                                        providers: [
                                          BlocProvider<TimeRangeCubit>(
                                            create: (_) => TimeRangeCubit(TimeRangeState(
                                                TimeOfDay(
                                                    hour: state.unfinishedList[index].start.hour,
                                                    minute: state.unfinishedList[index].start.minute),
                                                TimeOfDay(
                                                    hour: state.unfinishedList[index].end.hour,
                                                    minute: state.unfinishedList[index].end.minute))),
                                          ),
                                          BlocProvider<ColorCubit>(
                                            create: (_) => ColorCubit(
                                                Centre.colors.indexOf(Color(state.unfinishedList[index].color))),
                                          ),
                                          BlocProvider.value(value: context.read<DateCubit>()),
                                          BlocProvider.value(value: context.read<TodoBloc>()),
                                          BlocProvider.value(value: context.read<UnfinishedListBloc>()),
                                        ],
                                        child: AddEventDialog.daily(
                                          addingFutureTodo: false,
                                          event: state.unfinishedList[index],
                                        )),
                                  );
                                });
                          },
                          child: Container(
                            width: Centre.safeBlockHorizontal * 28,
                            padding: EdgeInsets.only(right: Centre.safeBlockHorizontal * 1),
                            margin: EdgeInsets.only(bottom: Centre.safeBlockVertical * 1.5),
                            child: Text(
                              state.unfinishedList[index].text,
                              maxLines: 2,
                              style: Centre.smallerDialogText,
                            ),
                          ),
                        ),
                      ],
                    );
                  },
                ));
              }),
            ))
          ],
        )),
        Expanded(
            child: Column(
          children: [
            Padding(
              padding: EdgeInsets.only(top: Centre.safeBlockVertical * 3, bottom: Centre.safeBlockVertical * 2),
              child: Text("This Month", style: Centre.todoSemiTitle),
            ),
            Padding(
              padding: EdgeInsets.symmetric(horizontal: Centre.safeBlockHorizontal * 3),
              child: Divider(
                color: Centre.pink,
                thickness: 2,
              ),
            ),
            Expanded(
                child: ScrollConfiguration(
              behavior: MyBehavior(),
              child: BlocBuilder<DailyMonthlyListCubit, List<EventData>>(builder: (context, state) {
                return FadingEdgeScrollView.fromScrollView(
                  child: ListView.builder(
                    controller: monthly_controller,
                    itemCount: state.length,
                    itemBuilder: (context, index) {
                      return GestureDetector(
                        onTap: () async {
                          await showDialog<EventData>(
                              context: context,
                              builder: (BuildContext tcontext) {
                                return Scaffold(
                                  backgroundColor: Colors.transparent,
                                  body: MultiBlocProvider(
                                      providers: [
                                        BlocProvider<TimeRangeCubit>(
                                          create: (_) => TimeRangeCubit(TimeRangeState(null, null)),
                                        ),
                                        BlocProvider<ColorCubit>(
                                          create: (_) => ColorCubit(Centre.colors.indexOf(Color(state[index].color))),
                                        ),
                                        BlocProvider.value(value: context.read<DateCubit>()),
                                        BlocProvider.value(value: context.read<TodoBloc>()),
                                        BlocProvider.value(value: context.read<UnfinishedListBloc>()),
                                      ],
                                      child: AddEventDialog.daily(
                                        addingFutureTodo: false,
                                        event: state[index],
                                      )),
                                );
                              });
                        },
                        child: Row(
                          children: [
                            Container(
                              margin: EdgeInsets.only(
                                  bottom: Centre.safeBlockVertical * 1.5,
                                  left: Centre.safeBlockHorizontal * 4,
                                  right: Centre.safeBlockHorizontal * 3),
                              height: Centre.safeBlockVertical * 3.5,
                              width: Centre.safeBlockVertical * 3.5,
                              child: SvgPicture.asset(
                                "assets/icons/squiggle.svg",
                                color: Color(state[index].color),
                              ),
                            ),
                            Container(
                              width: Centre.safeBlockHorizontal * 28,
                              padding: EdgeInsets.only(right: Centre.safeBlockHorizontal * 1),
                              margin: EdgeInsets.only(bottom: Centre.safeBlockVertical * 1.5),
                              child: Text(
                                state[index].text,
                                maxLines: 2,
                                style: Centre.smallerDialogText,
                              ),
                            ),
                          ],
                        ),
                      );
                    },
                  ),
                );
              }),
            ))
          ],
        ))
      ],
    );
  }
}

class MyBehavior extends ScrollBehavior {
  @override
  Widget buildOverscrollIndicator(BuildContext context, Widget child, ScrollableDetails details) {
    return child;
  }
}
