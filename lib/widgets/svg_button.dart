import 'package:flutter/material.dart';
import 'package:flutter_svg/svg.dart';
import 'package:todo/utils/centre.dart';

Widget svgButton({
  required String name,
  required Color color,
  required int height,
  required int width,
  EdgeInsetsGeometry? margin,
  EdgeInsetsGeometry? padding,
  Color? borderColor,
}) {
  return Container(
    margin: margin,
    padding: padding,
    decoration: borderColor != null
        ? ShapeDecoration(
            shape: RoundedRectangleBorder(
                side: BorderSide(color: borderColor, width: 2),
                borderRadius: const BorderRadius.all(Radius.circular(10))),
          )
        : null,
    height: Centre.safeBlockVertical * height,
    width: Centre.safeBlockVertical * width,
    child: SvgPicture.asset("assets/icons/$name.svg",
        colorFilter: ColorFilter.mode(color, BlendMode.srcIn)),
  );
}
