import 'dart:async';
import 'dart:ui';

import 'package:flutter/foundation.dart';
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
  double? barrierBlur,
  bool barrierDismissible = false,
  FutureOr<bool> Function()? onBarrierTap,
  Curve barrierCurve = Curves.ease,
  Duration? duration,
  bool persistent = true,
  VoidCallback? onRemoveFromRoute,
}) {
  return DefaultFlashController<T>(
    context,
    builder: builder,
    transitionDuration: transitionDuration,
    reverseTransitionDuration: reverseTransitionDuration,
    barrierColor: barrierColor,
    barrierBlur: barrierBlur,
    barrierDismissible: barrierDismissible,
    onBarrierTap: onBarrierTap,
    barrierCurve: barrierCurve,
    duration: duration,
    persistent: persistent,
    onRemoveFromRoute: onRemoveFromRoute,
  ).show();
}

class DefaultFlashController<T> implements FlashController<T> {
  DefaultFlashController(
    this.context, {
    required this.builder,
    this.transitionDuration = const Duration(milliseconds: 250),
    this.reverseTransitionDuration = const Duration(milliseconds: 200),
    this.barrierColor,
    this.barrierBlur,
    this.barrierDismissible = false,
    this.onBarrierTap,
    this.barrierCurve = Curves.ease,
    this.persistent = true,
    this.onRemoveFromRoute,
    this.duration,
  })  : assert(onBarrierTap == null || (barrierDismissible || barrierColor != null || barrierBlur != null)),
        route = ModalRoute.of(context) {
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

  final double? barrierBlur;

  final bool barrierDismissible;

  /// Called when tap the barrier.
  ///
  /// If the returns that resolves to false, the flash will be dismiss.
  final FutureOr<bool> Function()? onBarrierTap;

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

  /// Called when this flash is removed from the history of its associated [LocalHistoryRoute].
  /// Only works when [persistent] is false.
  final VoidCallback? onRemoveFromRoute;

  /// The animation controller that the route uses to drive the transitions.
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
      if (hasBarrier)
        OverlayEntry(
          builder: (context) => _buildBarrier(context),
        ),
      OverlayEntry(
        builder: (context) => _FlashScope(controller: this, child: builder(context, this)),
        maintainState: true,
      ),
    ];
  }

  bool get hasBarrier => barrierDismissible || barrierColor != null || barrierBlur != null;

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
          onTap: onBarrierTap == null
              ? dismiss
              : () async {
                  if (!await onBarrierTap!()) {
                    dismiss();
                  }
                },
          child: barrier,
        ),
      );
    }
    if (barrierBlur != null) {
      barrier = AnimatedBuilder(
        animation: controller,
        builder: (context, child) {
          final blur = (barrierBlur ?? 0.0) * controller.value;
          return BackdropFilter(
            filter: ImageFilter.blur(sigmaX: blur, sigmaY: blur),
            child: child,
          );
        },
        child: barrier,
      );
    }
    return barrier;
  }

  void _configurePersistent() {
    if (!persistent) {
      _historyEntry = LocalHistoryEntry(onRemove: () {
        assert(!_transitionCompleter.isCompleted, 'Cannot reuse a $runtimeType after disposing it.');
        onRemoveFromRoute?.call();
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
    deactivate();
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

class _FlashScope extends StatefulWidget {
  const _FlashScope({required this.controller, required this.child});

  final DefaultFlashController controller;

  final Widget child;

  @override
  State<_FlashScope> createState() => __FlashScopeState();
}

class __FlashScopeState extends State<_FlashScope> {
  final focusScopeNode = FocusScopeNode(debugLabel: '$__FlashScopeState Focus Scope');

  bool get _shouldIgnoreFocusRequest {
    return widget.controller.controller.status == AnimationStatus.reverse ||
        (widget.controller.route?.navigator?.userGestureInProgress ?? false);
  }

  @override
  void initState() {
    super.initState();
    if (widget.controller.hasBarrier &&
        (widget.controller.route?.isCurrent ?? false) &&
        (widget.controller.route?.navigator!.widget.requestFocus ?? false)) {
      widget.controller.route?.navigator!.focusNode.enclosingScope?.setFirstFocus(focusScopeNode);
    }
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (widget.controller.hasBarrier &&
        (widget.controller.route?.isCurrent ?? false) &&
        (widget.controller.route?.navigator!.widget.requestFocus ?? false)) {
      widget.controller.route?.navigator!.focusNode.enclosingScope?.setFirstFocus(focusScopeNode);
    }
  }

  @override
  Widget build(BuildContext context) => FocusScope(
        node: focusScopeNode,
        child: AnimatedBuilder(
            animation: widget.controller.controller,
            builder: (context, child) {
              final bool ignoreEvents = _shouldIgnoreFocusRequest;
              focusScopeNode.canRequestFocus = !ignoreEvents;
              return child!;
            },
            child: widget.child),
      );
}

Future<T?> showModalFlash<T>({
  required BuildContext context,
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
}) {
  final navigator = Navigator.of(context, rootNavigator: useRootNavigator);
  return navigator.push(ModalFlashRoute<T>(
    builder: builder,
    capturedThemes: InheritedTheme.capture(from: context, to: navigator.context),
    barrierBlur: barrierBlur,
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
    this.barrierBlur,
    this.barrierDismissible = true,
    this.barrierCurve = Curves.ease,
    this.barrierLabel,
    this.transitionDuration = const Duration(milliseconds: 250),
    this.reverseTransitionDuration = const Duration(milliseconds: 200),
    super.settings,
    this.duration,
  });

  final FlashBuilder<T> builder;

  /// Stores a list of captured [InheritedTheme]s that are wrapped around the flash.
  final CapturedThemes? capturedThemes;

  @override
  final Color? barrierColor;

  final double? barrierBlur;

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
  Iterable<OverlayEntry> createOverlayEntries() {
    return [
      OverlayEntry(
        builder: (context) {
          return AnimatedBuilder(
            animation: controller,
            builder: (context, child) {
              final value = controller.value;
              final blur = (barrierBlur ?? 0.0) * value;
              return BackdropFilter(
                filter: ImageFilter.blur(sigmaX: blur, sigmaY: blur),
                child: const SizedBox.expand(),
              );
            },
          );
        },
      ),
      ...super.createOverlayEntries()
    ];
  }

  @override
  Widget buildPage(BuildContext context, Animation<double> animation, Animation<double> secondaryAnimation) {
    final child = Builder(builder: (context) => builder(context, this));
    return capturedThemes?.wrap(child) ?? child;
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
    deactivate();
    controller.removeStatusListener(_handleStatusChanged);
    super.dispose();
  }

  /// A short description of this route useful for debugging.
  @override
  String get debugLabel => objectRuntimeType(this, 'ModalFlashRoute');
}
