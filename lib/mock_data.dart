// fake data so the UI has something to show
//  ONLY thing to delete when a real backend arrives
// The lists reference shared Friend objects

import 'models.dart';

List<Friend> createFriends() {
  return <Friend>[
    Friend(
      id: 'f1',
      name: 'Nick Dai',
      description: 'gang from Alcuin.',
      frequencyDays: 7,
      relationship: Relationship.maintaining,
      streak: 5,
      hangoutCount: 12,
      nextReminderInDays: 3,
      history: <HangoutMemory>[
        HangoutMemory(
          id: 'h1',
          title: 'Hawaii',
          date: 'Aug 20',
          note: 'just up to tomfoolery.',
          hasPhoto: true,
          relationshipAtLogTime: Relationship.maintaining,
        ),
        HangoutMemory(
          id: 'h2',
          title: 'gym sesh',
          date: 'Oct 6',
          note: 'We both fell asleep 40 minutes in.',
          relationshipAtLogTime: Relationship.maintaining,
        ),
        HangoutMemory(
          id: 'h3',
          title: 'study session',
          date: 'Sep 22',
          hasPhoto: true,
          relationshipAtLogTime: Relationship.maintaining,
        ),
      ],
    ),
    Friend(
      id: 'f2',
      name: 'Mike Wang',
      description: 'some guy from Ksig in freshman year.',
      frequencyDays: 14,
      streak: 2,
      hangoutCount: 4,
      nextReminderInDays: 9,
      history: <HangoutMemory>[
        HangoutMemory(
          id: 'h4',
          title: 'Bouldering at Rock Spot',
          date: 'Oct 11',
          note: 'got the V4 on the overhang.',
          hasPhoto: true,
        ),
      ],
    ),
    Friend(
      id: 'f3',
      name: 'Feridoon Amini',
      description: 'Met in Texas technically. Old.',
      frequencyDays: 10,
      streak: 4,
      hangoutCount: 6,
      nextReminderInDays: 0,
      history: <HangoutMemory>[
        HangoutMemory(
          id: 'h5',
          title: 'Coffee at George Howell',
          date: 'Oct 14',
        ),
      ],
    ),
    Friend(
      id: 'f4',
      name: 'Cooper Rau',
      description: ' always shows up when i crash the dirt bike.',
      frequencyDays: 30,
      relationship: Relationship.maintaining,
      hangoutCount: 9,
      nextReminderInDays: 21,
    ),
    Friend(
      id: 'f5',
      name: 'Mark Butters',
      description: 'Very competitive at board games.',
      frequencyDays: 14,
      streak: 1,
      hangoutCount: 3,
      nextReminderInDays: 5,
    ),
    Friend(
      id: 'f6',
      name: 'Ryan Vandal',
      description: 'guy with coolest name ever.',
      frequencyDays: 21,
      relationship: Relationship.maintaining,
      streak: 3,
      hangoutCount: 7,
      nextReminderInDays: 12,
    ),
    Friend(
      id: 'f7',
      name: 'Raisa Saoda',
      description: 'Grad. last year. chiller.',
      frequencyDays: 3,
      relationship: Relationship.maintaining,
      streak: 8,
      hangoutCount: 24,
      nextReminderInDays: 0,
      history: <HangoutMemory>[
        HangoutMemory(
          id: 'h6',
          title: 'Taste-test dinner',
          date: 'Oct 20',
          note: 'Lena picked every course. No notes.',
          hasPhoto: true,
          relationshipAtLogTime: Relationship.maintaining,
        ),
      ],
    ),
    Friend(
      id: 'f8',
      name: 'Theo Brink',
      description: 'Gamma Alpha. Funny guy.',
      frequencyDays: 30,
      hangoutCount: 2,
      nextReminderInDays: 26,
    ),
    Friend(
      id: 'f9',
      name: 'Sam Unger',
      description: 'Gym partner. Reliable at 7am, unreachable after 9pm.',
      frequencyDays: 7,
      streak: 2,
      hangoutCount: 5,
      nextReminderInDays: 4,
    ),
    // Two "new contacts" the app added automatically: gray, awaiting setup.
    Friend(id: 'n1', name: 'Autumn Glover', isSetUp: false),
    Friend(id: 'n2', name: 'Henry Ford', isSetUp: false),
  ];
}

List<Reminder> createReminders(List<Friend> friends) {
  return <Reminder>[
    Reminder(
      id: 'r1',
      friend: _byId(friends, 'f7'),
      dueInDays: 0,
      isOutstanding: true,
    ),
    Reminder(
      id: 'r2',
      friend: _byId(friends, 'f3'),
      dueInDays: 0,
      isOutstanding: true,
    ),
    Reminder(id: 'r3', friend: _byId(friends, 'f1'), dueInDays: 3),
    Reminder(id: 'r4', friend: _byId(friends, 'f9'), dueInDays: 4),
    Reminder(id: 'r5', friend: _byId(friends, 'f5'), dueInDays: 5),
    Reminder(id: 'r6', friend: _byId(friends, 'f2'), dueInDays: 9),
  ];
}

List<PlannedHangout> createHangouts(List<Friend> friends) {
  DateTime now = DateTime.now();
  // A hangout a few days out from today, at the given hour.
  DateTime inDays(int days, int hour) =>
      DateTime(now.year, now.month, now.day + days, hour);

  return <PlannedHangout>[
    PlannedHangout(
      id: 'p1',
      friends: <Friend>[_byId(friends, 'f7'), _byId(friends, 'f1')],
      bucket: HangoutBucket.soon,
      when: inDays(1, 19),
      activity: 'Dinner at Tatte',
      note: 'picking the playlist.',
    ),
    PlannedHangout(
      id: 'p2',
      friends: <Friend>[_byId(friends, 'f3')],
      bucket: HangoutBucket.soon,
      when: inDays(3, 11),
      activity: 'Coffee + class notes',
    ),
    PlannedHangout(
      id: 'p3',
      friends: <Friend>[
        _byId(friends, 'f2'),
        _byId(friends, 'f5'),
        _byId(friends, 'f9'),
      ],
      bucket: HangoutBucket.later,
      when: inDays(12, 18),
      activity: 'Climbing + tacos',
      note: 'Group thing.',
    ),
    PlannedHangout(
      id: 'p4',
      friends: <Friend>[_byId(friends, 'f6')],
      bucket: HangoutBucket.later,
      when: inDays(19, 15),
      activity: 'Walk on the Esplanade',
    ),
    // Pending: user replied to the nudge but no time is confirmed yet.
    PlannedHangout(
      id: 'p5',
      friends: <Friend>[_byId(friends, 'f4')],
      bucket: HangoutBucket.pending,
      activity: 'Board game night',
      awaitingReplyFrom: 'Jonah',
    ),
  ];
}

Friend _byId(List<Friend> friends, String id) {
  return friends.firstWhere((Friend f) => f.id == id);
}
