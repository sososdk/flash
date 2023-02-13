import 'dart:async';

import 'package:back_button_interceptor/back_button_interceptor.dart';
import 'package:device_preview/device_preview.dart';
import 'package:example/clear_focus.dart';
import 'package:flash/flash.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';

void main() => runApp(
      DevicePreview(
        enabled: kIsWeb,
        builder: (context) => App(),
      ),
    );

class App extends StatefulWidget {
  // This widget is the root of your application.
  @override
  State<StatefulWidget> createState() {
    return _AppState();
  }
}

class _AppState extends State<App> {
  final navigatorKey = GlobalKey<NavigatorState>();

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      builder: (context, _) {
        var child = _!;
        child = DevicePreview.appBuilder(context, _);
        final theme = Theme.of(context);
        final isThemeDark = theme.brightness == Brightness.dark;
        // Wrap with toast.
        child = Toast(child: child, navigatorKey: navigatorKey);
        // Wrap with flash theme
        child = FlashTheme(
          child: child,
          flashBarTheme: isThemeDark
              ? const FlashBarThemeData.dark()
              : const FlashBarThemeData.light(),
          flashDialogTheme: const FlashDialogThemeData(),
        );
        return child;
      },
      locale: DevicePreview.locale(context),
      title: 'Flash Demo',
      theme: ThemeData(
        primarySwatch: Colors.blue,
      ),
      home: HomePage(title: 'Flash Demo Home Page'),
    );
  }
}

class HomePage extends StatefulWidget {
  HomePage({Key? key, required this.title}) : super(key: key);

  final String title;

  @override
  _HomePageState createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> {
  @override
  Widget build(BuildContext context) {
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

  bool onBackPressed(bool stopDefaultButtonEvent, RouteInfo routeInfo) {
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
                          TextButton(
                            onPressed: () => Navigator.pop(context),
                            child: Text('YES'),
                          ),
                          TextButton(
                            onPressed: () => Navigator.pop(context),
                            child: Text('NO'),
                          ),
                        ],
                      );
                    });
              })
        ],
      ),
      body: ClearFocus(
        child: Column(
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
                      ElevatedButton(
                        onPressed: () => _showBasicsFlash(),
                        child: Text('Basics'),
                      ),
                      ElevatedButton(
                        onPressed: () =>
                            _showBasicsFlash(duration: Duration(seconds: 2)),
                        child: Text('Basics | Duration'),
                      ),
                      ElevatedButton(
                        onPressed: () =>
                            _showBasicsFlash(flashStyle: FlashBehavior.fixed),
                        child: Text('Basics | Grounded'),
                      ),
                      Row(children: <Widget>[]),
                      ElevatedButton(
                        onPressed: () => _showTopFlash(),
                        child: Text('Top'),
                      ),
                      ElevatedButton(
                        onPressed: () =>
                            _showTopFlash(style: FlashBehavior.fixed),
                        child: Text('Top | Grounded'),
                      ),
                      Row(children: <Widget>[]),
                      ElevatedButton(
                        onPressed: () => _showBottomFlash(),
                        child: Text('Bottom'),
                      ),
                      ElevatedButton(
                        onPressed: () => _showBottomFlash(
                            margin: const EdgeInsets.only(
                                left: 12.0, right: 12.0, bottom: 34.0)),
                        child: Text('Bottom | Margin'),
                      ),
                      ElevatedButton(
                        onPressed: () => _showBottomFlash(persistent: false),
                        child: Text('Bottom | No Persistent'),
                      ),
                      Row(
                        children: <Widget>[
                          Text('Flash Input'),
                        ],
                      ),
                      ElevatedButton(
                        onPressed: () =>
                            _showInputFlash(barrierColor: Colors.black54),
                        child: Text('Input'),
                      ),
                      ElevatedButton(
                        onPressed: () => _showInputFlash(
                          persistent: false,
                          onWillPop: (_) => Future.value(true),
                        ),
                        child: Text('Input | No Persistent | Will Pop'),
                      ),
                      Row(
                        children: <Widget>[
                          Text('Flash Helper'),
                        ],
                      ),
                      ElevatedButton(
                        onPressed: () => context.showToast(
                            'You can put any message of any length here.'),
                        child: Text('Toast'),
                      ),
                      ElevatedButton(
                        onPressed: () => context.showSuccessBar(
                            content: Text('I succeeded!')),
                        child: Text('Success Bar'),
                      ),
                      ElevatedButton(
                        onPressed: () => context.showInfoBar(
                            content: Text('Place information here!')),
                        child: Text('Information Bar'),
                      ),
                      ElevatedButton(
                        onPressed: () => context.showErrorBar(
                            content: Text('Place error here!')),
                        child: Text('Error Bar'),
                      ),
                      ElevatedButton(
                        onPressed: () => _showDialogFlash(),
                        child: Text('Simple Dialog'),
                      ),
                      ElevatedButton(
                        onPressed: () {
                          var completer = Completer();
                          Future.delayed(Duration(seconds: 5))
                              .then((_) => completer.complete());
                          context.showBlockDialog(
                            dismissCompleter: completer,
                          );
                        },
                        child: Text('Block Dialog'),
                      ),
                      ElevatedButton(
                        onPressed: () {
                          Future.delayed(Duration(seconds: 2),
                              () => _showDialogFlash(persistent: false));
                        },
                        child: Text('Simple Dialog Delay'),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () => Navigator.of(context)
            .push(MaterialPageRoute(builder: (context) => NextPage())),
        child: Icon(Icons.navigate_next),
      ),
    );
  }

  void _showBasicsFlash({
    Duration? duration,
    flashStyle = FlashBehavior.floating,
  }) {
    showFlash(
      context: context,
      duration: duration,
      builder: (context, controller) {
        return Flash(
          controller: controller,
          behavior: flashStyle,
          position: FlashPosition.bottom,
          boxShadows: kElevationToShadow[4],
          horizontalDismissDirection: HorizontalDismissDirection.horizontal,
          child: FlashBar(
            content: Text('This is a basic flash'),
          ),
        );
      },
    );
  }

  void _showTopFlash({FlashBehavior style = FlashBehavior.floating}) {
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
          behavior: style,
          position: FlashPosition.top,
          child: FlashBar(
            title: Text('Title'),
            content: Text('Hello world!'),
            showProgressIndicator: true,
            primaryAction: TextButton(
              onPressed: () => controller.dismiss(),
              child: Text('DISMISS', style: TextStyle(color: Colors.amber)),
            ),
          ),
        );
      },
    );
  }

  void _showBottomFlash({
    bool persistent = true,
    EdgeInsets margin = EdgeInsets.zero,
  }) {
    showFlash(
      context: context,
      persistent: persistent,
      builder: (_, controller) {
        return Flash(
          controller: controller,
          margin: margin,
          behavior: FlashBehavior.fixed,
          position: FlashPosition.bottom,
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
              content: Text('You can put any message of any length here.'),
              indicatorColor: Colors.red,
              icon: Icon(Icons.info_outline),
              primaryAction: TextButton(
                onPressed: () => controller.dismiss(),
                child: Text('DISMISS'),
              ),
              actions: <Widget>[
                TextButton(
                    onPressed: () => controller.dismiss('Yes, I do!'),
                    child: Text('YES')),
                TextButton(
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
    FlashWillPopCallback? onWillPop,
    Color? barrierColor,
  }) {
    var editingController = TextEditingController();
    context.showFlashBar(
      persistent: persistent,
      onWillPop: onWillPop,
      barrierColor: barrierColor,
      borderWidth: 3,
      behavior: FlashBehavior.fixed,
      forwardAnimationCurve: Curves.fastLinearToSlowEaseIn,
      title: Text('Hello Flash'),
      content: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text('You can put any message of any length here.'),
          Form(
            child: TextFormField(
              controller: editingController,
              autofocus: true,
              decoration: InputDecoration(hintText: 'Please input something.'),
            ),
          ),
        ],
      ),
      indicatorColor: Colors.red,
      primaryActionBuilder: (context, controller, _) {
        return IconButton(
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
        );
      },
    );
  }

  void _showDialogFlash({bool persistent = true}) {
    context.showFlashDialog(
        constraints: BoxConstraints(maxWidth: 300),
        persistent: persistent,
        title: Text('Flash Dialog'),
        content: Text(
            '⚡️A highly customizable, powerful and easy-to-use alerting library for Flutter.'),
        negativeActionBuilder: (context, controller, _) {
          return TextButton(
            onPressed: () {
              controller.dismiss();
            },
            child: Text('NO'),
          );
        },
        positiveActionBuilder: (context, controller, _) {
          return TextButton(
              onPressed: () {
                controller.dismiss();
              },
              child: Text('YES'));
        });
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
            behavior: FlashBehavior.fixed,
            child: FlashBar(
              icon: Icon(
                Icons.face,
                size: 36.0,
                color: Colors.black,
              ),
              content: Text(message),
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
