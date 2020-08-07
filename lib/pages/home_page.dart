import 'package:google_calendar_wrapper/helpers.dart';
import 'package:google_calendar_wrapper/imports.dart';

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

  Map<DateTime, List<Event>> sortedEvents = {};

  DateTime selectedDate;

  Future<void> login() async {
    await this.googleSignIn.signIn();
  }

  /// Updates events
  Future<void> updateEvents() async {
    try {
      this.events =
          await getEvents(this.googleSignIn.currentUser, selectedDate, 0, 3);
      this.listEvents = filteredEvents(this.events);
      this.sortedEvents = sortEvents(listEvents);
      setState(() {});
    } catch (error) {
      print(error);
    }
  }

  /// Updates the date
  Future<void> updateDate(BuildContext context) async {
    DateTime newDate = await selectDate(context, selectedDate);
    if (newDate != null) {
      selectedDate = newDate;
    }
  }

  List<Widget> createWidgets() {
    List<Widget> finalList = [];
    List<DateTime> dates = this.sortedEvents.keys.toList();
    dates.sort();
    for (DateTime dateTime in dates) {
      finalList.add(Text(dateTime.toIso8601String()));
      finalList.add(SizedBox(height: 16));
      for (Event event in this.sortedEvents[dateTime]) {
        finalList.add(EventWidget(event: event));
        finalList.add(SizedBox(height: 16));
      }
    }
    return finalList;
  }

  @override
  void initState() {
    super.initState();
    this.login();
    selectedDate = DateTime.now();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
        appBar: AppBar(
          title: Text('Calendar Wrapper'),
          actions: [
            IconButton(
                icon: Icon(Icons.calendar_today),
                onPressed: () async {
                  await updateDate(context);
                  updateEvents();
                })
          ],
        ),
        body: Center(
          child: Padding(
              padding: EdgeInsets.all(16),
              child: ListView(
                children: createWidgets(),
              )),
          // child: ListView.separated(
          //   itemCount: (this.listEvents ?? []).length,
          //   itemBuilder: (context, index) =>
          //       EventWidget(event: this.listEvents[index]),
          //   separatorBuilder: (context, index) => SizedBox(height: 16),
          // )),
        ),
        floatingActionButton: FloatingActionButton(
            child: Icon(Icons.refresh), onPressed: updateEvents));
  }
}
