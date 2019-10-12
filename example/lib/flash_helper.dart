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

  static Future<T> toast<T>(String msg) async {
    var context = await _buildCompleter.future;
    return showFlash<T>(
      context: context,
      duration: Duration(seconds: 3),
      builder: (_, controller) {
        return Flash(
          controller: controller,
          alignment: Alignment(0, 0.5),
          margin: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 8.0),
          borderRadius: BorderRadius.circular(8.0),
          enableDrag: false,
          backgroundColor: Colors.black87,
          child: DefaultTextStyle(
            style: TextStyle(fontSize: 16.0, color: Colors.white),
            child: Padding(
              padding:
                  const EdgeInsets.symmetric(horizontal: 16.0, vertical: 8.0),
              child: Text(msg),
            ),
          ),
        );
      },
    );
  }

  static Future<T> success<T>(BuildContext context) {
    return null;
  }

  static Future<T> information<T>(BuildContext context) {
    return null;
  }

  static Future<T> error<T>(BuildContext context) {
    return null;
  }

  static Future<T> action<T>(BuildContext context) {
    return null;
  }

  static Future<T> simpleDialog<T>(BuildContext context) {
    return null;
  }

  static Future<T> blockDialog<T>(BuildContext context) {
    return null;
  }
}
