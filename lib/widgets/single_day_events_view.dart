import 'package:google_calendar_wrapper/imports.dart';

class SingleDayEventsView extends StatelessWidget {
  final DateTime date;
  final List<CustomEvent> events;

  SingleDayEventsView({@required this.date, @required this.events});

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
            
            itemCount: this.events.length,
            itemBuilder: (context, index) =>
              EventWidget(
                date: this.date,
                event: this.events[index],
              ),
            separatorBuilder: (context, index) => 
              SizedBox(height: 8),
          )
        ],
      ),
    );
  }
}
