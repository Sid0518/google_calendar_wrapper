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

  DateTime selectedDate = DateTime.now();
  RangeValues dateRange = RangeValues(-30, 7);

  List<SingleDayEventsView> dayViews;
  List<StreamSubscription> listeners = [];

  Future<void> login() async {
    await this.googleSignIn.signIn();
    this.selectedDate = resetDate(DateTime.now());

    await this.updateEvents();
  }

  /// Updates events
  Future<void> updateEvents() async {
    try {
      // Nullify sortedEvents and setState, so that progress indicator pops up
      this.dayViews = null;
      for(StreamSubscription listener in this.listeners)
        listener.cancel();
      this.listeners = [];

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
      Map<DateTime, List<CustomEvent>> sortedEvents = sortEvents(
        events,
        this.selectedDate, 
        this.dateRange.start.round().abs(),
        this.dateRange.end.round().abs()
      );

      this.dayViews = [];
      sortedEvents.forEach((date, events) =>
        this.dayViews.add(SingleDayEventsView(
          date: date,
          events: events,
        ))
      );

      this.dayViews.sort((a, b) => a.date.compareTo(b.date));
      for(SingleDayEventsView dayView in this.dayViews)
        this.listeners.add(dayView.notifier.listen((_) => setState(() {})));

      setState(() {});
    } 
    
    catch (error) {  
      this.dayViews = [];
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
  void setState(fn) {
    if(this.mounted)  
      super.setState(fn);
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
    this.dayViews?.removeWhere((dayView) => dayView.events.length == 0);

    return Scaffold(
        appBar: AppBar(
          title: Text('${DateFormat('EEEE, MMM d, y').format(this.selectedDate)}:  -${this.dateRange.start.toInt().abs()}  +${this.dateRange.end.toInt().abs()}'),
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
            this.dayViews != null ?
              RefreshIndicator(
                onRefresh: this.updateEvents,

                child: ListView.separated(
                  shrinkWrap: true,
                  scrollDirection: Axis.vertical,
                  controller: this.scrollController,

                  itemCount: this.dayViews.length,
                  itemBuilder: (context, index) =>
                    this.dayViews[index],
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
                  Map<DateTime, List<CustomEvent>> newEvents = 
                    filterEventsByDate(
                      splitEvent(newEvent), 
                      this.selectedDate, 
                      this.dateRange.start.toInt().abs(), 
                      this.dateRange.end.toInt().abs(),
                    );
                  print(newEvents);
                    
                  newEvents.forEach((date, newEvents) {
                    List<CustomEvent> currentEvents = [];
                    int index = this.dayViews
                      .indexWhere((dayView) => dayView.date == date);

                    if(index != -1) {
                      currentEvents = this.dayViews[index].events;

                      this.dayViews.removeAt(index);
                      this.listeners[index].cancel();
                      this.listeners.removeAt(index);
                    }

                    SingleDayEventsView dayView = 
                      SingleDayEventsView(
                        date: date,
                        events: [...currentEvents, ...newEvents],
                      );

                    this.dayViews.add(dayView);
                    this.dayViews.sort((a, b) => a.date.compareTo(b.date));

                    index = this.dayViews.indexOf(dayView);
                    this.listeners.insert(
                      index,
                      dayView.notifier.listen((_) => setState(() {}))
                    );

                    setState(() {});
                  });
                });
            }
        )
    );
  }

  @override
  void dispose() {
    for(StreamSubscription listener in this.listeners)
      listener.cancel();
    this.listeners = [];

    super.dispose();
  }
}
