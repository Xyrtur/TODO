import 'package:flutter/material.dart';

class Centre {
  static late double safeBlockHorizontal;
  static late double safeBlockVertical;
  static late double screenWidth;
  static late double screenHeight;

  static late double scheduleBlock;
  static Color red = const Color.fromARGB(255, 255, 103, 93);
  static Color yellow = const Color.fromARGB(255, 255, 205, 148);
  static Color pink = const Color.fromARGB(255, 255, 205, 200);
  static Color bgColor = const Color.fromARGB(255, 27, 27, 27);
  static Color darkerBgColor = const Color.fromARGB(255, 20, 20, 20);
  static Color textColor = const Color.fromARGB(255, 250, 250, 253);
  static Color dialogBgColor = const Color.fromARGB(255, 66, 66, 66);
  static Color lighterDialogColor = const Color.fromARGB(255, 110, 110, 110);
  static Color secondaryColor = const Color.fromARGB(255, 129, 155, 228);
  static Color primaryColor = const Color.fromARGB(255, 255, 205, 148);

  static const List<Color> colors = [
    Color.fromARGB(255, 252, 151, 138),
    Color.fromARGB(255, 150, 241, 158),
    Color.fromARGB(255, 252, 226, 255),
    Color.fromARGB(255, 206, 253, 233),
    Color.fromARGB(255, 170, 201, 234),
    Color.fromARGB(255, 253, 209, 63),
    Color.fromARGB(255, 165, 159, 201),
    Color.fromARGB(255, 255, 249, 158),
    Color.fromARGB(255, 221, 221, 221),
    Color.fromARGB(255, 197, 165, 153),
  ];

  static final todoText = TextStyle(
      color: textColor, fontWeight: FontWeight.w400, fontSize: Centre.safeBlockHorizontal * 3.5, fontFamily: 'Raleway');

  static final todoSemiTitle = TextStyle(
      color: textColor, fontWeight: FontWeight.w400, fontSize: Centre.safeBlockHorizontal * 6.5, fontFamily: 'Raleway');

  static final todoTitle = TextStyle(
      color: textColor, fontWeight: FontWeight.w600, fontSize: Centre.safeBlockHorizontal * 6, fontFamily: 'Raleway');

  static final dialogText = TextStyle(
      color: textColor, fontWeight: FontWeight.w400, fontSize: Centre.safeBlockHorizontal * 4.5, fontFamily: 'Raleway');

  static final smallerDialogText = TextStyle(
      color: textColor, fontWeight: FontWeight.w400, fontSize: Centre.safeBlockHorizontal * 4, fontFamily: 'Raleway');

  static final titleDialogText = TextStyle(
      color: textColor, fontWeight: FontWeight.w400, fontSize: Centre.safeBlockHorizontal * 5.5, fontFamily: 'Raleway');

  void init(BuildContext buildContext) {
    MediaQueryData mediaQueryData;
    double safeAreaHorizontal;
    double safeAreaVertical;
    mediaQueryData = MediaQuery.of(buildContext);
    screenWidth = mediaQueryData.size.width;
    screenHeight = mediaQueryData.size.height;

    safeAreaHorizontal = mediaQueryData.padding.left + mediaQueryData.padding.right;
    safeAreaVertical = mediaQueryData.padding.top + mediaQueryData.padding.bottom;
    safeBlockHorizontal = (screenWidth - safeAreaHorizontal) / 100;
    safeBlockVertical = (screenHeight - safeAreaVertical) / 100;

    // Size of one hour on the Todo table
    scheduleBlock = Centre.safeBlockVertical * 9.5;
  }
}
