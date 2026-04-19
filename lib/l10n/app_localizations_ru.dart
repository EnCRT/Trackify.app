// ignore: unused_import
import 'package:intl/intl.dart' as intl;
import 'app_localizations.dart';

// ignore_for_file: type=lint

/// The translations for Russian (`ru`).
class AppLocalizationsRu extends AppLocalizations {
  AppLocalizationsRu([String locale = 'ru']) : super(locale);

  @override
  String helloRider(String name) {
    return 'Привет, $name!';
  }

  @override
  String get rider => 'Райдер';

  @override
  String get yourStats => 'Ваша статистика';

  @override
  String get distance => 'Дистанция';

  @override
  String get time => 'Время';

  @override
  String get avgSpeed => 'Сред. скорость';

  @override
  String get avgTime => 'Сред. время';

  @override
  String get riderInfo => 'Инфо';

  @override
  String daysTracking(int days) {
    return '$days дней трекинга';
  }

  @override
  String get noVehicle => 'Нет транспорта';

  @override
  String get addOneInProfile => 'Добавьте в профиле';

  @override
  String get home => 'Главная';

  @override
  String get feed => 'Лента';

  @override
  String get add => 'Добавить';

  @override
  String get profile => 'Профиль';

  @override
  String get importing => 'Импорт...';

  @override
  String get pleaseAddVehicle => 'Пожалуйста, сначала добавьте ТС в Профиле.';

  @override
  String errorParsingFile(String error) {
    return 'Ошибка парсинга файла: $error';
  }

  @override
  String get sessionDeleted => 'Сессия удалена';

  @override
  String get noSessionsYet => 'Сессий пока нет.';

  @override
  String get addFirstSession => 'Добавьте первую сессию!';

  @override
  String get deleteSession => 'Удалить сессию';

  @override
  String get deleteSessionConfirm =>
      'Вы уверены, что хотите удалить эту сессию? Это действие нельзя отменить.';

  @override
  String get cancel => 'ОТМЕНА';

  @override
  String get delete => 'УДАЛИТЬ';

  @override
  String get unknownTrack => 'Неизвестная трасса';

  @override
  String trackedOn(String date) {
    return 'Дата заезда: $date';
  }

  @override
  String importedOn(String date) {
    return 'Импортировано: $date';
  }

  @override
  String get duration => 'Длительность';

  @override
  String get routePts => 'Точки';

  @override
  String get maxGatesAllowed => 'Максимум 5 линий ворот.';

  @override
  String get sfGate => 'S/F';

  @override
  String sectorGate(int index) {
    return 'S$index';
  }

  @override
  String get tapToDrawSF =>
      'Нажмите 2 точки, чтобы нарисовать ворота Старт/Финиш';

  @override
  String get tapToCompleteGate =>
      'Нажмите вторую точку, чтобы завершить линию ворот';

  @override
  String gatesCount(int count) {
    return '$count ворот • Нажмите, чтобы добавить сектора';
  }

  @override
  String get newRace => 'Новая гонка';

  @override
  String get save => 'Сохранить';

  @override
  String get nameYourRace => 'Назовите вашу гонку';

  @override
  String get undo => 'Отмена';

  @override
  String get sessionNameUpdated => 'Название сессии обновлено';

  @override
  String get enterSessionName => 'Введите название сессии';

  @override
  String get mapAndStats => 'Карта и Статы';

  @override
  String get sectorsAnalysis => 'Анализ секторов';

  @override
  String get allLaps => 'Все круги';

  @override
  String lapIndex(int index) {
    return 'Круг $index';
  }

  @override
  String get sessionSummary => 'Итоги сессии';

  @override
  String get totalTime => 'Всего';

  @override
  String get bestLap => 'Лучший круг';

  @override
  String lapsCompleted(int count) {
    return 'Кругов завершено: $count';
  }

  @override
  String get slow => 'Медленно';

  @override
  String get mid => 'Средне';

  @override
  String get fast => 'Быстро';

  @override
  String get noLapsDetected =>
      'Круги не обнаружены.\nУстановите маркеры Старт/Финиш и Сектора на экране настройки гонки.';

  @override
  String get unknownUser => 'Неизвестный пользователь';

  @override
  String get memberSince => 'В системе с';

  @override
  String get garage => 'Гараж';

  @override
  String get noBrand => 'Без марки';

  @override
  String get welcome => 'Добро пожаловать в MotoLapTimer!';

  @override
  String get setupPrompt =>
      'Давайте настроим ваш профиль и гараж для начала работы.';

  @override
  String get yourProfile => 'Ваш профиль';

  @override
  String get nickname => 'Никнейм';

  @override
  String get required => 'Обязательно';

  @override
  String get firstName => 'Имя';

  @override
  String get lastName => 'Фамилия';

  @override
  String get firstVehicle => 'Первый транспорт';

  @override
  String get brandHint => 'Марка (напр., KTM, Yamaha)';

  @override
  String get modelHint => 'Модель (напр., 250 SX-F, YZ250F)';

  @override
  String get year => 'Год';

  @override
  String get mustBeNumber => 'Должно быть числом';

  @override
  String get saveAndContinue => 'Сохранить и продолжить';

  @override
  String get addVehicle => 'Добавить транспорт';

  @override
  String get sectorAnalysisDeltaMode => 'Дельта vs Лучший круг';

  @override
  String get sectorAnalysisAbsoluteMode => 'Абсолютное время';

  @override
  String get lap => 'Круг';

  @override
  String get lapTime => 'Время круга';

  @override
  String get sector => 'Сектор';

  @override
  String lapShort(Object index) {
    return 'К$index';
  }

  @override
  String get lastRide => 'Последний заезд';

  @override
  String get favorite => 'Избранное';
}
