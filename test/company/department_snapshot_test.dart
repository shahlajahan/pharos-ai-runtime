import 'package:pharos_ai_runtime/company/department.dart';
import 'package:pharos_ai_runtime/company/department_context.dart';
import 'package:pharos_ai_runtime/company/department_snapshot.dart';
import 'package:test/test.dart';

DepartmentContext _emptyContext(
  Department department,
  Set<String> relevantCategories,
) => DepartmentContext(
  department: department,
  relevantCategories: relevantCategories,
  company: const [],
  knowledge: const [],
  products: const [],
  assets: const [],
  services: const [],
  websites: const [],
  social: const [],
  analytics: const [],
);

void main() {
  test('fromContext() detects missing data only among relevant categories', () {
    final context = _emptyContext(Department.sales, {
      'Company',
      'Knowledge',
      'Products',
    });

    final snapshot = DepartmentSnapshot.fromContext(context);

    expect(
      snapshot.missingData,
      containsAll(['Company', 'Knowledge', 'Products']),
    );
    expect(snapshot.missingData, isNot(contains('Assets')));
    expect(snapshot.knownData, isEmpty);
  });

  test('fromContext() moves a populated category from missingData to '
      'knownData', () {
    final context = DepartmentContext(
      department: Department.marketing,
      relevantCategories: const {'Company', 'Knowledge', 'Products'},
      company: const ['overview: We build software.'],
      knowledge: const [],
      products: const [],
      assets: const [],
      services: const [],
      websites: const [],
      social: const [],
      analytics: const [],
    );

    final snapshot = DepartmentSnapshot.fromContext(context);

    expect(snapshot.knownData, contains('Company'));
    expect(snapshot.missingData, isNot(contains('Company')));
  });

  test('fromContext() appends department-specific connector gaps to '
      'missingData', () {
    final context = _emptyContext(Department.finance, {'Company', 'Knowledge'});

    final snapshot = DepartmentSnapshot.fromContext(context);

    expect(snapshot.missingData, contains('Revenue'));
    expect(snapshot.missingData, contains('Billing'));
  });

  test('fromContext() generates one blocked item per missing entry', () {
    final context = _emptyContext(Department.operations, {
      'Company',
      'Knowledge',
    });

    final snapshot = DepartmentSnapshot.fromContext(context);

    expect(snapshot.blockedItems, hasLength(snapshot.missingData.length));
    expect(snapshot.blockedItems, everyElement(contains('Operations')));
  });

  test('fromContext() deduplicates facts within each category', () {
    final context = DepartmentContext(
      department: Department.engineering,
      relevantCategories: const {'Company', 'Knowledge', 'Products'},
      company: const [],
      knowledge: const [],
      products: const [
        'petsupo: A pet care marketplace.',
        'petsupo: A pet care marketplace.',
      ],
      assets: const [],
      services: const [],
      websites: const [],
      social: const [],
      analytics: const [],
    );

    final snapshot = DepartmentSnapshot.fromContext(context);

    expect(snapshot.products, ['petsupo: A pet care marketplace.']);
  });

  test('fromContext() generates traceability evidence for every known fact, '
      'tracing it to its category and source document', () {
    final context = DepartmentContext(
      department: Department.marketing,
      relevantCategories: const {'Company', 'Knowledge', 'Products'},
      company: const [],
      knowledge: const [],
      products: const ['petsupo: A pet care marketplace.'],
      assets: const [],
      services: const [],
      websites: const [],
      social: const [],
      analytics: const [],
    );

    final snapshot = DepartmentSnapshot.fromContext(context);

    expect(snapshot.evidence, hasLength(1));
    expect(snapshot.evidence.single.category, 'Products');
    expect(snapshot.evidence.single.source, 'petsupo');
    expect(snapshot.evidence.single.confidence, 'High');
  });

  test('fromContext() is deterministic', () {
    final context = DepartmentContext(
      department: Department.sales,
      relevantCategories: const {'Company', 'Knowledge', 'Products'},
      company: const ['overview: We build software.'],
      knowledge: const [],
      products: const ['petsupo: A pet care marketplace.'],
      assets: const [],
      services: const [],
      websites: const [],
      social: const [],
      analytics: const [],
    );

    final first = DepartmentSnapshot.fromContext(context);
    final second = DepartmentSnapshot.fromContext(context);

    expect(first.knownData, second.knownData);
    expect(first.missingData, second.missingData);
    expect(first.blockedItems, second.blockedItems);
    expect(first.evidence.length, second.evidence.length);
  });
}
