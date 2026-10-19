import '../../core/config.dart';
import '../models/substitution_model.dart';
import '../services/groq_service.dart';
import 'gemini_substitution_service.dart';
import 'genkit_substitution_service.dart';
import 'groq_substitution_service.dart';

export 'gemini_substitution_service.dart';
export 'genkit_substitution_service.dart';
export 'groq_substitution_service.dart';

/// Abstract service contract for AI-powered and offline culinary substitutions.
abstract class SubstitutionService {
  /// Factory constructor routing to Groq, Genkit, or legacy Gemini based on availability
  factory SubstitutionService({bool? useGenkit}) {
    if (GroqService().isAvailable) {
      return GroqSubstitutionService();
    }
    final shouldUseGenkit = useGenkit ?? AppConfig.useGenkitSubstitutions;
    if (shouldUseGenkit) {
      return GenkitSubstitutionService();
    }
    return GeminiSubstitutionService();
  }

  /// Fetches intelligent culinary substitutions for missing ingredients
  Future<List<SubstitutionModel>> getSubstitutions({
    required List<String> missingIngredients,
    required String recipeTitle,
  });

  /// Curated offline culinary staples substitutions
  static final Map<String, SubstitutionModel> offlineSubstitutions = {
    'coriander': const SubstitutionModel(
      originalIngredient: 'coriander',
      substitute: 'Parsley, Mint (Pudina), or Celery Leaves',
      culinaryTip: 'Garnish with fresh parsley or chopped mint right before serving for a fresh herbaceous lift.',
      rationale: 'Provides similar fresh aromatic finish and herbal vibrancy.',
    ),
    'dhania': const SubstitutionModel(
      originalIngredient: 'dhania',
      substitute: 'Fresh Parsley, Mint, or Ground Coriander Powder + Lemon',
      culinaryTip: 'Use a pinch of coriander powder in the gravy and garnish with fresh parsley or mint.',
      rationale: 'Replicates both the earthy ground flavor and fresh citrusy herbal notes.',
    ),
    'cilantro': const SubstitutionModel(
      originalIngredient: 'cilantro',
      substitute: 'Fresh Parsley or Chopped Mint',
      culinaryTip: 'Add at the very end of cooking to preserve bright aroma.',
      rationale: 'Delivers vibrant green color and crisp herbal finish.',
    ),
    'cumin': const SubstitutionModel(
      originalIngredient: 'cumin',
      substitute: 'Coriander Seeds, Fennel Seeds (Saunf), or Carom (Ajwain)',
      culinaryTip: 'Lightly crush and roast in hot oil/ghee for 30 seconds to release warm earthy oils.',
      rationale: 'Supplies warming earthy aroma and digestive comfort.',
    ),
    'jeera': const SubstitutionModel(
      originalIngredient: 'jeera',
      substitute: 'Coriander Seeds, Ajwain, or Garam Masala pinch',
      culinaryTip: 'Temper in hot ghee for an authentic tadka aroma.',
      rationale: 'Brings signature warm earthy fragrance to the dish.',
    ),
    'curry leaves': const SubstitutionModel(
      originalIngredient: 'curry leaves',
      substitute: 'Kaffir Lime Leaves, Fresh Basil, or Lemon Zest',
      culinaryTip: 'Gently fry fresh lemon zest in oil to mimic the citrusy aromatic depth.',
      rationale: 'Infuses citrus-herbal fragrance essential in Indian cooking.',
    ),
    'kadi patta': const SubstitutionModel(
      originalIngredient: 'kadi patta',
      substitute: 'Lemon Zest, Kaffir Lime Leaves, or Fresh Basil',
      culinaryTip: 'A strip of lemon zest in warm oil provides identical citrus aromatics.',
      rationale: 'Replicates classic tempering aromatics.',
    ),
    'mint': const SubstitutionModel(
      originalIngredient: 'mint',
      substitute: 'Fresh Coriander, Basil, or Dried Mint Flakes',
      culinaryTip: 'Use half quantity if substituting with dried mint flakes.',
      rationale: 'Offers cooling herbal contrast and digestive brightness.',
    ),
    'pudina': const SubstitutionModel(
      originalIngredient: 'pudina',
      substitute: 'Fresh Coriander (Dhania) or Dried Mint',
      culinaryTip: 'Stir in at the end so delicate aromatics do not burn.',
      rationale: 'Preserves signature cooling aromatic depth.',
    ),
    'green chilli': const SubstitutionModel(
      originalIngredient: 'green chilli',
      substitute: 'Red Chilli Flakes, Cayenne Pepper, or Black Pepper',
      culinaryTip: 'Use 1/4 tsp crushed red chilli flakes per green chilli.',
      rationale: 'Delivers balanced heat and pungent brightness.',
    ),
    'green chili': const SubstitutionModel(
      originalIngredient: 'green chili',
      substitute: 'Red Chilli Flakes, Jalapeño, or Serrano pepper',
      culinaryTip: 'Adjust seeds and membranes to calibrate desired spiciness.',
      rationale: 'Provides crisp piquant heat.',
    ),
    'mirchi': const SubstitutionModel(
      originalIngredient: 'mirchi',
      substitute: 'Crushed Red Pepper or Paprika + Cayenne',
      culinaryTip:
          'Bloom in hot oil for 10 seconds to disperse color and heat.',
      rationale: 'Supplies warm heat and appetizing red hue.',
    ),
    'onion': const SubstitutionModel(
      originalIngredient: 'onion',
      substitute: 'Shallots, Leeks, or Pinch of Hing (Asafoetida) + Cabbage',
      culinaryTip: 'A tiny pinch of hing in warm oil replicates allium depth without onion.',
      rationale: 'Brings sweet savory foundation and gravy body.',
    ),
    'pyaz': const SubstitutionModel(
      originalIngredient: 'pyaz',
      substitute: 'Shallots, Scallions, or 1/8 tsp Hing in hot oil',
      culinaryTip: 'Sauté shallots slowly until caramel golden.',
      rationale: 'Maintains sweetness and gravy thickness.',
    ),
    'lemon': const SubstitutionModel(
      originalIngredient: 'lemon',
      substitute: 'Dry Mango Powder (Amchur), Lime Juice, or White Vinegar',
      culinaryTip: '1/2 tsp amchur powder or 1 tsp vinegar equals 1 tbsp fresh lemon juice.',
      rationale: 'Restores tangy balance and cuts through rich spices.',
    ),
    'lime': const SubstitutionModel(
      originalIngredient: 'lime',
      substitute: 'Lemon Juice, Tamarind Paste, or Amchur',
      culinaryTip: 'Squeeze fresh juice just before serving.',
      rationale: 'Injects bright citrus acidity and freshness.',
    ),
    'nimbu': const SubstitutionModel(
      originalIngredient: 'nimbu',
      substitute: 'Amchur (Dry Mango Powder) or Lemon Juice',
      culinaryTip:
          'Add at the end to keep the dish vibrant without bitter notes.',
      rationale: 'Restores vital tart balance.',
    ),
    'turmeric': const SubstitutionModel(
      originalIngredient: 'turmeric',
      substitute: 'Ground Ginger + Pinch of Saffron or Paprika',
      culinaryTip:
          'Combine ground ginger for earthiness and paprika for golden hue.',
      rationale: 'Provides warm earthy aroma and cheerful golden color.',
    ),
    'haldi': const SubstitutionModel(
      originalIngredient: 'haldi',
      substitute: 'Ground Ginger + Saffron Threads or Yellow Mustard',
      culinaryTip: 'A tiny pinch is enough to brighten curries naturally.',
      rationale: 'Replicates classic Indian golden hue and subtle warmth.',
    ),
    'garam masala': const SubstitutionModel(
      originalIngredient: 'garam masala',
      substitute: 'Equal parts Cumin + Coriander + Cinnamon + Pinch Cardamom',
      culinaryTip: 'Sprinkle this homemade blend into the pan during the final 2 minutes of simmering.',
      rationale: 'Delivers full-bodied fragrant warmth.',
    ),
    'mustard seeds': const SubstitutionModel(
      originalIngredient: 'mustard seeds',
      substitute: 'Cumin Seeds (Jeera) or Pinch of Horseradish',
      culinaryTip: 'Crack cumin seeds in hot oil as an alternative tadka base.',
      rationale: 'Adds nutty pungent crunch and aromatics.',
    ),
    'rai': const SubstitutionModel(
      originalIngredient: 'rai',
      substitute: 'Cumin Seeds (Jeera) or Fennel Seeds',
      culinaryTip:
          'Splutter seeds in hot oil until they pop and release fragrance.',
      rationale: 'Traditional tadka foundation.',
    ),
    'cloves': const SubstitutionModel(
      originalIngredient: 'cloves',
      substitute: 'Allspice, Nutmeg Pinch, or Cinnamon Stick piece',
      culinaryTip: 'Use a tiny pinch of ground allspice or cinnamon.',
      rationale: 'Shares pungent eugenol warmth and festive aroma.',
    ),
    'laung': const SubstitutionModel(
      originalIngredient: 'laung',
      substitute: 'Allspice or Cinnamon piece',
      culinaryTip: 'Temper in hot ghee for rich pilafs and curries.',
      rationale: 'Provides deep woodsy sweet heat.',
    ),
    'cinnamon': const SubstitutionModel(
      originalIngredient: 'cinnamon',
      substitute: 'Nutmeg, Allspice, or Cardamom pinch',
      culinaryTip:
          'A dash of ground nutmeg works wonders in savories and desserts.',
      rationale: 'Imparts sweet aromatic warmth.',
    ),
    'dalchini': const SubstitutionModel(
      originalIngredient: 'dalchini',
      substitute: 'Nutmeg Pinch or Cardamom',
      culinaryTip: 'Add whole spices to oil to perfume the base sauce.',
      rationale: 'Recreates woody sweet fragrance.',
    ),
    'cardamom': const SubstitutionModel(
      originalIngredient: 'cardamom',
      substitute: 'Pinch of Cinnamon + Nutmeg',
      culinaryTip:
          'Equal parts cinnamon and nutmeg mimic complex cardamom notes.',
      rationale: 'Supplies citrusy floral warmth.',
    ),
    'elaichi': const SubstitutionModel(
      originalIngredient: 'elaichi',
      substitute: 'Cinnamon + Nutmeg or Allspice pinch',
      culinaryTip: 'Crush whole pods or use a tiny pinch of ground spice.',
      rationale: 'Gives delicate fragrant aroma to gravies and sweets.',
    ),
    'coconut': const SubstitutionModel(
      originalIngredient: 'coconut',
      substitute: 'Desiccated Coconut (soaked in warm milk) or Almond Meal',
      culinaryTip: 'Soak 3 tbsp desiccated coconut in 3 tbsp warm water/milk for 10 min.',
      rationale:
          'Provides identical rich nutty texture and subtle natural sweetness.',
    ),
    'drumstick': const SubstitutionModel(
      originalIngredient: 'drumstick',
      substitute: 'Green Beans, Zucchini, or Okra (Bhindi)',
      culinaryTip:
          'Cut green beans or zucchini into 2-inch batons to simmer evenly.',
      rationale:
          'Absorbs coconut water and curry spices with pleasing texture.',
    ),
    'sekta': const SubstitutionModel(
      originalIngredient: 'sekta',
      substitute: 'Drumstick (Saragvo), Green Beans, or Ridge Gourd (Turai)',
      culinaryTip:
          'Simmer gently so vegetable becomes tender without falling apart.',
      rationale: 'Traditional Gujarati/Parsi vegetable alternative (Saragvo).',
    ),
    'paneer': const SubstitutionModel(
      originalIngredient: 'paneer',
      substitute: 'Firm Tofu or Halloumi',
      culinaryTip:
          'Press firm tofu with a paper towel and pan-fry lightly in ghee/oil.',
      rationale: 'Absorbs gravy spices similarly with comparable texture.',
    ),
    'buttermilk': const SubstitutionModel(
      originalIngredient: 'buttermilk',
      substitute: '1 cup Milk + 1 tbsp Lemon Juice or Vinegar',
      culinaryTip:
          'Let sit for 5 minutes until it curdles slightly before stirring in.',
      rationale: 'Provides the required acidity and tenderizing enzyme action.',
    ),
    'curd': const SubstitutionModel(
      originalIngredient: 'curd',
      substitute: 'Greek Yogurt or Coconut Yogurt',
      culinaryTip: 'Whisk with a splash of water for silky smooth consistency.',
      rationale: 'Maintains creamy tanginess without curdling.',
    ),
    'yogurt': const SubstitutionModel(
      originalIngredient: 'yogurt',
      substitute: 'Sour Cream or Coconut Cream + Lemon',
      culinaryTip: 'Temper at room temperature before adding to warm sauces.',
      rationale: 'Ensures creamy tanginess without splitting.',
    ),
    'ghee': const SubstitutionModel(
      originalIngredient: 'ghee',
      substitute: 'Clarified Butter, Coconut Oil, or Mustard Oil',
      culinaryTip: 'Melt unsalted butter on low until milk solids separate for true ghee aroma.',
      rationale: 'High smoke point and rich nutty savoriness.',
    ),
    'heavy cream': const SubstitutionModel(
      originalIngredient: 'heavy cream',
      substitute: 'Cashew Paste or Coconut Cream',
      culinaryTip: 'Soak 10 cashews in warm water for 15 min, then blend with 3 tbsp water.',
      rationale: 'Creates rich restaurant-style velvety gravy naturally.',
    ),
    'fresh cream': const SubstitutionModel(
      originalIngredient: 'fresh cream',
      substitute: 'Cashew Puree or Full-Fat Milk + Butter',
      culinaryTip: 'Blend soaked cashews into a glossy puree.',
      rationale: 'Thickens sauce with rich creamy mouthfeel.',
    ),
    'tomato': const SubstitutionModel(
      originalIngredient: 'tomato',
      substitute: 'Tomato Paste + Water, or Tamarind Paste',
      culinaryTip: 'Use 1 tbsp tomato paste diluted with 3 tbsp warm water.',
      rationale: 'Brings natural umami and sweet acidity.',
    ),
    'ginger': const SubstitutionModel(
      originalIngredient: 'ginger',
      substitute: '1/4 tsp Ground Dry Ginger (Saunth)',
      culinaryTip: 'Mix with warm water to rehydrate before sautéing.',
      rationale: 'Maintains peppery pungent warmth.',
    ),
    'garlic': const SubstitutionModel(
      originalIngredient: 'garlic',
      substitute: 'Garlic Powder or Pinch of Asafoetida (Hing)',
      culinaryTip: '1/8 tsp garlic powder or 1 pinch hing in hot oil mimics allium depth.',
      rationale: 'Offers deep savory aromatic undertones.',
    ),
    'eggs': const SubstitutionModel(
      originalIngredient: 'eggs',
      substitute: '1/4 cup Yogurt or 1 tbsp Flaxseed Meal + 3 tbsp Water',
      culinaryTip:
          'Let flax mixture rest for 5 min to form a gelatinous binder.',
      rationale: 'Acts as structural moisture and binding agent.',
    ),
    'egg': const SubstitutionModel(
      originalIngredient: 'egg',
      substitute: '1/4 cup Silken Tofu or Yogurt',
      culinaryTip: 'Whisk until completely smooth before incorporating.',
      rationale: 'Provides binder and tender crumb in baking and cooking.',
    ),
    'kasuri methi': const SubstitutionModel(
      originalIngredient: 'kasuri methi',
      substitute: 'Fresh Fenugreek or Celery Leaves',
      culinaryTip:
          'Crush dried leaves between palms just before turning off the flame.',
      rationale: 'Signature bittersweet aroma in North Indian curries.',
    ),
    'tamarind': const SubstitutionModel(
      originalIngredient: 'tamarind',
      substitute: 'Lime Juice + Pinch of Brown Sugar or Amchur',
      culinaryTip: 'Equal parts fresh lime and jaggery/brown sugar balance sour-sweet notes.',
      rationale: 'Replicates classic sweet and sour complexity.',
    ),
    'besan': const SubstitutionModel(
      originalIngredient: 'besan',
      substitute: 'Chickpea Flour or Roasted Cornstarch',
      culinaryTip:
          'Lightly roast in dry pan for 2 minutes to eliminate raw taste.',
      rationale: 'Nutty thickener and binding agent for batters.',
    ),
    'amchur': const SubstitutionModel(
      originalIngredient: 'amchur',
      substitute: 'Lemon Juice or Pomegranate Powder (Anardana)',
      culinaryTip:
          'Add lemon juice right at the end to preserve bright fruitiness.',
      rationale: 'Provides dry fruity tanginess without extra liquid.',
    ),
    'coconut milk': const SubstitutionModel(
      originalIngredient: 'coconut milk',
      substitute: 'Cashew Milk or Whole Milk + Drop of Coconut Extract',
      culinaryTip: 'Simmer gently; do not boil rapidly to avoid separation.',
      rationale: 'Maintains silky mouthfeel and tropical aroma.',
    ),
    'sugar': const SubstitutionModel(
      originalIngredient: 'sugar',
      substitute: 'Jaggery Powder, Brown Sugar, or Honey',
      culinaryTip: 'Swap with equal parts jaggery powder, brown sugar, or 1/3 cup honey / maple syrup.',
      rationale: 'Provides natural sweetness and moisture retention.',
    ),
  };

  /// Generates a culinary-informed fallback when an ingredient is not in the curated dictionary
  static SubstitutionModel createSmartFallback(
    String rawIngredient, {
    String recipeCategory = '',
    String recipeTitle = '',
  }) {
    final lower = rawIngredient.toLowerCase().trim();
    final isSweet = recipeCategory.toLowerCase().contains('dessert') ||
        recipeCategory.toLowerCase().contains('baking') ||
        recipeCategory.toLowerCase().contains('sweet') ||
        recipeCategory.toLowerCase().contains('cookie') ||
        recipeCategory.toLowerCase().contains('cake') ||
        recipeTitle.toLowerCase().contains('cookie') ||
        recipeTitle.toLowerCase().contains('cake') ||
        recipeTitle.toLowerCase().contains('dessert') ||
        recipeTitle.toLowerCase().contains('sweet') ||
        recipeTitle.toLowerCase().contains('halwa') ||
        recipeTitle.toLowerCase().contains('kheer') ||
        recipeTitle.toLowerCase().contains('pudding') ||
        recipeTitle.toLowerCase().contains('barfi') ||
        recipeTitle.toLowerCase().contains('laddu');

    if (lower.contains('sugar')) {
      return SubstitutionModel(
        originalIngredient: rawIngredient,
        substitute: isSweet
            ? 'Jaggery powder, brown sugar, or 1/3 cup honey / maple syrup'
            : 'Pinch of jaggery, honey, or caramelized onions',
        culinaryTip: isSweet
            ? 'Swap with equal parts jaggery powder, brown sugar, or 1/3 cup honey/maple syrup.'
            : 'Add a pinch of jaggery, honey, or caramelized onions to balance acidity.',
        rationale: isSweet
            ? 'Maintains sweetness and structure for baked goods and desserts.'
            : 'Provides balanced sweetness to contrast sour or acidic notes.',
      );
    }

    if (lower.contains('leaf') ||
        lower.contains('leaves') ||
        lower.contains('herb')) {
      return SubstitutionModel(
        originalIngredient: rawIngredient,
        substitute: 'Fresh Parsley, Celery Leaves, or Dried Herbs',
        culinaryTip:
            'Garnish towards the end of cooking for fresh herbaceous aroma.',
        rationale: 'Provides similar fresh herbal lift and visual vibrancy.',
      );
    }

    if (lower.contains('seed') ||
        lower.contains('powder') ||
        lower.contains('spice') ||
        lower.contains('masala')) {
      return SubstitutionModel(
        originalIngredient: rawIngredient,
        substitute: 'Pantry Garam Masala, Cumin Pinch, or Black Pepper',
        culinaryTip:
            'Bloom in hot oil or ghee for 15 seconds to awaken warm aromatics.',
        rationale: 'Supplies warming earthy notes and culinary balance.',
      );
    }

    if (lower.contains('paste') || lower.contains('sauce')) {
      return SubstitutionModel(
        originalIngredient: rawIngredient,
        substitute: 'Pureed Fresh Aromatics or Tomato Paste',
        culinaryTip:
            'Blend available kitchen staples with a drop of water or oil.',
        rationale: 'Thickens gravy base with concentrated savory flavor.',
      );
    }

    if (lower.contains('oil') || lower.contains('fat')) {
      return SubstitutionModel(
        originalIngredient: rawIngredient,
        substitute: 'Sunflower Oil, Butter, or Ghee',
        culinaryTip: 'Use equal parts available cooking oil or melted butter.',
        rationale: 'Conducts heat and carries spice fat-soluble aromatics.',
      );
    }

    return SubstitutionModel(
      originalIngredient: rawIngredient,
      substitute: isSweet ? 'Baking staple alternative or omit' : 'Pantry staple alternative or omit',
      culinaryTip: isSweet
          ? 'Check baking substitutions for $rawIngredient to maintain dough texture.'
          : 'Omit or adjust salt, herbs, and aromatics to taste.',
      rationale: isSweet
          ? 'Maintains moisture balance and texture in sweet recipes.'
          : 'The dish remains balanced even without this specific ingredient.',
    );
  }
}
