import 'package:latlong2/latlong.dart';

class PlaceResult {
  final String name;
  final LatLng location;

  const PlaceResult({required this.name, required this.location});

  factory PlaceResult.fromJson(Map<String, dynamic> json) => PlaceResult(
        name: (json['display_name'] ?? '') as String,
        location: LatLng(
          double.parse(json['lat'] as String),
          double.parse(json['lon'] as String),
        ),
      );
}

class ReversePlace {
  final String address;
  final String? postcode;

  const ReversePlace({required this.address, this.postcode});
}