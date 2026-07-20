import 'package:pharos_ai_runtime/core/agent.dart';
import 'package:pharos_ai_runtime/core/context.dart';
import 'package:pharos_ai_runtime/core/result.dart';
import 'package:pharos_ai_runtime/models/conversation.dart';
import 'package:pharos_ai_runtime/models/model_request.dart';
import 'package:pharos_ai_runtime/prompts/daily_marketing_prompt.dart';
import 'package:pharos_ai_runtime/registry/company_product.dart';
import 'package:pharos_ai_runtime/registry/company_registry.dart';

const _doubleLine = '══════════════════════════════';
const _productsSectionRule = '--------';
const _productSeparator = '--------------------------------';

class DailyAgent extends Agent {
  @override
  String get id => 'daily';

  @override
  Future<Result> run(ExecutionContext context) async {
    const registry = CompanyRegistry();
    const prompt = DailyMarketingPrompt();
    final products = registry.enabledProducts();

    print(_doubleLine);
    print('PHAROS DAILY REPORT');
    print(_doubleLine);
    print('');
    print('Product');
    print(_productsSectionRule);

    for (var i = 0; i < products.length; i++) {
      if (i > 0) {
        print('');
        print(_productSeparator);
      }

      await _printProductSection(
        context: context,
        product: products[i],
        prompt: prompt,
      );
    }

    return Result.success('Daily report generated successfully.');
  }

  Future<void> _printProductSection({
    required ExecutionContext context,
    required CompanyProduct product,
    required DailyMarketingPrompt prompt,
  }) async {
    print('');
    print(product.name);
    print('');

    final response = await context.modelProvider.generate(
      ModelRequest(
        conversation: Conversation(
          messages: [UserMessage(content: prompt.build(product))],
        ),
      ),
    );

    print(response.text);
  }
}
