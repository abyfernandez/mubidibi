import 'package:mubidibi/viewmodels/startup_view_model.dart';
import 'package:flutter/material.dart';
import 'package:provider_architecture/viewmodel_provider.dart';
import 'package:shimmer/shimmer.dart';

class StartUpView extends StatelessWidget {
  const StartUpView({Key key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return ViewModelProvider<StartUpViewModel>.withConsumer(
      viewModel: StartUpViewModel(),
      onModelReady: (model) => model.handleStartUpLogic(),
      builder: (context, model, child) => Scaffold(
        body: Center(
          child: Column(mainAxisSize: MainAxisSize.min, children: <Widget>[
            SizedBox(
              width: 300,
              height: 100,
              child: Center(
                child: Shimmer.fromColors(
                  period: Duration(milliseconds: 500),
                  baseColor: Colors.blue,
                  highlightColor: Colors.red,
                  child: Container(
                    height: 100,
                    alignment: Alignment.center,
                    child: Text(
                      "mubidibi",
                      style: TextStyle(
                        fontSize: 50,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                ),
              ),
            ),
            SizedBox(height: 50),
            CircularProgressIndicator(
                //   strokeWidth: 3,
                //   valueColor: AlwaysStoppedAnimation(Theme.of(context).accentColor),
                ),
          ]),
        ),
      ),
    );
  }
}
