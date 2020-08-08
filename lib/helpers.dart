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
      
      firstDate: DateTime.now().subtract(Duration(days: 365 * 5)),
      lastDate: DateTime.now().add(Duration(days: 365 * 5))
  );
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
Future<Events> getEvents(
  GoogleSignInAccount currentUser, 
  DateTime selectedDate,
  int daysBackward, 
  int daysForward,
) async {
  final authHeaders = await currentUser.authHeaders;
  final httpClient = GoogleHttpClient(authHeaders);
  
  DateTime resettedDate = resetDate(selectedDate);
  Events newEvents = await CalendarApi(httpClient)
    .events
    .list(
      'primary',
      timeMin: resettedDate.subtract(Duration(days: daysBackward)).toUtc(),
      timeMax: resettedDate.add(Duration(days: daysForward)).toUtc(),
    );

  return newEvents;
}

/// Sorts events into a map with dates to events
Map<DateTime, List<Event>> sortEvents(List<Event> events) {
  Map<DateTime, List<Event>> outMap = {};

  for (Event event in events) {
    // If event is full-day event
    if(event.start.dateTime == null) {
      event.start.dateTime = event.start.date;
      event.end.dateTime = event.end.date;
    }

    event.start.dateTime = event.start.dateTime.toLocal();
    event.end.dateTime = event.end.dateTime.toLocal();

    DateTime startResetDate = resetDate(event.start.dateTime);
    DateTime endResetDate = resetDate(event.end.dateTime);

    do {
      if(outMap.containsKey(startResetDate))
        outMap[startResetDate].add(event);
      else
        outMap[startResetDate] = <Event>[event];
      
      startResetDate = startResetDate.add(Duration(days: 1));
    } 
    while(!endResetDate.isBefore(startResetDate));
    print('\n');
  }

  for (DateTime date in outMap.keys)
    outMap[date]
      .sort((a, b) => a.start.dateTime.compareTo(b.start.dateTime));

  return outMap;
}