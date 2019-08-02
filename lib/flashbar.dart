library flashbar;

import 'dart:async';
import 'dart:ui';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

const double _minFlingVelocity = 700.0;
const double _closeProgressThreshold = 0.5;

typedef FlashbarBuilder = Widget Function(
    BuildContext context, FlashbarController controller);

Future<T> showFlashbar<T>({
  @required BuildContext context,
  @required FlashbarBuilder builder,
  Duration duration,
  Duration transitionDuration = const Duration(milliseconds: 500),
  bool isPersistent = false,
  WillPopCallback onWillPop,
}) {
  return FlashbarController(
    context,
    builder,
    duration: duration,
    transitionDuration: transitionDuration,
    isPersistent: isPersistent,
    onWillPop: onWillPop,
  ).show();
}

class FlashbarController<T> {
  final OverlayState overlay;
  final ModalRoute route;
  final BuildContext context;
  final FlashbarBuilder builder;

  /// How long until Flashbar will hide itself (be dismissed). To make it indefinite, leave it null.
  final Duration duration;

  /// Use it to speed up or slow down the animation duration
  final Duration transitionDuration;

  /// FIXED: add doc
  final bool isPersistent;

  /// Called to veto attempts by the user to dismiss the enclosing [ModalRoute].
  ///
  /// If the callback returns a Future that resolves to false, the enclosing
  /// route will not be popped.
  final WillPopCallback onWillPop;

  /// The animation controller that the route uses to drive the transitions.
  ///
  /// The animation itself is exposed by the [animation] property.
  AnimationController get controller => _controller;
  AnimationController _controller;
  Timer _timer;
  LocalHistoryEntry _historyEntry;
  bool _dismissed = false;
  bool _removedHistoryEntry = false;

  FlashbarController(
    this.context,
    this.builder, {
    this.duration,
    this.transitionDuration = const Duration(milliseconds: 500),
    this.isPersistent = false,
    this.onWillPop,
  })  : assert(context != null),
        assert(builder != null),
        assert(isPersistent != null),
        overlay = Overlay.of(context),
        route = ModalRoute.of(context) {
    _controller = createAnimationController()
      ..addStatusListener(_handleStatusChanged);
  }

  /// A future that completes when this route is popped off the navigator.
  ///
  /// The future completes with the value given to [Navigator.pop], if any.
  Future<T> get popped => _transitionCompleter.future;
  final Completer<T> _transitionCompleter = Completer<T>();

  List<OverlayEntry> _overlayEntries;
  T _result;

  Future<T> show() {
    assert(!_transitionCompleter.isCompleted,
        'Cannot show a $runtimeType after disposing it.');

    if (onWillPop != null) route?.addScopedWillPopCallback(onWillPop);
    overlay.insertAll(_overlayEntries = _createOverlayEntries());
    _controller.forward();
    _configureTimer();
    _configureLocalHistory();

    return popped;
  }

  /// Called to create the animation controller that will drive the transitions to
  /// this route from the previous one, and back to the previous route from this
  /// one.
  AnimationController createAnimationController() {
    assert(!_transitionCompleter.isCompleted,
        'Cannot reuse a $runtimeType after disposing it.');
    final Duration duration = transitionDuration;
    return AnimationController(
      duration: duration,
      debugLabel: debugLabel,
      vsync: overlay,
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
        // We might still be an active route if a subclass is controlling the
        // the transition and hits the dismissed status. For example, the iOS
        // back gesture drives this animation to the dismissed status before
        // removing the route and disposing it.
        dispose();
        break;
    }
  }

  List<OverlayEntry> _createOverlayEntries() {
    List<OverlayEntry> overlays = [];

    overlays.add(
      OverlayEntry(
          builder: (BuildContext context) {
            return builder(context, this);
          },
          maintainState: false,
          opaque: false),
    );

    return overlays;
  }

  void _configureLocalHistory() {
    if (isPersistent) {
      _historyEntry = LocalHistoryEntry(onRemove: () {
        assert(!_transitionCompleter.isCompleted,
            'Cannot reuse a $runtimeType after disposing it.');
        _removedHistoryEntry = true;
        if (!_dismissed) {
          if (onWillPop != null) route?.removeScopedWillPopCallback(onWillPop);
          _cancelTimer();
          _controller.reverse();
        }
      });
      ModalRoute.of(context).addLocalHistoryEntry(_historyEntry);
    }
  }

  void _removeLocalHistory() {
    if (isPersistent && !_removedHistoryEntry) {
      _historyEntry.remove();
      _removedHistoryEntry = true;
    }
  }

  void _configureTimer() {
    if (duration != null) {
      if (_timer?.isActive == true) {
        _timer.cancel();
      }
      _timer = Timer(duration, () {
        dismiss();
      });
    } else {
      _timer?.cancel();
    }
  }

  void _cancelTimer() {
    if (_timer?.isActive == true) {
      _timer.cancel();
    }
  }

  @protected
  void dismissManual() {
    assert(!_transitionCompleter.isCompleted,
        'Cannot reuse a $runtimeType after disposing it.');
    _dismissed = true;
    if (onWillPop != null) route?.removeScopedWillPopCallback(onWillPop);
    _removeLocalHistory();
    _cancelTimer();
  }

  void dismiss([T result]) {
    assert(!_transitionCompleter.isCompleted,
        'Cannot reuse a $runtimeType after disposing it.');
    _dismissed = true;
    _result = result;
    if (onWillPop != null) route?.removeScopedWillPopCallback(onWillPop);
    _removeLocalHistory();
    _cancelTimer();
    _controller.reverse();
  }

  @protected
  void dispose() {
    assert(!_transitionCompleter.isCompleted,
        'Cannot dispose a $runtimeType twice.');
    for (OverlayEntry entry in _overlayEntries) entry.remove();
    _overlayEntries.clear();
    _controller.dispose();
    _transitionCompleter.complete(_result);
  }

  /// A short description of this route useful for debugging.
  String get debugLabel => '$runtimeType';

  @override
  String toString() => '$runtimeType(animation: $_controller)';
}

/// A highly customizable widget so you can notify your user when you fell like he needs a beautiful explanation.
class Flashbar<T extends Object> extends StatefulWidget {
  Flashbar({
    Key key,
    @required this.controller,
    this.title,
    this.message,
    this.titleText,
    this.messageText,
    this.icon,
    this.shouldIconPulse = true,
    this.margin = const EdgeInsets.all(0.0),
    this.padding = const EdgeInsets.all(16),
    this.borderRadius,
    this.borderColor,
    this.borderWidth = 1.0,
    this.backgroundColor = const Color(0xFF303030),
    this.leftBarIndicatorColor,
    this.boxShadows,
    this.backgroundGradient,
    this.primaryAction,
    this.onTap,
    this.enableDrag = true,
    this.showProgressIndicator = false,
    this.progressIndicatorController,
    this.progressIndicatorBackgroundColor,
    this.progressIndicatorValueColor,
    this.flashbarPosition = FlashbarPosition.BOTTOM,
    this.flashbarStyle = FlashbarStyle.FLOATING,
    this.forwardAnimationCurve = Curves.fastLinearToSlowEaseIn,
    this.reverseAnimationCurve = Curves.fastOutSlowIn,
    this.animationDuration = const Duration(seconds: 1),
    this.overlayBlur,
    this.overlayColor,
    this.userInputForm,
  })  : assert(controller != null),
        super(key: key);

  final FlashbarController controller;

  /// The title displayed to the user
  final String title;

  /// The message displayed to the user.
  final String message;

  /// Replaces [title]. Although this accepts a [Widget], it is meant to receive [Text] or [RichText]
  final Widget titleText;

  /// Replaces [message]. Although this accepts a [Widget], it is meant to receive [Text] or  [RichText]
  final Widget messageText;

  /// Will be ignored if [backgroundGradient] is not null
  final Color backgroundColor;

  /// If not null, shows a left vertical bar to better indicate the humor of the notification.
  /// It is not possible to use it with a [Form] and I do not recommend using it with [LinearProgressIndicator]
  final Color leftBarIndicatorColor;

  /// [boxShadows] The shadows generated by Flashbar. Leave it null if you don't want a shadow.
  /// You can use more than one if you feel the need.
  /// Check (this example)[https://github.com/flutter/flutter/blob/master/packages/flutter/lib/src/material/shadows.dart]
  final List<BoxShadow> boxShadows;

  /// Makes [backgroundColor] be ignored.
  final Gradient backgroundGradient;

  /// You can use any widget here, but I recommend [Icon] or [Image] as indication of what kind
  /// of message you are displaying. Other widgets may break the layout
  final Widget icon;

  /// An option to animate the icon (if present). Defaults to true.
  final bool shouldIconPulse;

  /// A widget if you need an action from the user.
  final Widget primaryAction;

  /// A callback that registers the user's click anywhere. An alternative to [primaryAction]
  final GestureTapCallback onTap;

  /// True if you want to show a [LinearProgressIndicator].
  final bool showProgressIndicator;

  /// An optional [AnimationController] when you want to control the progress of your [LinearProgressIndicator].
  final AnimationController progressIndicatorController;

  /// A [LinearProgressIndicator] configuration parameter.
  final Color progressIndicatorBackgroundColor;

  /// A [LinearProgressIndicator] configuration parameter.
  final Animation<Color> progressIndicatorValueColor;

  /// Determines if the user can swipe to dismiss the bar.
  /// It is recommended that you set [duration] != null if this is false.
  /// If the user swipes to dismiss no value will be returned.
  final bool enableDrag;

  /// Adds a custom margin to Flashbar
  final EdgeInsets margin;

  /// Adds a custom padding to Flashbar
  /// The default follows material design guide line
  final EdgeInsets padding;

  /// Adds a radius to all corners of Flashbar. Best combined with [margin].
  /// I do not recommend using it with [showProgressIndicator] or [leftBarIndicatorColor].
  final BorderRadius borderRadius;

  /// Adds a border to every side of Flashbar
  /// I do not recommend using it with [showProgressIndicator] or [leftBarIndicatorColor].
  final Color borderColor;

  /// Changes the width of the border if [borderColor] is specified
  final double borderWidth;

  /// Flashbar can be based on [FlashbarPosition.TOP] or on [FlashbarPosition.BOTTOM] of your screen.
  /// [FlashbarPosition.BOTTOM] is the default.
  final FlashbarPosition flashbarPosition;

  /// Flashbar can be floating or be grounded to the edge of the screen.
  /// If grounded, I do not recommend using [margin] or [borderRadius]. [FlashbarStyle.FLOATING] is the default
  final FlashbarStyle flashbarStyle;

  /// The [Curve] animation used when show() is called. [Curves.easeOut] is default
  final Curve forwardAnimationCurve;

  /// The [Curve] animation used when dismiss() is called. [Curves.fastOutSlowIn] is default
  final Curve reverseAnimationCurve;

  /// Use it to speed up or slow down the animation duration
  final Duration animationDuration;

  /// Only takes effect if [FlashbarController.isPersistent] is true.
  /// Creates a blurred overlay that prevents the user from interacting with the screen.
  /// The greater the value, the greater the blur.
  final double overlayBlur;

  /// Only takes effect if [FlashbarController.isPersistent] is true.
  /// Make sure you use a color with transparency here e.g. Colors.grey[600].withOpacity(0.2).
  final Color overlayColor;

  /// A [TextFormField] in case you want a simple user input. Every other widget is ignored if this is not null.
  final Form userInputForm;

  @override
  State createState() {
    return _FlashbarState<T>();
  }
}

class _FlashbarState<K extends Object> extends State<Flashbar>
    with TickerProviderStateMixin {
  AnimationController _fadeController;
  Animation<double> _fadeAnimation;

  final Widget _emptyWidget = SizedBox(width: 0.0, height: 0.0);
  final double _initialOpacity = 1.0;
  final double _finalOpacity = 0.4;

  final Duration _pulseAnimationDuration = Duration(seconds: 1);

  bool _isTitlePresent;
  double _messageTopMargin;

  FocusScopeNode _focusNode;
  FocusAttachment _focusAttachment;

  final GlobalKey _childKey = GlobalKey(debugLabel: 'flashbar child');

  double get _childHeight {
    final RenderBox renderBox = _childKey.currentContext.findRenderObject();
    return renderBox.size.height;
  }

  FlashbarController get controller => widget.controller;

  AnimationController get animationController => controller.controller;

  Animation<double> _animation, _slideAnimation;

  bool _isDragging = false;

  @override
  void initState() {
    super.initState();

    assert(
        widget.userInputForm != null ||
            widget.message?.isNotEmpty == true ||
            widget.messageText != null,
        "A message is mandatory if you are not using userInputForm. Set either a message or messageText");

    _isTitlePresent = (widget.title != null || widget.titleText != null);
    _messageTopMargin = _isTitlePresent ? 6.0 : widget.padding.top;

    _configureProgressIndicatorAnimation();

    if (widget.icon != null && widget.shouldIconPulse) {
      _configurePulseAnimation();
      _fadeController?.forward();
    }

    _focusNode = FocusScopeNode();
    _focusAttachment = _focusNode.attach(context);

    animationController.addStatusListener(_handleStatusChanged);
    _slideAnimation = _animation = createAnimation();
  }

  @override
  void dispose() {
    _fadeController?.dispose();

    widget.progressIndicatorController?.removeListener(_progressListener);
    widget.progressIndicatorController?.dispose();

    _focusAttachment.detach();
    _focusNode.dispose();
    super.dispose();
  }

  void _configurePulseAnimation() {
    _fadeController =
        AnimationController(vsync: this, duration: _pulseAnimationDuration);
    _fadeAnimation = Tween(begin: _initialOpacity, end: _finalOpacity).animate(
      CurvedAnimation(
        parent: _fadeController,
        curve: Curves.linear,
      ),
    );

    _fadeController.addStatusListener((status) {
      if (status == AnimationStatus.completed) {
        _fadeController.reverse();
      }
      if (status == AnimationStatus.dismissed) {
        _fadeController.forward();
      }
    });

    _fadeController.forward();
  }

  Function _progressListener;

  void _configureProgressIndicatorAnimation() {
    if (widget.showProgressIndicator &&
        widget.progressIndicatorController != null) {
      _progressListener = () {
        setState(() {});
      };
      widget.progressIndicatorController.addListener(_progressListener);

      _progressAnimation = CurvedAnimation(
          curve: Curves.linear, parent: widget.progressIndicatorController);
    }
  }

  bool get _dismissUnderway =>
      animationController.status == AnimationStatus.reverse;

  @override
  Widget build(BuildContext context) {
    Widget child = _getFlashbar();

    void warpChild() {
      if (widget.enableDrag) {
        child = GestureDetector(
          behavior: HitTestBehavior.opaque,
          onVerticalDragUpdate: _handleDragUpdate,
          onVerticalDragEnd: _handleDragEnd,
          child: child,
          excludeFromSemantics: true,
        );
      }
      child = Material(
        color: widget.backgroundColor,
        type: widget.flashbarStyle == FlashbarStyle.GROUNDED
            ? MaterialType.canvas
            : MaterialType.transparency,
        child: child,
      );
      child = DecoratedBox(
        decoration: BoxDecoration(
          boxShadow: widget.boxShadows,
        ),
        child: child,
      );
    }

    if (widget.flashbarStyle == FlashbarStyle.FLOATING) {
      warpChild();
    }

    child = SafeArea(
      minimum: widget.flashbarPosition == FlashbarPosition.BOTTOM
          ? EdgeInsets.only(bottom: MediaQuery.of(context).viewInsets.bottom)
          : EdgeInsets.only(top: MediaQuery.of(context).viewInsets.top),
      bottom: widget.flashbarPosition == FlashbarPosition.BOTTOM,
      top: widget.flashbarPosition == FlashbarPosition.TOP,
      left: false,
      right: false,
      child: child,
    );

    if (widget.flashbarStyle == FlashbarStyle.GROUNDED) {
      warpChild();
    }

    if (widget.margin != null) {
      child = Padding(
        padding: widget.margin,
        child: child,
      );
    }

    if (widget.flashbarStyle != FlashbarStyle.FLOATING) {
      child = AnnotatedRegion<SystemUiOverlayStyle>(
          child: child,
          value: ThemeData.estimateBrightnessForColor(widget.backgroundColor) ==
                  Brightness.dark
              ? SystemUiOverlayStyle.light
              : SystemUiOverlayStyle.dark);
    }

    child = SlideTransition(
      key: _childKey,
      position: _slideAnimation.drive(widget.flashbarPosition ==
              FlashbarPosition.BOTTOM
          ? Tween<Offset>(begin: const Offset(0.0, 1.0), end: Offset.zero)
          : Tween<Offset>(begin: const Offset(0.0, -1.0), end: Offset.zero)),
      child: child,
    );

    var overlayBlur = widget.overlayBlur;
    var overlayColor = widget.overlayColor;
    child = Semantics(
      focused: false,
      scopesRoute: true,
      explicitChildNodes: true,
      child: Stack(
        children: <Widget>[
          if (controller.isPersistent &&
              (overlayBlur != null || overlayColor != null))
            AnimatedBuilder(
              animation: animationController,
              builder: (context, child) {
                var value = animationController.value;
                overlayBlur ??= 0.0;
                overlayColor ??= Colors.transparent;
                return BackdropFilter(
                  filter: ImageFilter.blur(
                    sigmaX: overlayBlur * value,
                    sigmaY: overlayBlur * value,
                  ),
                  child: Container(
                    constraints: BoxConstraints.expand(),
                    color:
                        overlayColor.withOpacity(overlayColor.opacity * value),
                  ),
                );
              },
            ),
          Align(
            alignment: widget.flashbarPosition == FlashbarPosition.TOP
                ? Alignment.topCenter
                : Alignment.bottomCenter,
            child: child,
          ),
        ],
      ),
    );
    return child;
  }

  Widget _getFlashbar() {
    Widget child = _generateFlashbar();

    if (widget.borderRadius != null) {
      child = ClipRRect(
        borderRadius: widget.borderRadius,
        child: child,
      );
    }

    child = Ink(
      decoration: BoxDecoration(
        color: widget.backgroundColor,
        gradient: widget.backgroundGradient,
        borderRadius: widget.borderRadius,
        border: widget.borderColor != null
            ? Border.all(color: widget.borderColor, width: widget.borderWidth)
            : null,
      ),
      child: child,
    );

    if (widget.onTap != null) {
      child = InkWell(
        onTap: widget.onTap,
        child: child,
      );
    }
    return child;
  }

  CurvedAnimation _progressAnimation;

  Widget _generateFlashbar() {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        widget.showProgressIndicator
            ? LinearProgressIndicator(
                value: widget.progressIndicatorController != null
                    ? _progressAnimation.value
                    : null,
                backgroundColor: widget.progressIndicatorBackgroundColor,
                valueColor: widget.progressIndicatorValueColor,
              )
            : _emptyWidget,
        IntrinsicHeight(
          child: Row(
              mainAxisSize: MainAxisSize.max,
              children: _getAppropriateRowLayout()),
        ),
      ],
    );
  }

  List<Widget> _getAppropriateRowLayout() {
    double buttonRightPadding;
    double iconPadding = 0;
    if (widget.padding.right - 12 < 0) {
      buttonRightPadding = 4;
    } else {
      buttonRightPadding = widget.padding.right - 12;
    }

    if (widget.padding.left > 16.0) {
      iconPadding = widget.padding.left;
    }

    if (widget.icon == null && widget.primaryAction == null) {
      return [
        _buildLeftBarIndicator(),
        Expanded(
          flex: 1,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            mainAxisSize: MainAxisSize.min,
            children: <Widget>[
              (_isTitlePresent)
                  ? Padding(
                      padding: EdgeInsets.only(
                        top: widget.padding.top,
                        left: widget.padding.left,
                        right: widget.padding.right,
                      ),
                      child: _getTitle(),
                    )
                  : _emptyWidget,
              Padding(
                padding: EdgeInsets.only(
                  top: _messageTopMargin,
                  left: widget.padding.left,
                  right: widget.padding.right,
                  bottom: widget.padding.bottom,
                ),
                child: _getMessage(),
              ),
            ],
          ),
        ),
      ];
    } else if (widget.icon != null && widget.primaryAction == null) {
      return <Widget>[
        _buildLeftBarIndicator(),
        ConstrainedBox(
          constraints: BoxConstraints.tightFor(width: 42.0 + iconPadding),
          child: _getIcon(),
        ),
        Expanded(
          flex: 1,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            mainAxisSize: MainAxisSize.min,
            children: <Widget>[
              (_isTitlePresent)
                  ? Padding(
                      padding: EdgeInsets.only(
                        top: widget.padding.top,
                        left: 4.0,
                        right: widget.padding.left,
                      ),
                      child: _getTitle(),
                    )
                  : _emptyWidget,
              Padding(
                padding: EdgeInsets.only(
                  top: _messageTopMargin,
                  left: 4.0,
                  right: widget.padding.right,
                  bottom: widget.padding.bottom,
                ),
                child: _getMessage(),
              ),
            ],
          ),
        ),
      ];
    } else if (widget.icon == null && widget.primaryAction != null) {
      return <Widget>[
        _buildLeftBarIndicator(),
        Expanded(
          flex: 1,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            mainAxisSize: MainAxisSize.min,
            children: <Widget>[
              (_isTitlePresent)
                  ? Padding(
                      padding: EdgeInsets.only(
                        top: widget.padding.top,
                        left: widget.padding.left,
                        right: widget.padding.right,
                      ),
                      child: _getTitle(),
                    )
                  : _emptyWidget,
              Padding(
                padding: EdgeInsets.only(
                  top: _messageTopMargin,
                  left: widget.padding.left,
                  right: 8.0,
                  bottom: widget.padding.bottom,
                ),
                child: _getMessage(),
              ),
            ],
          ),
        ),
        Padding(
          padding: EdgeInsets.only(right: buttonRightPadding),
          child: _getMainActionButton(),
        ),
      ];
    } else {
      return <Widget>[
        _buildLeftBarIndicator(),
        ConstrainedBox(
          constraints: BoxConstraints.tightFor(width: 42.0 + iconPadding),
          child: _getIcon(),
        ),
        Expanded(
          flex: 1,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            mainAxisSize: MainAxisSize.min,
            children: <Widget>[
              (_isTitlePresent)
                  ? Padding(
                      padding: EdgeInsets.only(
                        top: widget.padding.top,
                        left: 4.0,
                        right: 8.0,
                      ),
                      child: _getTitle(),
                    )
                  : _emptyWidget,
              Padding(
                padding: EdgeInsets.only(
                  top: _messageTopMargin,
                  left: 4.0,
                  right: 8.0,
                  bottom: widget.padding.bottom,
                ),
                child: _getMessage(),
              ),
            ],
          ),
        ),
        Padding(
              padding: EdgeInsets.only(right: buttonRightPadding),
              child: _getMainActionButton(),
            ) ??
            _emptyWidget,
      ];
    }
  }

  Widget _getMessage() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: <Widget>[
        if (widget.messageText != null)
          widget.messageText
        else if (widget.message?.isNotEmpty == true)
          _getDefaultNotificationText(),
        if (widget.userInputForm != null)
          FocusScope(
            child: widget.userInputForm,
            node: _focusNode,
            autofocus: true,
          ),
      ],
    );
  }

  Widget _buildLeftBarIndicator() {
    if (widget.leftBarIndicatorColor != null) {
      return Container(
        color: widget.leftBarIndicatorColor,
        width: 5.0,
      );
    } else {
      return _emptyWidget;
    }
  }

  Widget _getIcon() {
    if (widget.icon != null && widget.icon is Icon && widget.shouldIconPulse) {
      return FadeTransition(
        opacity: _fadeAnimation,
        child: widget.icon,
      );
    } else if (widget.icon != null) {
      return widget.icon;
    } else {
      return _emptyWidget;
    }
  }

  Widget _getTitle() {
    return widget.titleText != null
        ? widget.titleText
        : Text(
            widget.title ?? "",
            style: TextStyle(
                fontSize: 16.0,
                color: Colors.white,
                fontWeight: FontWeight.bold),
          );
  }

  Text _getDefaultNotificationText() {
    return Text(
      widget.message,
      style: TextStyle(fontSize: 14.0, color: Colors.white),
    );
  }

  Widget _getMainActionButton() {
    if (widget.primaryAction != null) {
      return widget.primaryAction;
    } else {
      return null;
    }
  }

  /// Called to create the animation that exposes the current progress of
  /// the transition controlled by the animation controller created by
  /// [createAnimationController].
  Animation<double> createAnimation() {
    assert(animationController != null);
    return CurvedAnimation(
      parent: animationController.view,
      curve: widget.forwardAnimationCurve,
      // only the reverseCurve will be used
      reverseCurve: widget.reverseAnimationCurve,
    );
  }

  void _handleDragUpdate(DragUpdateDetails details) {
    assert(widget.enableDrag);
    if (_dismissUnderway) return;
    _isDragging = true;
    if (widget.flashbarPosition == FlashbarPosition.TOP) {
      animationController.value +=
          details.primaryDelta / (_childHeight ?? details.primaryDelta);
    } else {
      animationController.value -=
          details.primaryDelta / (_childHeight ?? details.primaryDelta);
    }
  }

  void _handleDragEnd(DragEndDetails details) {
    assert(widget.enableDrag);
    if (_dismissUnderway) return;
    _isDragging = false;
    if (animationController.status == AnimationStatus.completed) {
      setState(() => _slideAnimation = _animation);
    }
    if (widget.flashbarPosition == FlashbarPosition.TOP &&
        details.velocity.pixelsPerSecond.dy < -_minFlingVelocity) {
      final double flingVelocity =
          details.velocity.pixelsPerSecond.dy / _childHeight;
      if (animationController.value > 0.0) {
        animationController.fling(velocity: flingVelocity);
      }
      controller.dismissManual();
    } else if (widget.flashbarPosition == FlashbarPosition.BOTTOM &&
        details.velocity.pixelsPerSecond.dy > _minFlingVelocity) {
      final double flingVelocity =
          -details.velocity.pixelsPerSecond.dy / _childHeight;
      if (animationController.value > 0.0) {
        animationController.fling(velocity: flingVelocity);
      }
      controller.dismissManual();
    } else if (animationController.value < _closeProgressThreshold) {
      if (animationController.value > 0.0)
        animationController.fling(velocity: -1.0);
      controller.dismissManual();
    } else {
      animationController.forward();
    }
  }

  void _handleStatusChanged(AnimationStatus status) {
    switch (status) {
      case AnimationStatus.completed:
        if (!_isDragging) {
          setState(() => _slideAnimation = _animation);
        }
        break;
      case AnimationStatus.forward:
      case AnimationStatus.reverse:
        if (_isDragging) {
          setState(() => _slideAnimation = animationController);
        }
        break;
      case AnimationStatus.dismissed:
        break;
    }
  }
}

/// Indicates if flashbar is going to start at the [TOP] or at the [BOTTOM]
enum FlashbarPosition { TOP, BOTTOM }

/// Indicates if flashbar will be attached to the edge of the screen or not
enum FlashbarStyle { FLOATING, GROUNDED }
