import 'package:geolocator/geolocator.dart';
import 'api_service.dart';

class LocationService {
  static Stream<Position> getPositionStream() {
    return Geolocator.getPositionStream(
      locationSettings: const LocationSettings(
        accuracy: LocationAccuracy.high,
        distanceFilter: 10, // meters
      ),
    );
  }

  static Future<void> startLiveUpdates(String email) async {
    await Geolocator.requestPermission();
    LocationService.getPositionStream().listen((pos) async {
      print("Location recived");
      await ApiService.updateUserLocation(email, pos.latitude, pos.longitude);
    });
  }
}
