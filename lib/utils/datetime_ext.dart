import 'package:flutter/material.dart';

extension TimeofDayCompare on TimeOfDay {
  bool isDailyBefore({required TimeOfDay end}) {
    if (hour <= 1 && end.hour >= 7) return false;

    if (end.hour == hour) {
      return minute <= end.minute;
    } else {
      return hour < end.hour;
    }
  }

  TimeOfDay add({required int minutes}) {
    return replacing(hour: (hour + ((minute + minutes) / 60).floor()) % 24, minute: (minute + minutes) % 60);
  }

  int diffInMinutes({required TimeOfDay end}) {
    if (end.hour <= 1) {
      if (hour == 0) {
        return (end.hour - 0) * 60 + end.minute - minute;
      }
      return (24 - hour) * 60 + (end.hour - 0) * 60 + end.minute - minute;
    } else {
      return (end.hour - hour) * 60 + end.minute - minute;
    }
  }
}

extension DatePrecisionCompare on DateTime {
  DateTime addDurationWithoutDST(Duration duration) {
    // Account for daylight savings: sometimes 24 hours is seen as 23 hours or 25 if the country is jumping ahead or falling backward that day
    // This solution converts the local time to UTC so that daylight savings will have no effect on the added 24 hours, and then convert back
    // to local time using the manual timezone offset addition and the local timezone constructor.
    DateTime tempUTCdate = toUtc().add(duration).add(timeZoneOffset);
    return DateTime(tempUTCdate.year, tempUTCdate.month, tempUTCdate.day, tempUTCdate.hour, tempUTCdate.minute);
  }

  // Return whether or not the event occurs inside the calendar window
  bool inCalendarWindow({required DateTime end, required DateTime currentMonth}) {
    return isBetweenDates(currentMonth.startingMonthCalenNum(),
            currentMonth.startingMonthCalenNum().addDurationWithoutDST(const Duration(days: 41))) ||
        end.isBetweenDates(currentMonth.startingMonthCalenNum(),
            currentMonth.startingMonthCalenNum().addDurationWithoutDST(const Duration(days: 41))) ||
        isBefore(currentMonth.startingMonthCalenNum()) &&
            end.isAfter(currentMonth.startingMonthCalenNum().addDurationWithoutDST(const Duration(days: 41)));
  }

  // Return either the events date or a date just inside the calendar window
  DateTime dateInCalendarWindow({required DateTime currentMonth}) {
    return isBetweenDates(currentMonth.startingMonthCalenNum(),
            currentMonth.startingMonthCalenNum().addDurationWithoutDST(const Duration(days: 41)))
        ? this
        : isBefore(currentMonth.startingMonthCalenNum())
            ? currentMonth.startingMonthCalenNum()
            : currentMonth.startingMonthCalenNum().addDurationWithoutDST(const Duration(days: 41));
  }

  /* 
   * Returns the proper day index for the monthly maps list since it covers the 6 weeks surrounding the current month
   * This means that the first day of the month is not necessarily the first index of the list
   */
  int monthlyMapDayIndex({required DateTime currentMonth}) {
    return isBefore(currentMonth)
        ? day - currentMonth.startingMonthCalenNum().day
        : isAfter(currentMonth
                .addDurationWithoutDST(Duration(days: currentMonth.totalDaysInMonth() - 1, hours: 23, minutes: 59)))
            ? (currentMonth.weekday - 1) + currentMonth.totalDaysInMonth() + day - 1
            : day - 1 + (currentMonth.weekday - 1);
  }

  /*
   * Checks if this is on the same day as other  
   */
  bool isSameDate({required DateTime other, required bool daily}) {
    if (daily) {
      return year == other.year &&
          (month == other.month && (day == other.day && (hour >= 7) || day == other.day + 1 && hour <= 1) ||
              month == other.month + 1 && day == 1 && hour <= 1);
    } else {
      return year == other.year && month == other.month && day == other.day;
    }
  }

  bool isSameMonthYear(DateTime other) {
    return year == other.year && month == other.month;
  }

  bool isBetweenDates(DateTime start, DateTime end) {
    DateTime dayStart;
    DateTime dayEnd;

    dayStart = DateTime(start.year, start.month, start.day);
    dayEnd = DateTime(end.year, end.month, end.day, 23, 59);

    return (isAfter(dayStart) || isAtSameMomentAs(dayStart)) && (isBefore(dayEnd) || isAtSameMomentAs(dayEnd));
  }

  bool isInTimeRange(DateTime start, DateTime end) {
    return isAfter(start) && isBefore(end);
  }

  bool enclosesOrContains(DateTime end, DateTime otherStart, DateTime otherEnd) {
    return (isAfter(otherStart) || isAtSameMomentAs(otherStart)) &&
            (end.isBefore(otherEnd) || end.isAtSameMomentAs(otherEnd)) ||
        isAtSameMomentAs(otherStart) && end.isAfter(otherEnd) ||
        end.isAtSameMomentAs(otherEnd) && isBefore(otherStart) ||
        isBefore(otherStart) && end.isAfter(otherEnd);
  }

  DateTime startingMonthCalenNum() {
    return addDurationWithoutDST(Duration(days: -(weekday - 1)));
  }

  int totalDaysInMonth() {
    return DateTime(year, month + 1, 0).day;
  }

  int totalDaysInPrevMonth() {
    return DateTime(year, month, 0).day;
  }
}
