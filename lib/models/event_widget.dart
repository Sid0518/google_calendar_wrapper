import 'package:google_calendar_wrapper/helpers.dart';
import 'package:google_calendar_wrapper/imports.dart';
import 'package:google_calendar_wrapper/models/single_day_event_view.dart';

class EventWidget extends StatefulWidget {
  final Event event;
  bool checked;
  EventWidget({this.event,this.checked = false});

  @override
  _EventWidgetState createState() => _EventWidgetState();
}

class _EventWidgetState extends State<EventWidget> 
with SingleTickerProviderStateMixin {
  @override
  Widget build(BuildContext context) {
    Color eventColor = colorFromHex(COLORS['event'][this.widget.event.colorId ?? 'default']['background']);
    
    var startHour;
    var startMinute;
    if(widget.event.start.dateTime != null) {
      startHour = widget.event.start.dateTime.hour.toString().padLeft(2, '0');
      startMinute = widget.event.start.dateTime.minute.toString().padLeft(2, '0');
    }
    
    var endHour;
    var endMinute;
    if(widget.event.end.dateTime != null) {
      endHour = widget.event.end.dateTime.hour.toString().padLeft(2, '0');
      endMinute = widget.event.end.dateTime.minute.toString().padLeft(2, '0');
    }

    List<Widget> time = [
      Text(
        '${startHour ?? '-'}${startMinute ?? ''}',

        style: TextStyle(
          fontSize: 18,
          color: Colors.white,
          decoration: 
            widget.checked ? 
              TextDecoration.lineThrough :
              TextDecoration.none
        ),
      ),

      Text(
        '${endHour ?? '-'}${endMinute ?? ''}',

        style: TextStyle(
          fontSize: 18,
          color: Colors.white,
          decoration: 
            widget.checked ? 
              TextDecoration.lineThrough :
              TextDecoration.none
        ),
      )
    ];

    return AnimatedSize(
      vsync: this,
      duration: Duration(milliseconds: 400),
      curve: Curves.decelerate,

      child: InkWell(
        onTap: () {},
        child: Container(
          decoration: BoxDecoration(
            color: eventColor,
            borderRadius: BorderRadius.circular(8),
          ),

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
                }
              ),

              Expanded(
                flex: 1,
                child:
                  Column(
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
                      Text(
                        '${widget.event.summary ?? 'No name'}',
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,

                        style: TextStyle(
                          fontSize: 20,
                          color: Colors.white,
                          decoration: 
                          widget.checked ? 
                            TextDecoration.lineThrough :
                            TextDecoration.none
                        ),
                      ),

                      if(!widget.checked)
                        SizedBox(height: 16),

                      if(!widget.checked)
                        Text(
                          '${widget.event.description ?? 'No description'}',
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
    );
  }
}