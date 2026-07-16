import 'package:http/http.dart' as http;
import 'package:pharos_ai_runtime/models/model_config.dart';
import 'package:pharos_ai_runtime/models/openai_config.dart';
import 'package:pharos_ai_runtime/models/openai_environment.dart';
import 'package:pharos_ai_runtime/models/openai_provider.dart';
import 'package:pharos_ai_runtime/models/http_openai_client.dart';
import 'package:pharos_ai_runtime/network/package_http_transport.dart';

class OpenAIProviderFactory {
  const OpenAIProviderFactory();

  OpenAIProvider build(OpenAIEnvironment environment) {
    final openAiConfig = OpenAIConfig(
      apiKey: environment.apiKey,
      baseUrl: environment.baseUrl,
      organization: environment.organization,
    );

    final modelConfig = ModelConfig(
      model: environment.model,
      temperature: environment.temperature,
    );

    final transport = PackageHttpTransport(client: http.Client());

    final client = HttpOpenAIClient(transport: transport);

    return OpenAIProvider(
      client: client,
      modelConfig: modelConfig,
      openAiConfig: openAiConfig,
    );
  }
}
