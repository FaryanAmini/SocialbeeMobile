// this will host all the structs and classes for the apps data
// ie friends, calendar events, notifications
// in the production version of this application this will be the backend / database
// the rest of this projects code will not change by much

import 'dart:developer';

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
}
