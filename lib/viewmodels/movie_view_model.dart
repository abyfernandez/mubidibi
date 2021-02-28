import 'base_model.dart';
import 'package:mubidibi/services/dialog_service.dart';
import 'package:mubidibi/services/firestore_service.dart';
import 'package:mubidibi/locator.dart';

class MovieViewModel extends BaseModel {
  final DialogService _dialogService = locator<DialogService>();
  final FirestoreService _firestoreService = locator<FirestoreService>();

  Future getMovie() async {
    setBusy(true);

    var result = await _firestoreService.getMovie();
    print(result.first_name);

    setBusy(false);

    if (result is bool) {
      if (result) {
        print("Data retrieval done!");
      } else {
        await _dialogService.showDialog(
          title: 'Data Retrieval Failure',
          description: 'Try again later.',
        );
      }
    } else {
      await _dialogService.showDialog(
        title: 'Data Retrieval Failure',
        description: result,
      );
    }
  }
}
