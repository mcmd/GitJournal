import 'package:recase/recase.dart';

import 'package:gitjournal/logger/logger.dart';
import 'analytics.dart';

enum Event {
  NoteAdded,
  NoteUpdated,
  NoteDeleted,
  NoteUndoDeleted,
  NoteRenamed,
  NoteMoved,
  FileRenamed,
  FolderAdded,
  FolderDeleted,
  FolderRenamed,
  FolderConfigUpdated,
  RepoSynced,

  DrawerSetupGitHost,
  DrawerShare,
  DrawerRate,
  DrawerFeedback,
  DrawerBugReport,
  DrawerSettings,

  PurchaseScreenOpen,
  PurchaseScreenClose,
  PurchaseScreenThankYou,

  GitHostSetupError,
  GitHostSetupComplete,
  GitHostSetupGitCloneError,
  GitHostSetupButtonClick,

  Settings,
  FeatureTimelineGithubClicked,

  AppFirstOpen,
  AppUpdate,

  // FIXME: Add os_update

  /*
  Firebase Automatic Events:
    app_update:
      previous_app_version

    first_open
    in_app_purchase
    screen_view
    session_start
    user_engagement
  */
  ScreenView,
  AnalyticsLevelChanged,
  CrashReportingLevelChanged,
}

void logEvent(Event event, {Map<String, String> parameters = const {}}) {
  Analytics.instance?.log(event, parameters);
  Log.d("$event", props: parameters);
}

String eventToString(Event e) {
  var str = e.toString().substring('Event.'.length);
  return ReCase(str).snakeCase;
}
