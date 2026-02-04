import 'dart:ui' as ui;

class SystemLocaleInfo {
  final String languageCode;
  final String? scriptCode;
  final String? countryCode;

  const SystemLocaleInfo({
    required this.languageCode,
    this.scriptCode,
    this.countryCode,
  });
}

abstract class SystemLocaleProvider {
  SystemLocaleInfo get currentLocale;
}

class PlatformSystemLocaleProvider implements SystemLocaleProvider {
  const PlatformSystemLocaleProvider();

  @override
  SystemLocaleInfo get currentLocale {
    final locale = ui.PlatformDispatcher.instance.locale;
    return SystemLocaleInfo(
      languageCode: locale.languageCode,
      scriptCode: locale.scriptCode,
      countryCode: locale.countryCode,
    );
  }
}
