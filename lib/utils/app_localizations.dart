import 'package:flutter/material.dart';
import '../services/localization_service.dart';

class AppLocalizations {
  // Helper method to translate a Text widget
  static Widget translateText(Text text) {
    if (text.data == null) return text;
    
    return Text(
      text.data!.tr,
      style: text.style,
      textAlign: text.textAlign,
      overflow: text.overflow,
      maxLines: text.maxLines,
    );
  }
  
  // Helper to translate a ListTile
  static ListTile translateListTile(ListTile listTile) {
    Widget? title = listTile.title;
    Widget? subtitle = listTile.subtitle;
    
    if (title is Text) {
      title = translateText(title);
    }
    
    if (subtitle is Text) {
      subtitle = translateText(subtitle);
    }
    
    return ListTile(
      title: title,
      subtitle: subtitle,
      leading: listTile.leading,
      trailing: listTile.trailing,
      onTap: listTile.onTap,
      onLongPress: listTile.onLongPress,
      selected: listTile.selected,
      enabled: listTile.enabled,
      contentPadding: listTile.contentPadding,
    );
  }
}

// Extension method to quickly apply translations to common widgets
extension TranslateWidgetX on Widget {
  Widget translate() {
    if (this is Text) {
      return AppLocalizations.translateText(this as Text);
    } else if (this is ListTile) {
      return AppLocalizations.translateListTile(this as ListTile);
    }
    return this;
  }
} 