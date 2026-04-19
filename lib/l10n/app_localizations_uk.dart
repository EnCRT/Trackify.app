// ignore: unused_import
import 'package:intl/intl.dart' as intl;
import 'app_localizations.dart';

// ignore_for_file: type=lint

/// The translations for Ukrainian (`uk`).
class AppLocalizationsUk extends AppLocalizations {
  AppLocalizationsUk([String locale = 'uk']) : super(locale);

  @override
  String helloRider(String name) {
    return 'Привіт, $name!';
  }

  @override
  String get rider => 'Райдер';

  @override
  String get yourStats => 'Ваша статистика';

  @override
  String get distance => 'Дистанція';

  @override
  String get time => 'Час';

  @override
  String get avgSpeed => 'Сер. швидкість';

  @override
  String get avgTime => 'Сер. час';

  @override
  String get riderInfo => 'Інфо';

  @override
  String daysTracking(int days) {
    return '$days днів трекінгу';
  }

  @override
  String get noVehicle => 'Немає транспорту';

  @override
  String get addOneInProfile => 'Додайте у профілі';

  @override
  String get home => 'Головна';

  @override
  String get feed => 'Стрічка';

  @override
  String get add => 'Додати';

  @override
  String get profile => 'Профіль';

  @override
  String get importing => 'Імпорт...';

  @override
  String get pleaseAddVehicle => 'Будь ласка, спочатку додайте ТЗ у Профілі.';

  @override
  String errorParsingFile(String error) {
    return 'Помилка парсингу файлу: $error';
  }

  @override
  String get sessionDeleted => 'Сесію видалено';

  @override
  String get allVehicles => 'Всі ТЗ';

  @override
  String get noSessionsYet => 'Сесій поки немає.';

  @override
  String get addFirstSession => 'Додайте першу сесію!';

  @override
  String get deleteSession => 'Видалити сесію';

  @override
  String get deleteSessionConfirm =>
      'Ви впевнені, че хочете видалити цю сесію? Цю дію неможливо скасувати.';

  @override
  String get cancel => 'СКАСУВАТИ';

  @override
  String get delete => 'ВИДАЛИТИ';

  @override
  String get unknownTrack => 'Невідома траса';

  @override
  String trackedOn(String date) {
    return 'Дата заїзду: $date';
  }

  @override
  String importedOn(String date) {
    return 'Імпортовано: $date';
  }

  @override
  String get duration => 'Тривалість';

  @override
  String get routePts => 'Точки';

  @override
  String get maxGatesAllowed => 'Максимум 5 ліній воріт.';

  @override
  String get sfGate => 'S/F';

  @override
  String sectorGate(int index) {
    return 'S$index';
  }

  @override
  String get tapToDrawSF =>
      'Натисніть 2 точки, щоб намалювати ворота Старт/Фініш';

  @override
  String get tapToCompleteGate =>
      'Натисніть другу точку, щоб завершити лінію воріт';

  @override
  String gatesCount(int count) {
    return '$count воріт • Натисніть, щоб додати сектори';
  }

  @override
  String get newRace => 'Нова гонка';

  @override
  String get save => 'Зберегти';

  @override
  String get nameYourRace => 'Назвіть вашу гонку';

  @override
  String get undo => 'Скасувати';

  @override
  String get sessionNameUpdated => 'Назва сесії оновлена';

  @override
  String get enterSessionName => 'Введіть назву сесії';

  @override
  String get mapAndStats => 'Карта та Стати';

  @override
  String get sectorsAnalysis => 'Аналіз секторів';

  @override
  String get allLaps => 'Всі кола';

  @override
  String lapIndex(int index) {
    return 'Коло $index';
  }

  @override
  String get sessionSummary => 'Підсумки сесії';

  @override
  String get totalTime => 'Всього';

  @override
  String get bestLap => 'Найкраще коло';

  @override
  String lapsCompleted(int count) {
    return 'Кіл завершено: $count';
  }

  @override
  String get slow => 'Повільно';

  @override
  String get mid => 'Середньо';

  @override
  String get fast => 'Швидко';

  @override
  String get noLapsDetected =>
      'Кола не виявлені.\nВстановіть маркери Старт/Фініш та Сектори на екрані налаштування гонки.';

  @override
  String get unknownUser => 'Невідомий користувач';

  @override
  String get memberSince => 'У системі з';

  @override
  String get garage => 'Гараж';

  @override
  String get noBrand => 'Без марки';

  @override
  String get welcome => 'Ласкаво просимо до MotoLapTimer!';

  @override
  String get setupPrompt =>
      'Давайте налаштуємо ваш профіль та гараж для початку роботи.';

  @override
  String get yourProfile => 'Ваш профіль';

  @override
  String get nickname => 'Нікнейм';

  @override
  String get required => 'Обов\'язково';

  @override
  String get firstName => 'Ім\'я';

  @override
  String get lastName => 'Прізвище';

  @override
  String get firstVehicle => 'Перший транспорт';

  @override
  String get brandHint => 'Марка (напр., KTM, Yamaha)';

  @override
  String get modelHint => 'Модель (напр., 250 SX-F, YZ250F)';

  @override
  String get year => 'Рік';

  @override
  String get mustBeNumber => 'Має бути числом';

  @override
  String get saveAndContinue => 'Зберегти та продовжити';

  @override
  String get addVehicle => 'Додати транспорт';

  @override
  String get sectorAnalysisDeltaMode => 'Дельта vs Найкраще коло';

  @override
  String get sectorAnalysisAbsoluteMode => 'Абсолютний час';

  @override
  String get lap => 'Коло';

  @override
  String get lapTime => 'Час кола';

  @override
  String get sector => 'Сектор';

  @override
  String lapShort(Object index) {
    return 'К$index';
  }

  @override
  String get lastRide => 'Останній заїзд';

  @override
  String get favorite => 'Обране';
}
