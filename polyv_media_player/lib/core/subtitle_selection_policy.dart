import 'player_events.dart';
import 'system_locale_provider.dart';

class SubtitleSelectionPolicy {
  const SubtitleSelectionPolicy();

  int selectDefaultSubtitleIndex({
    required List<SubtitleItem> subtitles,
    required SystemLocaleInfo locale,
  }) {
    if (subtitles.isEmpty) return -1;

    final bilingualIndex = subtitles.indexWhere((s) => s.isBilingual);
    if (bilingualIndex >= 0) {
      return bilingualIndex;
    }

    final systemLanguageIndex = findBestLanguageMatchIndex(
      subtitles: subtitles,
      locale: locale,
    );
    if (systemLanguageIndex >= 0) {
      return systemLanguageIndex;
    }

    final defaultIndex = subtitles.indexWhere((s) => s.isDefault);
    if (defaultIndex >= 0) {
      return defaultIndex;
    }

    return 0;
  }

  int findBestLanguageMatchIndex({
    required List<SubtitleItem> subtitles,
    required SystemLocaleInfo locale,
  }) {
    if (subtitles.isEmpty) return -1;

    final systemLanguage = locale.languageCode;
    final systemScript = locale.scriptCode;
    final systemCountry = locale.countryCode;

    final possibleTags = <String>[
      if (systemScript != null && systemCountry != null)
        '$systemLanguage-$systemScript-$systemCountry',
      if (systemScript != null) '$systemLanguage-$systemScript',
      if (systemCountry != null) '$systemLanguage-$systemCountry',
      systemLanguage,
    ];

    for (final tag in possibleTags) {
      final index = subtitles.indexWhere((s) {
        final lang = s.language.toLowerCase();
        return lang == tag.toLowerCase() ||
            lang.startsWith('$tag-') ||
            tag.startsWith('$lang-');
      });
      if (index >= 0) return index;
    }

    for (final tag in possibleTags) {
      final langPrefix = tag.split('-')[0];
      final index = subtitles.indexWhere((s) {
        final lang = s.language.toLowerCase().split('-')[0];
        return lang == langPrefix;
      });
      if (index >= 0) return index;
    }

    return -1;
  }

  String? determineCurrentSubtitleId({
    required bool enabled,
    required String? trackKey,
    required int currentIndex,
    required List<SubtitleItem> subtitles,
  }) {
    if (!enabled) return null;

    if (trackKey != null && trackKey.isNotEmpty) {
      return trackKey;
    }

    if (currentIndex >= 0 && currentIndex < subtitles.length) {
      return subtitles[currentIndex].language;
    }

    return null;
  }
}
