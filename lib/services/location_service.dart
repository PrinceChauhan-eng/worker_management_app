import 'package:geolocator/geolocator.dart';
import 'package:geocoding/geocoding.dart';
import '../utils/logger.dart';

class LocationService {
  static final LocationService _instance = LocationService._internal();
  factory LocationService() => _instance;
  LocationService._internal();

  /// Check if location services are enabled and permissions are granted
  Future<bool> _checkLocationPermissions() async {
    try {
      // Check if location services are enabled
      bool serviceEnabled = await Geolocator.isLocationServiceEnabled();
      if (!serviceEnabled) {
        Logger.info('Location services are disabled.');
        return false;
      }

      // Check location permissions
      LocationPermission permission = await Geolocator.checkPermission();
      if (permission == LocationPermission.denied) {
        permission = await Geolocator.requestPermission();
        if (permission == LocationPermission.denied) {
          Logger.info('Location permissions are denied.');
          return false;
        }
      }

      if (permission == LocationPermission.deniedForever) {
        Logger.info('Location permissions are permanently denied.');
        return false;
      }

      return true;
    } catch (e) {
      Logger.error('Error checking location permissions: $e', e);
      return false;
    }
  }

  /// Get current location (latitude, longitude)
  Future<Map<String, double>?> getCurrentLocation() async {
    try {
      // Check permissions first
      bool hasPermission = await _checkLocationPermissions();
      if (!hasPermission) {
        return null;
      }

      // Get current position
      Position position = await Geolocator.getCurrentPosition(
        desiredAccuracy: LocationAccuracy.high,
      );

      return {
        'latitude': position.latitude,
        'longitude': position.longitude,
      };
    } catch (e) {
      Logger.error('Error getting current location: $e', e);
      return null;
    }
  }

  /// Convert coordinates to address
  Future<String?> getAddressFromCoordinates(double latitude, double longitude) async {
    try {
      List<Placemark> placemarks = await placemarkFromCoordinates(latitude, longitude);
      
      if (placemarks.isNotEmpty) {
        Placemark place = placemarks[0];
        String address = '';
        
        if (place.street != null && place.street!.isNotEmpty) {
          address += '${place.street}, ';
        }
        if (place.subLocality != null && place.subLocality!.isNotEmpty) {
          address += '${place.subLocality}, ';
        }
        if (place.locality != null && place.locality!.isNotEmpty) {
          address += '${place.locality}, ';
        }
        if (place.administrativeArea != null && place.administrativeArea!.isNotEmpty) {
          address += '${place.administrativeArea}';
        }
        
        // Remove trailing comma and space if present
        if (address.endsWith(', ')) {
          address = address.substring(0, address.length - 2);
        }
        
        return address.isNotEmpty ? address : 'Address not found';
      }
      
      return 'Address not found';
    } catch (e) {
      Logger.error('Error getting address from coordinates: $e', e);
      return 'Address not found';
    }
  }

  /// Get current location with address
  Future<Map<String, dynamic>?> getCurrentLocationWithAddress() async {
    try {
      // Get current location
      Map<String, double>? location = await getCurrentLocation();
      if (location == null) {
        return null;
      }

      // Get address from coordinates
      String? address = await getAddressFromCoordinates(
        location['latitude']!,
        location['longitude']!,
      );

      return {
        'latitude': location['latitude'],
        'longitude': location['longitude'],
        'address': address ?? 'Address not found',
      };
    } catch (e) {
      Logger.error('Error getting location with address: $e', e);
      return null;
    }
  }
}