import 'package:flutter/foundation.dart';
import 'package:flutter_test/flutter_test.dart';

/// Lets golden images differ in up to [tolerance] (a fraction, 0.0001 =
/// 0.01%) of their pixels, about 40 pixels of a phone-sized screen. That
/// absorbs stray anti-aliasing differences, while even a single changed digit
/// moves more pixels than that and fails.
void useTolerantGoldenComparator({double tolerance = 0.0001}) {
  final previous = goldenFileComparator;
  if (previous is! LocalFileComparator) return;
  goldenFileComparator = _TolerantComparator(
    // LocalFileComparator takes the test file and uses its directory
    previous.basedir.resolve('golden_test.dart'),
    tolerance,
  );
  addTearDown(() => goldenFileComparator = previous);
}

class _TolerantComparator extends LocalFileComparator {
  final double tolerance;
  _TolerantComparator(super.testFile, this.tolerance);

  @override
  Future<bool> compare(Uint8List imageBytes, Uri golden) async {
    final result = await GoldenFileComparator.compareLists(
      imageBytes,
      await getGoldenBytes(golden),
    );
    if (result.passed || result.diffPercent <= tolerance) {
      result.dispose();
      return true;
    }
    final error = await generateFailureOutput(result, golden, basedir);
    result.dispose();
    throw FlutterError(error);
  }
}
