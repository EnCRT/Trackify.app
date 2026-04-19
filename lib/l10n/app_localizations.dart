import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:intl/intl.dart' as intl;

import 'app_localizations_en.dart';
import 'app_localizations_ru.dart';
import 'app_localizations_uk.dart';

// ignore_for_file: type=lint

/// Callers can lookup localized strings with an instance of AppLocalizations
/// returned by `AppLocalizations.of(context)`.
///
/// Applications need to include `AppLocalizations.delegate()` in their app's
/// `localizationDelegates` list, and the locales they support in the app's
/// `supportedLocales` list. For example:
///
/// ```dart
/// import 'l10n/app_localizations.dart';
///
/// return MaterialApp(
///   localizationsDelegates: AppLocalizations.localizationsDelegates,
///   supportedLocales: AppLocalizations.supportedLocales,
///   home: MyApplicationHome(),
/// );
/// ```
///
/// ## Update pubspec.yaml
///
/// Please make sure to update your pubspec.yaml to include the following
/// packages:
///
/// ```yaml
/// dependencies:
///   # Internationalization support.
///   flutter_localizations:
///     sdk: flutter
///   intl: any # Use the pinned version from flutter_localizations
///
///   # Rest of dependencies
/// ```
///
/// ## iOS Applications
///
/// iOS applications define key application metadata, including supported
/// locales, in an Info.plist file that is built into the application bundle.
/// To configure the locales supported by your app, you’ll need to edit this
/// file.
///
/// First, open your project’s ios/Runner.xcworkspace Xcode workspace file.
/// Then, in the Project Navigator, open the Info.plist file under the Runner
/// project’s Runner folder.
///
/// Next, select the Information Property List item, select Add Item from the
/// Editor menu, then select Localizations from the pop-up menu.
///
/// Select and expand the newly-created Localizations item then, for each
/// locale your application supports, add a new item and select the locale
/// you wish to add from the pop-up menu in the Value field. This list should
/// be consistent with the languages listed in the AppLocalizations.supportedLocales
/// property.
abstract class AppLocalizations {
  AppLocalizations(String locale)
    : localeName = intl.Intl.canonicalizedLocale(locale.toString());

  final String localeName;

  static AppLocalizations? of(BuildContext context) {
    return Localizations.of<AppLocalizations>(context, AppLocalizations);
  }

  static const LocalizationsDelegate<AppLocalizations> delegate =
      _AppLocalizationsDelegate();

  /// A list of this localizations delegate along with the default localizations
  /// delegates.
  ///
  /// Returns a list of localizations delegates containing this delegate along with
  /// GlobalMaterialLocalizations.delegate, GlobalCupertinoLocalizations.delegate,
  /// and GlobalWidgetsLocalizations.delegate.
  ///
  /// Additional delegates can be added by appending to this list in
  /// MaterialApp. This list does not have to be used at all if a custom list
  /// of delegates is preferred or required.
  static const List<LocalizationsDelegate<dynamic>> localizationsDelegates =
      <LocalizationsDelegate<dynamic>>[
        delegate,
        GlobalMaterialLocalizations.delegate,
        GlobalCupertinoLocalizations.delegate,
        GlobalWidgetsLocalizations.delegate,
      ];

  /// A list of this localizations delegate's supported locales.
  static const List<Locale> supportedLocales = <Locale>[
    Locale('en'),
    Locale('ru'),
    Locale('uk'),
  ];

  /// No description provided for @helloRider.
  ///
  /// In ru, this message translates to:
  /// **'Привет, {name}!'**
  String helloRider(String name);

  /// No description provided for @rider.
  ///
  /// In ru, this message translates to:
  /// **'Райдер'**
  String get rider;

  /// No description provided for @yourStats.
  ///
  /// In ru, this message translates to:
  /// **'Ваша статистика'**
  String get yourStats;

  /// No description provided for @distance.
  ///
  /// In ru, this message translates to:
  /// **'Дистанция'**
  String get distance;

  /// No description provided for @time.
  ///
  /// In ru, this message translates to:
  /// **'Время'**
  String get time;

  /// No description provided for @avgSpeed.
  ///
  /// In ru, this message translates to:
  /// **'Сред. скорость'**
  String get avgSpeed;

  /// No description provided for @avgTime.
  ///
  /// In ru, this message translates to:
  /// **'Сред. время'**
  String get avgTime;

  /// No description provided for @riderInfo.
  ///
  /// In ru, this message translates to:
  /// **'Инфо'**
  String get riderInfo;

  /// No description provided for @daysTracking.
  ///
  /// In ru, this message translates to:
  /// **'{days} дней трекинга'**
  String daysTracking(int days);

  /// No description provided for @noVehicle.
  ///
  /// In ru, this message translates to:
  /// **'Нет транспорта'**
  String get noVehicle;

  /// No description provided for @addOneInProfile.
  ///
  /// In ru, this message translates to:
  /// **'Добавьте в профиле'**
  String get addOneInProfile;

  /// No description provided for @home.
  ///
  /// In ru, this message translates to:
  /// **'Главная'**
  String get home;

  /// No description provided for @feed.
  ///
  /// In ru, this message translates to:
  /// **'Лента'**
  String get feed;

  /// No description provided for @add.
  ///
  /// In ru, this message translates to:
  /// **'Добавить'**
  String get add;

  /// No description provided for @profile.
  ///
  /// In ru, this message translates to:
  /// **'Профиль'**
  String get profile;

  /// No description provided for @importing.
  ///
  /// In ru, this message translates to:
  /// **'Импорт...'**
  String get importing;

  /// No description provided for @pleaseAddVehicle.
  ///
  /// In ru, this message translates to:
  /// **'Пожалуйста, сначала добавьте ТС в Профиле.'**
  String get pleaseAddVehicle;

  /// No description provided for @errorParsingFile.
  ///
  /// In ru, this message translates to:
  /// **'Ошибка парсинга файла: {error}'**
  String errorParsingFile(String error);

  /// No description provided for @sessionDeleted.
  ///
  /// In ru, this message translates to:
  /// **'Сессия удалена'**
  String get sessionDeleted;

  /// No description provided for @noSessionsYet.
  ///
  /// In ru, this message translates to:
  /// **'Сессий пока нет.'**
  String get noSessionsYet;

  /// No description provided for @addFirstSession.
  ///
  /// In ru, this message translates to:
  /// **'Добавьте первую сессию!'**
  String get addFirstSession;

  /// No description provided for @deleteSession.
  ///
  /// In ru, this message translates to:
  /// **'Удалить сессию'**
  String get deleteSession;

  /// No description provided for @deleteSessionConfirm.
  ///
  /// In ru, this message translates to:
  /// **'Вы уверены, что хотите удалить эту сессию? Это действие нельзя отменить.'**
  String get deleteSessionConfirm;

  /// No description provided for @cancel.
  ///
  /// In ru, this message translates to:
  /// **'ОТМЕНА'**
  String get cancel;

  /// No description provided for @delete.
  ///
  /// In ru, this message translates to:
  /// **'УДАЛИТЬ'**
  String get delete;

  /// No description provided for @unknownTrack.
  ///
  /// In ru, this message translates to:
  /// **'Неизвестная трасса'**
  String get unknownTrack;

  /// No description provided for @trackedOn.
  ///
  /// In ru, this message translates to:
  /// **'Дата заезда: {date}'**
  String trackedOn(String date);

  /// No description provided for @importedOn.
  ///
  /// In ru, this message translates to:
  /// **'Импортировано: {date}'**
  String importedOn(String date);

  /// No description provided for @duration.
  ///
  /// In ru, this message translates to:
  /// **'Длительность'**
  String get duration;

  /// No description provided for @routePts.
  ///
  /// In ru, this message translates to:
  /// **'Точки'**
  String get routePts;

  /// No description provided for @maxGatesAllowed.
  ///
  /// In ru, this message translates to:
  /// **'Максимум 5 линий ворот.'**
  String get maxGatesAllowed;

  /// No description provided for @sfGate.
  ///
  /// In ru, this message translates to:
  /// **'S/F'**
  String get sfGate;

  /// No description provided for @sectorGate.
  ///
  /// In ru, this message translates to:
  /// **'S{index}'**
  String sectorGate(int index);

  /// No description provided for @tapToDrawSF.
  ///
  /// In ru, this message translates to:
  /// **'Нажмите 2 точки, чтобы нарисовать ворота Старт/Финиш'**
  String get tapToDrawSF;

  /// No description provided for @tapToCompleteGate.
  ///
  /// In ru, this message translates to:
  /// **'Нажмите вторую точку, чтобы завершить линию ворот'**
  String get tapToCompleteGate;

  /// No description provided for @gatesCount.
  ///
  /// In ru, this message translates to:
  /// **'{count} ворот • Нажмите, чтобы добавить сектора'**
  String gatesCount(int count);

  /// No description provided for @newRace.
  ///
  /// In ru, this message translates to:
  /// **'Новая гонка'**
  String get newRace;

  /// No description provided for @save.
  ///
  /// In ru, this message translates to:
  /// **'Сохранить'**
  String get save;

  /// No description provided for @nameYourRace.
  ///
  /// In ru, this message translates to:
  /// **'Назовите вашу гонку'**
  String get nameYourRace;

  /// No description provided for @undo.
  ///
  /// In ru, this message translates to:
  /// **'Отмена'**
  String get undo;

  /// No description provided for @sessionNameUpdated.
  ///
  /// In ru, this message translates to:
  /// **'Название сессии обновлено'**
  String get sessionNameUpdated;

  /// No description provided for @enterSessionName.
  ///
  /// In ru, this message translates to:
  /// **'Введите название сессии'**
  String get enterSessionName;

  /// No description provided for @mapAndStats.
  ///
  /// In ru, this message translates to:
  /// **'Карта и Статы'**
  String get mapAndStats;

  /// No description provided for @sectorsAnalysis.
  ///
  /// In ru, this message translates to:
  /// **'Анализ секторов'**
  String get sectorsAnalysis;

  /// No description provided for @allLaps.
  ///
  /// In ru, this message translates to:
  /// **'Все круги'**
  String get allLaps;

  /// No description provided for @lapIndex.
  ///
  /// In ru, this message translates to:
  /// **'Круг {index}'**
  String lapIndex(int index);

  /// No description provided for @sessionSummary.
  ///
  /// In ru, this message translates to:
  /// **'Итоги сессии'**
  String get sessionSummary;

  /// No description provided for @totalTime.
  ///
  /// In ru, this message translates to:
  /// **'Всего'**
  String get totalTime;

  /// No description provided for @bestLap.
  ///
  /// In ru, this message translates to:
  /// **'Лучший круг'**
  String get bestLap;

  /// No description provided for @lapsCompleted.
  ///
  /// In ru, this message translates to:
  /// **'Кругов завершено: {count}'**
  String lapsCompleted(int count);

  /// No description provided for @slow.
  ///
  /// In ru, this message translates to:
  /// **'Медленно'**
  String get slow;

  /// No description provided for @mid.
  ///
  /// In ru, this message translates to:
  /// **'Средне'**
  String get mid;

  /// No description provided for @fast.
  ///
  /// In ru, this message translates to:
  /// **'Быстро'**
  String get fast;

  /// No description provided for @noLapsDetected.
  ///
  /// In ru, this message translates to:
  /// **'Круги не обнаружены.\nУстановите маркеры Старт/Финиш и Сектора на экране настройки гонки.'**
  String get noLapsDetected;

  /// No description provided for @unknownUser.
  ///
  /// In ru, this message translates to:
  /// **'Неизвестный пользователь'**
  String get unknownUser;

  /// No description provided for @memberSince.
  ///
  /// In ru, this message translates to:
  /// **'В системе с'**
  String get memberSince;

  /// No description provided for @garage.
  ///
  /// In ru, this message translates to:
  /// **'Гараж'**
  String get garage;

  /// No description provided for @noBrand.
  ///
  /// In ru, this message translates to:
  /// **'Без марки'**
  String get noBrand;

  /// No description provided for @welcome.
  ///
  /// In ru, this message translates to:
  /// **'Добро пожаловать в MotoLapTimer!'**
  String get welcome;

  /// No description provided for @setupPrompt.
  ///
  /// In ru, this message translates to:
  /// **'Давайте настроим ваш профиль и гараж для начала работы.'**
  String get setupPrompt;

  /// No description provided for @yourProfile.
  ///
  /// In ru, this message translates to:
  /// **'Ваш профиль'**
  String get yourProfile;

  /// No description provided for @nickname.
  ///
  /// In ru, this message translates to:
  /// **'Никнейм'**
  String get nickname;

  /// No description provided for @required.
  ///
  /// In ru, this message translates to:
  /// **'Обязательно'**
  String get required;

  /// No description provided for @firstName.
  ///
  /// In ru, this message translates to:
  /// **'Имя'**
  String get firstName;

  /// No description provided for @lastName.
  ///
  /// In ru, this message translates to:
  /// **'Фамилия'**
  String get lastName;

  /// No description provided for @firstVehicle.
  ///
  /// In ru, this message translates to:
  /// **'Первый транспорт'**
  String get firstVehicle;

  /// No description provided for @brandHint.
  ///
  /// In ru, this message translates to:
  /// **'Марка (напр., KTM, Yamaha)'**
  String get brandHint;

  /// No description provided for @modelHint.
  ///
  /// In ru, this message translates to:
  /// **'Модель (напр., 250 SX-F, YZ250F)'**
  String get modelHint;

  /// No description provided for @year.
  ///
  /// In ru, this message translates to:
  /// **'Год'**
  String get year;

  /// No description provided for @mustBeNumber.
  ///
  /// In ru, this message translates to:
  /// **'Должно быть числом'**
  String get mustBeNumber;

  /// No description provided for @saveAndContinue.
  ///
  /// In ru, this message translates to:
  /// **'Сохранить и продолжить'**
  String get saveAndContinue;

  /// No description provided for @addVehicle.
  ///
  /// In ru, this message translates to:
  /// **'Добавить транспорт'**
  String get addVehicle;

  /// No description provided for @sectorAnalysisDeltaMode.
  ///
  /// In ru, this message translates to:
  /// **'Дельта vs Лучший круг'**
  String get sectorAnalysisDeltaMode;

  /// No description provided for @sectorAnalysisAbsoluteMode.
  ///
  /// In ru, this message translates to:
  /// **'Абсолютное время'**
  String get sectorAnalysisAbsoluteMode;

  /// No description provided for @lap.
  ///
  /// In ru, this message translates to:
  /// **'Круг'**
  String get lap;

  /// No description provided for @lapTime.
  ///
  /// In ru, this message translates to:
  /// **'Время круга'**
  String get lapTime;

  /// No description provided for @sector.
  ///
  /// In ru, this message translates to:
  /// **'Сектор'**
  String get sector;

  /// No description provided for @lapShort.
  ///
  /// In ru, this message translates to:
  /// **'К{index}'**
  String lapShort(Object index);

  /// No description provided for @lastRide.
  ///
  /// In ru, this message translates to:
  /// **'Последний заезд'**
  String get lastRide;

  /// No description provided for @favorite.
  ///
  /// In ru, this message translates to:
  /// **'Избранное'**
  String get favorite;
}

class _AppLocalizationsDelegate
    extends LocalizationsDelegate<AppLocalizations> {
  const _AppLocalizationsDelegate();

  @override
  Future<AppLocalizations> load(Locale locale) {
    return SynchronousFuture<AppLocalizations>(lookupAppLocalizations(locale));
  }

  @override
  bool isSupported(Locale locale) =>
      <String>['en', 'ru', 'uk'].contains(locale.languageCode);

  @override
  bool shouldReload(_AppLocalizationsDelegate old) => false;
}

AppLocalizations lookupAppLocalizations(Locale locale) {
  // Lookup logic when only language code is specified.
  switch (locale.languageCode) {
    case 'en':
      return AppLocalizationsEn();
    case 'ru':
      return AppLocalizationsRu();
    case 'uk':
      return AppLocalizationsUk();
  }

  throw FlutterError(
    'AppLocalizations.delegate failed to load unsupported locale "$locale". This is likely '
    'an issue with the localizations generation tool. Please file an issue '
    'on GitHub with a reproducible sample app and the gen-l10n configuration '
    'that was used.',
  );
}
