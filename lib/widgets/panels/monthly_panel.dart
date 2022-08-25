import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:todo/utils/centre.dart';
import 'package:intl/intl.dart';

class MonthlyPanel extends StatelessWidget {
  const MonthlyPanel({super.key});

  @override
  Widget build(BuildContext context) {
    DateTime todayDate = DateTime.utc(2022, 7, 1);
    int firstEnd = 8 - todayDate.weekday;
    int numWeeks = 1 +
        ((DateTime.utc(2022, 7 + 1, 0).day - firstEnd) / 7).floor() +
        (((DateTime.utc(2022, 7 + 1, 0).day - firstEnd) % 7) == 0 ? 0 : 1);

    return SingleChildScrollView(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          for (int i = 0; i < numWeeks; i++)
            ExpansionTile(
                collapsedIconColor: Colors.white,
                controlAffinity: ListTileControlAffinity.leading,
                title: Text(
                  '${DateFormat.MMMM().format(todayDate)} ${i == 0 ? 1 : firstEnd + 7 * i - 6}-${i == numWeeks ? DateTime.utc(2022, 7 + 1, 0).day : firstEnd + 7 * i}',
                  style: Centre.todoSemiTitle,
                ),
                children: [
                  SizedBox(
                    height: i >= 2 ? Centre.safeBlockVertical * 20 : null,
                    child: SingleChildScrollView(
                      child: Column(children: [
                        Padding(
                          padding:
                              EdgeInsets.only(bottom: Centre.safeBlockVertical),
                          child: Row(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Container(
                                margin: EdgeInsets.only(
                                    left: Centre.safeBlockHorizontal * 6,
                                    right: Centre.safeBlockHorizontal * 3),
                                height: Centre.safeBlockVertical * 3.5,
                                width: Centre.safeBlockVertical * 3.5,
                                child: SvgPicture.asset(
                                  "assets/icons/squiggle.svg",
                                  color: Colors.white,
                                ),
                              ),
                              Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(
                                      "Shit pant",
                                      style: Centre.dialogText,
                                    ),
                                    Container(
                                      margin: EdgeInsets.only(
                                          top: Centre.safeBlockVertical * 0.5),
                                      decoration: BoxDecoration(
                                          color: Colors.grey,
                                          borderRadius: BorderRadius.all(
                                              Radius.circular(4))),
                                      height: Centre.safeBlockHorizontal * 5,
                                      width: Centre.safeBlockHorizontal * 5,
                                      child: Center(
                                        child: Text(
                                          "14",
                                          style: Centre.todoText.copyWith(
                                              fontSize:
                                                  Centre.safeBlockHorizontal *
                                                      3),
                                        ),
                                      ),
                                    )
                                  ])
                            ],
                          ),
                        ),
                        Padding(
                          padding:
                              EdgeInsets.only(bottom: Centre.safeBlockVertical),
                          child: Row(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Container(
                                margin: EdgeInsets.only(
                                    left: Centre.safeBlockHorizontal * 6,
                                    right: Centre.safeBlockHorizontal * 3),
                                height: Centre.safeBlockVertical * 3.5,
                                width: Centre.safeBlockVertical * 3.5,
                                child: SvgPicture.asset(
                                  "assets/icons/squiggle.svg",
                                  color: Colors.white,
                                ),
                              ),
                              Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(
                                      "Shit pant",
                                      style: Centre.dialogText,
                                    ),
                                    Container(
                                      margin: EdgeInsets.only(
                                          top: Centre.safeBlockVertical * 0.5),
                                      decoration: BoxDecoration(
                                          color: Colors.grey,
                                          borderRadius: BorderRadius.all(
                                              Radius.circular(4))),
                                      height: Centre.safeBlockHorizontal * 5,
                                      width: Centre.safeBlockHorizontal * 5,
                                      child: Center(
                                        child: Text(
                                          "14",
                                          style: Centre.todoText.copyWith(
                                              fontSize:
                                                  Centre.safeBlockHorizontal *
                                                      3),
                                        ),
                                      ),
                                    )
                                  ])
                            ],
                          ),
                        ),
                      ]),
                    ),
                  )
                  // for (int i = 0; i < numWeeks; i++)
                  //   ListTile(
                  //     leading: Icon(
                  //       Icons.circle_notifications_outlined,
                  //       color: Colors.white,
                  //     ),
                  //     title: Text(
                  //       "shit pant",
                  //       style: Centre.todoText,
                  //     ),
                  //     subtitle: Text(
                  //       "${1 + ((DateTime.utc(2022, 7 + 1, 0).day - firstEnd) / 7).floor() + ((DateTime.utc(2022, 7 + 1, 0).day - firstEnd % 7) == 0 ? 0 : 1)}",
                  //       style: Centre.todoText,
                  //     ),
                  //   )
                ]),
        ],
      ),
    );
  }
}
