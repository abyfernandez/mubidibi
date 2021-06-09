// FORM VIEW: (AWARDS)

import 'dart:async';
// import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:modal_progress_hud/modal_progress_hud.dart';
import 'package:mubidibi/models/award.dart';
import 'package:mubidibi/services/authentication_service.dart';
import 'package:mubidibi/services/dialog_service.dart';
import 'package:mubidibi/services/navigation_service.dart';
import 'package:mubidibi/viewmodels/award_view_model.dart';
import 'package:provider_architecture/provider_architecture.dart';
import 'package:mubidibi/locator.dart';
import 'package:mubidibi/ui/shared/shared_styles.dart';
import 'package:mubidibi/ui/widgets/my_stepper.dart';

class AddAward extends StatefulWidget {
  final Award award;

  AddAward({Key key, this.award}) : super(key: key);

  @override
  _AddAwardState createState() => _AddAwardState(award);
}

class _AddAwardState extends State<AddAward> {
  final Award award;

  _AddAwardState(this.award);

  // Local state variables
  bool _saving = false;
  int awardId;
  List<String> category = [];
  List<String> categoryOptions = ['Pelikula', 'Personalidad'];

  // FIELD CONTROLLERS
  final nameController = TextEditingController();
  final descriptionController = TextEditingController();

  // FIELD NODES
  final nameNode = FocusNode();
  final descriptionNode = FocusNode();
  final categoryNode = FocusNode();

  // FORM KEY
  GlobalKey<FormState> _formKey = GlobalKey<FormState>();

  // STEPPER TITLES
  int currentStep = 0;
  List<String> stepperTitle = ["Mga Basic na Detalye", "Review"];
  List<bool> _selected = [false, false];

  // SERVICES
  final AuthenticationService _authenticationService =
      locator<AuthenticationService>();
  final NavigationService _navigationService = locator<NavigationService>();
  final DialogService _dialogService = locator<DialogService>();

  Future<bool> onBackPress() async {
    // used in onwillpopscope function
    var response = await _dialogService.showConfirmationDialog(
        title: "Confirm cancellation",
        cancelTitle: "No",
        confirmationTitle: "Yes",
        description: "Are you sure that you want to close the form?");
    if (response.confirmed == true) {
      await _navigationService.pop();
    }
    return Future.value(false);
  }

  @override
  void initState() {
    super.initState();
  }

  @override
  Widget build(BuildContext context) {
    var currentUser = _authenticationService.currentUser;
    final _scaffoldKey = GlobalKey<ScaffoldState>();

    return ViewModelProvider<AwardViewModel>.withConsumer(
      viewModel: AwardViewModel(),
      onModelReady: (model) async {
        awardId = award?.awardId ?? 0;

        // update controller's text field
        nameController.text = award?.name ?? "";
        descriptionController.text = award?.description ?? "";
        category = award?.category ?? [];
      },
      builder: (context, model, child) => Scaffold(
        key: _scaffoldKey,
        appBar: AppBar(
          iconTheme: IconThemeData(
            color: Colors.black, //change your color here
          ),
          leading: GestureDetector(
            child: Icon(Icons.arrow_back),
            onTap: () async {
              FocusScope.of(context).unfocus();

              var response = await _dialogService.showConfirmationDialog(
                  title: "Confirm cancellation",
                  cancelTitle: "No",
                  confirmationTitle: "Yes",
                  description: "Are you sure that you want to close the form?");
              if (response.confirmed == true) {
                await _navigationService.pop();
              }
            },
          ),
          backgroundColor: Colors.white,
          title: Text(
            "Magdagdag ng Award",
            style: TextStyle(color: Colors.black),
          ),
        ),
        body: WillPopScope(
          onWillPop: onBackPress,
          child: ModalProgressHUD(
            inAsyncCall: _saving,
            child: AnnotatedRegion<SystemUiOverlayStyle>(
              value: SystemUiOverlayStyle.light,
              child: GestureDetector(
                onTap: () => FocusScope.of(context).unfocus(),
                child: Stack(
                  children: <Widget>[
                    Container(
                      height: double.infinity,
                      child: SingleChildScrollView(
                        physics: AlwaysScrollableScrollPhysics(),
                        padding: EdgeInsets.symmetric(
                          horizontal: 30.0,
                        ),
                        child: Column(
                          children: [
                            SizedBox(height: 20),
                            MyStepper(
                              physics: ClampingScrollPhysics(),
                              stepperCircle: [
                                Icons.edit, // Mga Basic na Detalye
                                Icons.grading, // Review
                              ],
                              type: MyStepperType.vertical,
                              currentStep: currentStep,
                              onStepTapped: (step) async {
                                if (currentStep == 0) {
                                  // first step
                                  setState(() {
                                    if (_formKey.currentState.validate()) {
                                      currentStep = step;
                                    }
                                  });
                                } else {
                                  // allow tapping of steps
                                  setState(() => currentStep = step);
                                }
                              },
                              onStepCancel: () => {
                                if (currentStep != 0)
                                  setState(() => --currentStep)
                              }, // else do nothing
                              onStepContinue: () async {
                                if (currentStep + 1 != stepperTitle.length) {
                                  // do not allow user to continue to next step if inputs aren't filled out yet
                                  switch (currentStep) {
                                    case 0: // Mga basic na detalye
                                      setState(() {
                                        if (_formKey.currentState.validate()) {
                                          nameNode.unfocus();
                                          descriptionNode.unfocus();
                                          categoryNode.unfocus();
                                          currentStep++;
                                        }
                                      });
                                      break;
                                  }
                                } else {
                                  // Review
                                  // last step
                                  var confirm = await _dialogService
                                      .showConfirmationDialog(
                                          title: "Confirm Details",
                                          cancelTitle: "No",
                                          confirmationTitle: "Yes",
                                          description:
                                              "Are you sure that you want to continue?");
                                  if (confirm.confirmed == true) {
                                    _saving =
                                        true; // set saving to true to trigger circular progress indicator

                                    final response = await model.addAward(
                                        name: nameController.text,
                                        description: descriptionController.text,
                                        category: category,
                                        addedBy: currentUser.userId,
                                        awardId: awardId);

                                    // when response is returned, stop showing circular progress indicator
                                    if (response != 0) {
                                      _saving =
                                          false; // set saving to false to trigger circular progress indicator
                                      // show success snackbar
                                      _scaffoldKey.currentState.showSnackBar(
                                          mySnackBar(
                                              context,
                                              'Award added successfully.',
                                              Colors.green));

                                      _saving =
                                          true; // set saving to true to trigger circular progress indicator

                                      // get movie using id redirect to detail view using response
                                      var awardRes = await model.getAward(
                                          awardId: response);

                                      if (awardRes != null) {
                                        _saving =
                                            false; // set saving to false to trigger circular progress indicator
                                        Timer(
                                            const Duration(milliseconds: 2000),
                                            () {
                                          // Navigator.pushReplacement(
                                          //   context,
                                          //   MaterialPageRoute(
                                          //     builder: (context) => MovieView(
                                          //         movieId:
                                          //             movie.movieId.toString()),
                                          //   ),
                                          // );
                                        });
                                      }
                                    } else {
                                      _saving =
                                          false; // set saving to false to trigger circular progress indicator
                                      // show error snackbar
                                      _scaffoldKey.currentState.showSnackBar(
                                          mySnackBar(
                                              context,
                                              'Something went wrong. Check your inputs and try again.',
                                              Colors.red));
                                    }
                                  }
                                }
                              },
                              steps: [
                                for (var i = 0; i < stepperTitle.length; i++)
                                  MyStep(
                                    title: Text(
                                      stepperTitle[i],
                                      style: TextStyle(
                                        fontSize: 18,
                                      ),
                                    ),
                                    isActive: i <= currentStep,
                                    state: i == currentStep
                                        ? MyStepState.editing
                                        : i < currentStep
                                            ? MyStepState.complete
                                            : MyStepState.indexed,
                                    content: Container(
                                      width: 300,
                                      child: SingleChildScrollView(
                                        child: getContent(i),
                                      ),
                                    ),
                                  ),
                              ],
                            ),
                          ],
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget getContent(int index) {
    switch (index) {
      case 0: // Mga Basic na Detalye
        return Form(
          key: _formKey,
          child: Container(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                SizedBox(height: 15),
                // AWARD NAME
                Container(
                  child: TextFormField(
                    controller: nameController,
                    autofocus: true,
                    focusNode: nameNode,
                    textCapitalization: TextCapitalization.words,
                    autovalidateMode: AutovalidateMode.onUserInteraction,
                    style: TextStyle(
                      color: Colors.black,
                    ),
                    onFieldSubmitted: (val) {
                      descriptionNode.requestFocus();
                    },
                    decoration: InputDecoration(
                      labelText: "Award *",
                      filled: true,
                      fillColor: Color.fromRGBO(240, 240, 240, 1),
                    ),
                    validator: (value) {
                      if (value.isEmpty || value == null) {
                        return 'Required ang field na ito.';
                      }
                      return null;
                    },
                  ),
                ),
                SizedBox(height: 15),
                // AWARD DESCRIPTION
                Container(
                  decoration:
                      BoxDecoration(borderRadius: BorderRadius.circular(10)),
                  child: TextFormField(
                    controller: descriptionController,
                    focusNode: descriptionNode,
                    textCapitalization: TextCapitalization.sentences,
                    autovalidateMode: AutovalidateMode.onUserInteraction,
                    style: TextStyle(
                      color: Colors.black,
                    ),
                    maxLines: null, // 5
                    decoration: InputDecoration(
                      labelText: "Description",
                      contentPadding: EdgeInsets.all(10),
                      filled: true,
                      fillColor: Color.fromRGBO(240, 240, 240, 1),
                    ),
                    onFieldSubmitted: (val) {
                      descriptionNode.requestFocus();
                      // FocusScope.of(context).unfocus();
                    },
                  ),
                ),
                SizedBox(height: 15),
                // AWARD CATEGORY
                Flexible(
                  child: Container(
                    height: 80,
                    width: 350,
                    decoration: BoxDecoration(
                      color: Color.fromRGBO(240, 240, 240, 1),
                      borderRadius: BorderRadius.circular(5),
                    ),
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.start,
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Padding(
                          padding: EdgeInsets.only(left: 10, top: 10),
                          child:
                              Text('Category', style: TextStyle(fontSize: 12)),
                        ),
                        Container(
                          child: Wrap(
                            children: categoryOptions.map((cat) {
                              var i = categoryOptions.indexOf(cat);
                              return Padding(
                                  padding: EdgeInsets.symmetric(horizontal: 10),
                                  child: FilterChip(
                                    selected: _selected[i],
                                    label: Text(cat,
                                        style: TextStyle(color: Colors.black)),
                                    pressElevation: 5,
                                    showCheckmark: false,
                                    backgroundColor: Colors.white,
                                    selectedColor: Colors.blue[100],
                                    onSelected: (bool selected) {
                                      setState(() {
                                        _selected[i] = selected;
                                        category.contains(cat)
                                            ? category.remove(cat)
                                            : category.add(cat);
                                      });
                                    },
                                  ));
                            }).toList(),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
                Padding(
                  padding: EdgeInsets.only(left: 10, top: 10),
                  child: Container(
                    alignment: Alignment.centerLeft,
                    child: Text(
                      'Pindutin ang mga chip para pumili.',
                      style:
                          TextStyle(fontSize: 14, fontStyle: FontStyle.italic),
                    ),
                  ),
                ),
                SizedBox(height: 15),
              ],
            ),
          ),
        );
      case 1: // Review
        return Container(
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(5),
            color: Color.fromRGBO(240, 240, 240, 1),
          ),
          padding: EdgeInsets.all(10),
          child: Scrollbar(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.start,
              children: [
                // award name
                Container(
                  alignment: Alignment.topLeft,
                  child: Text(
                    "Award: ",
                    style: TextStyle(
                      fontWeight: FontWeight.bold,
                      fontSize: 16,
                    ),
                  ),
                ),
                Container(
                  alignment: Alignment.topLeft,
                  child: Text(
                    nameController.text.trim() != "" ? nameController.text : "",
                    style: TextStyle(
                      fontSize: 16,
                    ),
                  ),
                ),
                // Category
                category.isNotEmpty ? SizedBox(height: 10) : SizedBox(),
                category.isNotEmpty
                    ? Container(
                        alignment: Alignment.topLeft,
                        child: Text("Category: ",
                            style: TextStyle(
                              fontWeight: FontWeight.bold,
                              fontSize: 16,
                            )),
                      )
                    : SizedBox(),
                category.isNotEmpty
                    ? Container(
                        alignment: Alignment.topLeft,
                        child: Wrap(
                            children: category
                                .map<Widget>((str) => Container(
                                      margin: EdgeInsets.only(right: 3),
                                      child: Chip(
                                        label: Text(str),
                                        backgroundColor: Colors.blue[100],
                                      ),
                                    ))
                                .toList()),
                      )
                    : SizedBox(),
                // Description
                descriptionController.text.trim() != ""
                    ? SizedBox(height: 10)
                    : SizedBox(),
                descriptionController.text.trim() != ""
                    ? Container(
                        alignment: Alignment.topLeft,
                        child: Text("Description: ",
                            style: TextStyle(
                              fontWeight: FontWeight.bold,
                              fontSize: 16,
                            )),
                      )
                    : SizedBox(),
                descriptionController.text.trim() != ""
                    ? Container(
                        alignment: Alignment.topLeft,
                        child: Text(
                          descriptionController.text,
                          style: TextStyle(
                            fontSize: 16,
                          ),
                        ),
                      )
                    : SizedBox(),
                SizedBox(height: 10)
              ],
            ),
          ),
        );
    }
    return null;
  }
}
