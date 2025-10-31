import 'dart:math';
import 'package:geolocator/geolocator.dart';
import 'package:geocoding/geocoding.dart';
import 'package:permission_handler/permission_handler.dart';

class LocationService {
  // Check if location services are enabled
  static Future<bool> isLocationServiceEnabled() async {
    return await Geolocator.isLocationServiceEnabled();
  }

  // Request location permission
  static Future<bool> requestLocationPermission() async {
    var status = await Permission.location.status;
    
    if (status.isDenied) {
      status = await Permission.location.request();
    }
    
    if (status.isPermanentlyDenied) {
      // Open app settings
      await openAppSettings();
      return false;
    }
    
    return status.isGranted;
  }

  // Get current location
  static Future<Position?> getCurrentLocation() async {
    try {
      // Check if location service is enabled
      bool serviceEnabled = await isLocationServiceEnabled();
      if (!serviceEnabled) {
        print('Location services are disabled');
        return null;
      }

      // Request permission
      bool permissionGranted = await requestLocationPermission();
      if (!permissionGranted) {
        print('Location permission denied');
        return null;
      }

      // Get current position
      Position position = await Geolocator.getCurrentPosition(
        desiredAccuracy: LocationAccuracy.high,
      );
      
      print('Current position: ${position.latitude}, ${position.longitude}');
      return position;
    } catch (e) {
      print('Error getting current location: $e');
      return null;
    }
  }

  // Get address from coordinates
  static Future<String?> getAddressFromCoordinates(
    double latitude,
    double longitude,
  ) async {
    try {
      List<Placemark> placemarks = await placemarkFromCoordinates(
        latitude,
        longitude,
      );
      
      if (placemarks.isNotEmpty) {
        Placemark place = placemarks.first;
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
          address += '${place.administrativeArea}, ';
        }
        if (place.postalCode != null && place.postalCode!.isNotEmpty) {
          address += place.postalCode!;
        }
        
        return address.isNotEmpty ? address : 'Unknown Location';
      }
      
      return 'Unknown Location';
    } catch (e) {
      print('Error getting address from coordinates: $e');
      return 'Unknown Location';
    }
  }

  // Calculate distance between two coordinates using Haversine formula
  // Returns distance in meters
  static double calculateDistance(
    double lat1,
    double lon1,
    double lat2,
    double lon2,
  ) {
    const double earthRadius = 6371000; // Earth radius in meters
    
    double dLat = _toRadians(lat2 - lat1);
    double dLon = _toRadians(lon2 - lon1);
    
    double a = sin(dLat / 2) * sin(dLat / 2) +
        cos(_toRadians(lat1)) * cos(_toRadians(lat2)) *
        sin(dLon / 2) * sin(dLon / 2);
    
    double c = 2 * atan2(sqrt(a), sqrt(1 - a));
    
    double distance = earthRadius * c;
    
    print('Distance calculated: $distance meters');
    return distance;
  }

  // Convert degrees to radians
  static double _toRadians(double degrees) {
    return degrees * pi / 180;
  }

  // Check if current location is within allowed radius of work location
  static Future<Map<String, dynamic>> verifyLocation(
    double workLat,
    double workLon,
    double allowedRadius,
  ) async {
    try {
      Position? currentPosition = await getCurrentLocation();
      
      if (currentPosition == null) {
        return {
          'success': false,
          'message': 'Unable to get current location',
          'distance': null,
          'latitude': null,
          'longitude': null,
          'address': null,
        };
      }

      double distance = calculateDistance(
        workLat,
        workLon,
        currentPosition.latitude,
        currentPosition.longitude,
      );

      String? address = await getAddressFromCoordinates(
        currentPosition.latitude,
        currentPosition.longitude,
      );

      bool isWithinRange = distance <= allowedRadius;

      return {
        'success': isWithinRange,
        'message': isWithinRange
            ? 'Location verified successfully'
            : 'You are ${distance.toStringAsFixed(0)}m away from work location. Must be within ${allowedRadius.toStringAsFixed(0)}m',
        'distance': distance,
        'latitude': currentPosition.latitude,
        'longitude': currentPosition.longitude,
        'address': address,
      };
    } catch (e) {
      print('Error verifying location: $e');
      return {
        'success': false,
        'message': 'Error verifying location: $e',
        'distance': null,
        'latitude': null,
        'longitude': null,
        'address': null,
      };
    }
  }

  // Format distance for display
  static String formatDistance(double meters) {
    if (meters < 1000) {
      return '${meters.toStringAsFixed(0)} m';
    } else {
      return '${(meters / 1000).toStringAsFixed(2)} km';
    }
  }
}
