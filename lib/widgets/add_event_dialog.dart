import 'package:google_calendar_wrapper/imports.dart';

class AddEventDialog extends StatefulWidget {
  @override
  _AddEventDialogState createState() => _AddEventDialogState();
}

class _AddEventDialogState extends State<AddEventDialog> {
  String summary;
  String description;
  String colorId = 'default';
  
  DateTime startDate = resetDate(DateTime.now().toLocal());
  TimeOfDay startTime = TimeOfDay.fromDateTime(DateTime.now().toLocal());

  DateTime endDate = resetDate(DateTime.now().toLocal());
  TimeOfDay endTime = TimeOfDay.fromDateTime(DateTime.now().toLocal());

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: EdgeInsets.all(16),

      child: ListView(
        shrinkWrap: true,
        scrollDirection: Axis.vertical,

        children: <Widget>[
          Text(
            'Add an Event',

            style: TextStyle(
              fontWeight: FontWeight.w500,
              fontSize: 20,
            ),
          ),

          TextField(
            decoration: InputDecoration(
              labelText: 'Add a title'
            ),

            onChanged: (String newValue) => this.summary = newValue,
          ),

          TextField(
            decoration: InputDecoration(
              labelText: 'Add a description'
            ),

            onChanged: (String newValue) => this.description = newValue,
          ),

          SizedBox(height: 16),

          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,

            children: <Widget>[
              Expanded(
                flex: 2,
                child: Text(
                  'Start date and time: ',
                  
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w400,
                    color: Theme.of(context).accentColor
                  ),
                  textAlign: TextAlign.center,
                ),
              ),

              Expanded(
                flex: 2,
                child: InkWell(
                  onTap: () async {
                    DateTime date = await showDatePicker(
                      context: context,
                      initialDate: this.startDate,
                      firstDate: DateTime.now().toLocal().subtract(Duration(days: 365*5)),
                      lastDate: DateTime.now().toLocal().add(Duration(days: 365*5)),
                    );

                    if(date != null)
                      setState(() {
                        this.startDate = date;
                        
                        if(endBeforeStart(
                          this.startDate, this.startTime, 
                          this.endDate, this.endTime
                        )) {
                          this.endDate = this.startDate;
                          this.endTime = this.startTime;
                        }
                      });
                  },
                  
                  child: Text(
                    DateFormat('yMMMMd').format(this.startDate),
                    
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.w500,
                      color: Theme.of(context).primaryColor
                    ),
                    textAlign: TextAlign.center,
                  ),
                ),
              ),

              Expanded(
                flex: 1,
                child: InkWell(
                  onTap: () async {
                    TimeOfDay time = await showTimePicker(
                      context: context,
                      initialTime: this.startTime,
                    );

                    if(time != null)
                      setState(() {
                        this.startTime = time;
                        
                        if(endBeforeStart(
                          this.startDate, this.startTime, 
                          this.endDate, this.endTime
                        )) {
                          this.endDate = this.startDate;
                          this.endTime = this.startTime;
                        }
                      });
                  },

                  child: Text(
                    this.startTime.format(context),

                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.w500,
                      color: Theme.of(context).primaryColor
                    ),
                    textAlign: TextAlign.center,
                  ),
                ),
              ),
            ],
          ),

          SizedBox(height: 8),

          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,

            children: <Widget>[
              Expanded(
                flex: 2,
                child: Text(
                  'End date and time: ',
                  
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w400,
                    color: Theme.of(context).accentColor
                  ),
                  textAlign: TextAlign.center,
                ),
              ),

              Expanded(
                flex: 2,
                child: InkWell(
                  onTap: () async {
                    DateTime date = await showDatePicker(
                      context: context,
                      initialDate: this.startDate,
                      firstDate: this.startDate,
                      lastDate: DateTime.now().toLocal().add(Duration(days: 365*5)),
                    );

                    if(date != null)
                      setState(() {
                        this.endDate = date;
                        
                        if(endBeforeStart(
                          this.startDate, this.startTime, 
                          this.endDate, this.endTime
                        )) {
                          this.endDate = this.startDate;
                          this.endTime = this.startTime;
                        }
                      });
                  },
                  
                  child: Text(
                    DateFormat('yMMMMd').format(this.endDate),
                    
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.w500,
                      color: Theme.of(context).primaryColor
                    ),
                    textAlign: TextAlign.center,
                  ),
                ),
              ),

              Expanded(
                flex: 1,
                child: InkWell(
                  onTap: () async {
                    TimeOfDay time = await showTimePicker(
                      context: context,
                      initialTime: this.endTime,
                    );

                    if(time != null)
                      setState(() {
                        this.endTime = time;
                        
                        if(endBeforeStart(
                          this.startDate, this.startTime, 
                          this.endDate, this.endTime
                        )) {
                          this.endDate = this.startDate;
                          this.endTime = this.startTime;
                        }
                      });
                  },

                  child: Text(
                    this.endTime.format(context),

                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.w500,
                      color: Theme.of(context).primaryColor
                    ),
                    textAlign: TextAlign.center,
                  ),
                ),
              ),
            ],
          ),

          SizedBox(height: 16),
          
          Align(
            alignment: Alignment.centerLeft,
            child: Text(
              'Event color: ',
              
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.w400,
                color: Theme.of(context).primaryColor,
              ),
              textAlign: TextAlign.center,
            ),
          ),

          SizedBox(height: 16),

          GridView.count(
            crossAxisCount: 6,
            shrinkWrap: true,
            scrollDirection: Axis.vertical,

            children: COLORS['event'].keys.map(
              (colorId) => 
                InkWell(
                  onTap: () => setState(() => this.colorId = colorId),

                  child: Stack(
                    children: <Widget>[
                      Container(
                        decoration: BoxDecoration(
                          color: colorFromHex(COLORS['event'][colorId]['background']), 
                        ),
                      ),

                      if(colorId == this.colorId)
                        Positioned(
                          bottom: 0,
                          right: 0,

                          child: Icon(Icons.check_circle)
                        )
                    ],
                  ),
                )
              ).toList().cast<Widget>(),
          ),

          SizedBox(height: 32),

          Row(
            children: <Widget>[
              Expanded(
                flex: 2,
                child: SizedBox(),
              ),

              Expanded(
                flex: 1,
                child: FlatButton(
                  child: Text(
                    'CONFIRM',
                    
                    style: TextStyle(
                      fontWeight: FontWeight.bold,
                      color: Theme.of(context).primaryColor
                    ),
                  ),

                  onPressed: () async {
                    CustomEvent event = CustomEvent(
                      summary: this.summary,
                      description: this.description,
                      colorId: this.colorId,

                      start: this.startDate.add(
                        Duration(
                          hours: this.startTime.hour, 
                          minutes: this.startTime.minute
                        )
                      ),

                      end: this.endDate.add(
                        Duration(
                          hours: this.endTime.hour, 
                          minutes: this.endTime.minute
                        )
                      ),
                    );

                    Navigator.pop(context, event);
                  }
                ),
              ),

              Expanded(
                flex: 1,
                child: FlatButton(
                  child: Text(
                    'CANCEL',

                    style: TextStyle(
                      fontWeight: FontWeight.bold,
                      color: Theme.of(context).accentColor
                    ),
                  ),

                  onPressed: () =>
                    Navigator.pop(context, null)
                ),
              ),
            ],
          )
        ],
      ),
    );
  }
}