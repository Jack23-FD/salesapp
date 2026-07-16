import 'package:flutter/material.dart';
import '../utils/translation_utils.dart';

/// A Text widget that automatically translates its content
class TranslatableText extends StatelessWidget {
  /// The text key to be translated
  final String textKey;
  
  /// Style for the text
  final TextStyle? style;
  
  /// Text alignment
  final TextAlign? textAlign;
  
  /// Text overflow behavior
  final TextOverflow? overflow;
  
  /// Maximum number of lines
  final int? maxLines;
  
  /// Parameters for text replacement
  final Map<String, String>? params;
  
  /// Whether to capitalize the first letter
  final bool capitalize;

  const TranslatableText(
    this.textKey, {
    super.key,
    this.style,
    this.textAlign,
    this.overflow,
    this.maxLines,
    this.params,
    this.capitalize = false,
  });

  @override
  Widget build(BuildContext context) {
    String translatedText;
    
    if (params != null && params!.isNotEmpty) {
      translatedText = textKey.trParams(params!);
    } else {
      translatedText = textKey.translate();
    }
    
    if (capitalize && translatedText.isNotEmpty) {
      translatedText = translatedText[0].toUpperCase() + translatedText.substring(1);
    }
    
    return Text(
      translatedText,
      style: style,
      textAlign: textAlign,
      overflow: overflow,
      maxLines: maxLines,
    );
  }
}

/// A widget decorator that translates all Text children
class TranslationWrapper extends StatelessWidget {
  /// The widget to translate
  final Widget child;

  const TranslationWrapper({
    super.key,
    required this.child,
  });

  @override
  Widget build(BuildContext context) {
    return _translateWidget(child);
  }

  Widget _translateWidget(Widget widget) {
    if (widget is Text && widget.data != null) {
      return Text(
        widget.data!.translate(),
        style: widget.style,
        textAlign: widget.textAlign,
        overflow: widget.overflow,
        maxLines: widget.maxLines,
        strutStyle: widget.strutStyle,
        textDirection: widget.textDirection,
        locale: widget.locale,
        softWrap: widget.softWrap,
        semanticsLabel: widget.semanticsLabel,
        textScaleFactor: widget.textScaleFactor,
      );
    } else if (widget is Column || widget is Row || widget is Stack) {
      return _translateMultiChildWidget(widget);
    } else if (widget is Container && widget.child != null) {
      return Container(
        key: widget.key,
        alignment: widget.alignment,
        padding: widget.padding,
        color: widget.color,
        decoration: widget.decoration,
        foregroundDecoration: widget.foregroundDecoration,
        width: widget.constraints?.maxWidth,
        height: widget.constraints?.maxHeight,
        margin: widget.margin,
        transform: widget.transform,
        child: _translateWidget(widget.child!),
      );
    }
    
    return widget;
  }

  Widget _translateMultiChildWidget(Widget widget) {
    if (widget is Column) {
      return Column(
        mainAxisAlignment: widget.mainAxisAlignment,
        crossAxisAlignment: widget.crossAxisAlignment,
        mainAxisSize: widget.mainAxisSize,
        children: widget.children.map(_translateWidget).toList(),
      );
    } else if (widget is Row) {
      return Row(
        mainAxisAlignment: widget.mainAxisAlignment,
        crossAxisAlignment: widget.crossAxisAlignment,
        mainAxisSize: widget.mainAxisSize,
        children: widget.children.map(_translateWidget).toList(),
      );
    } else if (widget is Stack) {
      return Stack(
        alignment: widget.alignment,
        fit: widget.fit,
        children: widget.children.map(_translateWidget).toList(),
      );
    }
    
    return widget;
  }
} 