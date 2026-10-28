// the single place where all the app's data lives
//   1. AppState holds the lists (friends, hangouts, reminders) and the methods
//      that change them ("schedule this", "log that hangout").
//   2. When something changes it calls notifyListeners(). That is Flutter's way
//      of saying "data changed, screens should redraw".
//   3. AppScope is the widget that hands AppState to every screen. It uses one
//      Flutter built-in (InheritedNotifier) so screens can just write:
//          AppState app = AppScope.of(context);
//      Treat the AppScope class below as fixed boilerplate. You never change it.
// To connect a real backend later: change this file only. The screens call
// app.scheduleHangout(...) etc

import 'package:flutter/material.dart';

import 'mock_data.dart';
import 'models.dart';

class AppState extends ChangeNotifier {
  AppState() {
    friends = createFriends();
    // hangouts and reminders point at the same Friend objects, so a change to
    // one friend is visible everywhere
    hangouts = createHangouts(friends);
    reminders = createReminders(friends);
  }

  late List<Friend> friends;
  late List<PlannedHangout> hangouts;
  late List<Reminder> reminders;

  // New contacts shown gray at the top of the Friends page.
  List<Friend> get unconfiguredFriends {
    return friends.where((Friend f) => !f.isSetUp).toList();
  }

  List<Friend> get configuredFriends {
    return friends.where((Friend f) => f.isSetUp).toList();
  }

  List<Reminder> get outstandingReminders {
    return reminders.where((Reminder r) => r.isOutstanding).toList();
  }

  // Not due reminders, earliest first.
  List<Reminder> get upcomingReminders {
    List<Reminder> result = reminders
        .where((Reminder r) => !r.isOutstanding)
        .toList();
    result.sort((Reminder a, Reminder b) => a.dueInDays.compareTo(b.dueInDays));
    return result;
  }

  List<PlannedHangout> hangoutsInBucket(HangoutBucket bucket) {
    return hangouts.where((PlannedHangout h) => h.bucket == bucket).toList();
  }

  // Every memory across every friend. Each one is a brick in the build.
  List<HangoutMemory> get allMemories {
    List<HangoutMemory> result = <HangoutMemory>[];
    for (Friend f in friends) {
      result.addAll(f.history);
    }
    return result;
  }

  // the only ways data changes should be through the helper functions

  // The user finished setting up a gray new contact.
  void finishSetup(Friend friend) {
    friend.isSetUp = true;
    notifyListeners();
  }

  // Save edits made on the friend page
  // (no real saving needed in a this repo yet, but we still notify so any open screen refreshes)
  void saveFriendChanges() {
    notifyListeners();
  }

  void toggleRelationship(Friend friend) {
    if (friend.relationship == Relationship.building) {
      friend.relationship = Relationship.maintaining;
    } else {
      friend.relationship = Relationship.building;
    }
    notifyListeners();
  }

  // The user pressed Complete in the scheduling sheet.
  void scheduleHangout(PlannedHangout hangout) {
    hangouts.insert(0, hangout);

    // Scheduling with someone answers their nudge, so clear it and push the
    // next reminder out to the friend's normal cadence.
    for (Friend attendee in hangout.friends) {
      for (Reminder r in reminders) {
        if (r.friend.id == attendee.id) {
          r.isOutstanding = false;
          r.dueInDays = attendee.frequencyDays;
        }
      }
    }
    notifyListeners();
  }

  // "Remind me later": void this one, wait for the next scheduled nudge.
  void deferReminder(Reminder reminder) {
    reminder.isOutstanding = false;
    reminder.dueInDays = reminder.friend.frequencyDays;
    notifyListeners();
  }

  // A hangout actually happened. Update counts, streak, next nudge.
  // `memory` is the brick: the app passes it to ONE attendee only, so a
  // three-person hangout adds one brick, not three. Pass null for the others.
  void logHangout(Friend friend, HangoutMemory? memory) {
    if (memory != null) {
      friend.history.insert(0, memory);
    }
    friend.hangoutCount = friend.hangoutCount + 1;
    friend.streak = friend.streak + 1;
    friend.nextReminderInDays = friend.frequencyDays;
    notifyListeners();
  }
}

// The one widget that makes AppState reachable from any screen.
// See the comment at the top of this file for how to use it.
class AppScope extends InheritedNotifier<AppState> {
  const AppScope({super.key, required AppState state, required super.child})
    : super(notifier: state);

  static AppState of(BuildContext context) {
    AppScope scope = context.dependOnInheritedWidgetOfExactType<AppScope>()!;
    return scope.notifier!;
  }
}
