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
  String text = 'Trying to log in...';

  Future<void> login() async {
    this.googleSignIn.signIn()
      .then((value) => 
        setState(() =>
          this.text = 
            'Signed in as ${this.googleSignIn.currentUser.displayName}'
        )
      )
      .catchError((error) => 
        setState(() => this.text = error.toString())
      );
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
          child: Text(
            this.text,
            
            style: TextStyle(
              fontSize: 24,
            ),
            textAlign: TextAlign.center,
          ),
        ),
      ),

      floatingActionButton: FloatingActionButton(
        child: Icon(Icons.add),
        onPressed: () async {
          final authHeaders = await this.googleSignIn.currentUser.authHeaders;
          final httpClient = GoogleHttpClient(authHeaders);

          try {
            Events events = await CalendarApi(httpClient)
              .events
              .list(
                'primary', 
                timeMin: DateTime.now()
                .subtract(Duration(days: 30)).toUtc(),
              );

            final prettyPrinter = JsonEncoder.withIndent('  ');
            events.items.forEach((event) {
              print(event.summary);
            });

          } catch(error) {
            print(error);
          }
        }
      )
    );
  }
}