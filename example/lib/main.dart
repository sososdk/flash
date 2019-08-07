import 'package:flashbar/flashbar.dart';
import 'package:flutter/material.dart';

void main() => runApp(App());

class App extends StatelessWidget {
  // This widget is the root of your application.
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Flashbar Demo',
      theme: ThemeData(
        primarySwatch: Colors.blue,
      ),
      home: HomePage(title: 'Flashbar Demo Home Page'),
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
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(widget.title),
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () {
          Navigator.of(context).push(MaterialPageRoute(builder: (context) {
            return Overlay(
              initialEntries: [
                OverlayEntry(builder: (context) {
                  return FlashbarPage();
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

class FlashbarPage extends StatefulWidget {
  @override
  _FlashbarPageState createState() => _FlashbarPageState();
}

class _FlashbarPageState extends State<FlashbarPage> {
  GlobalKey<ScaffoldState> _key = GlobalKey<ScaffoldState>();

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      key: _key,
      resizeToAvoidBottomInset: false,
      appBar: AppBar(
        title: Text('Flashbar Demo'),
      ),
      body: Container(
        padding: const EdgeInsets.all(16.0),
        width: double.infinity,
        child: Column(
          children: <Widget>[
            Wrap(
              spacing: 8.0,
              crossAxisAlignment: WrapCrossAlignment.center,
              alignment: WrapAlignment.start,
              runAlignment: WrapAlignment.center,
              children: <Widget>[
                RaisedButton(
                  onPressed: () => _showBasicsFlashbar(),
                  child: Text('Basics'),
                ),
                RaisedButton(
                  onPressed: () =>
                      _showBasicsFlashbar(duration: Duration(seconds: 3)),
                  child: Text('Basics with Duration'),
                ),
                RaisedButton(
                  onPressed: () => _showBasicsFlashbar(
                      flashbarStyle: FlashbarStyle.GROUNDED),
                  child: Text('Basics with grounded style'),
                ),
                RaisedButton(
                  onPressed: () => _showTopFlashbar(),
                  child: Text('Show Top'),
                ),
                RaisedButton(
                  onPressed: () => _showBottomFlashbar(),
                  child: Text('Show Bottom'),
                ),
                RaisedButton(
                  onPressed: () => _showInputFlashbar(),
                  child: Text('Show Input'),
                ),
                RaisedButton(
                  onPressed: () => _showInputFlashbar(
                      isPersistent: false,
                      onWillPop: () => Future.value(false)),
                  child: Text('Show Block Input'),
                ),
              ],
            ),
            Spacer(),
            SafeArea(child: Container(), top: false),
          ],
        ),
      ),
      floatingActionButton: Row(
        mainAxisAlignment: MainAxisAlignment.end,
        children: <Widget>[
          FloatingActionButton(
            onPressed: () {
              showDialog(
                  context: context,
                  builder: (_) {
                    return AlertDialog(
                      title: Text('Flashbar'),
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
            },
            heroTag: null,
            child: Icon(Icons.bubble_chart),
          ),
          FloatingActionButton(
            onPressed: () => Navigator.of(context)
                .push(MaterialPageRoute(builder: (context) => NextPage())),
            child: Icon(Icons.navigate_next),
          ),
        ],
      ),
    );
  }

  void _showBasicsFlashbar({
    Duration duration,
    flashbarStyle = FlashbarStyle.FLOATING,
  }) {
    showFlashbar(
      context: context,
      duration: duration,
      builder: (context, controller) {
        return Flashbar(
          controller: controller,
          message: Text('This is a basic flashbar'),
          flashbarStyle: flashbarStyle,
        );
      },
    );
  }

  void _showTopFlashbar() {
    showFlashbar(
      context: context,
      duration: const Duration(seconds: 3),
      isPersistent: false,
      builder: (_, controller) {
        return Flashbar(
          controller: controller,
          title: Text('Title'),
          message: Text('Hello world!'),
          backgroundColor: Colors.white,
          showProgressIndicator: true,
          boxShadows: [BoxShadow(blurRadius: 10)],
          flashbarPosition: FlashbarPosition.TOP,
          flashbarStyle: FlashbarStyle.GROUNDED,
          barrierBlur: 3.0,
          barrierColor: Color(0x66000000),
          barrierDismissible: true,
          primaryAction: FlatButton(
            onPressed: () => controller.dismiss(),
            child: Text('DISMISS', style: TextStyle(color: Colors.amber)),
          ),
        );
      },
    );
  }

  void _showBottomFlashbar() {
    showFlashbar(
      context: context,
      builder: (_, controller) {
        return Flashbar(
          controller: controller,
          title: Text('Hello Flashbar'),
          message: Text('You can put any message of any length here.'),
          margin: const EdgeInsets.only(left: 8.0, right: 8.0, bottom: 34.0),
          borderRadius: BorderRadius.circular(8.0),
          leftBarIndicatorColor: Colors.red,
          borderColor: Colors.blue,
          boxShadows: [BoxShadow(blurRadius: 8)],
          onTap: () => controller.dismiss(),
          forwardAnimationCurve: Curves.easeInCirc,
          reverseAnimationCurve: Curves.bounceIn,
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
        );
      },
    ).then((_) {
      if (_ != null) {
        _showMessage(_.toString());
      }
    });
  }

  void _showInputFlashbar({
    bool isPersistent = true,
    WillPopCallback onWillPop,
  }) {
    var editingController = TextEditingController();
    showFlashbar(
      context: context,
      isPersistent: isPersistent,
      onWillPop: onWillPop,
      builder: (_, controller) {
        return Flashbar(
          controller: controller,
          title: Text('Hello Flashbar'),
          message: Text('You can put any message of any length here.'),
          userInputForm: Form(
            child: TextFormField(
              controller: editingController,
              autofocus: true,
              style: TextStyle(color: Colors.white),
            ),
          ),
          flashbarStyle: FlashbarStyle.GROUNDED,
          leftBarIndicatorColor: Colors.red,
          barrierColor: Colors.black54,
          borderWidth: 3,
          forwardAnimationCurve: Curves.fastLinearToSlowEaseIn,
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
        );
      },
    );
  }

  void _showMessage(String message) {
    showFlashbar(
        context: context,
        duration: Duration(seconds: 3),
        builder: (_, controller) {
          return Flashbar(
            controller: controller,
            flashbarPosition: FlashbarPosition.TOP,
            flashbarStyle: FlashbarStyle.GROUNDED,
            icon: Icon(
              Icons.face,
              size: 36.0,
              color: Colors.white,
            ),
            message: Text(message),
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
