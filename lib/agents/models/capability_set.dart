import 'package:pharos_ai_runtime/agents/models/capability.dart';

/// An immutable collection of Capabilities. Deterministic: no AI, just
/// set membership and ratios.
class CapabilitySet {
  const CapabilitySet(this.capabilities);

  final Set<Capability> capabilities;

  bool contains(Capability capability) => capabilities.contains(capability);

  /// True when every capability in [required] is present in this set.
  bool supports(CapabilitySet required) =>
      required.capabilities.every(capabilities.contains);

  /// The fraction of [required]'s capabilities this set covers,
  /// 0.0-1.0. A [required] set with no capabilities at all is always
  /// fully covered (1.0) — there is nothing to be missing.
  double score(CapabilitySet required) {
    if (required.capabilities.isEmpty) {
      return 1.0;
    }

    final matched = required.capabilities.where(capabilities.contains).length;

    return matched / required.capabilities.length;
  }

  /// The capabilities shared between this set and [other].
  CapabilitySet intersection(CapabilitySet other) =>
      CapabilitySet(capabilities.intersection(other.capabilities));
}
