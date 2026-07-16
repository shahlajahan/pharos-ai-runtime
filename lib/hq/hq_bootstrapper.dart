import 'package:pharos_ai_runtime/hq/hq_boot_result.dart';
import 'package:pharos_ai_runtime/hq/hq_source.dart';

abstract class HQBootstrapper {
  Future<HQBootResult> boot(HQSource source);
}
