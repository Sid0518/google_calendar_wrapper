import 'imports.dart';
import 'package:http/http.dart' as http;

class App extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      home: HomePage(),
      theme: ThemeData(
          primaryColor: Color.fromRGBO(16, 76, 145, 1),
          accentColor: Color.fromRGBO(31, 138, 192, 1)),
    );
  }
}

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  COLORS = jsonDecode((await http.get(colorApi)).body);
  COLORS['event']['default'] = {
    'background': '#9bb2d1', 
    'foreground': '#1d1d1d'
  };

  db = await openDatabase(
    join(await getDatabasesPath(), 'events.db'),
    onCreate: (db, version) {
      db.execute(
        "CREATE TABLE events(_id INTEGER PRIMARY KEY AUTOINCREMENT, eventId TEXT, summary TEXT, description TEXT, colorId TEXT, start TEXT, end TEXT, checked INTEGER)",
      );
    },
    version: 1,
  );

  runApp(App());
}
