import 'package:google_calendar_wrapper/helpers.dart';
import 'package:google_calendar_wrapper/imports.dart';

class EventWidget extends StatefulWidget {
  final DateTime date;
  final Event event;

  bool checked;
  EventWidget({@required this.date, @required this.event, this.checked = false});

  @override
  _EventWidgetState createState() => _EventWidgetState();
}

class _EventWidgetState extends State<EventWidget>
    with SingleTickerProviderStateMixin {
  @override
  Widget build(BuildContext context) {
    Color eventColor = colorFromHex(
      COLORS['event'][this.widget.event.colorId ?? 'default']['background']
    );

    DateTime start = widget.event.start.dateTime;
    DateTime end = widget.event.end.dateTime;

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
            decoration: widget.checked
                ? TextDecoration.lineThrough
                : TextDecoration.none),
      ),
      Text(
        fullDayEvent ? 'Day' : '$endHour:$endMinute',
        style: TextStyle(
            fontSize: 18,
            color: Colors.white,
            decoration: widget.checked
                ? TextDecoration.lineThrough
                : TextDecoration.none),
      )
    ];

    return AnimatedSize(
      vsync: this,
      duration: Duration(milliseconds: 200),
      curve: Curves.decelerate,
      
      child: InkWell(
        onTap: () =>
          setState(() => widget.checked = !widget.checked),
        splashColor: Theme.of(context).primaryColor,

        child: Ink(
          decoration: BoxDecoration(
            color: eventColor,
            borderRadius: BorderRadius.circular(8),
          ),
          
          child: ConstrainedBox(
            constraints: BoxConstraints(
              minHeight: widget.checked ? 50 : 100,
            ),

            child: Row(
              crossAxisAlignment: CrossAxisAlignment.center,
              mainAxisSize: MainAxisSize.max,
              
              children: [
                Checkbox(
                    checkColor: eventColor,
                    activeColor: Colors.white,
                    value: widget.checked,
                    onChanged: (bool value) {
                      setState(() => widget.checked = value);
                    }),

                Expanded(
                  flex: 1,
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
                                '${widget.event.summary ?? '(No title)'}',
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                                
                                style: TextStyle(
                                    fontSize: 20,
                                    color: Colors.white,
                                    decoration: widget.checked
                                        ? TextDecoration.lineThrough
                                        : TextDecoration.none),
                              ),
                            ),
                          ],
                        ),

                        if (!widget.checked) SizedBox(height: 16),
                        
                        if (!widget.checked)
                          Text(
                            '${widget.event.description ?? '(No description)'}',
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
    );
  }
}
