import 'imports.dart';

Color colorFromHex(String hexColor) {
  hexColor = hexColor.toUpperCase().replaceAll('#', '');
  if (hexColor.length == 6) hexColor = 'FF' + hexColor;

  return Color(int.parse(hexColor, radix: 16));
}

/// Selects a date using the datepicker widget
Future<DateTime> selectDate(BuildContext context, DateTime initialDate) async {
  final DateTime picked = await showDatePicker(
      context: context,
      initialDate: initialDate,
      firstDate: initialDate.subtract(Duration(days: 30)),
      lastDate: DateTime.now().add(Duration(days: 30)));
  return picked;
}

/// Sets time component of date to 0
DateTime resetDate(DateTime selectedDate) {
  return selectedDate.subtract(Duration(
      hours: selectedDate.hour,
      minutes: selectedDate.minute,
      seconds: selectedDate.second,
      milliseconds: selectedDate.millisecond,
      microseconds: selectedDate.microsecond));
}

/// Gets all events for a user within a specific date range
Future<Events> getEvents(GoogleSignInAccount currentUser, DateTime selectedDate,
    int daysBackward, int daysForward) async {
  DateTime resettedDate = resetDate(selectedDate);
  final authHeaders = await currentUser.authHeaders;
  final httpClient = GoogleHttpClient(authHeaders);
  Events newEvents = await CalendarApi(httpClient).events.list(
        'primary',
        timeMin: resettedDate.subtract(Duration(days: daysBackward)).toUtc(),
        timeMax: resettedDate.add(Duration(days: daysForward)).toUtc(),
      );
  return newEvents;
}

/// Takes Events object and returns all valid events as some events have null endTime
List<Event> filteredEvents(Events events) {
  List<Event> finalList = [];
  for (Event event in events.items) {
    if (event.start != null || event.end != null) {
      finalList.add(event);
    } else {
      // print(event.summary);
    }
  }
  return finalList;
}

/// Sorts events into a map with dates to events
Map<DateTime, List<Event>> sortEvents(List<Event> events) {
  Map<DateTime, List<Event>> outMap = {};
  DateTime startResetDate;
  for (Event event in events) {
    startResetDate = resetDate(event.start.dateTime);
    if (outMap.containsKey(startResetDate)) {
      outMap[startResetDate].add(event);
    } else {
      outMap[startResetDate] = <Event>[event];
    }
  }
  for (DateTime date in outMap.keys) {
    outMap[date].sort((a, b) => a.start.dateTime.compareTo(b.start.dateTime));
  }
  return outMap;
}
