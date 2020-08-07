import 'package:google_calendar_wrapper/imports.dart';

class SingleDayEventView extends StatelessWidget {
  final List<Event> events;
  final DateTime date;

  SingleDayEventView({Events events, this.date})
      : this.events = events.items
            .where((element) =>
                element.start.dateTime != null &&
                element.start.dateTime
                        .difference(date)
                        .compareTo(Duration(days: 1)) <
                    0)
            .toList();

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: EdgeInsets.all(16),
      child: Column(
        children: <Widget>[
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: <Widget>[
              Text(DateFormat('EEEE').format(this.date)),
              Text(DateFormat('MMM e, y').format(this.date)),
            ],
          )
        ],
      ),
    );
  }
}
