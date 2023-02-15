import 'dart:async';
import 'dart:collection';
import 'dart:ui';

import 'package:flash/flash.dart';
import 'package:flutter/material.dart';

/// Wrap a widget with [Overlay].
Widget wrapWithOverlay({
  required WidgetBuilder builder,
  Clip clipBehavior = Clip.hardEdge,
}) {
  return Overlay(
    initialEntries: [OverlayEntry(builder: builder)],
    clipBehavior: clipBehavior,
  );
}

/// A widget provide the function of emit message.
class Toast extends StatefulWidget {
  /// The widget below this widget in the tree.
  final Widget child;

  /// A key to use when building the [Navigator].
  final GlobalKey<NavigatorState> navigatorKey;

  /// How to align the toast.
  final Alignment alignment;

  /// Adds a custom margin to toast.
  final EdgeInsets margin;

  /// Adds a radius to all corners of toast..
  final BorderRadius borderRadius;

  /// Style for the text message.
  final TextStyle textStyle;

  /// The amount of space to surround the message with.
  final EdgeInsets padding;

  /// Creates a toast to emit message.
  const Toast({
    Key? key,
    required this.child,
    required this.navigatorKey,
    this.alignment = const Alignment(0, 0.5),
    this.margin = const EdgeInsets.symmetric(horizontal: 16.0, vertical: 8.0),
    this.borderRadius = const BorderRadius.all(Radius.circular(8.0)),
    this.textStyle = const TextStyle(fontSize: 16.0, color: Colors.white),
    this.padding = const EdgeInsets.symmetric(horizontal: 16.0, vertical: 8.0),
  }) : super(key: key);

  /// Emit a message for the specified duration.
  static Future<T?> show<T>(
    BuildContext context,
    Object message, {
    Duration duration = const Duration(seconds: 3),
    Alignment? alignment,
    EdgeInsets? margin,
    BorderRadius? borderRadius,
    Color? backgroundColor,
    TextStyle? textStyle,
    EdgeInsets? padding,
  }) {
    return context.findAncestorStateOfType<_ToastState>()!.show(message,
        duration: duration,
        alignment: alignment,
        margin: margin,
        borderRadius: borderRadius,
        backgroundColor: backgroundColor,
        textStyle: textStyle,
        padding: padding);
  }

  @override
  State<Toast> createState() => _ToastState();
}

class _ToastState extends State<Toast> {
  final messageQueue = Queue<_MessageItem>();
  final initialized = Completer();
  Completer? messageCompleter;

  @override
  void dispose() {
    messageQueue.clear();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    if (!initialized.isCompleted) initialized.complete();
    return widget.child;
  }

  Future<T?> show<T>(
    Object message, {
    Duration duration = const Duration(seconds: 3),
    Alignment? alignment,
    EdgeInsets? margin,
    BorderRadius? borderRadius,
    Color? backgroundColor,
    TextStyle? textStyle,
    EdgeInsets? padding,
  }) async {
    // Wait initialized.
    await initialized.future;

    final context = widget.navigatorKey.currentContext!;

    // Wait previous toast dismissed.
    if (messageCompleter?.isCompleted == false) {
      final item =
          _MessageItem<T>(message, duration, alignment, margin, borderRadius, backgroundColor, textStyle, padding);
      messageQueue.add(item);
      return await item.completer.future;
    }

    messageCompleter = Completer();

    Future<T?> showToast(
        Object message, Duration duration, alignment, margin, borderRadius, backgroundColor, textStyle, padding) {
      return showFlash<T>(
        context: context,
        builder: (context, controller) {
          final Widget child;
          if (message is WidgetBuilder) {
            child = message(context);
          } else if (message is Widget) {
            child = message;
          } else {
            child = Text(message.toString());
          }
          return Flash<T>(
            controller: controller,
            alignment: alignment ?? widget.alignment,
            margin: margin ?? widget.margin,
            borderRadius: borderRadius ?? widget.borderRadius,
            backgroundColor: backgroundColor ?? Colors.black87,
            child: Padding(
              padding: padding ?? widget.padding,
              child: DefaultTextStyle(
                style: textStyle ?? widget.textStyle,
                child: child,
              ),
            ),
          );
        },
        duration: duration,
      ).whenComplete(() {
        if (messageQueue.isNotEmpty) {
          final item = messageQueue.removeFirst();
          item.completer.complete(showToast(item.message, item.duration, item.alignment, item.margin, item.borderRadius,
              item.backgroundColor, item.textStyle, item.padding));
        } else {
          messageCompleter?.complete();
        }
      });
    }

    return showToast(message, duration, alignment, margin, borderRadius, backgroundColor, textStyle, padding);
  }
}

class _MessageItem<T> {
  final Object message;
  final Duration duration;
  final Alignment? alignment;
  final EdgeInsets? margin;
  final BorderRadius? borderRadius;
  final Color? backgroundColor;
  final TextStyle? textStyle;
  final EdgeInsets? padding;
  final Completer<T?> completer;

  _MessageItem(this.message, this.duration, this.alignment, this.margin, this.borderRadius, this.backgroundColor,
      this.textStyle, this.padding)
      : completer = Completer<T?>();
}

/// Context extension for flash toast.
extension ToastShortcuts on BuildContext {
  /// Emit a message for the specified duration.
  Future<T?> showToast<T>(
    Object message, {
    Duration duration = const Duration(seconds: 3),
    Alignment? alignment,
    EdgeInsets? margin,
    BorderRadius? borderRadius,
    Color? backgroundColor,
    TextStyle? textStyle,
    EdgeInsets? padding,
  }) {
    assert(message is String || message is Widget || message is WidgetBuilder);
    return Toast.show(this, message,
        duration: duration,
        alignment: alignment,
        margin: margin,
        borderRadius: borderRadius,
        backgroundColor: backgroundColor,
        textStyle: textStyle,
        padding: padding);
  }
}

/// Context extension for flash bar.
extension FlashBarShortcuts on BuildContext {
  /// Show a custom flash bar.
  Future<T?> showFlashBar<T>({
    FlashBarType? barType,
    bool persistent = true,
    Duration? duration,
    Duration? transitionDuration,
    bool? enableVerticalDrag,
    List<HorizontalDismissDirection>? horizontalDismissDirections,
    FlashBehavior? behavior,
    FlashPosition? position,
    Brightness? brightness,
    Color? backgroundColor,
    TextStyle? titleStyle,
    TextStyle? contentStyle,
    Color? actionColor,
    Gradient? backgroundGradient,
    List<BoxShadow>? boxShadows,
    Color? barrierColor,
    ImageFilter? barrierFilter,
    bool? barrierDismissible,
    BorderRadius? borderRadius,
    Color? borderColor,
    double? borderWidth,
    EdgeInsets? margin,
    Duration? insetAnimationDuration,
    Curve? insetAnimationCurve,
    Curve? forwardAnimationCurve,
    Curve? reverseAnimationCurve,
    void Function(FlashController<T> controller)? onTap,
    EdgeInsets? padding,
    Widget? title,
    required Widget content,
    BoxConstraints? constraints,
    bool shouldIconPulse = true,
    Widget? icon,
    Color? indicatorColor,
    FlashBuilder<T>? primaryActionBuilder,
    FlashBuilder<T>? negativeActionBuilder,
    FlashBuilder<T>? positiveActionBuilder,
    bool showProgressIndicator = false,
    AnimationController? progressIndicatorController,
    Color? progressIndicatorBackgroundColor,
    Animation<Color>? progressIndicatorValueColor,
    Completer<T>? dismissCompleter,
  }) {
    final flashTheme = FlashTheme.bar(this);
    final controller = DefaultFlashController<T>(
      this,
      persistent: persistent,
      duration: duration,
      transitionDuration: transitionDuration ?? flashTheme.transitionDuration,
      barrierFilter: barrierFilter ?? flashTheme.barrierFilter,
      barrierColor: barrierColor ?? flashTheme.barrierColor,
      barrierDismissible: barrierDismissible ?? flashTheme.barrierDismissible ?? false,
      builder: (context, controller) {
        final theme = Theme.of(context);
        final colorScheme = theme.colorScheme;
        final isThemeDark = theme.brightness == Brightness.dark;
        final $brightness = brightness ?? flashTheme.brightness ?? (isThemeDark ? Brightness.light : Brightness.dark);
        final $backgroundColor = backgroundColor ??
            flashTheme.backgroundColor ??
            (isThemeDark
                ? theme.colorScheme.onSurface
                : Color.alphaBlend(
                    theme.colorScheme.onSurface.withOpacity(0.80),
                    theme.colorScheme.surface,
                  ));
        final $titleColor = titleStyle?.color ?? flashTheme.titleStyle?.color ?? theme.colorScheme.surface;
        final $contentColor = contentStyle?.color ?? flashTheme.contentStyle?.color ?? theme.colorScheme.surface;
        final $actionColor = actionColor ??
            flashTheme.actionColor ??
            (isThemeDark ? theme.colorScheme.primaryContainer : theme.colorScheme.secondary);

        final inverseTheme = theme.copyWith(
          colorScheme: ColorScheme(
            primary: colorScheme.onPrimary,
            primaryContainer: colorScheme.onPrimary,
            secondary: $actionColor,
            secondaryContainer: colorScheme.onSecondary,
            surface: colorScheme.onSurface,
            background: $backgroundColor,
            error: colorScheme.onError,
            onPrimary: colorScheme.primary,
            onSecondary: colorScheme.secondary,
            onSurface: colorScheme.surface,
            onBackground: colorScheme.background,
            onError: colorScheme.error,
            brightness: $brightness,
          ),
          textTheme: theme.textTheme.apply(
            displayColor: $titleColor,
            bodyColor: $contentColor,
          ),
          hintColor: $contentColor.withOpacity($contentColor.opacity * 0.6),
        );

        Color? $indicatorColor;
        if (barType == FlashBarType.info) {
          $indicatorColor = flashTheme.infoColor;
        } else if (barType == FlashBarType.success) {
          $indicatorColor = flashTheme.successColor;
        } else if (barType == FlashBarType.error) {
          $indicatorColor = flashTheme.errorColor;
        } else {
          $indicatorColor = indicatorColor;
        }

        Widget wrapActionBuilder(FlashBuilder<T> builder) {
          Widget child = IconTheme(
            data: IconThemeData(color: $actionColor),
            child: builder.call(context, controller),
          );
          child = TextButtonTheme(
            data: TextButtonThemeData(
              style: TextButton.styleFrom(foregroundColor: $actionColor),
            ),
            child: child,
          );
          return child;
        }

        return Theme(
          data: inverseTheme,
          child: Flash<T>.bar(
            controller: controller,
            behavior: behavior ?? flashTheme.behavior ?? FlashBehavior.fixed,
            position: position ?? flashTheme.position ?? FlashPosition.bottom,
            enableVerticalDrag: enableVerticalDrag ?? flashTheme.enableVerticalDrag ?? true,
            horizontalDismissDirections: horizontalDismissDirections ?? flashTheme.horizontalDismissDirections,
            brightness: $brightness,
            backgroundColor: $backgroundColor,
            backgroundGradient: backgroundGradient ?? flashTheme.backgroundGradient,
            boxShadows: boxShadows ?? flashTheme.boxShadows,
            borderRadius: borderRadius ?? flashTheme.borderRadius,
            borderColor: borderColor ?? flashTheme.borderColor,
            borderWidth: borderWidth ?? flashTheme.borderWidth,
            margin: margin ?? flashTheme.margin ?? EdgeInsets.zero,
            insetAnimationDuration:
                insetAnimationDuration ?? flashTheme.insetAnimationDuration ?? const Duration(milliseconds: 100),
            insetAnimationCurve: insetAnimationCurve ?? flashTheme.insetAnimationCurve ?? Curves.fastOutSlowIn,
            forwardAnimationCurve: forwardAnimationCurve ?? flashTheme.forwardAnimationCurve ?? Curves.fastOutSlowIn,
            reverseAnimationCurve: reverseAnimationCurve ?? flashTheme.reverseAnimationCurve ?? Curves.fastOutSlowIn,
            onTap: onTap == null ? null : () => onTap(controller),
            constraints: constraints ?? flashTheme.constraints,
            child: FlashBar(
              padding: padding ?? flashTheme.padding ?? const EdgeInsets.all(16.0),
              title: title == null
                  ? null
                  : DefaultTextStyle(
                      style: inverseTheme.textTheme.titleLarge!.merge(flashTheme.titleStyle).merge(titleStyle),
                      child: title,
                    ),
              content: DefaultTextStyle(
                style: inverseTheme.textTheme.titleMedium!.merge(flashTheme.contentStyle).merge(contentStyle),
                child: content,
              ),
              shouldIconPulse: shouldIconPulse,
              icon: icon == null
                  ? null
                  : IconTheme(
                      data: IconThemeData(color: $indicatorColor),
                      child: icon,
                    ),
              indicatorColor: $indicatorColor,
              primaryAction: primaryActionBuilder == null ? null : wrapActionBuilder(primaryActionBuilder),
              actions: <Widget>[
                if (negativeActionBuilder != null) wrapActionBuilder(negativeActionBuilder),
                if (positiveActionBuilder != null) wrapActionBuilder(positiveActionBuilder),
              ],
              showProgressIndicator: showProgressIndicator,
              progressIndicatorController: progressIndicatorController,
              progressIndicatorBackgroundColor: progressIndicatorBackgroundColor,
              progressIndicatorValueColor: progressIndicatorValueColor,
            ),
          ),
        );
      },
    );
    dismissCompleter?.future.then(controller.dismiss);
    return controller.show();
  }

  /// Show an information flash bar.
  Future<T?> showInfoBar<T>({
    required Widget content,
    FlashPosition? position,
    Duration duration = const Duration(seconds: 3),
    Icon? icon = const Icon(Icons.info_outline),
    FlashBuilder<T>? primaryActionBuilder,
  }) {
    return showFlashBar<T>(
      barType: FlashBarType.info,
      content: content,
      position: position,
      icon: icon,
      duration: duration,
      primaryActionBuilder: primaryActionBuilder,
    );
  }

  /// Show a success flash bar.
  Future<T?> showSuccessBar<T>({
    required Widget content,
    FlashPosition? position,
    Duration duration = const Duration(seconds: 3),
    Icon? icon = const Icon(Icons.check_circle_outline),
    FlashBuilder<T>? primaryActionBuilder,
  }) {
    return showFlashBar<T>(
      barType: FlashBarType.success,
      content: content,
      position: position,
      icon: icon,
      duration: duration,
      primaryActionBuilder: primaryActionBuilder,
    );
  }

  /// Show a error flash bar.
  Future<T?> showErrorBar<T>({
    required Widget content,
    FlashPosition? position,
    Duration duration = const Duration(seconds: 3),
    Icon? icon = const Icon(Icons.error_outline),
    FlashBuilder<T>? primaryActionBuilder,
  }) {
    return showFlashBar<T>(
      barType: FlashBarType.error,
      content: content,
      position: position,
      icon: icon,
      duration: duration,
      primaryActionBuilder: primaryActionBuilder,
    );
  }
}

/// Context extension for flash dialog.
extension FlashDialogShortcuts on BuildContext {
  /// Show a custom flash dialog.
  Future<T?> showFlashDialog<T>({
    bool persistent = true,
    Duration? transitionDuration,
    Brightness? brightness,
    Color? backgroundColor,
    TextStyle? titleStyle,
    TextStyle? contentStyle,
    Color? actionColor,
    Gradient? backgroundGradient,
    List<BoxShadow>? boxShadows,
    Color? barrierColor,
    ImageFilter? barrierFilter,
    bool? barrierDismissible,
    BorderRadius? borderRadius,
    Color? borderColor,
    double? borderWidth,
    EdgeInsets? margin,
    Duration? insetAnimationDuration,
    Curve? insetAnimationCurve,
    Curve? forwardAnimationCurve,
    Curve? reverseAnimationCurve,
    void Function(FlashController<T> controller)? onTap,
    EdgeInsets? padding,
    Widget? title,
    required Widget content,
    BoxConstraints? constraints,
    FlashBuilder<T>? negativeActionBuilder,
    FlashBuilder<T>? positiveActionBuilder,
    Completer<T>? dismissCompleter,
  }) {
    final flashTheme = FlashTheme.dialog(this);
    final controller = DefaultFlashController<T>(
      this,
      persistent: persistent,
      transitionDuration: transitionDuration ?? flashTheme.transitionDuration,
      barrierFilter: barrierFilter ?? flashTheme.barrierFilter,
      barrierColor: barrierColor ?? flashTheme.barrierColor ?? const Color(0x8A000000),
      barrierDismissible: barrierDismissible ?? flashTheme.barrierDismissible ?? true,
      builder: (context, controller) {
        final theme = Theme.of(context);
        final dialogTheme = DialogTheme.of(context);
        final $brightness = brightness ?? flashTheme.brightness ?? theme.brightness;
        final $backgroundColor =
            backgroundColor ?? flashTheme.backgroundColor ?? dialogTheme.backgroundColor ?? theme.dialogBackgroundColor;
        final $titleStyle =
            titleStyle ?? flashTheme.titleStyle ?? dialogTheme.titleTextStyle ?? theme.textTheme.titleLarge!;
        final $contentStyle =
            contentStyle ?? flashTheme.contentStyle ?? dialogTheme.contentTextStyle ?? theme.textTheme.titleMedium!;
        final $actionColor = actionColor ?? flashTheme.actionColor ?? theme.colorScheme.primary;
        Widget wrapActionBuilder(FlashBuilder<T> builder) {
          Widget child = IconTheme(
            data: IconThemeData(color: $actionColor),
            child: builder.call(context, controller),
          );
          child = TextButtonTheme(
            data: TextButtonThemeData(
              style: TextButton.styleFrom(foregroundColor: $actionColor),
            ),
            child: child,
          );
          return child;
        }

        return Flash<T>.dialog(
          controller: controller,
          brightness: $brightness,
          backgroundColor: $backgroundColor,
          backgroundGradient: backgroundGradient ?? flashTheme.backgroundGradient,
          boxShadows: boxShadows ?? flashTheme.boxShadows,
          borderRadius: borderRadius ?? flashTheme.borderRadius,
          borderColor: borderColor ?? flashTheme.borderColor,
          borderWidth: borderWidth ?? flashTheme.borderWidth,
          margin: margin ?? flashTheme.margin ?? const EdgeInsets.symmetric(horizontal: 40.0),
          insetAnimationDuration:
              insetAnimationDuration ?? flashTheme.insetAnimationDuration ?? const Duration(milliseconds: 100),
          insetAnimationCurve: insetAnimationCurve ?? flashTheme.insetAnimationCurve ?? Curves.fastOutSlowIn,
          forwardAnimationCurve: forwardAnimationCurve ?? flashTheme.forwardAnimationCurve ?? Curves.fastOutSlowIn,
          reverseAnimationCurve: reverseAnimationCurve ?? flashTheme.reverseAnimationCurve ?? Curves.fastOutSlowIn,
          onTap: onTap == null ? null : () => onTap(controller),
          constraints: constraints ?? flashTheme.constraints,
          child: FlashBar(
            padding: padding ?? flashTheme.padding ?? const EdgeInsets.all(16.0),
            title: title == null ? null : DefaultTextStyle(style: $titleStyle, child: title),
            content: DefaultTextStyle(style: $contentStyle, child: content),
            actions: <Widget>[
              if (negativeActionBuilder != null) wrapActionBuilder(negativeActionBuilder),
              if (positiveActionBuilder != null) wrapActionBuilder(positiveActionBuilder),
            ],
          ),
        );
      },
    );
    dismissCompleter?.future.then(controller.dismiss);
    return controller.show();
  }

  /// Display a block dialog.
  Future<T?> showBlockDialog<T>({
    bool persistent = true,
    Duration? transitionDuration,
    Color? backgroundColor,
    Gradient? backgroundGradient,
    List<BoxShadow>? boxShadows,
    Color? barrierColor,
    ImageFilter? barrierFilter,
    BorderRadius? borderRadius,
    Color? borderColor,
    double? borderWidth,
    EdgeInsets? margin,
    Duration? insetAnimationDuration,
    Curve? insetAnimationCurve,
    Curve? forwardAnimationCurve,
    Curve? reverseAnimationCurve,
    void Function(FlashController<T> controller)? onTap,
    EdgeInsets padding = const EdgeInsets.all(16.0),
    Widget child = const Padding(
      padding: EdgeInsets.all(16.0),
      child: CircularProgressIndicator(strokeWidth: 2.0),
    ),
    required Completer<T>? dismissCompleter,
  }) {
    final flashTheme = FlashTheme.blockDialog(this);
    final controller = DefaultFlashController<T>(
      this,
      persistent: persistent,
      transitionDuration: transitionDuration ?? flashTheme.transitionDuration,
      barrierFilter: barrierFilter ?? flashTheme.barrierFilter,
      barrierColor: barrierColor ?? flashTheme.barrierColor ?? const Color(0x8A000000),
      barrierDismissible: false,
      builder: (context, controller) {
        final theme = Theme.of(context);
        final dialogTheme = DialogTheme.of(context);
        final $backgroundColor =
            backgroundColor ?? flashTheme.backgroundColor ?? dialogTheme.backgroundColor ?? theme.dialogBackgroundColor;
        return Flash<T>.dialog(
          controller: controller,
          backgroundColor: $backgroundColor,
          backgroundGradient: backgroundGradient ?? flashTheme.backgroundGradient,
          boxShadows: boxShadows ?? flashTheme.boxShadows,
          borderRadius: borderRadius ?? flashTheme.borderRadius,
          borderColor: borderColor ?? flashTheme.borderColor,
          borderWidth: borderWidth ?? flashTheme.borderWidth,
          margin: margin ?? flashTheme.margin ?? const EdgeInsets.symmetric(horizontal: 40.0),
          insetAnimationDuration:
              insetAnimationDuration ?? flashTheme.insetAnimationDuration ?? const Duration(milliseconds: 100),
          insetAnimationCurve: insetAnimationCurve ?? flashTheme.insetAnimationCurve ?? Curves.fastOutSlowIn,
          forwardAnimationCurve: forwardAnimationCurve ?? flashTheme.forwardAnimationCurve ?? Curves.fastOutSlowIn,
          reverseAnimationCurve: reverseAnimationCurve ?? flashTheme.reverseAnimationCurve ?? Curves.fastOutSlowIn,
          onTap: onTap == null ? null : () => onTap(controller),
          child: child,
        );
      },
    );
    dismissCompleter?.future.then(controller.dismiss);
    return controller.show();
  }
}

/// Context extension for modal flash bar.
extension ModalFlashBarShortcuts on BuildContext {
  /// Show a custom flash bar.
  Future<T?> showModalFlashBar<T>({
    FlashBarType? barType,
    Duration? duration,
    Duration? transitionDuration,
    Duration? reverseTransitionDuration,
    bool? enableVerticalDrag,
    List<HorizontalDismissDirection>? horizontalDismissDirections,
    FlashBehavior? behavior,
    FlashPosition? position,
    Brightness? brightness,
    Color? backgroundColor,
    TextStyle? titleStyle,
    TextStyle? contentStyle,
    Color? actionColor,
    Gradient? backgroundGradient,
    List<BoxShadow>? boxShadows,
    Color? barrierColor,
    ImageFilter? barrierFilter,
    bool? barrierDismissible,
    BorderRadius? borderRadius,
    Color? borderColor,
    double? borderWidth,
    EdgeInsets? margin,
    Duration? insetAnimationDuration,
    Curve? insetAnimationCurve,
    Curve? forwardAnimationCurve,
    Curve? reverseAnimationCurve,
    void Function(FlashController<T> controller)? onTap,
    EdgeInsets? padding,
    Widget? title,
    required Widget content,
    BoxConstraints? constraints,
    bool shouldIconPulse = true,
    Widget? icon,
    Color? indicatorColor,
    FlashBuilder<T>? primaryActionBuilder,
    FlashBuilder<T>? negativeActionBuilder,
    FlashBuilder<T>? positiveActionBuilder,
    bool showProgressIndicator = false,
    AnimationController? progressIndicatorController,
    Color? progressIndicatorBackgroundColor,
    Animation<Color>? progressIndicatorValueColor,
  }) {
    final flashTheme = FlashTheme.bar(this);
    return showModalFlash(
      context: this,
      duration: duration,
      transitionDuration: transitionDuration ?? flashTheme.transitionDuration ?? const Duration(milliseconds: 250),
      reverseTransitionDuration:
          reverseTransitionDuration ?? flashTheme.reverseTransitionDuration ?? const Duration(milliseconds: 200),
      barrierFilter: barrierFilter ?? flashTheme.barrierFilter,
      barrierColor: barrierColor ?? flashTheme.barrierColor ?? const Color(0x8A000000),
      barrierDismissible: barrierDismissible ?? flashTheme.barrierDismissible ?? true,
      builder: (context, controller) {
        final theme = Theme.of(context);
        final colorScheme = theme.colorScheme;
        final isThemeDark = theme.brightness == Brightness.dark;
        final $brightness = brightness ?? flashTheme.brightness ?? (isThemeDark ? Brightness.light : Brightness.dark);
        final $backgroundColor = backgroundColor ??
            flashTheme.backgroundColor ??
            (isThemeDark
                ? theme.colorScheme.onSurface
                : Color.alphaBlend(
                    theme.colorScheme.onSurface.withOpacity(0.80),
                    theme.colorScheme.surface,
                  ));
        final $titleColor = titleStyle?.color ?? flashTheme.titleStyle?.color ?? theme.colorScheme.surface;
        final $contentColor = contentStyle?.color ?? flashTheme.contentStyle?.color ?? theme.colorScheme.surface;
        final $actionColor = actionColor ??
            flashTheme.actionColor ??
            (isThemeDark ? theme.colorScheme.primaryContainer : theme.colorScheme.secondary);

        final inverseTheme = theme.copyWith(
          colorScheme: ColorScheme(
            primary: colorScheme.onPrimary,
            primaryContainer: colorScheme.onPrimary,
            secondary: $actionColor,
            secondaryContainer: colorScheme.onSecondary,
            surface: colorScheme.onSurface,
            background: $backgroundColor,
            error: colorScheme.onError,
            onPrimary: colorScheme.primary,
            onSecondary: colorScheme.secondary,
            onSurface: colorScheme.surface,
            onBackground: colorScheme.background,
            onError: colorScheme.error,
            brightness: $brightness,
          ),
          textTheme: theme.textTheme.apply(
            displayColor: $titleColor,
            bodyColor: $contentColor,
          ),
          hintColor: $contentColor.withOpacity($contentColor.opacity * 0.6),
        );

        Color? $indicatorColor;
        if (barType == FlashBarType.info) {
          $indicatorColor = flashTheme.infoColor;
        } else if (barType == FlashBarType.success) {
          $indicatorColor = flashTheme.successColor;
        } else if (barType == FlashBarType.error) {
          $indicatorColor = flashTheme.errorColor;
        } else {
          $indicatorColor = indicatorColor;
        }

        Widget wrapActionBuilder(FlashBuilder<T> builder) {
          Widget child = IconTheme(
            data: IconThemeData(color: $actionColor),
            child: builder.call(context, controller),
          );
          child = TextButtonTheme(
            data: TextButtonThemeData(
              style: TextButton.styleFrom(foregroundColor: $actionColor),
            ),
            child: child,
          );
          return child;
        }

        return Theme(
          data: inverseTheme,
          child: Flash<T>.bar(
            controller: controller,
            behavior: behavior ?? flashTheme.behavior ?? FlashBehavior.fixed,
            position: position ?? flashTheme.position ?? FlashPosition.bottom,
            enableVerticalDrag: enableVerticalDrag ?? flashTheme.enableVerticalDrag ?? true,
            horizontalDismissDirections: horizontalDismissDirections ?? flashTheme.horizontalDismissDirections,
            brightness: $brightness,
            backgroundColor: $backgroundColor,
            backgroundGradient: backgroundGradient ?? flashTheme.backgroundGradient,
            boxShadows: boxShadows ?? flashTheme.boxShadows,
            borderRadius: borderRadius ?? flashTheme.borderRadius,
            borderColor: borderColor ?? flashTheme.borderColor,
            borderWidth: borderWidth ?? flashTheme.borderWidth,
            margin: margin ?? flashTheme.margin ?? EdgeInsets.zero,
            insetAnimationDuration:
                insetAnimationDuration ?? flashTheme.insetAnimationDuration ?? const Duration(milliseconds: 100),
            insetAnimationCurve: insetAnimationCurve ?? flashTheme.insetAnimationCurve ?? Curves.fastOutSlowIn,
            forwardAnimationCurve: forwardAnimationCurve ?? flashTheme.forwardAnimationCurve ?? Curves.fastOutSlowIn,
            reverseAnimationCurve: reverseAnimationCurve ?? flashTheme.reverseAnimationCurve ?? Curves.fastOutSlowIn,
            onTap: onTap == null ? null : () => onTap(controller),
            constraints: constraints ?? flashTheme.constraints,
            child: FlashBar(
              padding: padding ?? flashTheme.padding ?? const EdgeInsets.all(16.0),
              title: title == null
                  ? null
                  : DefaultTextStyle(
                      style: inverseTheme.textTheme.titleLarge!.merge(flashTheme.titleStyle).merge(titleStyle),
                      child: title,
                    ),
              content: DefaultTextStyle(
                style: inverseTheme.textTheme.titleMedium!.merge(flashTheme.contentStyle).merge(contentStyle),
                child: content,
              ),
              shouldIconPulse: shouldIconPulse,
              icon: icon == null
                  ? null
                  : IconTheme(
                      data: IconThemeData(color: $indicatorColor),
                      child: icon,
                    ),
              indicatorColor: $indicatorColor,
              primaryAction: primaryActionBuilder == null ? null : wrapActionBuilder(primaryActionBuilder),
              actions: <Widget>[
                if (negativeActionBuilder != null) wrapActionBuilder(negativeActionBuilder),
                if (positiveActionBuilder != null) wrapActionBuilder(positiveActionBuilder),
              ],
              showProgressIndicator: showProgressIndicator,
              progressIndicatorController: progressIndicatorController,
              progressIndicatorBackgroundColor: progressIndicatorBackgroundColor,
              progressIndicatorValueColor: progressIndicatorValueColor,
            ),
          ),
        );
      },
    );
  }
}

/// Context extension for modal flash dialog.
extension ModalFlashDialogShortcuts on BuildContext {
  /// Show a custom flash dialog.
  Future<T?> showModalFlashDialog<T>({
    Duration? transitionDuration,
    Duration? reverseTransitionDuration,
    Brightness? brightness,
    Color? backgroundColor,
    TextStyle? titleStyle,
    TextStyle? contentStyle,
    Color? actionColor,
    Gradient? backgroundGradient,
    List<BoxShadow>? boxShadows,
    Color? barrierColor,
    ImageFilter? barrierFilter,
    bool? barrierDismissible,
    BorderRadius? borderRadius,
    Color? borderColor,
    double? borderWidth,
    EdgeInsets? margin,
    Duration? insetAnimationDuration,
    Curve? insetAnimationCurve,
    Curve? forwardAnimationCurve,
    Curve? reverseAnimationCurve,
    void Function(FlashController<T> controller)? onTap,
    EdgeInsets? padding,
    Widget? title,
    required Widget content,
    BoxConstraints? constraints,
    FlashBuilder<T>? negativeActionBuilder,
    FlashBuilder<T>? positiveActionBuilder,
  }) {
    final flashTheme = FlashTheme.dialog(this);
    return showModalFlash(
      context: this,
      transitionDuration: transitionDuration ?? flashTheme.transitionDuration ?? const Duration(milliseconds: 250),
      reverseTransitionDuration:
          reverseTransitionDuration ?? flashTheme.reverseTransitionDuration ?? const Duration(milliseconds: 200),
      barrierFilter: barrierFilter ?? flashTheme.barrierFilter,
      barrierColor: barrierColor ?? flashTheme.barrierColor ?? const Color(0x8A000000),
      barrierDismissible: barrierDismissible ?? flashTheme.barrierDismissible ?? true,
      builder: (context, controller) {
        final theme = Theme.of(context);
        final dialogTheme = DialogTheme.of(context);
        final $brightness = brightness ?? flashTheme.brightness ?? theme.brightness;
        final $backgroundColor =
            backgroundColor ?? flashTheme.backgroundColor ?? dialogTheme.backgroundColor ?? theme.dialogBackgroundColor;
        final $titleStyle =
            titleStyle ?? flashTheme.titleStyle ?? dialogTheme.titleTextStyle ?? theme.textTheme.titleLarge!;
        final $contentStyle =
            contentStyle ?? flashTheme.contentStyle ?? dialogTheme.contentTextStyle ?? theme.textTheme.titleMedium!;
        final $actionColor = actionColor ?? flashTheme.actionColor ?? theme.colorScheme.primary;
        Widget wrapActionBuilder(FlashBuilder<T> builder) {
          Widget child = IconTheme(
            data: IconThemeData(color: $actionColor),
            child: builder.call(context, controller),
          );
          child = TextButtonTheme(
            data: TextButtonThemeData(
              style: TextButton.styleFrom(foregroundColor: $actionColor),
            ),
            child: child,
          );
          return child;
        }

        return Flash<T>.dialog(
          controller: controller,
          brightness: $brightness,
          backgroundColor: $backgroundColor,
          backgroundGradient: backgroundGradient ?? flashTheme.backgroundGradient,
          boxShadows: boxShadows ?? flashTheme.boxShadows,
          borderRadius: borderRadius ?? flashTheme.borderRadius,
          borderColor: borderColor ?? flashTheme.borderColor ?? const Color(0x8A000000),
          borderWidth: borderWidth ?? flashTheme.borderWidth,
          margin: margin ?? flashTheme.margin ?? const EdgeInsets.symmetric(horizontal: 40.0),
          insetAnimationDuration:
              insetAnimationDuration ?? flashTheme.insetAnimationDuration ?? const Duration(milliseconds: 100),
          insetAnimationCurve: insetAnimationCurve ?? flashTheme.insetAnimationCurve ?? Curves.fastOutSlowIn,
          forwardAnimationCurve: forwardAnimationCurve ?? flashTheme.forwardAnimationCurve ?? Curves.fastOutSlowIn,
          reverseAnimationCurve: reverseAnimationCurve ?? flashTheme.reverseAnimationCurve ?? Curves.fastOutSlowIn,
          onTap: onTap == null ? null : () => onTap(controller),
          constraints: constraints ?? flashTheme.constraints,
          child: FlashBar(
            padding: padding ?? flashTheme.padding ?? const EdgeInsets.all(16.0),
            title: title == null ? null : DefaultTextStyle(style: $titleStyle, child: title),
            content: DefaultTextStyle(style: $contentStyle, child: content),
            actions: <Widget>[
              if (negativeActionBuilder != null) wrapActionBuilder(negativeActionBuilder),
              if (positiveActionBuilder != null) wrapActionBuilder(positiveActionBuilder),
            ],
          ),
        );
      },
    );
  }
}

/// Flash bar type.
enum FlashBarType {
  /// Information type to use [FlashBarThemeData.infoColor].
  info,

  /// Success type to use [FlashBarThemeData.successColor].
  success,

  /// Success type to use [FlashBarThemeData.errorColor].
  error,
}
