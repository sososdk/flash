import 'package:flashbar/flashbar.dart';
import 'package:flutter/material.dart';

void main() => runApp(MyApp());

class MyApp extends StatelessWidget {
  // This widget is the root of your application.
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Flashbar Demo',
      theme: ThemeData(
        primarySwatch: Colors.blue,
      ),
      home: MyHomePage(title: 'Flashbar Demo Home Page'),
    );
  }
}

class MyHomePage extends StatefulWidget {
  MyHomePage({Key key, this.title}) : super(key: key);

  final String title;

  @override
  _MyHomePageState createState() => _MyHomePageState();
}

class _MyHomePageState extends State<MyHomePage> {
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(widget.title),
      ),
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: <Widget>[
            RaisedButton(
                child: Text('Flashbar >'),
                onPressed: () {
                  Navigator.of(context)
                      .push(MaterialPageRoute(builder: (context) {
                    return FlashbarPage();
                  }));
                }),
          ],
        ),
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
        width: double.infinity,
        child: Column(
          children: <Widget>[
            Wrap(
              spacing: 8.0,
              crossAxisAlignment: WrapCrossAlignment.center,
              alignment: WrapAlignment.spaceBetween,
              runAlignment: WrapAlignment.center,
              children: <Widget>[
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
              ],
            ),
            Spacer(),
            Wrap(
              spacing: 8.0,
              children: <Widget>[
                RaisedButton(
                  onPressed: () => _showInputFlashbar(),
                  child: Text('Show Input'),
                ),
              ],
            ),
            SafeArea(child: Container(), top: false),
          ],
        ),
      ),
    );
  }

  void _showTopFlashbar() {
    showFlashbar(
      context: context,
      duration: const Duration(seconds: 3),
      isPersistent: true,
      builder: (_, controller) {
        return Flashbar(
          controller: controller,
          titleText: Text(
            'Title',
            style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16.0),
          ),
          messageText: Text('Hello world!'),
          backgroundColor: Colors.white,
          showProgressIndicator: true,
          boxShadows: [BoxShadow(blurRadius: 10)],
          flashbarPosition: FlashbarPosition.TOP,
          flashbarStyle: FlashbarStyle.GROUNDED,
          overlayBlur: 3.0,
          overlayColor: Color(0x99000000),
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
      isPersistent: true,
      onWillPop: () => Future.value(false),
      builder: (_, controller) {
        return Flashbar(
          controller: controller,
          title: 'Title',
          message: 'Hello world!',
          margin: const EdgeInsets.only(left: 8.0, right: 8.0, bottom: 34.0),
          borderRadius: BorderRadius.circular(8.0),
          leftBarIndicatorColor: Colors.red,
          borderColor: Colors.blue,
          boxShadows: [BoxShadow(blurRadius: 8)],
          onTap: () => controller.dismiss(),
          forwardAnimationCurve: Curves.easeInCirc,
          reverseAnimationCurve: Curves.bounceIn,
          primaryAction: FlatButton(
              onPressed: () => controller.dismiss(),
              child: Text('DISMISS', style: TextStyle(color: Colors.amber))),
        );
      },
    );
  }

  void _showInputFlashbar() {
    var editingController = TextEditingController();
    showFlashbar(
      context: context,
      builder: (_, controller) {
        return Flashbar(
          controller: controller,
          title: 'Title',
          message: 'Hello world!',
          userInputForm: Form(
            child: TextFormField(
              controller: editingController,
              autofocus: true,
              style: TextStyle(color: Colors.white),
            ),
          ),
          flashbarStyle: FlashbarStyle.GROUNDED,
          leftBarIndicatorColor: Colors.red,
          borderWidth: 3,
          forwardAnimationCurve: Curves.fastLinearToSlowEaseIn,
          primaryAction: IconButton(
            onPressed: () {
              if (editingController.text.isEmpty) {
                controller.dismiss();
              } else {
                var message = editingController.text;
                print('message: $message');
                showFlashbar(
                    context: context,
                    duration: Duration(seconds: 2),
                    builder: (_, controller) {
                      return Flashbar(
                        controller: controller,
                        flashbarPosition: FlashbarPosition.TOP,
                        flashbarStyle: FlashbarStyle.GROUNDED,
                        icon: Icon(
                          Icons.face,
                          color: Colors.white,
                        ),
                        message: message,
                      );
                    });
                editingController.text = '';
              }
            },
            icon: Icon(Icons.send, color: Colors.amber),
          ),
        );
      },
    );
  }

  void _showInputBlockFlashbar() {}
}
