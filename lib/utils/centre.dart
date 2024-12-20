import 'package:flutter/material.dart';

class Centre {
  static late double safeBlockHorizontal;
  static late double safeBlockVertical;
  static late double screenWidth;
  static late Size size;
  static late double screenHeight;

  static late double scheduleBlock;
  static Color red = const Color.fromARGB(255, 255, 103, 93);
  static Color yellow = const Color.fromARGB(255, 255, 205, 148);
  static Color pink = const Color.fromARGB(255, 255, 205, 200);
  static Color bgColor = const Color.fromARGB(255, 27, 27, 27);
  static Color lighterBgColor = const Color.fromARGB(255, 37, 37, 37);
  static Color darkerBgColor = const Color.fromARGB(255, 20, 20, 20);
  static Color textColor = const Color.fromARGB(255, 250, 250, 253);
  static Color darkerDialogBgColor = const Color.fromARGB(255, 54, 54, 54);
  static Color editButtonColor = const Color.fromARGB(255, 78, 78, 78);
  static Color dialogBgColor = const Color.fromARGB(255, 66, 66, 66);
  static Color lighterDialogColor = const Color.fromARGB(255, 110, 110, 110);
  static Color secondaryColor = const Color.fromARGB(255, 129, 155, 228);
  static Color primaryColor = const Color.fromARGB(255, 255, 205, 148);

  static const List<Color> colors = [
    // First row
    Color.fromARGB(255, 243, 124, 149),
    Color.fromARGB(255, 255, 140, 198),
    Color.fromARGB(255, 244, 165, 105),
    Color.fromARGB(255, 211, 170, 186),
    Color.fromARGB(255, 206, 128, 232),
    Color.fromARGB(255, 253, 183, 145),
    Color.fromARGB(255, 172, 216, 170),
    Color.fromARGB(255, 168, 247, 246),
    Color.fromARGB(255, 255, 217, 125),
    Color.fromARGB(255, 193, 196, 255),

    // Second row
    Color.fromARGB(255, 86, 205, 132),
    Color.fromARGB(255, 139, 168, 248),
    Color.fromARGB(255, 126, 213, 224),
    Color.fromARGB(255, 177, 190, 220),
    Color.fromARGB(255, 244, 223, 88),
    Color.fromARGB(255, 226, 174, 221),
    Color.fromARGB(255, 193, 251, 164),
    Color.fromARGB(255, 251, 188, 207),
    Color.fromARGB(255, 255, 155, 133),
    Color.fromARGB(255, 190, 225, 230),
  ];

  static final todoText = TextStyle(
      color: textColor, fontWeight: FontWeight.w400, fontSize: Centre.safeBlockHorizontal * 3.5, fontFamily: 'Raleway');

  static final todoSemiTitle = TextStyle(
      color: textColor, fontWeight: FontWeight.w400, fontSize: Centre.safeBlockHorizontal * 6.2, fontFamily: 'Raleway');

  static final todoTitle = TextStyle(
      color: textColor, fontWeight: FontWeight.w600, fontSize: Centre.safeBlockHorizontal * 6, fontFamily: 'Raleway');

  static final dialogText = TextStyle(
      color: textColor, fontWeight: FontWeight.w400, fontSize: Centre.safeBlockHorizontal * 4.2, fontFamily: 'Raleway');

  static final smallerDialogText = TextStyle(
      color: textColor, fontWeight: FontWeight.w400, fontSize: Centre.safeBlockHorizontal * 4, fontFamily: 'Raleway');

  static final titleDialogText = TextStyle(
      color: textColor, fontWeight: FontWeight.w400, fontSize: Centre.safeBlockHorizontal * 5.2, fontFamily: 'Raleway');

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

    size = MediaQuery.of(buildContext).size;
  }
}
