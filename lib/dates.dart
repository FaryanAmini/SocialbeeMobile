// helpers to turn DateTime into readable text
// this one just ai but its chill gang i swear
const List<String> weekdayNames = <String>[
  'Mon',
  'Tue',
  'Wed',
  'Thu',
  'Fri',
  'Sat',
  'Sun',
];

const List<String> monthNames = <String>[
  'Jan',
  'Feb',
  'Mar',
  'Apr',
  'May',
  'Jun',
  'Jul',
  'Aug',
  'Sep',
  'Oct',
  'Nov',
  'Dec',
];

// 7:30pm -> "7:30 PM"
String timeLabel(DateTime d) {
  int hour12 = d.hour % 12;
  if (hour12 == 0) {
    hour12 = 12;
  }
  String minutes = d.minute.toString().padLeft(2, '0');
  String suffix = d.hour < 12 ? 'AM' : 'PM';
  return '$hour12:$minutes $suffix';
}

// "Today", "Tomorrow", "Sat" or "Wed Oct 30" depending on distance.
String dayLabel(DateTime d) {
  DateTime now = DateTime.now();
  DateTime today = DateTime(now.year, now.month, now.day);
  DateTime target = DateTime(d.year, d.month, d.day);
  int diff = target.difference(today).inDays;

  if (diff == 0) return 'Today';
  if (diff == 1) return 'Tomorrow';
  if (diff > 1 && diff < 7) return weekdayNames[d.weekday - 1];
  return '${weekdayNames[d.weekday - 1]} ${monthNames[d.month - 1]} ${d.day}';
}

// "Oct 30"
String shortDate(DateTime d) => '${monthNames[d.month - 1]} ${d.day}';

// "Sat, Oct 31"
String dateLabel(DateTime d) =>
    '${weekdayNames[d.weekday - 1]}, ${monthNames[d.month - 1]} ${d.day}';
