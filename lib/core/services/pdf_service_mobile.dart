import 'package:pdf/widgets.dart' as pw;
import 'package:printing/printing.dart';

Future<void> printTranscript(pw.Document pdf) async {
  await Printing.layoutPdf(onLayout: (format) async => pdf.save());
}