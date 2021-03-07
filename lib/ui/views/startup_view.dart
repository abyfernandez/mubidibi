import 'package:mubidibi/viewmodels/startup_view_model.dart';
import 'package:flutter/material.dart';
import 'package:provider_architecture/viewmodel_provider.dart';

class StartUpView extends StatelessWidget {
  const StartUpView({Key key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return ViewModelProvider<StartUpViewModel>.withConsumer(
      viewModel: StartUpViewModel(),
      onModelReady: (model) => model.handleStartUpLogic(),
      builder: (context, model, child) => Scaffold(
        backgroundColor: Colors.black,
        body: Center(
          child: Column(mainAxisSize: MainAxisSize.min, children: <Widget>[
            SizedBox(
              width: 300,
              height: 100,
              child: Center(
                child: Text("mubidibi",
                    style: TextStyle(
                        color: Color.fromRGBO(229, 9, 20, 1),
                        fontSize: 50,
                        fontWeight: FontWeight.bold)
                    // fallbackHeight: 100,
                    // fallbackWidth: 300,
                    ),
              ),
            ),
            SizedBox(height: 50),
            CircularProgressIndicator(
                strokeWidth: 3,
                valueColor: AlwaysStoppedAnimation(
                    MediaQuery.of(context).platformBrightness == Brightness.dark
                        ? Theme.of(context).accentColor
                        : Colors.white))
          ]),
        ),
      ),
    );
  }
}
