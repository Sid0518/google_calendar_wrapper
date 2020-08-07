import 'package:google_calendar_wrapper/imports.dart';

class DateRangeSlider extends StatefulWidget {
  final RangeValues initialValues;
  final double min;
  final double max;
  final Function onChangedCallback;
  DateRangeSlider({this.initialValues, this.min, this.max, this.onChangedCallback});

  @override
  _DateRangeSliderState createState() => _DateRangeSliderState();
}

class _DateRangeSliderState extends State<DateRangeSlider> {
  RangeValues dateRange;

  @override
  void initState() { 
    super.initState();
    this.dateRange = RangeValues(
      this.widget.initialValues.start,
      this.widget.initialValues.end
    );
  }

  @override
  Widget build(BuildContext context) {
    return Row(
      children: <Widget>[
        Text(this.dateRange.start.round().toString()),

        RangeSlider(
          values: this.dateRange,

          min: this.widget.min,
          max: this.widget.max,
          divisions: (this.widget.max - this.widget.min + 1).round(),

          activeColor: Theme.of(context).primaryColor,

          onChanged: (RangeValues values) => 
            setState(() {
              RangeValues constrainedValues = 
                RangeValues(
                  min(values.start, 0),
                  max(0, values.end)
                );

              this.dateRange = constrainedValues;
              this.widget.onChangedCallback(constrainedValues);
            }),
        ),

        Text(this.dateRange.end.round().abs().toString()),
      ],
    );
  }
}