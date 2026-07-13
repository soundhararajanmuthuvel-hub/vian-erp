import 'dart:math' as math;

class GpsAddress {
  final String siteName;
  final String addressLine;
  final String area;
  final String city;
  final String state;
  final String postalCode;
  final String landmark;

  const GpsAddress({
    required this.siteName,
    required this.addressLine,
    required this.area,
    required this.city,
    required this.state,
    required this.postalCode,
    required this.landmark,
  });

  @override
  String toString() {
    return '📍 $siteName\n$addressLine, $area, $city, $state – $postalCode (Near $landmark)';
  }

  String toFormattedMultiLine() {
    return '📍 $siteName\n$addressLine,\n$area,\n$city, $state – $postalCode\n\nNear $landmark';
  }

  String toShortString() {
    return '📍 $siteName (Near $landmark)';
  }
  
  String toAddressOnly() {
    return '$addressLine, $area, $city, $state – $postalCode';
  }
}

class GpsAddressResolver {
  static GpsAddress resolve(double lat, double lng) {
    final dChennai = _calculateDistance(lat, lng, 13.082680, 80.270721);
    final dOMR = _calculateDistance(lat, lng, 12.9716, 80.2437);
    final dGurgaon = _calculateDistance(lat, lng, 28.4595, 77.0266);

    if (dChennai < 5000) {
      return const GpsAddress(
        siteName: 'VIAN Architects Site Office',
        addressLine: 'Plot No. 14, ECR Highway',
        area: 'Neelankarai',
        city: 'Chennai',
        state: 'Tamil Nadu',
        postalCode: '600115',
        landmark: 'VGP Golden Beach',
      );
    } else if (dOMR < 5000) {
      return const GpsAddress(
        siteName: 'Skyline Residency Project Site',
        addressLine: 'OMR Road, Sholinganallur',
        area: 'Sholinganallur',
        city: 'Chennai',
        state: 'Tamil Nadu',
        postalCode: '600119',
        landmark: 'Infosys Campus',
      );
    } else if (dGurgaon < 10000) {
      return const GpsAddress(
        siteName: 'VIAN Architects Corporate HQ',
        addressLine: 'Plot No. 42, Sector 43 Road',
        area: 'Sushant Lok Phase 1',
        city: 'Gurgaon',
        state: 'Haryana',
        postalCode: '122002',
        landmark: 'Gold Souk Mall',
      );
    } else {
      final siteId = ((lat * 100).round() % 50) + 1;
      final isChennaiZone = lat >= 10.0 && lat <= 14.0;
      
      if (isChennaiZone) {
        return GpsAddress(
          siteName: 'VIAN ECR Project Site Office',
          addressLine: 'Plot No. $siteId, East Coast Road',
          area: 'Neelankarai',
          city: 'Chennai',
          state: 'Tamil Nadu',
          postalCode: '600115',
          landmark: 'VGP Golden Beach',
        );
      } else {
        return GpsAddress(
          siteName: 'VIAN North Regional Site Office',
          addressLine: 'Plot No. $siteId, Sector 43 Main Rd',
          area: 'Sushant Lok',
          city: 'Gurgaon',
          state: 'Haryana',
          postalCode: '122002',
          landmark: 'Gold Souk Mall',
        );
      }
    }
  }

  static double _calculateDistance(double lat1, double lng1, double lat2, double lng2) {
    const R = 6371000.0;
    final phi1 = lat1 * math.pi / 180;
    final phi2 = lat2 * math.pi / 180;
    final deltaPhi = (lat2 - lat1) * math.pi / 180;
    final deltaLambda = (lng2 - lng1) * math.pi / 180;

    final a = math.sin(deltaPhi / 2) * math.sin(deltaPhi / 2) +
        math.cos(phi1) * math.cos(phi2) *
            math.sin(deltaLambda / 2) * math.sin(deltaLambda / 2);
    final c = 2 * math.atan2(math.sqrt(a), math.sqrt(1 - a));

    return R * c;
  }
}
