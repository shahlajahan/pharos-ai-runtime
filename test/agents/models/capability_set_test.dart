import 'package:pharos_ai_runtime/agents/models/capability.dart';
import 'package:pharos_ai_runtime/agents/models/capability_set.dart';
import 'package:test/test.dart';

void main() {
  test('contains() reflects membership', () {
    final set = CapabilitySet({const Capability('image-generation')});

    expect(set.contains(const Capability('image-generation')), isTrue);
    expect(set.contains(const Capability('copywriting')), isFalse);
  });

  test('supports() is true only when every required capability is present', () {
    final set = CapabilitySet({
      const Capability('image-generation'),
      const Capability('creative-design'),
    });
    final required = CapabilitySet({const Capability('image-generation')});
    final unmet = CapabilitySet({const Capability('legal-review')});

    expect(set.supports(required), isTrue);
    expect(set.supports(unmet), isFalse);
  });

  test('score() is 1.0 when every required capability is covered', () {
    final set = CapabilitySet({
      const Capability('image-generation'),
      const Capability('creative-design'),
    });
    final required = CapabilitySet({
      const Capability('image-generation'),
      const Capability('creative-design'),
    });

    expect(set.score(required), 1.0);
  });

  test('score() is the fraction of required capabilities covered', () {
    final set = CapabilitySet({const Capability('creative-design')});
    final required = CapabilitySet({
      const Capability('image-generation'),
      const Capability('creative-design'),
    });

    expect(set.score(required), 0.5);
  });

  test('score() is 0.0 when none of the required capabilities are covered', () {
    final set = CapabilitySet({const Capability('legal-review')});
    final required = CapabilitySet({const Capability('image-generation')});

    expect(set.score(required), 0.0);
  });

  test('score() is 1.0 for an empty required set — nothing to be missing', () {
    const set = CapabilitySet({});
    const required = CapabilitySet({});

    expect(set.score(required), 1.0);
  });

  test('intersection() returns only the shared capabilities', () {
    final a = CapabilitySet({
      const Capability('image-generation'),
      const Capability('creative-design'),
    });
    final b = CapabilitySet({
      const Capability('creative-design'),
      const Capability('copywriting'),
    });

    expect(a.intersection(b).capabilities, {
      const Capability('creative-design'),
    });
  });
}
