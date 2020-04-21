import 'dart:async';

import 'package:back_button_interceptor/back_button_interceptor.dart';
import 'package:example/flash_helper.dart';
import 'package:flash/flash.dart';
import 'package:flutter/material.dart';

void main() => runApp(App());

class App extends StatelessWidget {
  // This widget is the root of your application.
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Flash Demo',
      theme: ThemeData(
        primarySwatch: Colors.blue,
      ),
      home: HomePage(title: 'Flash Demo Home Page'),
    );
  }
}

class HomePage extends StatefulWidget {
  HomePage({Key key, this.title}) : super(key: key);

  final String title;

  @override
  _HomePageState createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> {
  @override
  void dispose() {
    FlashHelper.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    FlashHelper.init(context);

    return Scaffold(
      appBar: AppBar(
        title: Text(widget.title),
      ),
      body: Container(
        padding: const EdgeInsets.all(16.0),
        child: Center(
          child: Text(
            '⚡️A highly customizable, powerful and easy-to-use alerting library for Flutter.',
            style: TextStyle(fontSize: 18.0, wordSpacing: 5.0),
            textAlign: TextAlign.center,
          ),
        ),
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () {
          Navigator.of(context).push(MaterialPageRoute(builder: (context) {
            return Overlay(
              initialEntries: [
                OverlayEntry(builder: (context) {
                  return FlashPage();
                }),
              ],
            );
          }));
        },
        child: Icon(Icons.navigate_next),
      ),
    );
  }
}

class FlashPage extends StatefulWidget {
  @override
  _FlashPageState createState() => _FlashPageState();
}

class _FlashPageState extends State<FlashPage> {
  GlobalKey<ScaffoldState> _key = GlobalKey<ScaffoldState>();

  @override
  void initState() {
    super.initState();
    BackButtonInterceptor.add(onBackPressed);
  }

  @override
  void dispose() {
    BackButtonInterceptor.remove(onBackPressed);
    super.dispose();
  }

  bool onBackPressed(bool stopDefaultButtonEvent) {
    // Handle android back event here. WillPopScope is not recommended.
    return false;
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      key: _key,
      appBar: AppBar(
        title: Text('Flash Demo'),
        actions: <Widget>[
          IconButton(
              icon: Icon(Icons.info_outline),
              onPressed: () {
                showDialog(
                    context: context,
                    builder: (_) {
                      return AlertDialog(
                        title: Text('Flash'),
                        content: Text(
                            '⚡️A highly customizable, powerful and easy-to-use alerting library for Flutter.'),
                        actions: <Widget>[
                          FlatButton(
                            onPressed: () => Navigator.pop(context),
                            child: Text('YES'),
                          ),
                          FlatButton(
                            onPressed: () => Navigator.pop(context),
                            child: Text('NO'),
                          ),
                        ],
                      );
                    });
              })
        ],
      ),
      body: Column(
        children: <Widget>[
          TextField(
            decoration: InputDecoration(
              hintText: 'Test FocusScopeNode',
              contentPadding: const EdgeInsets.symmetric(horizontal: 16.0),
            ),
          ),
          Expanded(
            child: ListView(
              padding: const EdgeInsets.all(16.0),
              physics: AlwaysScrollableScrollPhysics(),
              children: [
                Wrap(
                  spacing: 8.0,
                  crossAxisAlignment: WrapCrossAlignment.center,
                  alignment: WrapAlignment.start,
                  runAlignment: WrapAlignment.center,
                  children: <Widget>[
                    Row(
                      children: <Widget>[
                        Text('FlashBar'),
                      ],
                    ),
                    RaisedButton(
                      onPressed: () => _showBasicsFlash(),
                      child: Text('Basics'),
                    ),
                    RaisedButton(
                      onPressed: () =>
                          _showBasicsFlash(duration: Duration(seconds: 2)),
                      child: Text('Basics | Duration'),
                    ),
                    RaisedButton(
                      onPressed: () =>
                          _showBasicsFlash(flashStyle: FlashStyle.grounded),
                      child: Text('Basics | Grounded'),
                    ),
                    Row(children: <Widget>[]),
                    RaisedButton(
                      onPressed: () => _showTopFlash(),
                      child: Text('Top'),
                    ),
                    RaisedButton(
                      onPressed: () =>
                          _showTopFlash(style: FlashStyle.grounded),
                      child: Text('Top | Grounded'),
                    ),
                    Row(children: <Widget>[]),
                    RaisedButton(
                      onPressed: () => _showBottomFlash(),
                      child: Text('Bottom'),
                    ),
                    RaisedButton(
                      onPressed: () => _showBottomFlash(
                          margin: const EdgeInsets.only(
                              left: 12.0, right: 12.0, bottom: 34.0)),
                      child: Text('Bottom | Margin'),
                    ),
                    RaisedButton(
                      onPressed: () => _showBottomFlash(persistent: false),
                      child: Text('Bottom | No Persistent'),
                    ),
                    Row(
                      children: <Widget>[
                        Text('FLash Input'),
                      ],
                    ),
                    RaisedButton(
                      onPressed: () => _showInputFlash(),
                      child: Text('Input'),
                    ),
                    RaisedButton(
                      onPressed: () => _showInputFlash(
                        persistent: false,
                        onWillPop: () => Future.value(true),
                      ),
                      child: Text('Input | No Persistent | Will Pop'),
                    ),
                    Row(
                      children: <Widget>[
                        Text('Flash Toast'),
                      ],
                    ),
                    RaisedButton(
                      onPressed: () => _showCenterFlash(
                          position: FlashPosition.top,
                          style: FlashStyle.floating),
                      child: Text('Top'),
                    ),
                    RaisedButton(
                      onPressed: () =>
                          _showCenterFlash(alignment: Alignment.center),
                      child: Text('Center'),
                    ),
                    RaisedButton(
                      onPressed: () => _showCenterFlash(
                          position: FlashPosition.bottom,
                          style: FlashStyle.floating),
                      child: Text('Bottom'),
                    ),
                    Row(
                      children: <Widget>[
                        Text('FLash Helper'),
                      ],
                    ),
                    RaisedButton(
                      onPressed: () => FlashHelper.toast(
                          'You can put any message of any length here.'),
                      child: Text('Toast'),
                    ),
                    RaisedButton(
                      onPressed: () => FlashHelper.successBar(context,
                          message: 'I succeeded!'),
                      child: Text('Success Bar'),
                    ),
                    RaisedButton(
                      onPressed: () => FlashHelper.informationBar(context,
                          message: 'Place information here!'),
                      child: Text('Information Bar'),
                    ),
                    RaisedButton(
                      onPressed: () => FlashHelper.errorBar(context,
                          message: 'Place error here!'),
                      child: Text('Error Bar'),
                    ),
                    RaisedButton(
                      onPressed: () => FlashHelper.actionBar(context,
                          message: 'Place error here!',
                          primaryAction: Text('Done'),
                          onPrimaryActionTap: (controller) =>
                              controller.dismiss()),
                      child: Text('Action Bar'),
                    ),
                    RaisedButton(
                      onPressed: () => _showDialogFlash(),
                      child: Text('Simple Dialog'),
                    ),
                    RaisedButton(
                      onPressed: () {
                        var completer = Completer();
                        Future.delayed(Duration(seconds: 5))
                            .then((_) => completer.complete());
                        FlashHelper.blockDialog(
                          context,
                          dismissCompleter: completer,
                        );
                      },
                      child: Text('Block Dialog'),
                    ),
                    RaisedButton(
                      onPressed: () {
                        Future.delayed(
                            Duration(seconds: 2), () => _showDialogFlash());
                      },
                      child: Text('Simple Dialog Delay'),
                    ),
                    RaisedButton(
                      onPressed: () {
                        FlashHelper.inputDialog(context,
                                persistent: false,
                                title: 'Hello Flash',
                                message:
                                    'You can put any message of any length here.')
                            .then((value) {
                          if (value != null) _showMessage(value);
                        });
                      },
                      child: Text('Input Dialog'),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () => Navigator.of(context)
            .push(MaterialPageRoute(builder: (context) => NextPage())),
        child: Icon(Icons.navigate_next),
      ),
    );
  }

  void _showBasicsFlash({
    Duration duration,
    flashStyle = FlashStyle.floating,
  }) {
    showFlash(
      context: context,
      duration: duration,
      builder: (context, controller) {
        return Flash(
          controller: controller,
          style: flashStyle,
          boxShadows: kElevationToShadow[4],
          horizontalDismissDirection: HorizontalDismissDirection.horizontal,
          child: FlashBar(
            message: Text('This is a basic flash'),
          ),
        );
      },
    );
  }

  void _showTopFlash({FlashStyle style = FlashStyle.floating}) {
    showFlash(
      context: context,
      duration: const Duration(seconds: 2),
      persistent: false,
      builder: (_, controller) {
        return Flash(
          controller: controller,
          backgroundColor: Colors.white,
          brightness: Brightness.light,
          boxShadows: [BoxShadow(blurRadius: 4)],
          barrierBlur: 3.0,
          barrierColor: Colors.black38,
          barrierDismissible: true,
          style: style,
          position: FlashPosition.top,
          child: FlashBar(
            title: Text('Title'),
            message: Text('Hello world!'),
            showProgressIndicator: true,
            primaryAction: FlatButton(
              onPressed: () => controller.dismiss(),
              child: Text('DISMISS', style: TextStyle(color: Colors.amber)),
            ),
          ),
        );
      },
    );
  }

  void _showBottomFlash(
      {bool persistent = true, EdgeInsets margin = EdgeInsets.zero}) {
    showFlash(
      context: context,
      persistent: persistent,
      builder: (_, controller) {
        return Flash(
          controller: controller,
          margin: margin,
          borderRadius: BorderRadius.circular(8.0),
          borderColor: Colors.blue,
          boxShadows: kElevationToShadow[8],
          backgroundGradient: RadialGradient(
            colors: [Colors.amber, Colors.black87],
            center: Alignment.topLeft,
            radius: 2,
          ),
          onTap: () => controller.dismiss(),
          forwardAnimationCurve: Curves.easeInCirc,
          reverseAnimationCurve: Curves.bounceIn,
          child: DefaultTextStyle(
            style: TextStyle(color: Colors.white),
            child: FlashBar(
              title: Text('Hello Flash'),
              message: Text('You can put any message of any length here.'),
              leftBarIndicatorColor: Colors.red,
              icon: Icon(Icons.info_outline),
              primaryAction: FlatButton(
                onPressed: () => controller.dismiss(),
                child: Text('DISMISS'),
              ),
              actions: <Widget>[
                FlatButton(
                    onPressed: () => controller.dismiss('Yes, I do!'),
                    child: Text('YES')),
                FlatButton(
                    onPressed: () => controller.dismiss('No, I do not!'),
                    child: Text('NO')),
              ],
            ),
          ),
        );
      },
    ).then((_) {
      if (_ != null) {
        _showMessage(_.toString());
      }
    });
  }

  void _showInputFlash({
    bool persistent = true,
    WillPopCallback onWillPop,
  }) {
    var editingController = TextEditingController();
    showFlash(
      context: context,
      persistent: persistent,
      onWillPop: onWillPop,
      builder: (_, controller) {
        return Flash.bar(
          controller: controller,
          barrierColor: Colors.black54,
          borderWidth: 3,
          style: FlashStyle.grounded,
          forwardAnimationCurve: Curves.fastLinearToSlowEaseIn,
          child: FlashBar(
            title: Text('Hello Flash', style: TextStyle(fontSize: 24.0)),
            message: Column(
              children: [
                Text('You can put any message of any length here.'),
                Form(
                  child: TextFormField(
                    controller: editingController,
                    autofocus: true,
                  ),
                ),
              ],
            ),
            leftBarIndicatorColor: Colors.red,
            primaryAction: IconButton(
              onPressed: () {
                if (editingController.text.isEmpty) {
                  controller.dismiss();
                } else {
                  var message = editingController.text;
                  _showMessage(message);
                  editingController.text = '';
                }
              },
              icon: Icon(Icons.send, color: Colors.amber),
            ),
          ),
        );
      },
    );
  }

  void _showCenterFlash({
    FlashPosition position,
    FlashStyle style,
    Alignment alignment,
  }) {
    showFlash(
      context: context,
      duration: Duration(seconds: 5),
      builder: (_, controller) {
        return Flash(
          controller: controller,
          backgroundColor: Colors.black87,
          borderRadius: BorderRadius.circular(8.0),
          borderColor: Colors.blue,
          position: position,
          style: style,
          alignment: alignment,
          enableDrag: false,
          onTap: () => controller.dismiss(),
          child: Padding(
            padding: const EdgeInsets.all(12.0),
            child: DefaultTextStyle(
              style: TextStyle(color: Colors.white),
              child: Text(
                'You can put any message of any length here.',
              ),
            ),
          ),
        );
      },
    ).then((_) {
      if (_ != null) {
        _showMessage(_.toString());
      }
    });
  }

  void _showDialogFlash() {
    FlashHelper.simpleDialog(context,
        title: 'Flash Dialog',
        message:
            '⚡️A highly customizable, powerful and easy-to-use alerting library for Flutter.',
        negativeAction: Text('NO'),
        negativeActionTap: (controller) => controller.dismiss(),
        positiveAction: Text('YES'),
        positiveActionTap: (controller) => controller.dismiss());
  }

  void _showMessage(String message) {
    if (!mounted) return;
    showFlash(
        context: context,
        duration: Duration(seconds: 3),
        builder: (_, controller) {
          return Flash(
            controller: controller,
            position: FlashPosition.top,
            style: FlashStyle.grounded,
            child: FlashBar(
              icon: Icon(
                Icons.face,
                size: 36.0,
                color: Colors.black,
              ),
              message: Text(message),
            ),
          );
        });
  }
}

class NextPage extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(),
      body: Container(color: Colors.blueGrey),
    );
  }
}
