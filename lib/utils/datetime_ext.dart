extension DatePrecisionCompare on DateTime {
  /*
   * Checks if this is on the same day as other  
   */
  bool isSameDate({required DateTime other, required bool daily}) {
    if (daily) {
      return year == other.year &&
          (month == other.month && (day == other.day && hour >= 7 || day == other.day + 1 && hour <= 1) ||
              month == other.month + 1 && day == 1 && hour <= 1);
    } else {
      return year == other.year && month == other.month && day == other.day;
    }
  }

  bool isBeforeDate({required DateTime other}) {
    return isBefore(DateTime(other.year, other.month, other.day, 7));
  }

  bool isSameMonthYear(DateTime other) {
    return year == other.year && month == other.month;
  }

  bool isBetweenDates(DateTime start, DateTime end) {
    return year <= end.year &&
        year >= start.year &&
        month <= end.month &&
        month >= start.month &&
        day <= end.day &&
        day >= start.day;
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
    return subtract(Duration(days: weekday - 1));
  }

  int totalDaysInMonth() {
    return DateTime(year, month + 1, 0).day;
  }

  int totalDaysInPrevMonth() {
    return DateTime(year, month, 0).day;
  }
}
