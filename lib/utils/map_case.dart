/// Very small helper to convert maps from your old camelCase model keys
/// to the new snake_case column names expected by Supabase.
/// Use only if your UI still produces camelCase keys.
class MapCase {
  static Map<String, dynamic> toSnake(Map<String, dynamic> src) {
    final out = <String, dynamic>{};
    src.forEach((k, v) {
      out[_camelToSnake(k)] = v;
    });
    return out;
  }

  static String _camelToSnake(String input) {
    final regex = RegExp(r'(?<=[a-z0-9])[A-Z]');
    return input
        .replaceAllMapped(regex, (m) => '_${m.group(0)!.toLowerCase()}')
        .toLowerCase();
  }
}