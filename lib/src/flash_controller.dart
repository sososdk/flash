import 'dart:async';
import 'dart:ui';

import 'package:flutter/foundation.dart';
import 'package:flutter/semantics.dart';
import 'package:flutter/widgets.dart';

typedef FlashBuilder<T> = Widget Function(BuildContext context, FlashController<T> controller);

abstract class FlashController<T> {
  AnimationController get controller;

  Future<void> dismiss([T? result]);

  void deactivate();
}

Future<T?> showFlash<T>({
  required BuildContext context,
  required FlashBuilder<T> builder,
  Duration transitionDuration = const Duration(milliseconds: 250),
  Duration reverseTransitionDuration = const Duration(milliseconds: 200),
  Color? barrierColor,
  ImageFilter? barrierFilter,
  bool barrierDismissible = false,
  Curve barrierCurve = Curves.ease,
  Duration? duration,
  bool persistent = true,
}) {
  return DefaultFlashController<T>(
    context,
    builder: builder,
    transitionDuration: transitionDuration,
    reverseTransitionDuration: reverseTransitionDuration,
    barrierColor: barrierColor,
    barrierFilter: barrierFilter,
    barrierDismissible: barrierDismissible,
    barrierCurve: barrierCurve,
    duration: duration,
    persistent: persistent,
  ).show();
}

class DefaultFlashController<T> implements FlashController<T> {
  DefaultFlashController(
    this.context, {
    required this.builder,
    this.transitionDuration = const Duration(milliseconds: 250),
    this.reverseTransitionDuration = const Duration(milliseconds: 200),
    this.barrierColor,
    this.barrierFilter,
    this.barrierDismissible = false,
    this.barrierCurve = Curves.ease,
    this.persistent = true,
    this.duration,
  }) : route = ModalRoute.of(context) {
    final rootOverlay = Navigator.of(context, rootNavigator: true).overlay;
    if (persistent) {
      overlay = rootOverlay;
    } else {
      overlay = Overlay.of(context);
      assert(overlay != rootOverlay, '''overlay can't be the root overlay when persistent is false''');
    }
    assert(overlay != null);
    _controller = createAnimationController()..addStatusListener(_handleStatusChanged);
  }

  OverlayState? overlay;
  final ModalRoute? route;
  final BuildContext context;
  final FlashBuilder<T> builder;

  final Color? barrierColor;

  final ImageFilter? barrierFilter;

  final bool barrierDismissible;

  /// The curve that is used for animating the modal barrier in and out.
  final Curve barrierCurve;

  /// How long until Flash will hide itself (be dismissed). To make it indefinite, leave it null.
  final Duration? duration;

  /// The duration the transition going forwards.
  final Duration? transitionDuration;

  /// The duration the transition going in reverse.
  final Duration? reverseTransitionDuration;

  /// Whether this Flash is add to route.
  ///
  /// Must be non-null, defaults to `true`
  ///
  /// If `true` the Flash will not add to route.
  ///
  /// If `false`, the Flash will add to route as a [LocalHistoryEntry]. Typically the page is wrap with Overlay.
  ///
  /// This can be useful in situations where the app needs to dismiss the Flash with [Navigator.pop].
  ///
  /// ```dart
  /// Navigator.of(context).push(MaterialPageRoute(builder: (context) {
  ///   return Overlay(
  ///     initialEntries: [
  ///       OverlayEntry(builder: (context) {
  ///         return FlashPage();
  ///       }),
  ///     ],
  ///   );
  /// }
  /// ```
  final bool persistent;

  /// The animation controller that the route uses to drive the transitions.
  ///
  /// The animation itself is exposed by the [animation] property.
  @override
  AnimationController get controller => _controller;
  late AnimationController _controller;
  Timer? _timer;
  LocalHistoryEntry? _historyEntry;
  bool _dismissed = false;
  bool _removedHistoryEntry = false;

  bool get isDisposed => _transitionCompleter.isCompleted;

  /// A future that completes when this flash is popped.
  ///
  /// The future completes with the value given to [dismiss], if any.
  Future<T?> get popped => _transitionCompleter.future;
  final _transitionCompleter = Completer<T?>();

  late List<OverlayEntry> _overlayEntries;
  T? _result;

  Future<T?> show() {
    assert(!_transitionCompleter.isCompleted, 'Cannot show a $runtimeType after disposing it.');

    overlay!.insertAll(_overlayEntries = _createOverlayEntries());
    _controller.forward();
    _configureTimer();
    _configurePersistent();

    return popped;
  }

  /// Called to create the animation controller that will drive the transitions to
  /// this route from the previous one, and back to the previous route from this
  /// one.
  AnimationController createAnimationController() {
    assert(!_transitionCompleter.isCompleted, 'Cannot reuse a $runtimeType after disposing it.');
    final duration = transitionDuration;
    final reverseDuration = reverseTransitionDuration;
    assert(duration != null && duration >= Duration.zero);
    return AnimationController(
      duration: duration,
      reverseDuration: reverseDuration,
      debugLabel: debugLabel,
      vsync: overlay!,
    );
  }

  void _handleStatusChanged(AnimationStatus status) {
    switch (status) {
      case AnimationStatus.completed:
        if (_overlayEntries.isNotEmpty) _overlayEntries.first.opaque = false;
        break;
      case AnimationStatus.forward:
      case AnimationStatus.reverse:
        if (_overlayEntries.isNotEmpty) _overlayEntries.first.opaque = false;
        break;
      case AnimationStatus.dismissed:
        dispose();
        break;
    }
  }

  List<OverlayEntry> _createOverlayEntries() {
    return <OverlayEntry>[
      OverlayEntry(
        builder: (context) => _buildBarrier(context),
      ),
      OverlayEntry(
        builder: (context) => builder(context, this),
        maintainState: true,
      ),
    ];
  }

  Widget _buildBarrier(BuildContext context) {
    Widget barrier;
    if (barrierColor != null && barrierColor!.alpha != 0) {
      assert(barrierColor != barrierColor!.withOpacity(0.0));
      final color = controller.drive(
        ColorTween(
          begin: barrierColor!.withOpacity(0.0),
          end: barrierColor,
        ).chain(CurveTween(curve: barrierCurve)),
      );
      barrier = ConstrainedBox(
        constraints: const BoxConstraints.expand(),
        child: AnimatedBuilder(
          animation: color,
          builder: (context, child) {
            final value = color.value;
            return value == null ? SizedBox.shrink() : ColoredBox(color: value);
          },
        ),
      );
    } else {
      barrier = ConstrainedBox(constraints: const BoxConstraints.expand());
    }
    if (barrierDismissible) {
      barrier = MouseRegion(
        cursor: SystemMouseCursors.basic,
        child: GestureDetector(
          behavior: HitTestBehavior.translucent,
          onTap: barrierDismissible ? dismiss : null,
          child: barrier,
        ),
      );
    }
    if (barrierFilter != null) {
      barrier = BackdropFilter(
        filter: barrierFilter!,
        child: barrier,
      );
    }
    barrier = IgnorePointer(
      ignoring: controller.status == AnimationStatus.reverse || controller.status == AnimationStatus.dismissed,
      child: barrier,
    );
    if (barrierDismissible) {
      barrier = Semantics(
        sortKey: const OrdinalSortKey(1.0),
        child: barrier,
      );
    }
    return barrier;
  }

  void _configurePersistent() {
    if (!persistent) {
      _historyEntry = LocalHistoryEntry(onRemove: () {
        assert(!_transitionCompleter.isCompleted, 'Cannot reuse a $runtimeType after disposing it.');
        _removedHistoryEntry = true;
        if (!_dismissed) {
          _cancelTimer();
          _controller.reverse();
        }
      });
      route?.addLocalHistoryEntry(_historyEntry!);
    }
  }

  void _removeLocalHistory() {
    if (!persistent && !_removedHistoryEntry) {
      _historyEntry!.remove();
      _removedHistoryEntry = true;
    }
  }

  void _configureTimer() {
    if (duration != null) {
      if (_timer?.isActive == true) {
        _timer!.cancel();
      }
      _timer = Timer(duration!, () => dismiss());
    } else {
      _timer?.cancel();
    }
  }

  void _cancelTimer() {
    if (_timer?.isActive == true) {
      _timer!.cancel();
    }
  }

  @protected
  @override
  void deactivate() {
    _dismissed = true;
    _removeLocalHistory();
    _cancelTimer();
  }

  @override
  Future<void> dismiss([T? result]) {
    assert(!_transitionCompleter.isCompleted, 'Cannot reuse a $runtimeType after disposing it.');
    _dismissed = true;
    _result = result;
    _removeLocalHistory();
    _cancelTimer();
    return _controller.reverse();
  }

  @protected
  void dispose() {
    assert(!_transitionCompleter.isCompleted, 'Cannot dispose a $runtimeType twice.');
    for (OverlayEntry entry in _overlayEntries) {
      entry.remove();
    }
    _overlayEntries.clear();
    _controller.dispose();
    _transitionCompleter.complete(_result);
  }

  /// A short description of this route useful for debugging.
  String get debugLabel => '$runtimeType';

  @override
  String toString() => '$runtimeType(animation: $_controller)';
}

Future<T?> showModalFlash<T>({
  required BuildContext context,
  required FlashBuilder<T> builder,
  Color? barrierColor = const Color(0x8A000000),
  ImageFilter? barrierFilter,
  bool barrierDismissible = true,
  Curve barrierCurve = Curves.ease,
  String? barrierLabel,
  Duration transitionDuration = const Duration(milliseconds: 250),
  Duration reverseTransitionDuration = const Duration(milliseconds: 200),
  RouteSettings? settings,
  bool useRootNavigator = false,
  Duration? duration,
}) {
  final NavigatorState navigator = Navigator.of(context, rootNavigator: useRootNavigator);
  return navigator.push(ModalFlashRoute<T>(
    builder: builder,
    capturedThemes: InheritedTheme.capture(from: context, to: navigator.context),
    barrierFilter: barrierFilter,
    barrierColor: barrierColor,
    barrierDismissible: barrierDismissible,
    barrierCurve: barrierCurve,
    barrierLabel: barrierLabel,
    transitionDuration: transitionDuration,
    reverseTransitionDuration: reverseTransitionDuration,
    settings: settings,
    duration: duration,
  ));
}

class ModalFlashRoute<T> extends PopupRoute<T> implements FlashController<T> {
  ModalFlashRoute({
    required this.builder,
    this.capturedThemes,
    this.barrierColor = const Color(0x8A000000),
    ImageFilter? barrierFilter,
    this.barrierDismissible = true,
    this.barrierCurve = Curves.ease,
    this.barrierLabel,
    this.transitionDuration = const Duration(milliseconds: 250),
    this.reverseTransitionDuration = const Duration(milliseconds: 200),
    RouteSettings? settings,
    this.duration,
  }) : super(filter: barrierFilter, settings: settings);

  final FlashBuilder<T> builder;

  /// Stores a list of captured [InheritedTheme]s that are wrapped around the flash.
  final CapturedThemes? capturedThemes;

  @override
  final Color? barrierColor;

  @override
  final bool barrierDismissible;

  @override
  final Curve barrierCurve;

  @override
  final String? barrierLabel;

  @override
  final Duration transitionDuration;

  @override
  final Duration reverseTransitionDuration;

  @override
  AnimationController get controller => super.controller!;

  /// How long until route will hide itself (be dismissed). To make it indefinite, leave it null.
  final Duration? duration;
  Timer? _timer;

  void _configureTimer() {
    if (duration != null) {
      if (_timer?.isActive == true) {
        _timer!.cancel();
      }
      _timer = Timer(duration!, () => dismiss());
    } else {
      _timer?.cancel();
    }
  }

  void _cancelTimer() {
    if (_timer?.isActive == true) {
      _timer!.cancel();
    }
  }

  @override
  void install() {
    super.install();
    controller.addStatusListener(_handleStatusChanged);
  }

  void _handleStatusChanged(AnimationStatus status) {
    if (status == AnimationStatus.dismissed && isActive) {
      navigator!.removeRoute(this);
    }
  }

  @override
  Widget buildPage(BuildContext context, Animation<double> animation, Animation<double> secondaryAnimation) {
    return capturedThemes?.wrap(builder(context, this)) ?? builder(context, this);
  }

  @override
  TickerFuture didPush() {
    _configureTimer();
    return super.didPush();
  }

  @override
  bool didPop(T? result) {
    deactivate();
    return super.didPop(result);
  }

  @override
  void deactivate() {
    _cancelTimer();
  }

  @override
  Future<T?> dismiss([T? result]) async {
    if (isCurrent) {
      navigator!.pop(result);
      return completed;
    } else if (isActive) {
      navigator!.removeRoute(this);
    }
    return null;
  }

  @override
  void dispose() {
    controller.removeStatusListener(_handleStatusChanged);
    super.dispose();
  }

  /// A short description of this route useful for debugging.
  @override
  String get debugLabel => objectRuntimeType(this, 'ModalFlashRoute');
}
