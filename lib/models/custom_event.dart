import 'package:google_calendar_wrapper/imports.dart';

class CustomEvent {
  String id;
  String summary;
  String description;
  String colorId;

  DateTime start;
  DateTime end;

  bool checked;
  
  StreamController _eventEmitter = StreamController.broadcast();
  Stream get emitter => this._eventEmitter.stream;

  CustomEvent({
    this.summary = '(No title)', this.description = '(No description)', 
    this.start, this.end, 
    this.checked = false
  }) {
      this.id = Uuid().v1();
      this.colorId = 'default';
  }

  CustomEvent.fromEvent({Event event, this.checked = false}) {
    this.id = event.id;
    this.summary = event.summary ?? '(No title)';
    this.description = event.description ?? '(No description)';
    this.colorId = event.colorId ?? 'default';

    this.start = event.start.dateTime ?? event.start.date;
    this.end = event.end.dateTime ?? event.start.date;

    this.addToDatabase();
  }

  CustomEvent.fromMap(Map<String, dynamic> map) {
    this.id = map['eventId'];
    this.summary = map['summary'];
    this.description = map['description'];
    this.colorId = map['colorId'];

    this.start = DateTime.parse(map['start']);
    this.end = DateTime.parse(map['end']);

    this.checked = map['checked'] == 1 ? true : false;
  }

  void addToggleListener(Stream emitter) {
    emitter.listen((event) {
      if(event == 'Toggled with update')
        this.toggle();
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
      'checked': this.checked ? 1 : 0
    };
  }

  Future<void> addToDatabase() async {
    await db.insert(
      'events', 
      this.toMap(),
      conflictAlgorithm: ConflictAlgorithm.replace,
    );
  }

  void toggle() {
    this.checked = !this.checked;
    this._eventEmitter.add('Toggled');
  }

  Future<void> toggleWithUpdate() async {
    this.checked = !this.checked;
    this._eventEmitter.add('Toggled with update');

    await db.update(
      'events',
      {'checked': this.checked ? 1 : 0},
      where: 'eventId = ?',
      whereArgs: [this.id],
    );
  }
}