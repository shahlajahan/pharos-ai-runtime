import 'package:pharos_ai_runtime/hq/hq_source.dart';

class LocalHQSource extends HQSource {
  LocalHQSource(this._path);

  final String _path;

  @override
  Future<String> rootPath() async => _path;
}
