// ignore: unused_import
import 'package:intl/intl.dart' as intl;
import 'app_localizations.dart';

// ignore_for_file: type=lint

/// The translations for English (`en`).
class AppLocalizationsEn extends AppLocalizations {
  AppLocalizationsEn([String locale = 'en']) : super(locale);

  @override
  String helloRider(String name) {
    return 'Hello, $name!';
  }

  @override
  String get rider => 'Rider';

  @override
  String get yourStats => 'Your Stats';

  @override
  String get distance => 'Distance';

  @override
  String get time => 'Time';

  @override
  String get avgSpeed => 'Avg Speed';

  @override
  String get avgTime => 'Avg Time';

  @override
  String get riderInfo => 'Rider Info';

  @override
  String daysTracking(int days) {
    return '$days days tracking';
  }

  @override
  String get noVehicle => 'No vehicle';

  @override
  String get addOneInProfile => 'Add one in profile';

  @override
  String get home => 'Home';

  @override
  String get feed => 'Feed';

  @override
  String get add => 'Add';

  @override
  String get profile => 'Profile';

  @override
  String get importing => 'Importing...';

  @override
  String get pleaseAddVehicle => 'Please add a vehicle in Profile first.';

  @override
  String errorParsingFile(String error) {
    return 'Error parsing file: $error';
  }

  @override
  String get sessionDeleted => 'Session deleted';

  @override
  String get noSessionsYet => 'No sessions yet.';

  @override
  String get addFirstSession => 'Add a new session to see it here!';

  @override
  String get deleteSession => 'Delete Session';

  @override
  String get deleteSessionConfirm =>
      'Are you sure you want to delete this session? This action cannot be undone.';

  @override
  String get cancel => 'CANCEL';

  @override
  String get delete => 'DELETE';

  @override
  String get unknownTrack => 'Unknown Track';

  @override
  String trackedOn(String date) {
    return 'Tracked on: $date';
  }

  @override
  String importedOn(String date) {
    return 'Imported on: $date';
  }

  @override
  String get duration => 'Duration';

  @override
  String get routePts => 'Route Pts';

  @override
  String get maxGatesAllowed => 'Maximum 5 gate lines allowed.';

  @override
  String get sfGate => 'S/F';

  @override
  String sectorGate(int index) {
    return 'S$index';
  }

  @override
  String get tapToDrawSF => 'Tap 2 points to draw Start/Finish gate';

  @override
  String get tapToCompleteGate => 'Tap second point to complete the gate line';

  @override
  String gatesCount(int count) {
    return '$count gate(s) • Tap to add sector gates';
  }

  @override
  String get newRace => 'New Race';

  @override
  String get save => 'Save';

  @override
  String get nameYourRace => 'Name your race';

  @override
  String get undo => 'Undo';

  @override
  String get sessionNameUpdated => 'Session name updated';

  @override
  String get enterSessionName => 'Enter session name';

  @override
  String get mapAndStats => 'Map & Stats';

  @override
  String get sectorsAnalysis => 'Sectors Analysis';

  @override
  String get allLaps => 'All Laps';

  @override
  String lapIndex(int index) {
    return 'Lap $index';
  }

  @override
  String get sessionSummary => 'Session Summary';

  @override
  String get totalTime => 'Total Time';

  @override
  String get bestLap => 'Best Lap';

  @override
  String lapsCompleted(int count) {
    return '$count laps completed';
  }

  @override
  String get slow => 'Slow';

  @override
  String get mid => 'Mid';

  @override
  String get fast => 'Fast';

  @override
  String get noLapsDetected =>
      'No laps detected.\nPlace Start/Finish and Sector markers on the race setup screen.';

  @override
  String get unknownUser => 'Unknown User';

  @override
  String get memberSince => 'Member Since';

  @override
  String get garage => 'Garage';

  @override
  String get noBrand => 'No brand';

  @override
  String get welcome => 'Welcome to MotoLapTimer!';

  @override
  String get setupPrompt =>
      'Let\'s set up your profile and garage to get started.';

  @override
  String get yourProfile => 'Your Profile';

  @override
  String get nickname => 'Nickname';

  @override
  String get required => 'Required';

  @override
  String get firstName => 'First Name';

  @override
  String get lastName => 'Last Name';

  @override
  String get firstVehicle => 'First Vehicle';

  @override
  String get brandHint => 'Brand (e.g., KTM, Yamaha)';

  @override
  String get modelHint => 'Model (e.g., 250 SX-F, YZ250F)';

  @override
  String get year => 'Year';

  @override
  String get mustBeNumber => 'Must be a number';

  @override
  String get saveAndContinue => 'Save & Continue';

  @override
  String get addVehicle => 'Add Vehicle';

  @override
  String get sectorAnalysisDeltaMode => 'Delta vs Best Lap (Tap to switch)';

  @override
  String get sectorAnalysisAbsoluteMode => 'Absolute Time (Tap to switch)';

  @override
  String get lap => 'Lap';

  @override
  String get lapTime => 'Lap Time';

  @override
  String get sector => 'Sector';

  @override
  String lapShort(Object index) {
    return 'L$index';
  }

  @override
  String get lastRide => 'Last ride';

  @override
  String get favorite => 'Favorite';
}
