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

  /// Creates a toast to emit message.
  const Toast({
    super.key,
    required this.child,
    required this.navigatorKey,
  });

  /// Emit a message for the specified duration.
  static Future<T?> show<T>(
    BuildContext context,
    Widget child, {
    Duration duration = const Duration(seconds: 3),
    Color? backgroundColor,
    double? elevation,
    Color? shadowColor,
    Color? surfaceTintColor,
    ShapeBorder? shape,
    Clip clipBehavior = Clip.none,
    AlignmentGeometry? alignment,
    EdgeInsets? margin,
    EdgeInsets? padding,
    Color? iconColor,
    TextStyle? textStyle,
    bool queue = true,
  }) {
    return context.findAncestorStateOfType<_ToastState>()!.show(
        ToastMessage(
          child: child,
          duration: duration,
          backgroundColor: backgroundColor,
          elevation: elevation,
          shadowColor: shadowColor,
          surfaceTintColor: surfaceTintColor,
          shape: shape,
          clipBehavior: clipBehavior,
          alignment: alignment,
          margin: margin,
          padding: padding,
          iconColor: iconColor,
          textStyle: textStyle,
        ),
        queue: queue);
  }

  @override
  State<Toast> createState() => _ToastState();
}

class _ToastState extends State<Toast> {
  final messageQueue = Queue<ToastMessage>();
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

  Future<T?> show<T>(ToastMessage<T> message, {bool queue = true}) async {
    // Wait initialized.
    await initialized.future;
    final context = widget.navigatorKey.currentContext!;
    // Wait previous toast dismissed.
    if (queue && messageCompleter?.isCompleted == false) {
      messageQueue.add(message);
      return await message.completer().future;
    }

    if (queue) messageCompleter = Completer();

    Future<T?> showToast(ToastMessage<T> message, {bool queue = true}) {
      return showFlash<T>(
        context: context,
        builder: (context, controller) {
          final toastTheme = Theme.of(context).extension<FlashToastTheme>();
          final defaults = _DefaultFlashToastTheme(context);
          return Align(
            alignment: message.alignment ?? toastTheme?.alignment ?? defaults.alignment,
            child: Padding(
              padding: message.margin ?? toastTheme?.margin ?? defaults.margin,
              child: FadeTransition(
                opacity: controller.controller,
                child: Flash(
                  controller: controller,
                  position: FlashPosition.bottom,
                  dismissDirections: FlashDismissDirection.values,
                  child: Material(
                    color: message.backgroundColor ?? toastTheme?.backgroundColor ?? defaults.backgroundColor,
                    elevation: message.elevation ?? toastTheme?.elevation ?? defaults.elevation,
                    shadowColor: message.shadowColor ?? toastTheme?.shadowColor ?? defaults.shadowColor,
                    surfaceTintColor:
                        message.surfaceTintColor ?? toastTheme?.surfaceTintColor ?? defaults.surfaceTintColor,
                    shape: message.shape ?? toastTheme?.shape ?? defaults.shape,
                    type: MaterialType.card,
                    clipBehavior: message.clipBehavior,
                    child: Padding(
                      padding: message.padding ?? toastTheme?.padding ?? defaults.padding,
                      child: IconTheme(
                        data: IconThemeData(color: message.iconColor ?? toastTheme?.iconColor ?? defaults.iconColor),
                        child: DefaultTextStyle(
                          style: message.textStyle ?? toastTheme?.textStyle ?? defaults.textStyle!,
                          child: message.child,
                        ),
                      ),
                    ),
                  ),
                ),
              ),
            ),
          );
        },
        duration: message.duration,
      ).whenComplete(() {
        if (queue) {
          if (messageQueue.isNotEmpty) {
            final message = messageQueue.removeFirst() as ToastMessage<T>;
            message.complete(showToast(message, queue: true));
          } else {
            messageCompleter?.complete();
          }
        }
      });
    }

    return showToast(message, queue: queue);
  }
}

class _DefaultFlashToastTheme extends FlashToastTheme {
  _DefaultFlashToastTheme(this.context)
      : _theme = Theme.of(context),
        _textTheme = Theme.of(context).textTheme,
        _iconTheme = Theme.of(context).iconTheme;

  final BuildContext context;
  final ThemeData _theme;
  final TextTheme _textTheme;
  final IconThemeData _iconTheme;

  @override
  Color? get iconColor => _iconTheme.color;

  @override
  Color? get backgroundColor => _theme.colorScheme.surface;

  @override
  Color? get surfaceTintColor => _theme.colorScheme.surfaceTint;

  @override
  Color? get shadowColor => _theme.shadowColor;

  @override
  TextStyle? get textStyle => _textTheme.bodyLarge;
}

class ToastMessage<T> {
  ToastMessage({
    required this.child,
    this.duration = const Duration(seconds: 3),
    this.backgroundColor,
    this.elevation,
    this.shadowColor,
    this.surfaceTintColor,
    this.shape,
    this.clipBehavior = Clip.none,
    this.alignment,
    this.margin,
    this.padding,
    this.iconColor,
    this.textStyle,
  });

  final Widget child;
  final Duration duration;
  final Color? backgroundColor;
  final double? elevation;
  final Color? shadowColor;
  final Color? surfaceTintColor;
  final ShapeBorder? shape;
  final Clip clipBehavior;
  final AlignmentGeometry? alignment;
  final EdgeInsets? margin;
  final EdgeInsets? padding;
  final Color? iconColor;
  final TextStyle? textStyle;
  Completer<T?>? _completer;

  Completer<T?> completer() => _completer = Completer<T?>();

  void complete(Future<T?> toast) => _completer!.complete(toast);
}

/// Context extension for flash toast.
extension ToastShortcuts on BuildContext {
  /// Emit a message for the specified duration.
  Future<T?> showToast<T>(
    Widget child, {
    Duration duration = const Duration(seconds: 3),
    Color? backgroundColor,
    double? elevation,
    Color? shadowColor,
    Color? surfaceTintColor,
    ShapeBorder? shape,
    Clip clipBehavior = Clip.none,
    AlignmentGeometry? alignment,
    EdgeInsets? margin,
    EdgeInsets? padding,
    Color? iconColor,
    TextStyle? textStyle,
    bool queue = true,
  }) {
    return Toast.show(
      this,
      child,
      duration: duration,
      backgroundColor: backgroundColor,
      elevation: elevation,
      shadowColor: shadowColor,
      surfaceTintColor: surfaceTintColor,
      shape: shape,
      clipBehavior: clipBehavior,
      alignment: alignment,
      margin: margin,
      padding: padding,
      iconColor: iconColor,
      textStyle: textStyle,
      queue: queue,
    );
  }
}

/// Context extension for flash.
extension FlashShortcuts on BuildContext {
  Future<T?> showFlash<T>({
    Duration transitionDuration = const Duration(milliseconds: 250),
    Duration reverseTransitionDuration = const Duration(milliseconds: 200),
    Color? barrierColor,
    double? barrierBlur,
    bool barrierDismissible = false,
    FutureOr<bool> Function()? onBarrierTap,
    Curve barrierCurve = Curves.ease,
    bool persistent = true,
    VoidCallback? onRemoveFromRoute,
    Duration? duration,
    required FlashBuilder<T> builder,
    Completer<T>? dismissCompleter,
  }) {
    final controller = DefaultFlashController<T>(
      this,
      transitionDuration: transitionDuration,
      reverseTransitionDuration: reverseTransitionDuration,
      barrierColor: barrierColor,
      barrierBlur: barrierBlur,
      barrierDismissible: barrierDismissible,
      onBarrierTap: onBarrierTap,
      barrierCurve: barrierCurve,
      persistent: persistent,
      onRemoveFromRoute: onRemoveFromRoute,
      duration: duration,
      builder: builder,
    );
    dismissCompleter?.future.then(controller.dismiss);
    return controller.show();
  }
}

/// Context extension for flash bar.
extension FlashBarShortcuts on BuildContext {
  /// Show an information flash bar.
  Future<T?> showInfoBar<T>({
    required Widget content,
    FlashPosition position = FlashPosition.bottom,
    Duration duration = const Duration(seconds: 3),
    Icon? icon = const Icon(Icons.info_outline),
    Color? indicatorColor = const Color(0xFF64B5F6),
    FlashBuilder<T>? primaryActionBuilder,
  }) {
    return showFlash<T>(
      context: this,
      duration: duration,
      builder: (context, controller) {
        return FlashBar(
          controller: controller,
          position: position,
          indicatorColor: indicatorColor,
          icon: icon,
          content: content,
          primaryAction: primaryActionBuilder?.call(context, controller),
        );
      },
    );
  }

  /// Show a success flash bar.
  Future<T?> showSuccessBar<T>({
    required Widget content,
    FlashPosition position = FlashPosition.bottom,
    Duration duration = const Duration(seconds: 3),
    Icon? icon = const Icon(Icons.check_circle_outline),
    Color? indicatorColor = const Color(0xFF81C784),
    FlashBuilder<T>? primaryActionBuilder,
  }) {
    return showFlash<T>(
      context: this,
      duration: duration,
      builder: (context, controller) {
        return FlashBar(
          controller: controller,
          position: position,
          indicatorColor: indicatorColor,
          icon: icon,
          content: content,
          primaryAction: primaryActionBuilder?.call(context, controller),
        );
      },
    );
  }

  /// Show a error flash bar.
  Future<T?> showErrorBar<T>({
    required Widget content,
    FlashPosition position = FlashPosition.bottom,
    Duration duration = const Duration(seconds: 3),
    Icon? icon = const Icon(Icons.error_outline),
    Color? indicatorColor = const Color(0xFFE57373),
    FlashBuilder<T>? primaryActionBuilder,
  }) {
    return showFlash<T>(
      context: this,
      duration: duration,
      builder: (context, controller) {
        return FlashBar(
          controller: controller,
          position: position,
          indicatorColor: indicatorColor,
          icon: icon,
          content: content,
          primaryAction: primaryActionBuilder?.call(context, controller),
        );
      },
    );
  }
}

/// Context extension for modal flash.
extension ModalFlashShortcuts on BuildContext {
  Future<T?> showModalFlash<T>({
    required FlashBuilder<T> builder,
    Color? barrierColor = const Color(0x8A000000),
    double? barrierBlur,
    bool barrierDismissible = true,
    Curve barrierCurve = Curves.ease,
    String? barrierLabel,
    Duration transitionDuration = const Duration(milliseconds: 250),
    Duration reverseTransitionDuration = const Duration(milliseconds: 200),
    RouteSettings? settings,
    bool useRootNavigator = false,
    Duration? duration,
    @Deprecated('use Navigator.of(context).pop() instead') Completer<T>? dismissCompleter,
  }) {
    final NavigatorState navigator = Navigator.of(this, rootNavigator: useRootNavigator);
    final route = ModalFlashRoute<T>(
      builder: builder,
      capturedThemes: InheritedTheme.capture(from: this, to: navigator.context),
      barrierBlur: barrierBlur,
      barrierColor: barrierColor,
      barrierDismissible: barrierDismissible,
      barrierCurve: barrierCurve,
      barrierLabel: barrierLabel,
      transitionDuration: transitionDuration,
      reverseTransitionDuration: reverseTransitionDuration,
      settings: settings,
      duration: duration,
    );
    dismissCompleter?.future.then(route.dismiss);
    return navigator.push(route);
  }

  Future<T?> showBlockDialog<T>({
    Duration transitionDuration = const Duration(milliseconds: 250),
    Duration reverseTransitionDuration = const Duration(milliseconds: 200),
    Color barrierColor = const Color(0x8A000000),
    double? barrierBlur,
    Curve barrierCurve = Curves.ease,
    @Deprecated('use Navigator.of(context).pop() instead') Completer<T>? dismissCompleter,
  }) {
    return showModalFlash(
      transitionDuration: transitionDuration,
      reverseTransitionDuration: reverseTransitionDuration,
      barrierColor: barrierColor,
      barrierBlur: barrierBlur,
      barrierCurve: barrierCurve,
      dismissCompleter: dismissCompleter,
      builder: (context, controller) => PopScope(
        canPop: false,
        child: FadeTransition(
          opacity: controller.controller,
          child: const Align(
            child: Padding(
              padding: EdgeInsets.all(16.0),
              child: CircularProgressIndicator(strokeWidth: 2.0),
            ),
          ),
        ),
      ),
    );
  }
}
