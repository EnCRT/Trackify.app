# MotoLapTimer — Техническое задание

> **Версия:** 1.0 | **Дата:** 18.04.2026 | **Платформы:** Android, iOS (Flutter)

---

## 1. Общее описание

**MotoLapTimer** — мобильное приложение для мотоциклистов, позволяющее:
- Импортировать GPS-треки заездов (GPX / TXT)
- Визуально разметить старт/финиш и секторные ворота прямо на карте
- Автоматически рассчитать круги и секторы по GPS-данным
- Просматривать спидхетмапу маршрута (скорость → цвет трека)
- Анализировать времена кругов и секторов в удобной таблице
- Вести гараж мотоциклов и профиль пользователя

---

## 2. Технологический стек

| Компонент | Технология |
|---|---|
| Язык | Dart 3.11+ |
| UI-фреймворк | Flutter (Material 3) |
| Управление состоянием | Provider (`ChangeNotifier`) |
| Локальная БД | SQLite via `sqflite` |
| Карты | `flutter_map` + OpenStreetMap tiles |
| GPS-координаты | `latlong2` |
| Парсинг GPX | `xml` |
| Выбор файла | `file_picker` |
| Локализация | Flutter `intl` + ARB-файлы (ru, uk, en) |
| Прочее | `path_provider`, `path`, `intl` |

---

## 3. Архитектура приложения

```
lib/
├── main.dart              — Точка входа, MultiProvider, тема, роутинг
├── models/                — Сущности данных
│   ├── user.dart
│   ├── vehicle.dart
│   ├── session.dart
│   ├── lap.dart           — Также содержит SectorData
│   └── lap_sector.dart    — Отдельная сущность сектора (для lap_sectors таблицы)
├── providers/             — Управление состоянием (ChangeNotifier)
│   ├── user_provider.dart
│   ├── vehicle_provider.dart
│   └── session_provider.dart
├── services/              — Бизнес-логика
│   ├── database_helper.dart     — Singleton SQLite-хелпер (v8)
│   ├── gps_parser_service.dart  — Парсинг GPX и TXT
│   └── lap_calculator_service.dart — Расчёт кругов и секторов
├── screens/               — Экраны приложения
│   ├── onboarding_screen.dart   — Первоначальная настройка
│   ├── root_screen.dart         — Навигация (BottomNavBar)
│   ├── home_screen.dart         — Дашборд / Главная
│   ├── main_feed_screen.dart    — Лента сессий
│   ├── race_creation_screen.dart — Создание заезда (импорт + разметка ворот)
│   ├── session_detail_screen.dart — Детали сессии
│   ├── profile_screen.dart      — Профиль и гараж
│   └── add_vehicle_screen.dart  — Добавление мотоцикла
├── widgets/
│   └── animated_gradient_background.dart — Фон с анимированным градиентом
├── utils/
│   └── time_utils.dart    — Форматирование времени
└── l10n/                  — Локализация (ru, uk, en)
```

### Поток инициализации

```
main() → MultiProvider → MotoLapTimerApp → MainGate
  UserProvider (loadUser) ──┐
  VehicleProvider (loadVehicles) ──┤→ isLoading?
                                   ├─ needsOnboarding → OnboardingScreen
                                   └─ готово → RootScreen
```

---

## 4. Модели данных

### 4.1 User
```dart
id?: int
nickname: String      // уникальный никнейм
firstName: String
lastName: String
joinDate: DateTime
```
**Вычисляемые:** `fullName` = `"$firstName $lastName"`

---

### 4.2 Vehicle
```dart
id?: int
brand: String         // марка (Honda, KTM, ...)
model: String
year: int
isFavorite: bool      // только один может быть favorite (транзакция)
```
**Вычисляемые:** `displayName` = `"$year $brand $model"`

---

### 4.3 Session
```dart
id?: int
vehicleId: int
date: DateTime             // фактическая дата заезда из GPS
importDate: DateTime       // дата сохранения в приложение
locationName: String       // редактируемое название
durationMillis: int        // общая продолжительность
totalDistanceMeters: double
routePoints: List<LatLng>          // даунсемплированные 10Hz GPS-точки
routeSpeeds: List<double>          // скорость km/h для каждой точки
routeTimestamps: List<DateTime>    // реальные GPS-метки времени
laps: List<Lap>                    // расчитанные круги
sectorGates: List<List<LatLng>>    // [pointA, pointB] для каждых ворот
```
**Вычисляемые:** `formattedDuration`

---

### 4.4 Lap + SectorData
```dart
// Lap
number: int
durationMillis: int
startPointIndex: int       // индекс в routePoints начала круга
endPointIndex: int         // индекс в routePoints конца круга
sectors: List<SectorData>

// SectorData
sectorIndex: int
durationMillis: int
crossingPointIndex: int    // индекс пересечения ворот
```

---

### 4.5 LapSector (отдельная таблица — частично используется)
```dart
id?: int
sessionId: int
lapNumber: int
sectorNumber: int    // 0 = полный круг, 1+ = секторы
timeMillis: int
distanceMeters: double
isBest: bool
```

---

## 5. База данных (SQLite v8)

### Схема таблиц

```sql
CREATE TABLE users (
  id INTEGER PRIMARY KEY AUTOINCREMENT,
  nickname TEXT NOT NULL,
  firstName TEXT NOT NULL,
  lastName TEXT NOT NULL,
  joinDate TEXT NOT NULL
);

CREATE TABLE vehicles (
  id INTEGER PRIMARY KEY AUTOINCREMENT,
  brand TEXT NOT NULL,
  model TEXT NOT NULL,
  year INTEGER NOT NULL,
  isFavorite INTEGER NOT NULL DEFAULT 0    -- added in v8
);

CREATE TABLE sessions (
  id INTEGER PRIMARY KEY AUTOINCREMENT,
  vehicleId INTEGER NOT NULL,
  date TEXT NOT NULL,
  locationName TEXT NOT NULL,
  durationMillis INTEGER NOT NULL,
  totalDistanceMeters REAL NOT NULL,
  routePointsJson TEXT NOT NULL,
  routeSpeedsJson TEXT NOT NULL,           -- added in v3
  routeTimestampsJson TEXT NOT NULL DEFAULT '[]',  -- added in v6
  importDate TEXT NOT NULL,                -- added in v4
  lapsJson TEXT NOT NULL DEFAULT '[]',     -- added in v5
  sectorGatesJson TEXT NOT NULL DEFAULT '[]',  -- added in v7
  FOREIGN KEY (vehicleId) REFERENCES vehicles(id) ON DELETE CASCADE
);

CREATE TABLE lap_sectors (
  id INTEGER PRIMARY KEY AUTOINCREMENT,
  sessionId INTEGER NOT NULL,
  lapNumber INTEGER NOT NULL,
  sectorNumber INTEGER NOT NULL,
  timeMillis INTEGER NOT NULL,
  distanceMeters REAL NOT NULL,
  isBest INTEGER NOT NULL DEFAULT 0,
  FOREIGN KEY (sessionId) REFERENCES sessions(id) ON DELETE CASCADE
);
```

> **Замечание:** `lapsJson` и `sectorGatesJson` хранятся как JSON прямо в таблице `sessions`. Таблица `lap_sectors` создана, но **пока не используется** — её данные дублируются в `lapsJson`.

### История миграций
| Версия | Изменение |
|---|---|
| v1 | Базовые таблицы: vehicles, sessions |
| v2 | Добавлена таблица users |
| v3 | `routeSpeedsJson` в sessions |
| v4 | `importDate` в sessions |
| v5 | `lapsJson`, `sectorPointsJson` в sessions |
| v6 | `routeTimestampsJson` в sessions |
| v7 | `sectorGatesJson` в sessions |
| v8 | `isFavorite` в vehicles |

---

## 6. Сервисы

### 6.1 GpsParserService

**Форматы:** `.gpx`, `.txt` (`lat,lng,timestamp_millis`)

**Алгоритм:**
1. Чтение и парсинг файла
2. Даунсемплинг до **10 Гц** (пропуск точек ближе 100мс друг от друга)
3. Вычисление `totalDistance` (сумма расстояний между соседними точками)
4. Вычисление `speed` км/ч для каждого сегмента: `speed = dist/dt`
5. Определение `durationMillis` = разница между первым и последним временем
6. Генерация `locationName` — автоматически из даты (TODO: геокодинг)
7. Возврат объекта `Session` без laps и ворот

---

### 6.2 LapCalculatorService

**Вход:** routePoints, routeSpeeds, sectorGates, routeTimestamps

**Алгоритм:**
1. Приведение `routeTimestamps` → относительные миллисекунды (или реконструкция по скорости)
2. Конвертация ворот `sectorGates` → `GateLine` объекты (линейные сегменты)
3. **Обнаружение пересечений:** итерация по сегментам трека, проверка пересечения с каждыми воротами через параметрическую формулу 2D-векторов
4. **Дебаунс:** пропуск нового пересечения если оно ближе 15м к предыдущему
5. **Интерполяция времени:** точное время пересечения = `t[i] + fraction * (t[i+1] - t[i])`
6. **Группировка в круги:** каждый круг = между двумя последовательными пересечениями ворот #0 (S/F)
7. **Секторы:** отрезки между промежуточными воротами внутри одного круга
8. Возврат `List<Lap>`

**Ограничения:**
- Макс. ворот: 5 (1 S/F + 4 секторных)
- `gateWidthMeters = 30.0` (расчётная ширина ворот)
- `debounceDistanceMeters = 15.0`

---

## 7. Провайдеры (состояние)

### 7.1 UserProvider
| Свойство | Тип | Описание |
|---|---|---|
| `currentUser` | `User?` | Текущий пользователь (единственный) |
| `isLoading` | `bool` | Идёт загрузка из БД |
| `needsProfileOnboarding` | `bool` | `currentUser == null && !isLoading` |

**Методы:** `loadUser()`, `saveUser(User)`

**Обновление:** `saveUser` → `loadUser` → `notifyListeners`

---

### 7.2 VehicleProvider
| Свойство | Тип | Описание |
|---|---|---|
| `vehicles` | `List<Vehicle>` | Все мотоциклы |
| `currentVehicle` | `Vehicle?` | Активный (isFavorite или first) |
| `isLoading` | `bool` | |
| `needsOnboarding` | `bool` | `vehicles.isEmpty && !isLoading` |

**Методы:** `loadVehicles({silent})`, `addVehicle(Vehicle)`, `setFavorite(Vehicle)`, `setCurrentVehicle(Vehicle)`

**Логика favorite:** при `setFavorite` — транзакция: все `isFavorite=0`, затем нужный `isFavorite=1`

**Инициализация:** `loadVehicles()` в конструкторе

---

### 7.3 SessionProvider
| Свойство | Тип | Описание |
|---|---|---|
| `sessions` | `List<Session>` | Сессии текущего транспортного средства |
| `isLoading` | `bool` | |

**Методы:** `loadSessionsForVehicle(vehicleId)`, `addSession(Session)`, `deleteSession(id, vehicleId)`, `updateSession(Session)`

**Логика:** каждая мутация → перезагрузка сессий для текущего vehicle → `notifyListeners`

**Инициализация:** вызывается из `MainFeedScreen.initState()` при первом рендере

---

## 8. Экраны

### 8.1 Onboarding Screen
**Файл:** `onboarding_screen.dart`

**Назначение:** Первый запуск — сбор данных профиля и первого мотоцикла

**UI-состояние:** Stateful, форма с `GlobalKey<FormState>`

**Поля формы:**
| Поле | Тип | Валидация |
|---|---|---|
| Никнейм | TextFormField | обязательное |
| Имя | TextFormField | обязательное |
| Фамилия | TextFormField | обязательное |
| Марка мотоцикла | TextFormField | обязательное |
| Модель | TextFormField | обязательное |
| Год | TextFormField (число) | обязательное, `int.tryParse != null` |

**Логика кнопки «Сохранить и продолжить»:**
1. Валидация формы
2. `UserProvider.saveUser(newUser)` → запись в БД
3. `VehicleProvider.addVehicle(newVehicle)` → запись в БД
4. Provider уведомляет → `MainGate` перестраивается → рендерит `RootScreen`

**Условие показа:** `UserProvider.needsProfileOnboarding || VehicleProvider.needsOnboarding`

**Статус:** ✅ Реализован

---

### 8.2 Root Screen (Навигация)
**Файл:** `root_screen.dart`

**Тип:** StatefulWidget (хранит `_currentIndex`)

**Bottom Navigation Bar — 4 вкладки:**
| Индекс | Иконка | Экран |
|---|---|---|
| 0 | `home` | HomeScreen |
| 1 | `list_alt` | MainFeedScreen |
| 2 | `add_circle` | *Action* — открывает FilePicker |
| 3 | `person` | ProfileScreen |

**Логика вкладки «+» (Import):**
1. Проверка наличия `currentVehicle` (иначе — SnackBar)
2. `FilePicker.platform.pickFiles(allowedExtensions: ['gpx'])`
3. Парсинг → `GpsParserService.parseGpxFile()` или `parseTxtFile()`
4. Навигация в `RaceCreationScreen(parsedSession: ...)`
5. При результате `true` → переключение на вкладку 1 (Feed)

**Дизайн NavBar:** плавающий, полупрозрачный, скруглённый контейнер, иконки без подписей

**Статус:** ✅ Реализован | ⚠️ TXT в `allowedExtensions` не добавлен (только GPX)

---

### 8.3 Home Screen (Дашборд)
**Файл:** `home_screen.dart`

**Тип:** StatelessWidget

**Данные:** `UserProvider`, `VehicleProvider`, `SessionProvider`

**Раздел — Шапка (Header Card):**
- Градиент: deepPurple → deepOrange
- Никнейм пользователя (крупный)
- Имя мотоцикла (`vehicle.displayName`)
- Полное имя пользователя
- Бейдж с датой последнего заезда

**Раздел — Статистика (4 плитки в сетке 2×2):**
| Плитка | Расчёт |
|---|---|
| Дистанция | `SUM(session.totalDistanceMeters) / 1000` km |
| Время | `SUM(session.durationMillis)` (formatDurationConcise) |
| Средняя скорость | `(totalKm / totalHours)` km/h |
| Среднее время | `totalMs / sessionsCount` |

**Логика обновления:** `context.watch<SessionProvider>()` — реактивно при изменении сессий

**Требования (нереализованные):**
- [ ] Кнопка переключения мотоцикла прямо из шапки
- [ ] Отображение рекорда (лучшее время круга) на текущем треке
- [ ] График активности (количество сессий по дням/месяцам)

**Статус:** ✅ Частично реализован

---

### 8.4 Main Feed Screen (Лента сессий)
**Файл:** `main_feed_screen.dart`

**Тип:** StatefulWidget

**Данные:** `SessionProvider`, `VehicleProvider`

**Инициализация:** `initState` → `loadSessionsForVehicle(currentVehicle.id)`

**Состояния экрана:**
- Loading → `CircularProgressIndicator`
- Пусто → иконка + текст "Нет сессий"
- Список → `ListView.builder` с `Dismissible`-карточками

**Карточка сессии (`_buildSessionCard`):**
- Название трека (`locationName`)
- Дата и время заезда (форматировано `DateFormat`)
- Имя мотоцикла (по `vehicleId`)
- Иконка → `SessionDetailScreen`
- 3 стат-колонки: Дистанция | Длительность | Ср. скорость

**Удаление:** swipe left → `Dismissible` → диалог подтверждения → `SessionProvider.deleteSession`

**Требования (нереализованные):**
- [ ] Фильтрация по мотоциклу (если несколько)
- [ ] Поиск по названию трека
- [ ] Сортировка (по дате / лучшему времени)
- [ ] Показ лучшего круга на карточке

**Статус:** ✅ Реализован

---

### 8.5 Race Creation Screen (Создание заезда)
**Файл:** `race_creation_screen.dart`

**Тип:** StatefulWidget

**Входные данные:** `Session parsedSession` (из `GpsParserService`)

**Поля состояния:**
- `_gates: List<List<LatLng>>` — завершённые ворота (макс. 5)
- `_pendingPoint: LatLng?` — первая точка рисуемых ворот
- `_selectedVehicleId: int?`
- `_selectedDate / _selectedTime`

**UI-блок сверху (белый):**
- `TextFormField` — название заезда (предзаполнен из парсера)
- `DropdownButtonFormField` — выбор мотоцикла
- `InkWell` — дата/время (Date+Time Pickers)
- Строка статуса + кнопка «Undo»

**UI-блок карта (`FlutterMap`):**
- Тайлы: OpenStreetMap
- `PolylineLayer` — 2 набора: спидхетмапа + ворота
- `MarkerLayer` — метки ворот (S/F зелёный, секторные оранжевые)
- FAB: очистить ворота, zoom +/-

**Рисование ворот (tap на карту):**
1. Первый тап: `_pendingPoint = point` (синяя точка)
2. Второй тап: `_gates.add([_pendingPoint!, point])` (линия нарисована)
3. Первые ворота (#0) — зелёные (S/F), остальные — оранжевые

**Спидхетмапа:**
- Сглаживание скоростей (moving average, окно 15 точек)
- Нормализация [minSpeed, maxSpeed]
- 4-ступенчатый градиент: красный → оранжевый → жёлтый → зелёный
- Рендер как `Polyline` с `gradientColors`

**Сохранение (кнопка ✓):**
1. `LapCalculatorService.calculateLaps(...)` — расчёт кругов
2. Создание `Session` с `laps` и `sectorGates`
3. `SessionProvider.addSession(session)` → БД
4. `Navigator.pop(true)` → RootScreen переключается на Feed

**Требования (нереализованные):**
- [ ] Отображение текущей скорости при наведении/тапе на трек (tooltip)
- [ ] Кнопка «Показать начало трека» (перейти к первой точке)
- [ ] Автоматическое предложение S/F линии по плотности точек
- [ ] Редактирование имеющихся ворот (drag точки)
- [ ] Загрузка карты в оффлайн-режиме (кеш тайлов)

**Статус:** ✅ Реализован

---

### 8.6 Session Detail Screen (Детали сессии)
**Файл:** `session_detail_screen.dart`

**Тип:** StatefulWidget, `DefaultTabController` (2 вкладки)

**Входные данные:** `Session session`

**AppBar:**
- Название сессии (кликабельно → режим редактирования)
- Кнопки: `edit` / `check`, `delete`
- `TabBar`: «Карта и статистика» | «Анализ секторов»

---

#### Вкладка 1: Карта и статистика

**Блок информации:**
- Имя мотоцикла (deepOrange, крупно)
- Дата и время заезда
- 3 иконки-круга (`_StatCircle`): Дистанция | Время | Лучший круг
- Счётчик кругов

**Переключатель кругов (`_buildLapSelector`):**
- `<` / `>` кнопки, отображает «Все круги» или «Круг N (время)»
- Фильтрует карту по выбранному кругу

**Карта (`_SessionMapWithZoom`):**
- Те же компоненты, что в `RaceCreationScreen`
- Фильтрация routePoints: при `selectedLapIndex > 0` — только точки [lap.startPointIndex, lap.endPointIndex]
- При «Все» — от начала первого до конца последнего круга
- Ворота отображаются поверх трека (markers с метками S/F, S1/S2...)
- FAB zoom +/-
- Легенда скоростей (медленно | средне | быстро)

---

#### Вкладка 2: Анализ секторов (`_SectorAnalysisTable`)

**Режимы (тап по таблице):**
- **Абсолютный** — реальное время каждого сектора
- **Дельта-режим** — отклонение от лучшего круга (+красный / -зелёный)

**Таблица:** `DataTable`
- Адаптивная ориентация (transposed если кругов меньше чем секторов)
- Подсветка лучшего круга (🏆 + amber bg)
- Подсветка лучшего времени в каждом секторе (purple)

**Редактирование названия:**
- Тап на `edit` → inline `TextField` в AppBar
- `check` → `SessionProvider.updateSession(updatedSession)` → SnackBar

**Удаление:**
- Кнопка `delete` → диалог → `SessionProvider.deleteSession` → `Navigator.pop()`

**Требования (нереализованные):**
- [ ] Скоростной граф (линейный chart) Speed vs Time/Distance
- [ ] Оверлей сравнения двух кругов на карте (разными цветами)
- [ ] Экспорт статистики (PDF / Share)
- [ ] Мини-спидометр / прокрутка по треку с анимацией

**Статус:** ✅ Реализован

---

### 8.7 Profile Screen (Профиль)
**Файл:** `profile_screen.dart`

**Тип:** StatelessWidget

**Данные:** `UserProvider`, `VehicleProvider`

**Блок профиля:**
- Аватар (иконка `Icons.person`, радиус 50)
- Полное имя
- Никнейм (`@nickname`)
- Дата регистрации (`joinDate`)

**Секция «Гараж»:**
- Кнопка `+` → `AddVehicleScreen`
- Список всех мотоциклов с `AnimatedContainer`
- Тап на мотоцикл → `VehicleProvider.setFavorite(v)`
- Активный (favorite): выделен фиолетовым, иконка `star`, чекмарк справа
- Неактивные: иконка `two_wheeler`

**Требования (нереализованные):**
- [ ] Обновление профиля (имя, никнейм)
- [ ] Удаление мотоцикла (с подтверждением)
- [ ] Аватар пользователя (фото)
- [ ] Переключение мотоцикла с автоматической перезагрузкой сессий

**Статус:** ✅ Частично реализован

---

### 8.8 Add Vehicle Screen
**Файл:** `add_vehicle_screen.dart`

**Тип:** StatefulWidget, форма

**Поля:** Марка, Модель, Год (валидация: не пустой, год — число)

**Логика:** `VehicleProvider.addVehicle(vehicle)` → `Navigator.pop()`

**Статус:** ✅ Реализован

---

## 9. Локализация

**Поддерживаемые языки:** `ru` (умолчание), `uk`, `en`

**Файлы:** `lib/l10n/app_*.arb` + авто-генерированные `app_localizations_*.dart`

**Использование:** `AppLocalizations.of(context)!.key`

**Требования (нереализованные):**
- [ ] Переключатель языка в настройках
- [ ] Сохранение выбранного языка (SharedPreferences)

---

## 10. Виджеты

### AnimatedGradientBackground
- Обёртка вокруг всего приложения
- Анимированный градиентный фон (deepPurple, deepOrange, blue, green)
- Рендерится за всеми экранами (используется вместо background color Scaffold)

---

## 11. Темизация

Определена в `main.dart`:

| Элемент | Значение |
|---|---|
| Seed color | `Colors.deepPurple` |
| Primary | `Colors.deepPurple` |
| Secondary | `Colors.lightGreen` |
| Background | `Color(0xFFF5F5F5)` |
| AppBar | deepPurple bg, white fg, centered title |
| ElevatedButton | deepPurple, rounded 18px |

---

## 12. Статус реализации

### ✅ Реализовано

- [x] Онбординг (профиль + первый мотоцикл)
- [x] Главный экран с дашбордом статистики
- [x] Лента сессий с удалением через swipe
- [x] Импорт GPX-файла через FilePicker
- [x] Парсинг GPX с даунсемплингом и расчётом скорости
- [x] Интерактивная карта (OpenStreetMap) для рисования ворот
- [x] Рисование линий S/F и секторных ворот (до 5)
- [x] Спидхетмапа маршрута (4-цветный градиент, сглаженная)
- [x] Алгоритм расчёта кругов и секторов (параметрические пересечения + дебаунс)
- [x] Хранение ворот и кругов в JSON внутри таблицы sessions
- [x] Детальный экран сессии: карта, статистика, переключатель кругов
- [x] Анализ секторов: таблица, абсолютный и дельта-режим, адаптивный layout
- [x] Редактирование названия сессии (inline в AppBar)
- [x] Удаление сессии из детального экрана
- [x] Профиль пользователя и гараж мотоциклов
- [x] Добавление мотоциклов
- [x] Выбор избранного мотоцикла
- [x] Локализация (ru, uk, en)
- [x] Мигрирующая схема SQLite (8 версий)
- [x] Парсинг TXT формата (`lat,lng,timestamp_millis`)
- [x] Sidebar/floating навигационная панель

---

### ❌ Не реализовано / Нужно доделать

#### Критически важные

- [ ] **TXT в FilePicker:** в `allowedExtensions` только `['gpx']`, TXT не выбрать через UI
- [ ] **Таблица `lap_sectors` не используется** — данные секторов дублируются в `lapsJson` и в `lap_sectors`. Нужно либо удалить таблицу, либо использовать последовательно
- [ ] **Геокодинг:** `locationName` формируется как `"Заезд YYYY-MM-DD"` — нужен reverse geocoding или ввод вручную при импорте
- [ ] **Переключение мотоцикла в Feed:** при смене `currentVehicle` сессии не перезагружаются автоматически; `loadSessionsForVehicle` вызывается только в `initState`

#### Функциональные улучшения

- [ ] **Редактирование профиля** (имя, никнейм после онбординга)
- [ ] **Удаление мотоцикла** (в ProfileScreen)
- [ ] **Фильтрация/поиск** в ленте сессий
- [ ] **Скоростной граф** Speed vs Distance в деталях сессии
- [ ] **Сравнение кругов** на карте (overlay двух кругов разными цветами)
- [ ] **Экспорт данных** (CSV, PDF, Share)
- [ ] **Автоматическое предложение S/F** ворот (кластеризация точек)
- [ ] **Редактирование ворот** в деталях сессии (drag & drop точек)
- [ ] **Переключатель языка** в настройках
- [ ] **Аватар пользователя**

#### Технический долг

- [ ] **Кеширование тайлов карты** (offline режим через `flutter_map_cache`)
- [ ] **Обработка ошибок** импорта с детальными сообщениями
- [ ] **Loading-состояние** при импорте/парсинге (сейчас нет индикатора)
- [ ] **Unit-тесты** для `LapCalculatorService` и `GpsParserService`
- [ ] **Pagination** в ленте сессий при большом количестве записей
- [ ] **Пересчёт кругов** при редактировании ворот (сейчас ворота хранятся, но пересчёт недоступен)
- [ ] **Фон и анимации:** `animated_gradient_background.dart` требует проверки производительности на слабых устройствах

---

## 13. Зависимости

```yaml
dependencies:
  flutter_localizations: sdk: flutter
  provider: ^6.1.5+1
  sqflite: ^2.4.2
  flutter_map: ^8.2.2
  latlong2: ^0.9.1
  path_provider: ^2.1.5
  xml: ^6.6.1
  file_picker: ^10.3.10
  intl: ^0.20.2
  path: ^1.9.1
```

---

## 14. Команды разработки

```powershell
# Установка зависимостей
flutter pub get

# Запуск в debug (hot reload: r, hot restart: R)
flutter run

# Список доступных эмуляторов
flutter emulators

# Запуск эмулятора
flutter emulators --launch <emulator_id>

# Сборка APK (release)
flutter build apk --release

# Сборка App Bundle (Google Play)
flutter build appbundle

# Диагностика
flutter doctor
```
