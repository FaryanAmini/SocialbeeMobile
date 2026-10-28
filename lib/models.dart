// this will host all the structs and classes for the apps data
// ie friends, calendar events, notifications
// in the production version of this application this will be the backend / database
// the rest of this projects code will not change by much

import 'package:flutter/material.dart';

import 'theme.dart';

// friendship status - building or maintaining
enum Relationship { building, maintaining }

//helper functions that will return vals and colours rather than writing
// if/else statements throughout this repo

extension RelationshipInfo on Relationship {
  String get label {
    if (this == Relationship.building) {
      return 'Building';
    }
    return 'Maintaining';
  }

  Color get color {
    if (this == Relationship.building) {
      return AppColors.building;
    }
    return AppColors.maintaining;
  }
}

// creating the friend class
// this will store friend id, name, description
// the users selected frequency
// relationship status
// hangout counts
// next reminder in days
// etc.

class Friend {
  Friend({
    // info that must be filled out on creationCreationLocation
    required this.id,
    required this.name,
    this.description = '',
    this.frequencyDays = 14,
    this.relationship = Relationship.building,
    this.isSetUp = true,
    this.streak = 0,
    this.hangoutCount = 0,
    this.nextReminderInDays = 7,
    List<HangoutMemory>? history,
  }) : history = history ?? <HangoutMemory>[];

  final String id;
  String name;
  String description;
  // how many days inbetween nudge
  int frequencyDays;
  Relationship relationship;
  // false = a new contact the app added automatically; shown gray
  // waiting for the user to set it up
  bool isSetUp;

  int streak;
  int hangoutCount;
  int nextReminderInDays;
  final List<HangoutMemory> history;

  // get initials for the default avatar
  String get initials {
    List<String> parts = name.trim().split(' ');
    if (parts.length == 1) {
      return parts[0].toUpperCase();
    }
    return (parts[0][0] + parts[parts.length - 1][0]).toUpperCase();
  }

  // get first name
  String get shortName => name.split(' ')[0];

  String get frequencyLabel {
    if (frequencyDays <= 1) return 'Every day';
    if (frequencyDays == 7) return 'Once a week';
    if (frequencyDays == 14) return 'Every 2 weeks';
    if (frequencyDays == 30) return 'Once a month';
    return 'Every $frequencyDays days';
  }

  String get countdownLabel {
    if (nextReminderInDays <= 0) return 'Due now';
    if (nextReminderInDays == 1) return 'Tomorrow';
    return 'In $nextReminderInDays days';
  }
}

// previous hangout that has already happened
// each of these becomes one of the lego pieces
// bricks or whatever in the build page

class HangoutMemory {
  HangoutMemory({
    required this.id,
    required this.title,
    required this.date,
    this.note = '',
    this.hasPhoto = false,
    this.relationshipAtLogTime = Relationship.building,
  });
  final String id;
  final String title;
  final String date;
  final String note;
  final bool hasPhoto;
  final Relationship relationshipAtLogTime;
}

// home screen "coming up" states
// is it coming up soon, later, etc
// reminder essentially

enum HangoutBucket { soon, later, pending }

class PlannedHangout {
  PlannedHangout({
    required this.id,
    required this.friends,
    required this.bucket,
    this.when,
    this.activity = '',
    this.note = '',
    this.awaitingReplyFrom = '',
  });

  final String id;
  final List<Friend> friends;
  HangoutBucket bucket;

  // null when the hangout has no confirmed time yet (pending).
  DateTime? when;
  String activity;
  String note;
  String awaitingReplyFrom;

  String get title => activity.isEmpty ? 'Hangout' : activity;

  // get the name of a friend used by whatever page or component wants
  // the name rather than photo or initials
  // used for text on the ui
  String get friendsLabel {
    List<String> names = <String>[];
    for (Friend f in friends) {
      names.add(f.shortName);
    }
    return names.join(', ');
  }
}

// reminder to reach out

class Reminder {
  Reminder({
    required this.id,
    required this.friend,
    required this.dueInDays,
    this.isOutstanding = false,
  });
  final String id;
  final Friend friend;
  int dueInDays;
  bool isOutstanding;
}
