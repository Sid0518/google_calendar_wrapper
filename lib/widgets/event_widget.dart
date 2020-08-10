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

    DateTime start = widget.event.start;
    DateTime end = widget.event.end;

    bool fullDayEvent = true;

    String startHour = '00';
    String startMinute = '00';

    if(!start.isBefore(widget.date)) {
      fullDayEvent = false;

      startHour = start.hour.toString().padLeft(2, '0');
      startMinute = start.minute.toString().padLeft(2, '0');
    }

    String endHour = '23';
    String endMinute = '59';

    if(!end.isAfter(widget.date.add(Duration(days: 1)))) {
      fullDayEvent = false;

      endHour = end.hour.toString().padLeft(2, '0');
      endMinute = end.minute.toString().padLeft(2, '0');
    }

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
                        flex: 6,
                        
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
                
                                    child: Text(
                                      '${widget.event.summary}',
                                      maxLines: 1,
                                      overflow: TextOverflow.ellipsis,
                                      
                                      style: TextStyle(
                                          fontSize: 20,
                                          color: Colors.white,
                                          decoration: this.checked
                                              ? TextDecoration.lineThrough
                                              : TextDecoration.none),
                                    ),
                                  ),
                                ],
                              ),

                              if (!this.checked) SizedBox(height: 16),
                              
                              if (!this.checked)
                                Text(
                                  '${widget.event.description}',
                                  maxLines: 4,
                                  overflow: TextOverflow.ellipsis,
                                  
                                  style: TextStyle(
                                    fontSize: 16,
                                    color: Colors.white70,
                                  ),
                                ),
                            ],
                          ),
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
