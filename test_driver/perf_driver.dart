import 'package:integration_test/integration_test_driver.dart';

/// Writes each `watchPerformance` report of the scroll test to
/// `build/<report>.json` and prints a summary.
Future<void> main() {
  return integrationDriver(
    responseDataCallback: (data) async {
      if (data == null) return;
      for (final MapEntry(:key, :value) in data.entries) {
        await writeResponseData(
          value as Map<String, dynamic>,
          testOutputFilename: key,
          destinationDirectory: 'build',
        );
        final summary = value;
        // ignore: avoid_print
        print(
          '$key: frames=${summary['frame_count']} '
          'build avg=${summary['average_frame_build_time_millis']}ms '
          'p90=${summary['90th_percentile_frame_build_time_millis']}ms '
          'p99=${summary['99th_percentile_frame_build_time_millis']}ms '
          'worst=${summary['worst_frame_build_time_millis']}ms '
          'missed=${summary['missed_frame_build_budget_count']} | '
          'raster avg=${summary['average_frame_rasterizer_time_millis']}ms '
          'p90=${summary['90th_percentile_frame_rasterizer_time_millis']}ms '
          'p99=${summary['99th_percentile_frame_rasterizer_time_millis']}ms '
          'worst=${summary['worst_frame_rasterizer_time_millis']}ms '
          'missed=${summary['missed_frame_rasterizer_budget_count']}',
        );
      }
    },
  );
}
