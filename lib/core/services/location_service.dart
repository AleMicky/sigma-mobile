import 'package:geolocator/geolocator.dart';

enum SigmaLocationResult {
  granted,
  serviceDisabled,
  permissionDenied,
  permissionDeniedForever,
  error,
}

class SigmaLocationState {
  final bool serviceEnabled;
  final LocationPermission permission;
  final Position? position;
  final String? errorMessage;

  const SigmaLocationState({
    required this.serviceEnabled,
    required this.permission,
    this.position,
    this.errorMessage,
  });

  bool get isPermissionGranted =>
      permission == LocationPermission.always ||
      permission == LocationPermission.whileInUse;

  bool get isReady => serviceEnabled && isPermissionGranted;

  bool get isDeniedForever => permission == LocationPermission.deniedForever;
}

class LocationService {
  LocationService._();

  static final LocationService instance = LocationService._();

  /// Consulta el estado actual del GPS y los permisos sin lanzar diálogos del sistema.
  Future<SigmaLocationState> checkStatus({bool fetchPosition = false}) async {
    try {
      final serviceEnabled = await Geolocator.isLocationServiceEnabled();
      final permission = await Geolocator.checkPermission();

      Position? currentPosition;
      final granted =
          permission == LocationPermission.always ||
          permission == LocationPermission.whileInUse;

      if (serviceEnabled && granted && fetchPosition) {
        try {
          currentPosition = await Geolocator.getCurrentPosition(
            locationSettings: const LocationSettings(
              accuracy: LocationAccuracy.high,
              timeLimit: Duration(seconds: 10),
            ),
          );
        } catch (_) {
          currentPosition = await Geolocator.getLastKnownPosition();
        }
      }

      return SigmaLocationState(
        serviceEnabled: serviceEnabled,
        permission: permission,
        position: currentPosition,
      );
    } catch (e) {
      return const SigmaLocationState(
        serviceEnabled: false,
        permission: LocationPermission.unableToDetermine,
        errorMessage: 'No se pudo verificar el estado de la geolocalización.',
      );
    }
  }

  /// Solicita activar el servicio de ubicación y los permisos necesarios.
  Future<(SigmaLocationResult, SigmaLocationState)>
  requestLocationActivation() async {
    try {
      final serviceEnabled = await Geolocator.isLocationServiceEnabled();
      if (!serviceEnabled) {
        final state = await checkStatus();
        return (SigmaLocationResult.serviceDisabled, state);
      }

      var permission = await Geolocator.checkPermission();
      if (permission == LocationPermission.denied) {
        permission = await Geolocator.requestPermission();
      }

      if (permission == LocationPermission.deniedForever) {
        final state = await checkStatus();
        return (SigmaLocationResult.permissionDeniedForever, state);
      }

      if (permission == LocationPermission.denied) {
        final state = await checkStatus();
        return (SigmaLocationResult.permissionDenied, state);
      }

      if (permission == LocationPermission.whileInUse ||
          permission == LocationPermission.always) {
        final state = await checkStatus(fetchPosition: true);
        return (SigmaLocationResult.granted, state);
      }

      final state = await checkStatus();
      return (SigmaLocationResult.error, state);
    } catch (_) {
      final state = await checkStatus();
      return (SigmaLocationResult.error, state);
    }
  }

  Future<bool> openLocationSettings() => Geolocator.openLocationSettings();

  Future<bool> openAppSettings() => Geolocator.openAppSettings();
}
