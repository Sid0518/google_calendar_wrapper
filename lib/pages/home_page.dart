import 'package:google_calendar_wrapper/helpers.dart';
import 'package:google_calendar_wrapper/imports.dart';
import 'package:google_calendar_wrapper/models/single_day_events_view.dart';

const scopes = const [
  'email',
  CalendarApi.CalendarEventsReadonlyScope,
];

class HomePage extends StatefulWidget {
  @override
  _HomePageState createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> {
  final googleSignIn = GoogleSignIn(scopes: scopes);
  Events events = Events();
  List<Event> listEvents = [];

  Map<DateTime, List<Event>> sortedEvents;

  DateTime selectedDate;

  Future<void> login() async {
    await this.googleSignIn.signIn();
    this.selectedDate = DateTime.now();
    await this.updateEvents();
  }

  /// Updates events
  Future<void> updateEvents() async {
    try {
      // Nullify sortedEvents and setState, so that progress indicator pops up
      this.sortedEvents = null;
      setState(() {});

      this.events =
          await getEvents(this.googleSignIn.currentUser, selectedDate, 30, 7);
      this.listEvents = filteredEvents(this.events);
      this.sortedEvents = sortEvents(listEvents);

      setState(() {});
    } catch (error) {
      print(error);
      this.sortedEvents = {};
    }
  }

  /// Updates the date
  Future<void> updateDate(BuildContext context) async {
    DateTime newDate = await selectDate(context, selectedDate);

    if (newDate != null) {
      selectedDate = newDate;

      await this.updateEvents();
    }
  }

  @override
  void initState() {
    super.initState();
    this.login();
  }

  @override
  Widget build(BuildContext context) {
    List<DateTime> dates;

    if(this.sortedEvents != null) {
      dates = this.sortedEvents.keys.toList();
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
          ],
        ),
        body: dates != null ?
          RefreshIndicator(
            onRefresh: this.updateEvents,

            child: ListView.separated(
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

        floatingActionButton: FloatingActionButton(
            child: Icon(Icons.add), 
            onPressed: () =>
              showDialog(
                context: context,

                child: AlertDialog(
                  title: Text('Adding to Todo not yet implemented'),
                )
              )
        )
    );
  }
}
