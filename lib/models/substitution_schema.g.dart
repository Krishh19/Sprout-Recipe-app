// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'substitution_schema.dart';

// **************************************************************************
// SchemaGenerator
// **************************************************************************

base class SubstitutionListOutput {
  /// Creates a [SubstitutionListOutput] from a JSON map.
  factory SubstitutionListOutput.fromJson(Map<String, dynamic> json) =>
      $schema.parse(json);

  SubstitutionListOutput._(this._json);

  SubstitutionListOutput({
    required List<SubstitutionOutputItem> substitutions,
  }) {
    _json = {'substitutions': substitutions.map((e) => e.toJson()).toList()};
  }

  late final Map<String, dynamic> _json;

  /// The JSON schema and type descriptor for [SubstitutionListOutput].
  static const SchemanticType<SubstitutionListOutput> $schema =
      _SubstitutionListOutputTypeFactory();

  List<SubstitutionOutputItem> get substitutions {
    return (_json['substitutions'] as List)
        .map((e) => SubstitutionOutputItem.fromJson(e as Map<String, dynamic>))
        .toList();
  }

  set substitutions(List<SubstitutionOutputItem> value) {
    _json['substitutions'] = value.map((e) => e.toJson()).toList();
  }

  @override
  String toString() {
    return _json.toString();
  }

  /// Serializes this [SubstitutionListOutput] to a JSON map.
  Map<String, dynamic> toJson() {
    return _json;
  }
}

base class _SubstitutionListOutputTypeFactory
    extends SchemanticType<SubstitutionListOutput> {
  const _SubstitutionListOutputTypeFactory();

  @override
  SubstitutionListOutput parse(Object? json) {
    return SubstitutionListOutput._(json as Map<String, dynamic>);
  }

  @override
  JsonSchemaMetadata get schemaMetadata => JsonSchemaMetadata(
    name: 'SubstitutionListOutput',
    definition: <String, Object?>{
      'type': 'object',
      'description': 'List of culinary substitutions for missing ingredients',
      'properties': <String, Object?>{
        'substitutions': <String, Object?>{
          'type': 'array',
          'items': <String, Object?>{
            r'$ref': r'#/$defs/SubstitutionOutputItem',
          },
        },
      },
      'required': ['substitutions'],
    },
    dependencies: [SubstitutionOutputItem.$schema],
  );
}

base class SubstitutionOutputItem {
  /// Creates a [SubstitutionOutputItem] from a JSON map.
  factory SubstitutionOutputItem.fromJson(Map<String, dynamic> json) =>
      $schema.parse(json);

  SubstitutionOutputItem._(this._json);

  SubstitutionOutputItem({
    required String originalIngredient,
    required String substitute,
    required String culinaryTip,
    String? rationale,
  }) {
    _json = {
      'original_ingredient': originalIngredient,
      'substitute': substitute,
      'culinary_tip': culinaryTip,
      'rationale': ?rationale,
    };
  }

  late final Map<String, dynamic> _json;

  /// The JSON schema and type descriptor for [SubstitutionOutputItem].
  static const SchemanticType<SubstitutionOutputItem> $schema =
      _SubstitutionOutputItemTypeFactory();

  String get originalIngredient {
    return _json['original_ingredient'] as String;
  }

  set originalIngredient(String value) {
    _json['original_ingredient'] = value;
  }

  String get substitute {
    return _json['substitute'] as String;
  }

  set substitute(String value) {
    _json['substitute'] = value;
  }

  String get culinaryTip {
    return _json['culinary_tip'] as String;
  }

  set culinaryTip(String value) {
    _json['culinary_tip'] = value;
  }

  String? get rationale {
    return _json['rationale'] as String?;
  }

  set rationale(String? value) {
    if (value == null) {
      _json.remove('rationale');
    } else {
      _json['rationale'] = value;
    }
  }

  @override
  String toString() {
    return _json.toString();
  }

  /// Serializes this [SubstitutionOutputItem] to a JSON map.
  Map<String, dynamic> toJson() {
    return _json;
  }
}

base class _SubstitutionOutputItemTypeFactory
    extends SchemanticType<SubstitutionOutputItem> {
  const _SubstitutionOutputItemTypeFactory();

  @override
  SubstitutionOutputItem parse(Object? json) {
    return SubstitutionOutputItem._(json as Map<String, dynamic>);
  }

  @override
  JsonSchemaMetadata get schemaMetadata => JsonSchemaMetadata(
    name: 'SubstitutionOutputItem',
    definition: <String, Object?>{
      'type': 'object',
      'description':
          'Individual culinary ingredient substitution recommendation',
      'properties': <String, Object?>{
        'original_ingredient': <String, Object?>{
          'type': 'string',
          'description': 'Name of the missing ingredient',
        },
        'substitute': <String, Object?>{
          'type': 'string',
          'description': 'Recommended substitute ingredient or combination',
        },
        'culinary_tip': <String, Object?>{
          'type': 'string',
          'description':
              'Actionable culinary tip on proportions or preparation method',
        },
        'rationale': <String, Object?>{
          'type': 'string',
          'description':
              'Culinary rationale for why this swap works in the dish',
        },
      },
      'required': ['original_ingredient', 'substitute', 'culinary_tip'],
    },
    dependencies: [],
  );
}
