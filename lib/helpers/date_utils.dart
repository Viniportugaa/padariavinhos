import 'package:flutter/material.dart';

DateTime? combineDateAndTime(DateTime? date, TimeOfDay? time) {
  if (date == null || time == null) return null;
  return DateTime(
    date.year,
    date.month,
    date.day,
    time.hour,
    time.minute,
  );
}
