import 'dart:async';

import 'package:flash/flash.dart';
import 'package:flutter/material.dart';
import 'package:flutter/widgets.dart';

class FlashHelper {
  static Completer<BuildContext> _buildCompleter = Completer<BuildContext>();

  static void init(BuildContext context) {
    if (_buildCompleter?.isCompleted == false) {
      _buildCompleter.complete(context);
    }
  }

  static void dispose() {
    if (_buildCompleter?.isCompleted == false) {
      _buildCompleter.completeError(FlutterError('disposed'));
    }
    _buildCompleter = Completer<BuildContext>();
  }

  static Future<T> toast<T>(String message) async {
    var context = await _buildCompleter.future;
    return showFlash<T>(
      context: context,
      duration: const Duration(seconds: 3),
      builder: (context, controller) {
        return Flash.dialog(
          controller: controller,
          alignment: const Alignment(0, 0.5),
          margin: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 8.0),
          borderRadius: const BorderRadius.all(Radius.circular(8.0)),
          enableDrag: false,
          backgroundColor: Colors.black87,
          child: DefaultTextStyle(
            style: const TextStyle(fontSize: 16.0, color: Colors.white),
            child: Padding(
              padding:
                  const EdgeInsets.symmetric(horizontal: 16.0, vertical: 8.0),
              child: Text(message),
            ),
          ),
        );
      },
    );
  }

  static Color _backgroundColor(BuildContext context) {
    var theme = Theme.of(context);
    return theme.dialogTheme?.backgroundColor ?? theme.dialogBackgroundColor;
  }

  static TextStyle _titleStyle(BuildContext context, [Color color]) {
    var theme = Theme.of(context);
    return (theme.dialogTheme?.titleTextStyle ?? theme.textTheme.title)
        .copyWith(color: color);
  }

  static TextStyle _contentStyle(BuildContext context, [Color color]) {
    var theme = Theme.of(context);
    return (theme.dialogTheme?.contentTextStyle ?? theme.textTheme.body1)
        .copyWith(color: color);
  }

  static Future<T> successBar<T>(
    BuildContext context, {
    String title,
    @required String message,
    Duration duration = const Duration(seconds: 3),
  }) {
    return showFlash<T>(
      context: context,
      duration: duration,
      builder: (context, controller) {
        return Flash(
          controller: controller,
          horizontalDismissDirection: HorizontalDismissDirection.horizontal,
          backgroundColor: Colors.black87,
          child: FlashBar(
            title: title == null
                ? null
                : Text(title, style: _titleStyle(context, Colors.white)),
            message: Text(message, style: _contentStyle(context, Colors.white)),
            icon: Icon(Icons.check_circle, color: Colors.green[300]),
            leftBarIndicatorColor: Colors.green[300],
          ),
        );
      },
    );
  }

  static Future<T> informationBar<T>(
    BuildContext context, {
    String title,
    @required String message,
    Duration duration = const Duration(seconds: 3),
  }) {
    return showFlash<T>(
      context: context,
      duration: duration,
      builder: (context, controller) {
        return Flash(
          controller: controller,
          horizontalDismissDirection: HorizontalDismissDirection.horizontal,
          backgroundColor: Colors.black87,
          child: FlashBar(
            title: title == null
                ? null
                : Text(title, style: _titleStyle(context, Colors.white)),
            message: Text(message, style: _contentStyle(context, Colors.white)),
            icon: Icon(Icons.info_outline, color: Colors.blue[300]),
            leftBarIndicatorColor: Colors.blue[300],
          ),
        );
      },
    );
  }

  static Future<T> errorBar<T>(
    BuildContext context, {
    String title,
    @required String message,
    Duration duration = const Duration(seconds: 3),
  }) {
    return showFlash<T>(
      context: context,
      duration: duration,
      builder: (context, controller) {
        return Flash(
          controller: controller,
          horizontalDismissDirection: HorizontalDismissDirection.horizontal,
          backgroundColor: Colors.black87,
          child: FlashBar(
            title: title == null
                ? null
                : Text(title, style: _titleStyle(context, Colors.white)),
            message: Text(message, style: _contentStyle(context, Colors.white)),
            icon: Icon(Icons.warning, color: Colors.red[300]),
            leftBarIndicatorColor: Colors.red[300],
          ),
        );
      },
    );
  }

  static Future<T> actionBar<T>(
    BuildContext context, {
    String title,
    @required String message,
    @required Widget primaryAction,
    @required ActionCallback onPrimaryActionTap,
    Duration duration = const Duration(seconds: 3),
  }) {
    return showFlash<T>(
      context: context,
      duration: duration,
      builder: (context, controller) {
        return Flash(
          controller: controller,
          horizontalDismissDirection: HorizontalDismissDirection.horizontal,
          backgroundColor: Colors.black87,
          child: FlashBar(
            title: title == null
                ? null
                : Text(title, style: _titleStyle(context, Colors.white)),
            message: Text(message, style: _contentStyle(context, Colors.white)),
            primaryAction: FlatButton(
              child: primaryAction,
              onPressed: onPrimaryActionTap == null
                  ? null
                  : () => onPrimaryActionTap(controller),
            ),
          ),
        );
      },
    );
  }

  static Future<T> simpleDialog<T>(
    BuildContext context, {
    String title,
    @required String message,
    Widget negativeAction,
    ActionCallback negativeActionTap,
    Widget positiveAction,
    ActionCallback positiveActionTap,
  }) {
    return showFlash<T>(
      context: context,
      persistent: false,
      builder: (context, controller) {
        return Flash.dialog(
          controller: controller,
          backgroundColor: _backgroundColor(context),
          margin: const EdgeInsets.only(left: 40.0, right: 40.0),
          borderRadius: const BorderRadius.all(Radius.circular(8.0)),
          child: FlashBar(
            title:
                title == null ? null : Text(title, style: _titleStyle(context)),
            message: Text(message, style: _contentStyle(context)),
            actions: <Widget>[
              if (negativeAction != null)
                FlatButton(
                  child: negativeAction,
                  onPressed: negativeActionTap == null
                      ? null
                      : () => negativeActionTap(controller),
                ),
              if (positiveAction != null)
                FlatButton(
                  child: positiveAction,
                  onPressed: positiveActionTap == null
                      ? null
                      : () => positiveActionTap(controller),
                ),
            ],
          ),
        );
      },
    );
  }

  static Future<T> blockDialog<T>(
    BuildContext context, {
    @required Completer<T> dismissCompleter,
  }) {
    return showFlash<T>(
      context: context,
      persistent: false,
      onWillPop: () => Future.value(false),
      builder: (context, FlashController<T> controller) {
        dismissCompleter.future.then((value) => controller.dismiss(value));
        return Flash.dialog(
          controller: controller,
          barrierDismissible: false,
          backgroundColor: Colors.black87,
          margin: const EdgeInsets.only(left: 40.0, right: 40.0),
          borderRadius: const BorderRadius.all(Radius.circular(8.0)),
          child: Padding(
            padding: const EdgeInsets.all(16.0),
            child: const CircularProgressIndicator(strokeWidth: 2.0),
          ),
        );
      },
    );
  }

  static Future<String> inputDialog(
    BuildContext context, {
    String title,
    String message,
    String defaultValue,
    bool persistent = true,
    WillPopCallback onWillPop,
  }) {
    var editingController = TextEditingController(text: defaultValue);
    return showFlash<String>(
      context: context,
      persistent: persistent,
      onWillPop: onWillPop,
      builder: (context, controller) {
        var theme = Theme.of(context);
        return Flash<String>.bar(
          controller: controller,
          barrierColor: Colors.black54,
          borderWidth: 3,
          borderRadius: const BorderRadius.vertical(top: Radius.circular(8.0)),
          child: FlashBar(
            title: title == null
                ? null
                : Text(title, style: TextStyle(fontSize: 24.0)),
            message: message == null ? null : Text(message),
            userInputForm: Form(
              child: TextFormField(
                controller: editingController,
                autofocus: true,
              ),
            ),
            leftBarIndicatorColor: theme.primaryColor,
            primaryAction: IconButton(
              onPressed: () {
                var message = editingController.text;
                controller.dismiss(message);
              },
              icon: Icon(Icons.send, color: theme.colorScheme.secondary),
            ),
          ),
        );
      },
    );
  }
}

typedef ActionCallback = void Function(FlashController controller);
