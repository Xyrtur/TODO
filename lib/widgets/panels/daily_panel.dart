import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:fading_edge_scrollview/fading_edge_scrollview.dart';
// import 'package:sliding_up_panel/sliding_up_panel.dart';

import 'package:todo/blocs/blocs_barrel.dart';
import 'package:todo/utils/centre.dart';
import 'package:todo/widgets/dialogs/add_event_dialog.dart';
import 'package:todo/widgets/dialogs/delete_confirmation_dialog.dart';

class DailyPanel extends StatelessWidget {
  DailyPanel({
    super.key,
    //  required this.thisPc
  });
  // final PanelController thisPc;
  final unFinishedController = ScrollController();
  final monthlyController = ScrollController();
  // final ValueNotifier<bool?> addedUnfinished = ValueNotifier<bool?>(false);

  @override
  Widget build(BuildContext context) {
    // Include if you want the panel closed when an event is added
    // addedUnfinished.addListener(() {
    //   if (addedUnfinished.value ?? false) {
    //     thisPc.close();
    //   }
    // });

    Widget scrollingList(bool unfinishedList, List<EventData> list) {
      return FadingEdgeScrollView.fromScrollView(
          child: ListView.builder(
        controller: unfinishedList ? unFinishedController : monthlyController,
        itemCount: list.length,
        itemBuilder: (context, index) {
          return Row(
            children: [
              if (unfinishedList)
                GestureDetector(
                  onTap: () async {
                    await showDialog(
                        context: context,
                        builder: (BuildContext tcontext) {
                          return BlocProvider.value(
                            value: context.read<UnfinishedListBloc>(),
                            child: DeleteConfirmationDialog(type: DeletingFrom.unfinishedList, event: list[index]),
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
                      color: Color(list[index].color),
                    ),
                  ),
                ),
              GestureDetector(
                onTap: () async {
                  if (!unfinishedList) {
                    await showDialog(
                        context: context,
                        builder: (BuildContext unUsedContext) {
                          return Scaffold(
                            backgroundColor: Colors.transparent,
                            body: MultiBlocProvider(
                                providers: [
                                  BlocProvider<TimeRangeCubit>(
                                    create: (_) => TimeRangeCubit(TimeRangeState(null, null)),
                                  ),
                                  BlocProvider<ColorCubit>(
                                    create: (_) => ColorCubit(Centre.colors.indexOf(Color(list[index].color))),
                                  ),
                                  BlocProvider.value(value: context.read<DateCubit>()),
                                  BlocProvider.value(value: context.read<TodoBloc>()),
                                ],
                                child: AddEventDialog.daily(
                                  addingFutureTodo: false,
                                  event: list[index],
                                )),
                          );
                        });
                  } else {
                    // addedUnfinished.value =
                    await showDialog<bool?>(
                        context: context,
                        builder: (BuildContext unUsedContext) {
                          return Scaffold(
                            backgroundColor: Colors.transparent,
                            body: MultiBlocProvider(
                                providers: [
                                  BlocProvider<TimeRangeCubit>(
                                    create: (_) => TimeRangeCubit(TimeRangeState(
                                        TimeOfDay(
                                            hour: list[index].start.toLocal().hour,
                                            minute: list[index].start.toLocal().minute),
                                        TimeOfDay(
                                            hour: list[index].end.toLocal().hour,
                                            minute: list[index].end.toLocal().minute))),
                                  ),
                                  BlocProvider<ColorCubit>(
                                    create: (_) => ColorCubit(Centre.colors.indexOf(Color(list[index].color))),
                                  ),
                                  BlocProvider.value(value: context.read<DateCubit>()),
                                  BlocProvider.value(value: context.read<TodoBloc>()),
                                  BlocProvider.value(value: context.read<UnfinishedListBloc>()),
                                ],
                                child: AddEventDialog.daily(
                                  addingFutureTodo: false,
                                  event: list[index],
                                )),
                          );
                        });
                  }
                },
                child: unfinishedList
                    ? Container(
                        width: Centre.safeBlockHorizontal * 28,
                        padding: EdgeInsets.only(right: Centre.safeBlockHorizontal * 1),
                        margin: EdgeInsets.only(bottom: Centre.safeBlockVertical * 1.5),
                        child: Text(
                          list[index].text,
                          maxLines: 2,
                          style: Centre.smallerDialogText,
                        ),
                      )
                    : Row(
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
                              color: Color(list[index].color),
                            ),
                          ),
                          Container(
                            width: Centre.safeBlockHorizontal * 28,
                            padding: EdgeInsets.only(right: Centre.safeBlockHorizontal * 1),
                            margin: EdgeInsets.only(bottom: Centre.safeBlockVertical * 1.5),
                            child: Text(
                              list[index].text,
                              maxLines: 2,
                              style: Centre.smallerDialogText,
                            ),
                          ),
                        ],
                      ),
              ),
            ],
          );
        },
      ));
    }

    Widget panelList(bool unfinishedList) {
      return Column(
        children: [
          Padding(
            padding: EdgeInsets.only(top: Centre.safeBlockVertical * 3, bottom: Centre.safeBlockVertical * 2),
            child: Text(unfinishedList ? "Unfinished" : "This Month", style: Centre.todoSemiTitle),
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
            child: unfinishedList
                ? BlocBuilder<UnfinishedListBloc, UnfinishedListState>(builder: (context, state) {
                    return scrollingList(unfinishedList, state.unfinishedList);
                  })
                : BlocBuilder<DailyMonthlyListCubit, List<EventData>>(builder: (context, state) {
                    return scrollingList(unfinishedList, state);
                  }),
          ))
        ],
      );
    }

    return Row(
      children: [Expanded(child: panelList(true)), Expanded(child: panelList(false))],
    );
  }
}

class MyBehavior extends ScrollBehavior {
  @override
  Widget buildOverscrollIndicator(BuildContext context, Widget child, ScrollableDetails details) {
    return child;
  }
}
