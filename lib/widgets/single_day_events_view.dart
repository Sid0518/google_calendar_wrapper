import 'package:google_calendar_wrapper/imports.dart';

/*
  TODO: Discard the slide transition from EventWidget, and instead use
  AnimatedList here
*/
class SingleDayEventsView extends StatefulWidget {
  final DateTime date;
  final List<CustomEvent> events;

  SingleDayEventsView({@required this.date, @required this.events});

  @override
  _SingleDayEventsViewState createState() => _SingleDayEventsViewState();
}

class _SingleDayEventsViewState extends State<SingleDayEventsView> {
  List<StreamSubscription> listeners = [];

  void deleteEvent(CustomEvent event) async {
    widget.events.remove(event);
    setState(() {});
  }
  
  @override
  Widget build(BuildContext context) {
    for(StreamSubscription listener in this.listeners)
      listener.cancel();

    for(CustomEvent event in this.widget.events)
      this.listeners.add(event.emitter.listen(
        (eventHeard) {
          if(eventHeard == 'Deleted')
            this.deleteEvent(event);
        })
      );

    return Padding(
      padding: EdgeInsets.all(16),
      
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,

        children: <Widget>[
          Padding(
            padding: EdgeInsets.symmetric(horizontal: 16),

            child: Text(
              DateFormat('EEEE, MMM d, y').format(this.widget.date),
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
            
            itemCount: this.widget.events.length,
            itemBuilder: (context, index) =>
              EventWidget(
                date: this.widget.date,
                event: this.widget.events[index],
              ),
            separatorBuilder: (context, index) => 
              SizedBox(height: 8),
          )
        ],
      ),
    );
  }
}
