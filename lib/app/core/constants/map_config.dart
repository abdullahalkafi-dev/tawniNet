import 'package:flutter_map/flutter_map.dart';

/// Map tiles. The public OpenStreetMap server is only meant for light use, so a
/// production build points to a commercial tile provider:
///
///   flutter build apk --dart-define=MAP_TILE_URL=https://api.maptiler.com/maps/streets-v2/{z}/{x}/{y}.png?key=YOUR_KEY
///
/// (any `{z}/{x}/{y}` raster URL works). Without it the app uses OpenStreetMap.
class MapConfig {
  MapConfig._();

  static const String tileUrl = String.fromEnvironment(
    'MAP_TILE_URL',
    defaultValue: 'https://tile.openstreetmap.org/{z}/{x}/{y}.png',
  );

  static const String userAgentPackage = 'com.example.awnneaapp';

  static bool get usesPublicOsm => tileUrl.contains('tile.openstreetmap.org');

  /// Tile layer used by every map in the app (tiles are cached on the device).
  static TileLayer tileLayer({required bool dark}) => TileLayer(
        urlTemplate: tileUrl,
        userAgentPackageName: userAgentPackage,
        maxZoom: 19,
        tileBuilder: dark ? darkModeTileBuilder : null,
      );
}
