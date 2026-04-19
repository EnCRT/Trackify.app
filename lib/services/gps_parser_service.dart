import 'dart:io';
import 'package:latlong2/latlong.dart';
import 'package:xml/xml.dart';
import '../models/session.dart';

class GpsParserService {
  /// Парсит GPX файл и возвращает сырые координаты и время старта/конца.
  /// Поскольку мы не храним сырые временные метки каждой точки в сессии (только LatLng для маршрута),
  /// мы вычисляем общую дистанцию и продолжительность на этапе парсинга.
  Future<Session> parseGpxFile(File file, int vehicleId) async {
    final document = XmlDocument.parse(await file.readAsString());
    final trkpts = document.findAllElements('trkpt');

    if (trkpts.isEmpty) {
      throw Exception('No track points found in GPX file');
    }

    List<LatLng> routePoints = [];
    List<double> routeSpeeds = [];
    DateTime? startTime;
    DateTime? endTime;
    double totalDistance = 0.0;

    LatLng? previousPoint;
    DateTime? previousTime;
    List<DateTime> allTimes = [];

    final distanceHelper = const Distance();

    for (final trkpt in trkpts) {
      final timeStr = trkpt.findElements('time').firstOrNull?.innerText;
      if (timeStr == null) continue;

      final time = DateTime.parse(timeStr);

      // 10Hz Downsampling (minimum 100ms between points)
      // if (previousTime != null &&
      //     time.difference(previousTime).inMilliseconds < 100) {
      //   continue;
      // }

      final lat = double.parse(trkpt.getAttribute('lat')!);
      final lon = double.parse(trkpt.getAttribute('lon')!);
      final currentPoint = LatLng(lat, lon);

      routePoints.add(currentPoint);
      allTimes.add(time);
      endTime = time;

      if (previousPoint != null && previousTime != null) {
        final dist = distanceHelper.as(
          LengthUnit.Meter,
          previousPoint,
          currentPoint,
        );
        totalDistance += dist;

        final deltaMs = time.difference(previousTime).inMilliseconds;
        if (deltaMs > 0) {
          final speedKmh = (dist / 1000.0) / (deltaMs / 3600000.0);
          routeSpeeds.add(speedKmh.isFinite ? speedKmh : 0.0);
        } else {
          routeSpeeds.add(0.0);
        }
      } else {
        routeSpeeds.add(0.0);
      }

      previousTime = time;
      previousPoint = currentPoint;
    }

    if (allTimes.isNotEmpty) {
      allTimes.sort();
      startTime = allTimes.first;
      endTime = allTimes.last;
    } else {
      startTime = DateTime.now();
      endTime = startTime;
    }

    final durationMillis = endTime.difference(startTime).inMilliseconds.abs();

    // TODO: Extract location name properly (e.g. reverse geocoding or file name)
    final mm = startTime.month.toString().padLeft(2, '0');
    final dd = startTime.day.toString().padLeft(2, '0');
    final locationName = "Заезд $mm-$dd";

    return Session(
      vehicleId: vehicleId,
      date: startTime,
      importDate: DateTime.now(),
      locationName: locationName,
      durationMillis: durationMillis,
      totalDistanceMeters: totalDistance,
      routePoints: routePoints,
      routeSpeeds: routeSpeeds,
      routeTimestamps: allTimes,
    );
  }

  /// Парсит простой TXT файл. Формат: lat,lng,timestamp_millis
  Future<Session> parseTxtFile(File file, int vehicleId) async {
    final lines = await file.readAsLines();

    if (lines.isEmpty) {
      throw Exception('TXT file is empty');
    }

    List<LatLng> routePoints = [];
    List<double> routeSpeeds = [];
    DateTime? startTime;
    DateTime? endTime;
    double totalDistance = 0.0;

    LatLng? previousPoint;
    DateTime? previousTime;
    List<DateTime> allTimes = [];
    final distanceHelper = const Distance();

    for (final line in lines) {
      final parts = line.split(',');
      if (parts.length >= 3) {
        final timeMillis = int.tryParse(parts[2]);
        if (timeMillis == null) continue;

        final time = DateTime.fromMillisecondsSinceEpoch(timeMillis);

        // 10Hz Downsampling
        if (previousTime != null &&
            time.difference(previousTime).inMilliseconds < 100) {
          continue;
        }

        final lat = double.tryParse(parts[0]);
        final lon = double.tryParse(parts[1]);

        if (lat != null && lon != null) {
          final currentPoint = LatLng(lat, lon);
          routePoints.add(currentPoint);
          allTimes.add(time);
          endTime = time;

          if (previousPoint != null && previousTime != null) {
            final dist = distanceHelper.as(
              LengthUnit.Meter,
              previousPoint,
              currentPoint,
            );
            totalDistance += dist;

            final deltaMs = time.difference(previousTime).inMilliseconds;
            if (deltaMs > 0) {
              final speedKmh = (dist / 1000.0) / (deltaMs / 3600000.0);
              routeSpeeds.add(speedKmh.isFinite ? speedKmh : 0.0);
            } else {
              routeSpeeds.add(0.0);
            }
          } else {
            routeSpeeds.add(0.0);
          }

          previousPoint = currentPoint;
          previousTime = time;
        }
      }
    }

    if (routePoints.isEmpty) {
      throw Exception('No valid data found in TXT file');
    }

    if (allTimes.isNotEmpty) {
      allTimes.sort();
      startTime = allTimes.first;
      endTime = allTimes.last;
    } else {
      startTime = DateTime.now();
      endTime = startTime;
    }

    final durationMillis = endTime.difference(startTime).inMilliseconds.abs();
    final mm = startTime.month.toString().padLeft(2, '0');
    final dd = startTime.day.toString().padLeft(2, '0');
    final locationName = "Заезд $mm-$dd";

    return Session(
      vehicleId: vehicleId,
      date: startTime,
      importDate: DateTime.now(),
      locationName: locationName,
      durationMillis: durationMillis,
      totalDistanceMeters: totalDistance,
      routePoints: routePoints,
      routeSpeeds: routeSpeeds,
      routeTimestamps: allTimes,
    );
  }
}
