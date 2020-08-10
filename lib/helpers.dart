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

  DateTime dtmin = resettedDate.subtract(Duration(days: daysBackward)).toUtc();
  DateTime dtmax = resettedDate.add(Duration(days: daysForward)).toUtc();
  
  // print("$dtmin, $dtmax");
  
  Events newEvents = await CalendarApi(httpClient)
    .events
    .list(
      'primary',
      timeMin: dtmin,
      timeMax: dtmax,
    );

  return newEvents;
}

/// Sorts events into a map with dates to events
Map<DateTime, List<CustomEvent>> sortEvents(
  List<Event> events, [DateTime selectedDate,
  int daysBackward, 
  int daysForward]
) {
  Map<DateTime, List<CustomEvent>> outMap = {};

  DateTime resettedDate = resetDate(selectedDate);

  DateTime dtmin = resettedDate.subtract(Duration(days: daysBackward)).toUtc();
  DateTime dtmax = resettedDate.add(Duration(days: daysForward)).toUtc();

  for (Event event in events) {
    if (event.start == null)
      continue;

    // If event is a full-day event, dateTime will be null, but date will not
    event.start.dateTime = (event.start.dateTime ?? event.start.date).toLocal();
    event.end.dateTime = (event.end.dateTime ?? event.start.date).toLocal();

    if (event.start.dateTime.compareTo(dtmin) < 0 || 
        event.start.dateTime.compareTo(dtmax) > 0)
      continue;
    
    DateTime startResetDate = resetDate(event.start.dateTime);
    DateTime endResetDate = resetDate(event.end.dateTime);

    List<CustomEvent> splitEvents = [];
    do {
      CustomEvent customEvent = CustomEvent.fromEvent(event: event);
      splitEvents.add(customEvent);

      if(outMap.containsKey(startResetDate))
        outMap[startResetDate].add(customEvent);
      else
        outMap[startResetDate] = [customEvent];
      
      startResetDate = startResetDate.add(Duration(days: 1));
    } 
    while(!endResetDate.isBefore(startResetDate));

    /*
      Every event spanning multiple days will have a CustomEvent
      object for each day that it spans

      Toggling the 'checked' attribute of this event from any one
      of its tiles should toggle it for all the tiles
      
      Hence each tile listens for toggle updates from all other
      tiles, and can then rebuild its EventWidget
    */
    for(CustomEvent event in splitEvents)
      for(CustomEvent other in splitEvents)
        if(event != other)
          event.addToggleListener(other.emitter);
  }

  for (List<CustomEvent> events in outMap.values)
    events.sort((a, b) => a.start.compareTo(b.start));

  return outMap;
}