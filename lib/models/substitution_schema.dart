import 'package:schemantic/schemantic.dart';

part 'substitution_schema.g.dart';

@Schema(description: 'List of culinary substitutions for missing ingredients')
abstract class $SubstitutionListOutput {
  List<$SubstitutionOutputItem> get substitutions;
}

@Schema(
  description: 'Individual culinary ingredient substitution recommendation',
)
abstract class $SubstitutionOutputItem {
  @Field(
    name: 'original_ingredient',
    description: 'Name of the missing ingredient',
  )
  String get originalIngredient;

  @Field(description: 'Recommended substitute ingredient or combination')
  String get substitute;

  @Field(
    name: 'culinary_tip',
    description: 'Actionable culinary tip on proportions or preparation method',
  )
  String get culinaryTip;

  @Field(description: 'Culinary rationale for why this swap works in the dish')
  String? get rationale;
}
