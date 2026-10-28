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
