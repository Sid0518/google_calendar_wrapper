import 'package:google_calendar_wrapper/imports.dart';

class CustomEvent {
  String id;
  String summary;
  String description;
  String colorId;

  DateTime start;
  DateTime end;

  bool checked;
  bool local;

  bool deleted = false;
  
  /* The comment below tells VSCode to stop crying */
  // ignore: close_sinks
  StreamController eventNotifier = StreamController.broadcast();
  Stream get emitter => this.eventNotifier.stream;

  CustomEvent({
    this.summary, this.description, this.colorId,
    this.start, this.end, 
    this.checked = false
  }) {
      this.id = Uuid().v1();
      this.summary ??= '(No title)';
      this.description ??= '(No description)';
      this.colorId ??= 'default';

      this.start = this.start.toUtc();
      this.end = this.end.toUtc();

      this.checked ??= false;
      this.local = true;

      this.addToDatabase();
  }

  CustomEvent.fromCustomEvent({CustomEvent event}) {
    this.id = event.id;
    this.summary = event.summary;
    this.description = event.description;
    this.colorId = event.colorId;

    this.start = event.start.toUtc();
    this.end = event.end.toUtc();

    this.checked = event.checked;
    this.local = event.local;
  }

  CustomEvent.fromEvent({Event event}) {
    this.id = event.id;
    this.summary = event.summary ?? '(No title)';
    this.description = event.description ?? '(No description)';
    this.colorId = event.colorId ?? 'default';

    if(event.originalStartTime != null)
      this.start = (event.originalStartTime.dateTime ?? event.originalStartTime.date).toUtc();
    else
      this.start = (event.start.dateTime ?? event.start.date).toUtc();
    this.end = (event.end.dateTime ?? event.start.date).toUtc();

    this.checked = false;
    this.local = false;
    this.setChecked().then((value) => this.addToDatabase());
  }

  CustomEvent.fromMap(Map<String, dynamic> map) {
    this.id = map['eventId'];
    this.summary = map['summary'];
    this.description = map['description'];
    this.colorId = map['colorId'];

    this.start = DateTime.parse(map['start']).toUtc();
    this.end = DateTime.parse(map['end']).toUtc();

    this.checked = map['checked'] == 1 ? true : false;
    this.local = map['local'] == 1 ? true : false;
  }

  void addListener(Stream notifier) {
    notifier.listen((event) {
      if(event == 'Toggled with update')
        this.toggle();
      else if(!this.deleted && event == 'Deleted') {
        this.deleted = true;
        this.eventNotifier.add('Deleted');
      }
    });
  }

  Map<String, dynamic> toMap() {
    return {
      'eventId': this.id,
      'summary': this.summary,
      'description': this.description,
      'colorId': this.colorId,
      'start': this.start.toIso8601String(),
      'end': this.end.toIso8601String(),
      'checked': this.checked ? 1 : 0,
      'local': this.local ? 1 : 0,
    };
  }

  Future<void> setChecked() async {
    List<Map<String, dynamic>> queryResult = 
      await db.query(
        'events',
        columns: ['checked'],
        where: 'eventId = ?',
        whereArgs: [this.id]
      );

    if(queryResult.length > 0)
      this.checked = queryResult.first['checked'] == 1 ? true : false;
    else
      this.checked = false;
    this.eventNotifier.add('Toggled');
  }

  Future<void> addToDatabase() async {
    await db.insert(
      'events', 
      this.toMap(),
      conflictAlgorithm: ConflictAlgorithm.replace,
    );
  }

  Future<void> deleteFromDatabase() async {
    if(!this.deleted) {
      await db.delete(
        'events', 
        where: 'eventId = ?',
        whereArgs: [this.id],
      );

      this.deleted = true;
      this.eventNotifier.add('Deleted');
    }
  }

  void toggle() {
    this.checked = !this.checked;
    this.eventNotifier.add('Toggled');
  }

  Future<void> toggleWithUpdate() async {
    this.checked = !this.checked;
    this.eventNotifier.add('Toggled with update');

    await db.update(
      'events',
      {'checked': this.checked ? 1 : 0},
      where: 'eventId = ?',
      whereArgs: [this.id],
    );
  }
}