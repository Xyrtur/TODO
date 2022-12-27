import 'package:flutter/material.dart';

extension TimeofDayCompare on TimeOfDay {
  bool isBefore({required TimeOfDay end}) {
    if (end.hour == hour) {
      return minute <= end.minute;
    } else {
      return hour < end.hour;
    }
  }

  TimeOfDay add({required int minutes}) {
    return replacing(
        hour: (hour + ((minute + minutes) / 60).floor()) % 24,
        minute: (minute + minutes) % 60);
  }
}

extension DatePrecisionCompare on DateTime {
  // Return whether or not the event occurs inside the calendar window
  bool inCalendarWindow(
      {required DateTime end, required DateTime currentMonth}) {
    return isBetweenDates(
            currentMonth.startingMonthCalenNum(),
            currentMonth
                .startingMonthCalenNum()
                .add(const Duration(days: 41))) ||
        end.isBetweenDates(currentMonth.startingMonthCalenNum(),
            currentMonth.startingMonthCalenNum().add(const Duration(days: 41)));
  }

  // Return either the events date or a date just inside the calendar window
  DateTime dateInCalendarWindow({required DateTime currentMonth}) {
    // Return a date in UTC time which is what *this* should be
    return isBetweenDates(currentMonth.startingMonthCalenNum(),
            currentMonth.startingMonthCalenNum().add(const Duration(days: 41)))
        ? toUtc()
        // a time at 00:00 should be at 7am UTC to preserve 00:00 local
        : isBefore(currentMonth.startingMonthCalenNum())
            ? currentMonth.startingMonthCalenNum().subtract(timeZoneOffset)
            : currentMonth
                .startingMonthCalenNum()
                .add(const Duration(days: 41))
                .subtract(timeZoneOffset);
  }

  /* 
   * Returns the proper day index for the monthly maps list since it covers the 6 weeks surrounding the current month
   * This means that the first day of the month is not necessarily the first index of the list
   */
  int monthlyMapDayIndex({required DateTime currentMonth}) {
    return isBefore(currentMonth)
        ? day - currentMonth.startingMonthCalenNum().day
        : isAfter(currentMonth.add(Duration(
                days: currentMonth.totalDaysInMonth() - 1,
                hours: 23,
                minutes: 59)))
            ? (currentMonth.weekday - 1) +
                currentMonth.totalDaysInMonth() +
                day -
                1
            : day - 1 + (currentMonth.weekday - 1);
  }

  /*
   * Checks if this is on the same day as other  
   */
  bool isSameDate({required DateTime other, required bool daily}) {
    if (daily) {
      return year == other.year &&
          (month == other.month &&
                  (day == other.day && (hour >= 7 || hour <= 1) ||
                      day == other.day + 1 && hour <= 1) ||
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
    if (isUtc) {
      dayStart = DateTime.utc(start.year, start.month, start.day);
      dayEnd = DateTime.utc(end.year, end.month, end.day, 23, 59);
    } else {
      dayStart = DateTime(start.year, start.month, start.day);
      dayEnd = DateTime(end.year, end.month, end.day, 23, 59);
    }

    return (isAfter(dayStart) || isAtSameMomentAs(dayStart)) &&
        (isBefore(dayEnd) || isAtSameMomentAs(dayEnd));
  }

  bool isInTimeRange(DateTime start, DateTime end) {
    return isAfter(start) && isBefore(end);
  }

  bool enclosesOrContains(
      DateTime end, DateTime otherStart, DateTime otherEnd) {
    return (isAfter(otherStart) || isAtSameMomentAs(otherStart)) &&
            (end.isBefore(otherEnd) || end.isAtSameMomentAs(otherEnd)) ||
        isAtSameMomentAs(otherStart) && end.isAfter(otherEnd) ||
        end.isAtSameMomentAs(otherEnd) && isBefore(otherStart) ||
        isBefore(otherStart) && end.isAfter(otherEnd);
  }

  DateTime startingMonthCalenNum() {
    return subtract(Duration(days: weekday - 1));
  }

  int totalDaysInMonth() {
    return DateTime.utc(year, month + 1, 0).day;
  }

  int totalDaysInPrevMonth() {
    return DateTime.utc(year, month, 0).day;
  }
}
