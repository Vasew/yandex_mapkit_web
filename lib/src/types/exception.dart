part of yandex_mapkit_web;

class YandexMapkitException implements Exception {}

abstract class SessionException implements YandexMapkitException {
  final String message;

  SessionException._(this.message);
}
