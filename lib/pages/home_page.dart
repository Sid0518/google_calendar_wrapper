import 'package:google_calendar_wrapper/imports.dart';

const scopes = const [
  'email',
  CalendarApi.CalendarEventsReadonlyScope,
];

/*
  TODO: Use AnimatedList here to animate in SingleDayEventsView widgets

  The idea is that if an EventWidget is deleted, its SingleDayEventsView 
  parent can animate it out of itself using AnimatedList. In case the 
  SingleDayEventsView becomes empty, then its parent, which is the HomePage, 
  can now animate it out of itself, again using AnimatedList
*/
class HomePage extends StatefulWidget {
  @override
  _HomePageState createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> {
  final googleSignIn = GoogleSignIn(scopes: scopes);

  final scrollController = ScrollController();
  bool enableGoBack = false;

  RangeValues dateRange = RangeValues(-30, 7);

  Map<DateTime, List<CustomEvent>> sortedEvents;

  DateTime selectedDate;

  Future<void> login() async {
    await this.googleSignIn.signIn();
    this.selectedDate = resetDate(DateTime.now());

    await this.updateEvents();
  }

  /// Updates events
  Future<void> updateEvents() async {
    try {
      // Nullify sortedEvents and setState, so that progress indicator pops up
      this.sortedEvents = null;
      setState(() {});
      List<CustomEvent> eventsFromApi =
        await getEventsFromCalendarApi(
          this.googleSignIn.currentUser, 
          this.selectedDate, 
          this.dateRange.start.round().abs(),
          this.dateRange.end.round().abs()
        );
      List<CustomEvent> eventsFromSQLite = await getEventsFromSQLite();

      List<CustomEvent> events = eventsFromApi + eventsFromSQLite;

      this.sortedEvents = sortEvents(
        events,
        this.selectedDate, 
        this.dateRange.start.round().abs(),
        this.dateRange.end.round().abs()
      );

      setState(() {});
    } 
    
    catch (error) {  
      this.sortedEvents = {};
    }
  }

  /// Updates the date
  Future<void> updateDate(BuildContext context) async {
    DateTime newDate = await selectDate(context, this.selectedDate);

    if (newDate != null) {
      this.selectedDate = resetDate(newDate);

      await this.updateEvents();
    }
  }

  Future<void> showSlider(context) async {
    RangeValues selectedRange;

    await showDialog(
      context: context,

      child: AlertDialog(
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(16)
        ),

        title: Text('Select range of dates: '),
        content: Container(
          constraints: BoxConstraints(
            maxHeight: 40,
          ),
          
          child: DateRangeSlider(
            initialValues: this.dateRange,
            min: -30,
            max: 30,
            onChangedCallback: (RangeValues values) => 
              selectedRange = values,
          ),
        ),

        actions: [
          FlatButton(
            child: Text(
              'CONFIRM',
              
              style: TextStyle(
                fontWeight: FontWeight.bold,
                color: Theme.of(context).primaryColor
              ),
            ),

            onPressed: () async {
              if(selectedRange != null)
                this.dateRange = selectedRange;
              Navigator.pop(context);

              await this.updateEvents();
            }
          ),

          FlatButton(
            child: Text(
              'CANCEL',

              style: TextStyle(
                fontWeight: FontWeight.bold,
                color: Theme.of(context).accentColor
              ),
            ),

            onPressed: () =>
              Navigator.pop(context)
          ),
        ],
      )
    );
  }

  @override
  void initState() {
    super.initState();
    this.login();

    this.scrollController.addListener(() {
      if(this.scrollController.offset > 800) {
        setState(() => this.enableGoBack = true);
      }

      else if(this.enableGoBack)
        setState(() => this.enableGoBack = false);
    });
  }

  @override
  Widget build(BuildContext context) {
    List<DateTime> dates;

    if(this.sortedEvents != null) {
      dates = this.sortedEvents.keys
        .where((key) => this.sortedEvents[key].length > 0)
        .toList();
      dates.sort();
    }

    return Scaffold(
        appBar: AppBar(
          title: Text('Calendar Wrapper'),
          actions: [
            IconButton(
                icon: Icon(Icons.calendar_today),
                onPressed: () => this.updateDate(context)
            ),

            IconButton(
                icon: Icon(Icons.av_timer),
                onPressed: () => this.showSlider(context)
            ),
          ],
        ),
        body: Stack(
          children: <Widget>[
            dates != null ?
              RefreshIndicator(
                onRefresh: this.updateEvents,

                child: ListView.separated(
                  controller: this.scrollController,

                  itemCount: dates.length,
                  itemBuilder: (context, index) {
                      DateTime date = dates[index];
                      return SingleDayEventsView(
                        date: date,
                        events: this.sortedEvents[date]
                      );
                  },
                  separatorBuilder: (context, index) =>
                    Divider(height: 8, thickness: 1, indent: 16, endIndent: 16),
                ),
              ) : 
              Center(
                child: CircularProgressIndicator(),
              ),

              AnimatedPositioned(
                duration: Duration(milliseconds: 200),

                top: this.enableGoBack ? 16 : -64,
                right: 16,

                child: Container(
                  height: 40,
                  width: 40,
                  
                  child: FittedBox(
                    child: FloatingActionButton(
                      child: Icon(
                        Icons.arrow_upward, 
                        color: Theme.of(context).accentColor
                      ),
                      backgroundColor: Colors.white,
                      
                      onPressed: () => 
                        this.scrollController
                          .animateTo(
                            0, 
                            duration: Duration(milliseconds: 400), 
                            curve: Curves.decelerate,
                          )
                    ),
                  ),
                ),
              )
          ],
        ),

        floatingActionButton: FloatingActionButton(
            child: Icon(Icons.add),

            onPressed: () async {
              CustomEvent newEvent = 
                await showModalBottomSheet(
                  context: context,
                  isDismissible: false,
                  isScrollControlled: true,

                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.vertical(top: Radius.circular(16)),
                  ),

                  builder: (context) => 
                    WillPopScope(
                      onWillPop: () async => false,
                      child: Padding(
                        padding: MediaQuery.of(context).viewInsets,
                        child: AddEventDialog(),
                      ),
                    )
                );
              
              if(newEvent != null)
                setState(() {
                  Map<DateTime, CustomEvent> eventMap = 
                    splitEvent(newEvent);
                    
                  eventMap.forEach((date, event) {
                    if(this.sortedEvents.containsKey(date))  
                      this.sortedEvents[date].add(event);
                    else
                      this.sortedEvents[date] = [event];
                    
                    this.sortedEvents[date]
                      .sort((a, b) => a.start.compareTo(b.start));
                  });
                });
            }
        )
    );
  }
}
