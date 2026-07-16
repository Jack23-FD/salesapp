import 'package:flutter/material.dart';
import '../services/localization_service.dart';

/// A cache for translated strings to improve performance
class TranslationCache {
  static final Map<String, String> _cache = {};
  static String? _currentLanguage;
  static int _lastCacheResetTime = DateTime.now().millisecondsSinceEpoch;

  /// Get a translation from cache or from the service
  static String getTranslation(String key) {
    final currentLocale = LocalizationService.currentLocale;
    final languageCode = currentLocale.languageCode;
    
    // If language changed, clear the cache
    if (_currentLanguage != languageCode) {
      print("TranslationCache: Language changed from $_currentLanguage to $languageCode, clearing cache");
      clear();
      _currentLanguage = languageCode;
    }
    
    // Build cache key that includes the language code
    final cacheKey = "${languageCode}:${key}";
    
    if (_cache.containsKey(cacheKey)) {
      return _cache[cacheKey]!;
    }
    
    final translation = LocalizationService.translate(key);
    _cache[cacheKey] = translation;
    
    // Log cache misses for debugging
    if (key.startsWith('dashboard.')) {
      print("TranslationCache: Cache miss for key '$key' = '$translation' (lang: $languageCode)");
    }
    
    return translation;
  }

  /// Clear the cache (call when language changes)
  static void clear() {
    print("TranslationCache: Clearing all cached translations");
    _cache.clear();
    _lastCacheResetTime = DateTime.now().millisecondsSinceEpoch;
  }
  
  /// Check if cache was recently reset (to avoid duplicate resets)
  static bool wasRecentlyReset() {
    final now = DateTime.now().millisecondsSinceEpoch;
    return (now - _lastCacheResetTime) < 1000; // Less than 1 second ago
  }
}

/// Extension for easy text translation
/// Note: Replaces the existing TranslateX extension
extension TranslationExtensions on String {
  /// Get translated string using the key pattern
  String translate() => TranslationCache.getTranslation(this);
  
  /// Translate with parameter replacement
  /// Usage: 'welcome.user'.trParams({'name': 'John'}) 
  /// where translation has "{name}" placeholder
  String trParams(Map<String, String> params) {
    String translated = translate();
    params.forEach((key, value) {
      translated = translated.replaceAll('{$key}', value);
    });
    return translated;
  }
  
  /// Translate text and capitalize first letter
  String get trCap {
    final translated = translate();
    if (translated.isEmpty) return translated;
    return translated[0].toUpperCase() + translated.substring(1);
  }
}

/// Widget extensions for easy translation
extension TranslationWidgetExtensions on Widget {
  /// Apply translation to Text widgets
  Widget translateWidget() {
    if (this is Text) {
      final text = this as Text;
      if (text.data == null) return text;
      
      return Text(
        text.data!.translate(),
        style: text.style,
        textAlign: text.textAlign,
        overflow: text.overflow,
        maxLines: text.maxLines,
        strutStyle: text.strutStyle,
        textDirection: text.textDirection,
        locale: text.locale,
        softWrap: text.softWrap,
        semanticsLabel: text.semanticsLabel,
        textScaleFactor: text.textScaleFactor,
      );
    }
    return this;
  }
}

/// Helper class for app translations
class AppTranslations {
  /// Translates all Text widgets in a list of widgets
  static List<Widget> translateWidgets(List<Widget> widgets) {
    return widgets.map((widget) {
      if (widget is Text) {
        return widget.translateWidget();
      } else if (widget is AppBar) {
        return _translateAppBar(widget);
      } else if (widget is ElevatedButton) {
        return _translateButton(widget);
      } else if (widget is TextButton) {
        return _translateTextButton(widget);
      } else if (widget is OutlinedButton) {
        return _translateOutlinedButton(widget);
      } else if (widget is ListTile) {
        return _translateListTile(widget);
      }
      return widget;
    }).toList();
  }
  
  /// Translates an AppBar
  static AppBar _translateAppBar(AppBar appBar) {
    Widget? title = appBar.title;
    List<Widget>? actions = appBar.actions;
    
    if (title is Text) {
      title = title.translateWidget();
    }
    
    if (actions != null) {
      actions = translateWidgets(actions);
    }
    
    return AppBar(
      title: title,
      actions: actions,
      backgroundColor: appBar.backgroundColor,
      leading: appBar.leading,
      automaticallyImplyLeading: appBar.automaticallyImplyLeading,
      flexibleSpace: appBar.flexibleSpace,
      bottom: appBar.bottom,
      elevation: appBar.elevation,
      centerTitle: appBar.centerTitle,
    );
  }
  
  /// Translates an ElevatedButton
  static ElevatedButton _translateButton(ElevatedButton button) {
    Widget? child = button.child;
    
    if (child is Text) {
      child = child.translateWidget();
    }
    
    return ElevatedButton(
      onPressed: button.onPressed,
      style: button.style,
      child: child ?? const SizedBox.shrink(),
    );
  }
  
  /// Translates a TextButton
  static TextButton _translateTextButton(TextButton button) {
    Widget? child = button.child;
    
    if (child is Text) {
      child = child.translateWidget();
    }
    
    return TextButton(
      onPressed: button.onPressed,
      style: button.style,
      child: child ?? const SizedBox.shrink(),
    );
  }
  
  /// Translates an OutlinedButton
  static OutlinedButton _translateOutlinedButton(OutlinedButton button) {
    Widget? child = button.child;
    
    if (child is Text) {
      child = child.translateWidget();
    }
    
    return OutlinedButton(
      onPressed: button.onPressed,
      style: button.style,
      child: child ?? const SizedBox.shrink(),
    );
  }
  
  /// Translates a ListTile
  static ListTile _translateListTile(ListTile tile) {
    Widget? title = tile.title;
    Widget? subtitle = tile.subtitle;
    Widget? trailing = tile.trailing;
    
    if (title is Text) {
      title = title.translateWidget();
    }
    
    if (subtitle is Text) {
      subtitle = subtitle.translateWidget();
    }
    
    if (trailing is Text) {
      trailing = trailing.translateWidget();
    }
    
    return ListTile(
      title: title,
      subtitle: subtitle,
      trailing: trailing,
      leading: tile.leading,
      onTap: tile.onTap,
      onLongPress: tile.onLongPress,
      selected: tile.selected,
      enabled: tile.enabled,
      contentPadding: tile.contentPadding,
    );
  }
  
  /// Get a standard snackbar with translated content
  static SnackBar getTranslatedSnackBar(
    String messageKey, {
    Duration duration = const Duration(seconds: 2),
    SnackBarBehavior behavior = SnackBarBehavior.floating,
  }) {
    return SnackBar(
      content: Text(messageKey.translate()),
      duration: duration,
      behavior: behavior,
    );
  }
} 