import 'dart:async';
import 'dart:collection';

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
  _ToastState createState() => _ToastState();
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
      final item = _MessageItem<T>(message, duration, alignment, margin,
          borderRadius, backgroundColor, textStyle, padding);
      messageQueue.add(item);
      return await item.completer.future;
    }

    messageCompleter = Completer();

    Future<T?> showToast(Object message, Duration duration, alignment, margin,
        borderRadius, backgroundColor, textStyle, padding) {
      return showFlash<T>(
        context: context,
        builder: (context, controller) {
          final child;
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
          item.completer.complete(showToast(
              item.message,
              item.duration,
              item.alignment,
              item.margin,
              item.borderRadius,
              item.backgroundColor,
              item.textStyle,
              item.padding));
        } else {
          messageCompleter?.complete();
        }
      });
    }

    return showToast(message, duration, alignment, margin, borderRadius,
        backgroundColor, textStyle, padding);
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

  _MessageItem(this.message, this.duration, this.alignment, this.margin,
      this.borderRadius, this.backgroundColor, this.textStyle, this.padding)
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
    WillPopCallback? onWillPop,
    bool? enableVerticalDrag,
    HorizontalDismissDirection? horizontalDismissDirection,
    FlashBehavior? behavior,
    FlashPosition? position,
    Brightness? brightness,
    Color? backgroundColor,
    TextStyle? titleStyle,
    TextStyle? contentStyle,
    Color? actionColor,
    Gradient? backgroundGradient,
    List<BoxShadow>? boxShadows,
    double? barrierBlur,
    Color? barrierColor,
    bool? barrierDismissible,
    BorderRadius? borderRadius,
    Color? borderColor,
    double? borderWidth,
    EdgeInsets? margin,
    Duration? insetAnimationDuration,
    Curve? insetAnimationCurve,
    Curve? forwardAnimationCurve,
    Curve? reverseAnimationCurve,
    FlashCallback? onTap,
    EdgeInsets? padding,
    Widget? title,
    required Widget content,
    BoxConstraints? constraints,
    bool shouldIconPulse = true,
    Widget? icon,
    Color? indicatorColor,
    FlashWidgetBuilder<T>? primaryActionBuilder,
    FlashWidgetBuilder<T>? negativeActionBuilder,
    FlashWidgetBuilder<T>? positiveActionBuilder,
    bool showProgressIndicator = false,
    AnimationController? progressIndicatorController,
    Color? progressIndicatorBackgroundColor,
    Animation<Color>? progressIndicatorValueColor,
    Completer<T>? dismissCompleter,
  }) {
    final flashTheme = FlashTheme.bar(this);
    final controller = FlashController<T>(
      this,
      persistent: persistent,
      duration: duration,
      transitionDuration: transitionDuration ?? flashTheme.transitionDuration,
      onWillPop: onWillPop,
      builder: (context, controller) {
        return StatefulBuilder(builder: (context, setState) {
          final theme = Theme.of(context);
          final colorScheme = theme.colorScheme;
          final isThemeDark = theme.brightness == Brightness.dark;
          final $brightness = brightness ??
              flashTheme.brightness ??
              (isThemeDark ? Brightness.light : Brightness.dark);
          final $backgroundColor = backgroundColor ??
              flashTheme.backgroundColor ??
              (isThemeDark
                  ? theme.colorScheme.onSurface
                  : Color.alphaBlend(
                      theme.colorScheme.onSurface.withOpacity(0.80),
                      theme.colorScheme.surface,
                    ));
          final $titleColor = titleStyle?.color ??
              flashTheme.titleStyle?.color ??
              theme.colorScheme.surface;
          final $contentColor = contentStyle?.color ??
              flashTheme.contentStyle?.color ??
              theme.colorScheme.surface;
          final $actionColor = actionColor ??
              flashTheme.actionColor ??
              (isThemeDark
                  ? theme.colorScheme.primaryContainer
                  : theme.colorScheme.secondary);

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

          Widget wrapActionBuilder(FlashWidgetBuilder<T> builder) {
            Widget child = IconTheme(
              data: IconThemeData(color: $actionColor),
              child: builder.call(context, controller, setState),
            );
            child = TextButtonTheme(
              data: TextButtonThemeData(
                style: TextButton.styleFrom(primary: $actionColor),
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
              enableVerticalDrag:
                  enableVerticalDrag ?? flashTheme.enableVerticalDrag ?? true,
              horizontalDismissDirection: horizontalDismissDirection ??
                  flashTheme.horizontalDismissDirection,
              brightness: $brightness,
              backgroundColor: $backgroundColor,
              backgroundGradient:
                  backgroundGradient ?? flashTheme.backgroundGradient,
              boxShadows: boxShadows ?? flashTheme.boxShadows,
              barrierBlur: barrierBlur ?? flashTheme.barrierBlur,
              barrierColor: barrierColor ?? flashTheme.barrierColor,
              barrierDismissible:
                  barrierDismissible ?? flashTheme.barrierDismissible ?? true,
              borderRadius: borderRadius ?? flashTheme.borderRadius,
              borderColor: borderColor ?? flashTheme.borderColor,
              borderWidth: borderWidth ?? flashTheme.borderWidth,
              margin: margin ?? flashTheme.margin ?? EdgeInsets.zero,
              insetAnimationDuration: insetAnimationDuration ??
                  flashTheme.insetAnimationDuration ??
                  const Duration(milliseconds: 100),
              insetAnimationCurve: insetAnimationCurve ??
                  flashTheme.insetAnimationCurve ??
                  Curves.fastOutSlowIn,
              forwardAnimationCurve: forwardAnimationCurve ??
                  flashTheme.forwardAnimationCurve ??
                  Curves.fastOutSlowIn,
              reverseAnimationCurve: reverseAnimationCurve ??
                  flashTheme.reverseAnimationCurve ??
                  Curves.fastOutSlowIn,
              onTap: onTap == null
                  ? null
                  : () => onTap(context, controller, setState),
              constraints: constraints ?? flashTheme.constraints,
              child: FlashBar(
                padding:
                    padding ?? flashTheme.padding ?? const EdgeInsets.all(16.0),
                title: title == null
                    ? null
                    : DefaultTextStyle(
                        style: inverseTheme.textTheme.titleLarge!
                            .merge(flashTheme.titleStyle)
                            .merge(titleStyle),
                        child: title,
                      ),
                content: DefaultTextStyle(
                  style: inverseTheme.textTheme.titleMedium!
                      .merge(flashTheme.contentStyle)
                      .merge(contentStyle),
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
                primaryAction: primaryActionBuilder == null
                    ? null
                    : wrapActionBuilder(primaryActionBuilder),
                actions: <Widget>[
                  if (negativeActionBuilder != null)
                    wrapActionBuilder(negativeActionBuilder),
                  if (positiveActionBuilder != null)
                    wrapActionBuilder(positiveActionBuilder),
                ],
                showProgressIndicator: showProgressIndicator,
                progressIndicatorController: progressIndicatorController,
                progressIndicatorBackgroundColor:
                    progressIndicatorBackgroundColor,
                progressIndicatorValueColor: progressIndicatorValueColor,
              ),
            ),
          );
        });
      },
    );
    dismissCompleter?.future.then(controller.dismiss);
    return controller.show();
  }

  /// Show an information flash bar.
  Future<T?> showInfoBar<T>({
    required Widget content,
    Duration duration = const Duration(seconds: 3),
    Icon? icon = const Icon(Icons.info_outline),
    FlashWidgetBuilder<T>? primaryActionBuilder,
  }) {
    return showFlashBar<T>(
      barType: FlashBarType.info,
      content: content,
      icon: icon,
      duration: duration,
      primaryActionBuilder: primaryActionBuilder,
    );
  }

  /// Show a success flash bar.
  Future<T?> showSuccessBar<T>({
    required Widget content,
    Duration duration = const Duration(seconds: 3),
    Icon? icon = const Icon(Icons.check_circle_outline),
    FlashWidgetBuilder<T>? primaryActionBuilder,
  }) {
    return showFlashBar<T>(
      barType: FlashBarType.success,
      content: content,
      icon: icon,
      duration: duration,
      primaryActionBuilder: primaryActionBuilder,
    );
  }

  /// Show a error flash bar.
  Future<T?> showErrorBar<T>({
    required Widget content,
    Duration duration = const Duration(seconds: 3),
    Icon? icon = const Icon(Icons.error_outline),
    FlashWidgetBuilder<T>? primaryActionBuilder,
  }) {
    return showFlashBar<T>(
      barType: FlashBarType.error,
      content: content,
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
    WillPopCallback? onWillPop,
    Brightness? brightness,
    Color? backgroundColor,
    TextStyle? titleStyle,
    TextStyle? contentStyle,
    Color? actionColor,
    Gradient? backgroundGradient,
    List<BoxShadow>? boxShadows,
    double? barrierBlur,
    Color? barrierColor,
    bool? barrierDismissible,
    BorderRadius? borderRadius,
    Color? borderColor,
    double? borderWidth,
    EdgeInsets? margin,
    Duration? insetAnimationDuration,
    Curve? insetAnimationCurve,
    Curve? forwardAnimationCurve,
    Curve? reverseAnimationCurve,
    FlashCallback? onTap,
    EdgeInsets? padding,
    Widget? title,
    required Widget content,
    BoxConstraints? constraints,
    FlashWidgetBuilder<T>? negativeActionBuilder,
    FlashWidgetBuilder<T>? positiveActionBuilder,
    Completer<T>? dismissCompleter,
  }) {
    final flashTheme = FlashTheme.dialog(this);
    final controller = FlashController<T>(
      this,
      persistent: persistent,
      transitionDuration: transitionDuration ?? flashTheme.transitionDuration,
      onWillPop: onWillPop,
      builder: (context, controller) {
        return StatefulBuilder(builder: (context, setState) {
          final theme = Theme.of(context);
          final dialogTheme = DialogTheme.of(context);
          final $brightness =
              brightness ?? flashTheme.brightness ?? theme.brightness;
          final $backgroundColor = backgroundColor ??
              flashTheme.backgroundColor ??
              dialogTheme.backgroundColor ??
              theme.dialogBackgroundColor;
          final $titleStyle = titleStyle ??
              flashTheme.titleStyle ??
              dialogTheme.titleTextStyle ??
              theme.textTheme.titleLarge!;
          final $contentStyle = contentStyle ??
              flashTheme.contentStyle ??
              dialogTheme.contentTextStyle ??
              theme.textTheme.titleMedium!;
          final $actionColor = actionColor ??
              flashTheme.actionColor ??
              theme.colorScheme.primary;
          Widget wrapActionBuilder(FlashWidgetBuilder<T> builder) {
            Widget child = IconTheme(
              data: IconThemeData(color: $actionColor),
              child: builder.call(context, controller, setState),
            );
            child = TextButtonTheme(
              data: TextButtonThemeData(
                style: TextButton.styleFrom(primary: $actionColor),
              ),
              child: child,
            );
            return child;
          }

          return Flash<T>.dialog(
            controller: controller,
            brightness: $brightness,
            backgroundColor: $backgroundColor,
            backgroundGradient:
                backgroundGradient ?? flashTheme.backgroundGradient,
            boxShadows: boxShadows ?? flashTheme.boxShadows,
            barrierBlur: barrierBlur ?? flashTheme.barrierBlur,
            barrierColor:
                barrierColor ?? flashTheme.barrierColor ?? Colors.black54,
            barrierDismissible:
                barrierDismissible ?? flashTheme.barrierDismissible ?? true,
            borderRadius: borderRadius ?? flashTheme.borderRadius,
            borderColor: borderColor ?? flashTheme.borderColor,
            borderWidth: borderWidth ?? flashTheme.borderWidth,
            margin: margin ??
                flashTheme.margin ??
                const EdgeInsets.symmetric(horizontal: 40.0),
            insetAnimationDuration: insetAnimationDuration ??
                flashTheme.insetAnimationDuration ??
                const Duration(milliseconds: 100),
            insetAnimationCurve: insetAnimationCurve ??
                flashTheme.insetAnimationCurve ??
                Curves.fastOutSlowIn,
            forwardAnimationCurve: forwardAnimationCurve ??
                flashTheme.forwardAnimationCurve ??
                Curves.fastOutSlowIn,
            reverseAnimationCurve: reverseAnimationCurve ??
                flashTheme.reverseAnimationCurve ??
                Curves.fastOutSlowIn,
            onTap: onTap == null
                ? null
                : () => onTap(context, controller, setState),
            constraints: constraints ?? flashTheme.constraints,
            child: FlashBar(
              padding:
                  padding ?? flashTheme.padding ?? const EdgeInsets.all(16.0),
              title: title == null
                  ? null
                  : DefaultTextStyle(style: $titleStyle, child: title),
              content: DefaultTextStyle(style: $contentStyle, child: content),
              actions: <Widget>[
                if (negativeActionBuilder != null)
                  wrapActionBuilder(negativeActionBuilder),
                if (positiveActionBuilder != null)
                  wrapActionBuilder(positiveActionBuilder),
              ],
            ),
          );
        });
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
    double? barrierBlur,
    Color? barrierColor,
    BorderRadius? borderRadius,
    Color? borderColor,
    double? borderWidth,
    EdgeInsets? margin,
    Duration? insetAnimationDuration,
    Curve? insetAnimationCurve,
    Curve? forwardAnimationCurve,
    Curve? reverseAnimationCurve,
    FlashCallback? onTap,
    EdgeInsets padding = const EdgeInsets.all(16.0),
    Widget child = const Padding(
      padding: EdgeInsets.all(16.0),
      child: CircularProgressIndicator(strokeWidth: 2.0),
    ),
    required Completer<T>? dismissCompleter,
  }) {
    final flashTheme = FlashTheme.blockDialog(this);
    final controller = FlashController<T>(
      this,
      persistent: persistent,
      transitionDuration: transitionDuration ?? flashTheme.transitionDuration,
      onWillPop: () => Future.value(false),
      builder: (context, controller) {
        return StatefulBuilder(builder: (context, setState) {
          final theme = Theme.of(context);
          final dialogTheme = DialogTheme.of(context);
          final $backgroundColor = backgroundColor ??
              flashTheme.backgroundColor ??
              dialogTheme.backgroundColor ??
              theme.dialogBackgroundColor;
          return Flash<T>.dialog(
            controller: controller,
            backgroundColor: $backgroundColor,
            backgroundGradient:
                backgroundGradient ?? flashTheme.backgroundGradient,
            boxShadows: boxShadows ?? flashTheme.boxShadows,
            barrierBlur: barrierBlur ?? flashTheme.barrierBlur,
            barrierColor:
                barrierColor ?? flashTheme.barrierColor ?? Colors.black54,
            barrierDismissible: false,
            borderRadius: borderRadius ?? flashTheme.borderRadius,
            borderColor: borderColor ?? flashTheme.borderColor,
            borderWidth: borderWidth ?? flashTheme.borderWidth,
            margin: margin ??
                flashTheme.margin ??
                const EdgeInsets.symmetric(horizontal: 40.0),
            insetAnimationDuration: insetAnimationDuration ??
                flashTheme.insetAnimationDuration ??
                const Duration(milliseconds: 100),
            insetAnimationCurve: insetAnimationCurve ??
                flashTheme.insetAnimationCurve ??
                Curves.fastOutSlowIn,
            forwardAnimationCurve: forwardAnimationCurve ??
                flashTheme.forwardAnimationCurve ??
                Curves.fastOutSlowIn,
            reverseAnimationCurve: reverseAnimationCurve ??
                flashTheme.reverseAnimationCurve ??
                Curves.fastOutSlowIn,
            onTap: onTap == null
                ? null
                : () => onTap(context, controller, setState),
            child: child,
          );
        });
      },
    );
    dismissCompleter?.future.then(controller.dismiss);
    return controller.show();
  }
}

/// A builder that creates a widget given the `controller` and `setState`.
typedef FlashWidgetBuilder<T> = Widget Function(
    BuildContext context, FlashController<T> controller, StateSetter setState);

/// Signature of callbacks that have arguments of flash and return no data.
typedef FlashCallback<T> = void Function(
    BuildContext context, FlashController<T> controller, StateSetter setState);

/// Flash bar type.
enum FlashBarType {
  /// Information type to use [FlashBarThemeData.infoColor].
  info,

  /// Success type to use [FlashBarThemeData.successColor].
  success,

  /// Success type to use [FlashBarThemeData.errorColor].
  error,
}

/// Applies a theme to descendant flash widgets.
class FlashTheme extends InheritedWidget {
  /// Specifies the styles for descendant flash bar widgets.
  final FlashBarThemeData? flashBarTheme;

  /// Specifies the style for descendant flash dialog widgets.
  final FlashDialogThemeData? flashDialogTheme;

  /// Specifies the style for descendant flash block dialog widgets.
  final FlashBlockDialogThemeData? flashBlockDialogTheme;

  /// Applies the given theme to [child].
  FlashTheme({
    Key? key,
    required Widget child,
    this.flashBarTheme,
    this.flashDialogTheme,
    this.flashBlockDialogTheme,
  }) : super(key: key, child: child);

  /// The data from the closest [FlashBarThemeData] instance given the build
  /// context.
  static FlashBarThemeData bar(BuildContext context) {
    final flashTheme = context.dependOnInheritedWidgetOfExactType<FlashTheme>();
    final theme = Theme.of(context);
    final isThemeDark = theme.brightness == Brightness.dark;
    return flashTheme?.flashBarTheme ??
        (isThemeDark
            ? const FlashBarThemeData.dark()
            : const FlashBarThemeData.light());
  }

  /// The data from the closest [FlashDialogThemeData] instance given the build
  /// context.
  static FlashDialogThemeData dialog(BuildContext context) {
    final flashTheme = context.dependOnInheritedWidgetOfExactType<FlashTheme>();
    return flashTheme?.flashDialogTheme ?? const FlashDialogThemeData();
  }

  /// The data from the closest [FlashBlockDialogThemeData] instance given the
  /// build context.
  static FlashBlockDialogThemeData blockDialog(BuildContext context) {
    final flashTheme = context.dependOnInheritedWidgetOfExactType<FlashTheme>();
    return flashTheme?.flashBlockDialogTheme ??
        const FlashBlockDialogThemeData();
  }

  @override
  bool updateShouldNotify(covariant FlashTheme oldWidget) {
    return flashBarTheme != oldWidget.flashBarTheme ||
        flashDialogTheme != oldWidget.flashDialogTheme ||
        flashBlockDialogTheme != oldWidget.flashBlockDialogTheme;
  }
}

/// Defines the configuration of the overall visual [FlashTheme] bar.
@immutable
class FlashBarThemeData {
  /// Default value for [FlashController.transitionDuration].
  final Duration? transitionDuration;

  /// Default value for [Flash.behavior].
  ///
  /// If null, [Flash] will default to [FlashBehavior.fixed].
  final FlashBehavior? behavior;

  /// Default value for [Flash.position].
  ///
  /// If null, [Flash] will default to [FlashPosition.bottom].
  final FlashPosition? position;

  /// Default value for [Flash.enableVerticalDrag].
  ///
  /// If null, [Flash] will default to true.
  final bool? enableVerticalDrag;

  /// Default value for [Flash.horizontalDismissDirection].
  final HorizontalDismissDirection? horizontalDismissDirection;

  /// Default value for [Flash.brightness].
  ///
  /// If null, [Flash] will default to inversion of [ThemeData.brightness].
  final Brightness? brightness;

  /// Default value for [Flash.backgroundColor].
  ///
  /// If null, [Flash] will default to inversion of [ThemeData.backgroundColor].
  final Color? backgroundColor;

  /// Default value for [Flash.backgroundGradient].
  final Gradient? backgroundGradient;

  /// Default value for [Flash.boxShadows].
  final List<BoxShadow>? boxShadows;

  /// Default value for [Flash.barrierBlur].
  final double? barrierBlur;

  /// Default value for [Flash.barrierColor].
  final Color? barrierColor;

  /// Default value for [Flash.barrierDismissible].
  ///
  /// If null, [Flash] will default to true.
  final bool? barrierDismissible;

  /// Default value for [Flash.borderRadius].
  final BorderRadius? borderRadius;

  /// Default value for [Flash.borderColor].
  final Color? borderColor;

  /// Default value for [Flash.borderWidth].
  final double? borderWidth;

  /// Default value for [Flash.constraints].
  final BoxConstraints? constraints;

  /// Default value for [Flash.margin].
  ///
  /// If null, [Flash] will default to [EdgeInsets.zero].
  final EdgeInsets? margin;

  /// Default value for [Flash.insetAnimationDuration].
  ///
  /// If null, [Flash] will default to 100 ms.
  final Duration? insetAnimationDuration;

  /// Default value for [Flash.insetAnimationCurve].
  ///
  /// If null, [Flash] will default to [Curves.fastOutSlowIn].
  final Curve? insetAnimationCurve;

  /// Default value for [Flash.forwardAnimationCurve].
  ///
  /// If null, [Flash] will default to [Curves.fastOutSlowIn].
  final Curve? forwardAnimationCurve;

  /// Default value for [Flash.reverseAnimationCurve].
  ///
  /// If null, [Flash] will default to [Curves.fastOutSlowIn].
  final Curve? reverseAnimationCurve;

  /// Default value for [FlashBar.padding].
  final EdgeInsets? padding;

  /// Default style for [FlashBar.title].
  final TextStyle? titleStyle;

  /// Default style for [FlashBar.content].
  final TextStyle? contentStyle;

  /// Default style for [FlashBar.primaryAction] and [FlashBar.actions].
  final Color? actionColor;

  /// Default value for [FlashBar.indicatorColor] when [FlashBarType.info] used.
  final Color? infoColor;

  /// Default value for [FlashBar.indicatorColor] when [FlashBarType.success]
  /// used.
  final Color? successColor;

  /// Default value for [FlashBar.indicatorColor] when [FlashBarType.error]
  /// used.
  final Color? errorColor;

  /// Creates a flash bar theme that can be used for [Flash] bar.
  const FlashBarThemeData({
    this.transitionDuration = const Duration(milliseconds: 500),
    this.behavior,
    this.position,
    this.enableVerticalDrag,
    this.horizontalDismissDirection,
    this.brightness,
    this.backgroundColor,
    this.backgroundGradient,
    this.boxShadows,
    this.barrierBlur,
    this.barrierColor,
    this.barrierDismissible,
    this.borderRadius,
    this.borderColor,
    this.borderWidth,
    this.constraints,
    this.margin,
    this.insetAnimationDuration,
    this.insetAnimationCurve,
    this.forwardAnimationCurve,
    this.reverseAnimationCurve,
    this.padding,
    this.titleStyle,
    this.contentStyle,
    this.actionColor,
    this.infoColor,
    this.successColor,
    this.errorColor,
  });

  /// A default light theme.
  const FlashBarThemeData.light()
      : this(
          brightness: Brightness.light,
          infoColor: const Color(0xFF64B5F6),
          successColor: const Color(0xFF81C784),
          errorColor: const Color(0xFFE57373),
        );

  /// A default dark theme.
  const FlashBarThemeData.dark()
      : this(
          brightness: Brightness.dark,
          infoColor: const Color(0xFF42A5F5),
          successColor: const Color(0xFF66BB6A),
          errorColor: const Color(0xFFEF5350),
        );

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is FlashBarThemeData &&
          runtimeType == other.runtimeType &&
          transitionDuration == other.transitionDuration &&
          behavior == other.behavior &&
          position == other.position &&
          enableVerticalDrag == other.enableVerticalDrag &&
          horizontalDismissDirection == other.horizontalDismissDirection &&
          brightness == other.brightness &&
          backgroundColor == other.backgroundColor &&
          backgroundGradient == other.backgroundGradient &&
          boxShadows == other.boxShadows &&
          barrierBlur == other.barrierBlur &&
          barrierColor == other.barrierColor &&
          barrierDismissible == other.barrierDismissible &&
          borderRadius == other.borderRadius &&
          borderColor == other.borderColor &&
          borderWidth == other.borderWidth &&
          constraints == other.constraints &&
          margin == other.margin &&
          insetAnimationDuration == other.insetAnimationDuration &&
          insetAnimationCurve == other.insetAnimationCurve &&
          forwardAnimationCurve == other.forwardAnimationCurve &&
          reverseAnimationCurve == other.reverseAnimationCurve &&
          padding == other.padding &&
          titleStyle == other.titleStyle &&
          contentStyle == other.contentStyle &&
          actionColor == other.actionColor &&
          infoColor == other.infoColor &&
          successColor == other.successColor &&
          errorColor == other.errorColor;

  @override
  int get hashCode =>
      transitionDuration.hashCode ^
      behavior.hashCode ^
      position.hashCode ^
      enableVerticalDrag.hashCode ^
      horizontalDismissDirection.hashCode ^
      brightness.hashCode ^
      backgroundColor.hashCode ^
      backgroundGradient.hashCode ^
      boxShadows.hashCode ^
      barrierBlur.hashCode ^
      barrierColor.hashCode ^
      barrierDismissible.hashCode ^
      borderRadius.hashCode ^
      borderColor.hashCode ^
      borderWidth.hashCode ^
      constraints.hashCode ^
      margin.hashCode ^
      insetAnimationDuration.hashCode ^
      insetAnimationCurve.hashCode ^
      forwardAnimationCurve.hashCode ^
      reverseAnimationCurve.hashCode ^
      padding.hashCode ^
      titleStyle.hashCode ^
      contentStyle.hashCode ^
      actionColor.hashCode ^
      infoColor.hashCode ^
      successColor.hashCode ^
      errorColor.hashCode;
}

/// Defines the configuration of the overall visual [FlashTheme] dialog.
@immutable
class FlashDialogThemeData {
  /// Default value for [FlashController.transitionDuration].
  final Duration? transitionDuration;

  /// Default value for [Flash.brightness].
  ///
  /// If null, [Flash] will default to [ThemeData.brightness].
  final Brightness? brightness;

  /// Default value for [Flash.backgroundColor].
  ///
  /// If null, [Flash] will default to [DialogTheme.backgroundColor] or
  /// [ThemeData.dialogBackgroundColor].
  final Color? backgroundColor;

  /// Default value for [Flash.backgroundGradient].
  final Gradient? backgroundGradient;

  /// Default value for [Flash.boxShadows].
  final List<BoxShadow>? boxShadows;

  /// Default value for [Flash.barrierBlur].
  final double? barrierBlur;

  /// Default value for [Flash.barrierColor].
  final Color? barrierColor;

  /// Default value for [Flash.barrierDismissible].
  ///
  /// If null, [Flash] will default to true.
  final bool? barrierDismissible;

  /// Default value for [Flash.borderRadius].
  final BorderRadius? borderRadius;

  /// Default value for [Flash.borderColor].
  final Color? borderColor;

  /// Default value for [Flash.borderWidth].
  final double? borderWidth;

  /// Default value for [Flash.constraints].
  final BoxConstraints? constraints;

  /// Default value for [Flash.margin].
  final EdgeInsets? margin;

  /// Default value for [Flash.insetAnimationDuration].
  ///
  /// If null, [Flash] will default to 100 ms.
  final Duration? insetAnimationDuration;

  /// Default value for [Flash.insetAnimationCurve].
  ///
  /// If null, [Flash] will default to [Curves.fastOutSlowIn].
  final Curve? insetAnimationCurve;

  /// Default value for [Flash.forwardAnimationCurve].
  ///
  /// If null, [Flash] will default to [Curves.fastOutSlowIn].
  final Curve? forwardAnimationCurve;

  /// Default value for [Flash.reverseAnimationCurve].
  ///
  /// If null, [Flash] will default to [Curves.fastOutSlowIn].
  final Curve? reverseAnimationCurve;

  /// Default value for [FlashBar.padding].
  final EdgeInsets? padding;

  /// Default style for [FlashBar.title].
  final TextStyle? titleStyle;

  /// Default style for [FlashBar.content].
  final TextStyle? contentStyle;

  /// Default style for [FlashBar.actions].
  final Color? actionColor;

  /// Creates a flash dialog theme that can be used for [Flash] dialog.
  const FlashDialogThemeData({
    this.transitionDuration = const Duration(milliseconds: 500),
    this.brightness,
    this.backgroundColor,
    this.backgroundGradient,
    this.boxShadows,
    this.barrierBlur,
    this.barrierColor = Colors.black54,
    this.barrierDismissible,
    this.borderRadius = const BorderRadius.all(Radius.circular(8.0)),
    this.borderColor,
    this.borderWidth,
    this.constraints,
    this.margin,
    this.insetAnimationDuration,
    this.reverseAnimationCurve,
    this.insetAnimationCurve,
    this.forwardAnimationCurve,
    this.padding,
    this.titleStyle,
    this.contentStyle,
    this.actionColor,
  });

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is FlashDialogThemeData &&
          runtimeType == other.runtimeType &&
          transitionDuration == other.transitionDuration &&
          brightness == other.brightness &&
          backgroundColor == other.backgroundColor &&
          backgroundGradient == other.backgroundGradient &&
          boxShadows == other.boxShadows &&
          barrierBlur == other.barrierBlur &&
          barrierColor == other.barrierColor &&
          barrierDismissible == other.barrierDismissible &&
          borderRadius == other.borderRadius &&
          borderColor == other.borderColor &&
          borderWidth == other.borderWidth &&
          constraints == other.constraints &&
          margin == other.margin &&
          insetAnimationDuration == other.insetAnimationDuration &&
          insetAnimationCurve == other.insetAnimationCurve &&
          forwardAnimationCurve == other.forwardAnimationCurve &&
          reverseAnimationCurve == other.reverseAnimationCurve &&
          padding == other.padding &&
          titleStyle == other.titleStyle &&
          contentStyle == other.contentStyle &&
          actionColor == other.actionColor;

  @override
  int get hashCode =>
      transitionDuration.hashCode ^
      brightness.hashCode ^
      backgroundColor.hashCode ^
      backgroundGradient.hashCode ^
      boxShadows.hashCode ^
      barrierBlur.hashCode ^
      barrierColor.hashCode ^
      barrierDismissible.hashCode ^
      borderRadius.hashCode ^
      borderColor.hashCode ^
      borderWidth.hashCode ^
      constraints.hashCode ^
      margin.hashCode ^
      insetAnimationDuration.hashCode ^
      insetAnimationCurve.hashCode ^
      forwardAnimationCurve.hashCode ^
      reverseAnimationCurve.hashCode ^
      padding.hashCode ^
      titleStyle.hashCode ^
      contentStyle.hashCode ^
      actionColor.hashCode;
}

/// Defines the configuration of the overall visual [FlashTheme] dialog.
@immutable
class FlashBlockDialogThemeData {
  /// Default value for [FlashController.transitionDuration].
  final Duration? transitionDuration;

  /// Default value for [Flash.brightness].
  ///
  /// If null, [Flash] will default to [ThemeData.brightness].
  final Brightness? brightness;

  /// Default value for [Flash.backgroundColor].
  ///
  /// If null, [Flash] will default to [DialogTheme.backgroundColor] or
  /// [ThemeData.dialogBackgroundColor].
  final Color? backgroundColor;

  /// Default value for [Flash.backgroundGradient].
  final Gradient? backgroundGradient;

  /// Default value for [Flash.boxShadows].
  final List<BoxShadow>? boxShadows;

  /// Default value for [Flash.barrierBlur].
  final double? barrierBlur;

  /// Default value for [Flash.barrierColor].
  final Color? barrierColor;

  /// Default value for [Flash.borderRadius].
  final BorderRadius? borderRadius;

  /// Default value for [Flash.borderColor].
  final Color? borderColor;

  /// Default value for [Flash.borderWidth].
  final double? borderWidth;

  /// Default value for [Flash.margin].
  final EdgeInsets? margin;

  /// Default value for [Flash.insetAnimationDuration].
  ///
  /// If null, [Flash] will default to 100 ms.
  final Duration? insetAnimationDuration;

  /// Default value for [Flash.insetAnimationCurve].
  ///
  /// If null, [Flash] will default to [Curves.fastOutSlowIn].
  final Curve? insetAnimationCurve;

  /// Default value for [Flash.forwardAnimationCurve].
  ///
  /// If null, [Flash] will default to [Curves.fastOutSlowIn].
  final Curve? forwardAnimationCurve;

  /// Default value for [Flash.reverseAnimationCurve].
  ///
  /// If null, [Flash] will default to [Curves.fastOutSlowIn].
  final Curve? reverseAnimationCurve;

  /// Default value for [FlashBar.padding].
  final EdgeInsets? padding;

  /// Creates a flash dialog theme that can be used for [Flash] block dialog.
  const FlashBlockDialogThemeData({
    this.transitionDuration = const Duration(milliseconds: 500),
    this.brightness,
    this.backgroundColor,
    this.backgroundGradient,
    this.boxShadows,
    this.barrierBlur,
    this.barrierColor = Colors.black54,
    this.borderRadius = const BorderRadius.all(Radius.circular(8.0)),
    this.borderColor,
    this.borderWidth,
    this.margin,
    this.insetAnimationDuration,
    this.reverseAnimationCurve,
    this.insetAnimationCurve,
    this.forwardAnimationCurve,
    this.padding,
  });

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is FlashBlockDialogThemeData &&
          runtimeType == other.runtimeType &&
          transitionDuration == other.transitionDuration &&
          brightness == other.brightness &&
          backgroundColor == other.backgroundColor &&
          backgroundGradient == other.backgroundGradient &&
          boxShadows == other.boxShadows &&
          barrierBlur == other.barrierBlur &&
          barrierColor == other.barrierColor &&
          borderRadius == other.borderRadius &&
          borderColor == other.borderColor &&
          borderWidth == other.borderWidth &&
          margin == other.margin &&
          insetAnimationDuration == other.insetAnimationDuration &&
          insetAnimationCurve == other.insetAnimationCurve &&
          forwardAnimationCurve == other.forwardAnimationCurve &&
          reverseAnimationCurve == other.reverseAnimationCurve &&
          padding == other.padding;

  @override
  int get hashCode =>
      transitionDuration.hashCode ^
      brightness.hashCode ^
      backgroundColor.hashCode ^
      backgroundGradient.hashCode ^
      boxShadows.hashCode ^
      barrierBlur.hashCode ^
      barrierColor.hashCode ^
      borderRadius.hashCode ^
      borderColor.hashCode ^
      borderWidth.hashCode ^
      margin.hashCode ^
      insetAnimationDuration.hashCode ^
      insetAnimationCurve.hashCode ^
      forwardAnimationCurve.hashCode ^
      reverseAnimationCurve.hashCode ^
      padding.hashCode;
}
