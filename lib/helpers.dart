import 'imports.dart';

Color colorFromHex(String hexColor) {
  hexColor = hexColor.toUpperCase().replaceAll('#', '');
  if (hexColor.length == 6) hexColor = 'FF' + hexColor;

  return Color(int.parse(hexColor, radix: 16));
}

bool endBeforeStart(
  DateTime startDate, TimeOfDay startTime,
  DateTime endDate, TimeOfDay endTime
) {
  return 
    endDate
      .add(Duration(hours: endTime.hour, minutes: endTime.minute))
      .isBefore(
        startDate
          .add(Duration(hours: startTime.hour, minutes: startTime.minute)));
}

Widget makeScrollable({Widget child, double maxHeight = 80}) {
  return ConstrainedBox(
    constraints: BoxConstraints(
      maxHeight: maxHeight
    ),

    child: NotificationListener<OverscrollIndicatorNotification>(
      onNotification: (OverscrollIndicatorNotification overscroll) {
        overscroll.disallowGlow();
        return true;
      },

      child: ListView(
        shrinkWrap: true,
        scrollDirection: Axis.vertical,

        children: <Widget>[
          child
        ],
      ),
    ),
  );
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
Future<List<CustomEvent>> getEventsFromCalendarApi(
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
      singleEvents: true,
      timeMin: dtmin,
      timeMax: dtmax,
    );

  return newEvents.items
    .map((event) => CustomEvent.fromEvent(event: event))
    .toList();
}

Future<List<CustomEvent>> getEventsFromSQLite() async {
  return db.query('events')
    .then((response) => 
      response.map((item) => 
        CustomEvent.fromMap(item)).toList()
    );
}

List<CustomEvent> filterEventsByDate(
  List<CustomEvent> events, 
  DateTime selectedDate,
  int daysBackward, 
  int daysForward
) {
  DateTime resettedDate = resetDate(selectedDate);

  DateTime dtmin = resettedDate.subtract(Duration(days: daysBackward)).toUtc();
  DateTime dtmax = resettedDate.add(Duration(days: daysForward)).toUtc();

  return events
    .where((event) => 
      !event.start.isBefore(dtmin) && !event.start.isAfter(dtmax))
    .toList();
}

Map<DateTime, List<CustomEvent>> groupEventsByDate(List<CustomEvent> events) {
  Map<DateTime, List<CustomEvent>> outMap = {};

  for (CustomEvent event in events) {
    DateTime startResetDate = resetDate(event.start.toLocal());
    DateTime endResetDate = resetDate(event.end.toLocal());

    List<CustomEvent> splitEvents = [];
    do {
      CustomEvent eventCopy = CustomEvent.fromCustomEvent(event: event);
      splitEvents.add(eventCopy);

      if(outMap.containsKey(startResetDate))
        outMap[startResetDate].add(eventCopy);
      else
        outMap[startResetDate] = [eventCopy];
      
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

  return outMap;
}

/// Sorts events into a map with dates to events
Map<DateTime, List<CustomEvent>> sortEvents(
  List<CustomEvent> events, 
  DateTime selectedDate,
  int daysBackward, 
  int daysForward
) {
  events = filterEventsByDate(events, selectedDate, daysBackward, daysForward);
  Map<DateTime, List<CustomEvent>> outMap = groupEventsByDate(events);

  for (List<CustomEvent> events in outMap.values)
    events.sort((a, b) => a.start.compareTo(b.start));

  return outMap;
}