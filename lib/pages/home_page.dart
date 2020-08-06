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
  final googleSignIn = GoogleSignIn(
    scopes: scopes
  );
  Events events = Events();

  Future<void> login() async {
    await this.googleSignIn.signIn();
  }

  @override
  void initState() {
    super.initState();
    this.login();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Calendar Wrapper'),
      ),

      body: Center(
        child: Padding(
          padding: EdgeInsets.all(16),
          child: ListView.separated(
            itemCount: (this.events.items ?? []).length,
            itemBuilder: (context, index) =>
              EventWidget(event: this.events.items[index]),
            separatorBuilder: (context, index) =>
              SizedBox(height: 16),
          )
        ),
      ),

      floatingActionButton: FloatingActionButton(
        child: Icon(Icons.add),
        onPressed: () async {
          final authHeaders = await this.googleSignIn.currentUser.authHeaders;
          final httpClient = GoogleHttpClient(authHeaders);

          try {
            this.events = await CalendarApi(httpClient)
              .events
              .list(
                'primary', 
                // timeMin: DateTime.now()
                // .subtract(Duration(days: 30)).toUtc(),
              );
            
            setState(() {});
          } catch(error) {
            print(error);
          }
        }
      )
    );
  }
}