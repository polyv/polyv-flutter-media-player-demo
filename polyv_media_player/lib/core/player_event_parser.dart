class ParsedPlayerEvent {
  final String? type;
  final Map<dynamic, dynamic>? data;

  const ParsedPlayerEvent({required this.type, required this.data});
}

class PlayerEventParser {
  const PlayerEventParser();

  ParsedPlayerEvent? tryParse(dynamic event) {
    if (event is! Map) return null;

    return ParsedPlayerEvent(
      type: event['type']?.toString(),
      data: event['data'] as Map<dynamic, dynamic>?,
    );
  }
}
