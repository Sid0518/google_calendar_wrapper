import 'package:google_calendar_wrapper/helpers.dart';
import 'package:google_calendar_wrapper/imports.dart';

class EventWidget extends StatefulWidget {
  final DateTime date;
  final CustomEvent event;

  EventWidget({@required this.date, @required this.event});

  @override
  _EventWidgetState createState() => _EventWidgetState();
}

class _EventWidgetState extends State<EventWidget>
    with TickerProviderStateMixin {
  bool get checked => this.widget.event.checked;
  AnimationController controller;
  Animation<Offset> offset;
  Animation<double> opacity;

  @override
  void initState() {
    this.widget.event.emitter.listen((event) {
      if(event == 'Toggled' && this.mounted)
        setState(() {});
    });
    super.initState();

    this.controller = AnimationController(
      duration: Duration(milliseconds: 320),
      vsync: this,
    );
    final curvedAnim = CurvedAnimation(
      curve: Curves.decelerate,
      parent: this.controller,
    );

    this.offset = 
      Tween<Offset>(begin: Offset(-1, 0), end: Offset.zero)
        .animate(curvedAnim);
    this.opacity = 
      Tween<double>(begin: 0.0, end: 1.0)
        .animate(curvedAnim);

    this.controller.forward();
  }

  @override
  Widget build(BuildContext context) {
    Color eventColor = colorFromHex(
      COLORS['event'][this.widget.event.colorId]['background']
    );

    DateTime start = widget.event.start.toLocal();
    DateTime end = widget.event.end.toLocal();

    if(start.isBefore(widget.date))
      start = widget.date;

    String startHour = start.hour.toString().padLeft(2, '0');
    String startMinute = start.minute.toString().padLeft(2, '0');

    if(end.isAfter(widget.date.add(Duration(days: 1))))
      end = widget.date.add(Duration(days: 1));

    String endHour = end.hour.toString().padLeft(2, '0');
    String endMinute = end.minute.toString().padLeft(2, '0');

    bool fullDayEvent = end.difference(start) == Duration(days: 1);

    List<Widget> time = [
      Text(
        fullDayEvent ? 'All' : '$startHour:$startMinute',
        style: TextStyle(
            fontSize: 18,
            color: Colors.white,
            decoration: this.checked
                ? TextDecoration.lineThrough
                : TextDecoration.none),
      ),
      Text(
        fullDayEvent ? 'Day' : '$endHour:$endMinute',
        style: TextStyle(
            fontSize: 18,
            color: Colors.white,
            decoration: this.checked
                ? TextDecoration.lineThrough
                : TextDecoration.none),
      )
    ];

    return AnimatedSize(
      vsync: this,
      duration: Duration(milliseconds: 200),
      curve: Curves.decelerate,
      
      child: FadeTransition(
        opacity: this.opacity,

        child: SlideTransition(
          position: this.offset,
          
          child: Container(
            decoration: BoxDecoration(
              color: eventColor,
              borderRadius: BorderRadius.circular(8),
            ),
            
            child: Material(
              type: MaterialType.transparency,

              child: InkWell(
                onTap: () async {
                  await widget.event.toggleWithUpdate();
                  setState(() {});
                },
                splashColor: Theme.of(context).primaryColor,
                
                child: ConstrainedBox(
                  constraints: BoxConstraints(
                    minHeight: this.checked ? 50 : 100,
                  ),

                  child: Row(
                    crossAxisAlignment: CrossAxisAlignment.center,
                    mainAxisSize: MainAxisSize.max,
                    
                    children: [
                      IgnorePointer(
                        child: Checkbox(
                          checkColor: eventColor,
                          activeColor: Colors.white,
                          
                          value: this.checked,
                          onChanged: (bool value) {},
                        ),
                      ),

                      Expanded(
                        flex: 2,
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.center,
                          children: time,
                        ),
                      ),

                      SizedBox(width: 8),

                      Expanded(
                        flex: widget.event.local ? 5 : 6,
                        
                        child: Padding(
                          padding: const EdgeInsets.fromLTRB(16, 16, 24, 16),
                          
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            
                            children: <Widget>[
                              Stack(
                                children: <Widget>[
                                  AnimatedPositioned(
                                    duration: Duration(milliseconds: 200),
                                    curve: Curves.decelerate,
                
                                    child: makeScrollable(
                                      maxHeight: 32,
                                      child: Text(
                                        '${widget.event.summary}',
                                        // maxLines: 1,
                                        // overflow: TextOverflow.ellipsis,
                                        
                                        style: TextStyle(
                                            fontSize: 20,
                                            color: Colors.white,
                                            decoration: this.checked
                                                ? TextDecoration.lineThrough
                                                : TextDecoration.none),
                                      ),
                                    ),
                                  ),
                                ],
                              ),

                              if (!this.checked) SizedBox(height: 16),
                              
                              if (!this.checked)
                                makeScrollable(
                                  maxHeight: 84,
                                  child: Text(
                                    '${widget.event.description}',
                                    // maxLines: 4,
                                    // overflow: TextOverflow.ellipsis,
                                    
                                    style: TextStyle(
                                      fontSize: 16,
                                      color: Colors.white70,
                                    ),
                                  ),
                                ),
                            ],
                          ),
                        ),
                      ),

                      if(widget.event.local)
                        Expanded(
                          flex: 1,
                          child: IconButton(
                            icon: Icon(Icons.delete, color: Colors.white),
                            onPressed: () {},
                          ),
                        )
                    ],
                  ),
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }

  @override
  void dispose() {
    this.controller.dispose();
    super.dispose();
  }
}
