import 'dart:io';
import 'dart:isolate';

void main() async {
  final uri = await Isolate.resolvePackageUri(Uri.parse('package:google_sign_in/google_sign_in.dart'));
  if (uri != null) {
    print('Found at: ${uri.toFilePath()}');
    final file = File(uri.toFilePath());
    if (await file.exists()) {
      print(await file.readAsString());
    }
  } else {
    print('Not found');
  }
}
