import 'dart:io';
import 'dart:isolate';

void main() async {
  final uri = await Isolate.resolvePackageUri(Uri.parse('package:google_sign_in/google_sign_in.dart'));
  if (uri != null) {
    final lines = File(uri.toFilePath()).readAsLinesSync();
    final startIndex = lines.indexWhere((l) => l.contains('class GoogleSignInClientAuthorization '));
    if (startIndex != -1) {
      print(lines.sublist(startIndex, startIndex + 20).join('\n'));
    }
  }
}
