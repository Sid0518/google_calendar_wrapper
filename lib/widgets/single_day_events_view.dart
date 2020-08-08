import 'package:google_calendar_wrapper/imports.dart';

class SingleDayEventsView extends StatelessWidget {
  final DateTime date;
  final List<Event> events;

  SingleDayEventsView({this.date, this.events});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: EdgeInsets.all(16),
      
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,

        children: <Widget>[
          Padding(
            padding: EdgeInsets.symmetric(horizontal: 16),

            child: Text(
              DateFormat('EEEE, MMM d, y').format(this.date),
              style: TextStyle(
                fontSize: 18
              ),
            ),
          ),

          SizedBox(height: 16),
          
          ListView.separated(
            shrinkWrap: true,
            scrollDirection: Axis.vertical,
            physics: NeverScrollableScrollPhysics(),
            separatorBuilder: (context, index) => SizedBox(height: 8),
            itemCount: this.events.length,
            itemBuilder: (context, index) =>
              EventWidget(
                event: this.events[index],
                checked: false,
              )
          )
        ],
      ),
    );
  }
}
