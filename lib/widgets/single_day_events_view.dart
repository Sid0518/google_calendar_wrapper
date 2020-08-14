import 'package:google_calendar_wrapper/imports.dart';

/*
  TODO: Discard the slide transition from EventWidget, and instead use
  AnimatedList here
*/
class SingleDayEventsView extends StatefulWidget {
  final DateTime date;
  List<CustomEvent> events;
  
  // ignore: close_sinks
  final eventNotifier = StreamController.broadcast();
  Stream get notifier => this.eventNotifier.stream;

  SingleDayEventsView({@required this.date, @required this.events}): 
    super(key: ValueKey(date));

  @override
  _SingleDayEventsViewState createState() => _SingleDayEventsViewState();
}

class _SingleDayEventsViewState extends State<SingleDayEventsView> {
  List<EventWidget> eventWidgets = [];
  List<StreamSubscription> listeners = [];

  final listKey = GlobalKey<AnimatedListState>();
  final offset = 
    Tween<Offset>(begin: Offset(-1, 0), end: Offset.zero)
      .chain(CurveTween(curve: Curves.decelerate));

  void addEvent(CustomEvent event) {
    if(this.listKey.currentState != null) {
      EventWidget eventWidget = EventWidget(date: widget.date, event: event);
      this.eventWidgets.add(eventWidget);
      this.eventWidgets.sort((a, b) => a.event.start.compareTo(b.event.start));

      int index = this.eventWidgets.indexOf(eventWidget);
      widget.events.insert(index, event);

      this.listeners.insert(
        index, 
        event.notifier.listen((message) => this.removeEvent(event))
      );

      this.listKey.currentState.insertItem(index);
    }
    else
      WidgetsBinding.instance
        .addPostFrameCallback((_) => this.addEvent(event));
  }

  void removeEvent(CustomEvent event) {
    if(this.listKey.currentState != null) {
      int index = 
        this.eventWidgets
          .indexWhere((eventWidget) => eventWidget.event == event);

      if(index != -1) {
        EventWidget eventWidget = this.eventWidgets[index];

        this.eventWidgets.removeAt(index);
        widget.events.removeAt(index);

        this.listeners[index].cancel();
        this.listeners.removeAt(index);

        this.listKey.currentState.removeItem(
          index, 
          (context, animation) => 
            SlideTransition(
              position: animation.drive(this.offset),
              child: eventWidget,
            )
        );

        if(widget.events.length == 0)
          widget.eventNotifier.add('Empty');
      }
    }
    else
      WidgetsBinding.instance
        .addPostFrameCallback((_) => this.removeEvent(event));
  }

  @override
  void setState(fn) {
    if(this.mounted)
      super.setState(fn);
  }

  @override
  void initState() {
    this.eventWidgets = [];

    List<CustomEvent> events = widget.events;
    widget.events = [];

    for(CustomEvent event in events)
      this.addEvent(event);

    super.initState();
  }
  
  @override
  Widget build(BuildContext context) {
    for(StreamSubscription listener in this.listeners)
      listener.cancel();

    for(CustomEvent event in this.widget.events)
      this.listeners.add(event.notifier.listen(
        (eventHeard) {
          if(eventHeard == 'Deleted')
            this.removeEvent(event);
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
          
          // ListView.separated(
          //   shrinkWrap: true,
          //   scrollDirection: Axis.vertical,
          //   physics: NeverScrollableScrollPhysics(),
            
          //   itemCount: this.widget.events.length,
          //   itemBuilder: (context, index) =>
          //     EventWidget(
          //       date: this.widget.date,
          //       event: this.widget.events[index],
          //     ),
          //   separatorBuilder: (context, index) => 
          //     SizedBox(height: 8),
          // ),

          AnimatedList(
            key: this.listKey,
            shrinkWrap: true,
            scrollDirection: Axis.vertical,
            physics: NeverScrollableScrollPhysics(),
            
            // initialItemCount: this.eventWidgets.length,
            /*
              TODO: Figure out why sometimes AnimatedList has 
              less/more elements than this.dayViews, and then 
              remove this ternary hack
            */
            itemBuilder: (context, index, animation) => 
              index < this.eventWidgets.length ?
                SlideTransition(
                  position: animation.drive(this.offset),
                  
                  child: Padding(
                    padding: EdgeInsets.only(
                      bottom: (index == this.eventWidgets.length - 1) ? 0 : 8,
                    ),
                    child: this.eventWidgets[index],
                  ),
                ) : null,
          ),
        ],
      ),
    );
  }

  void discardListeners() {
    for(StreamSubscription listener in this.listeners)
      listener.cancel();
    this.listeners.clear();
  }

  @override
  void dispose() {
    if(this.listKey.currentState != null) {
      int index = this.eventWidgets.length;

      while(index-- > 0)
        this.listKey.currentState
          .removeItem(index, (context, animation) => null);
    }
    this.eventWidgets.clear();
    this.discardListeners();
    
    super.dispose();
  }
}
