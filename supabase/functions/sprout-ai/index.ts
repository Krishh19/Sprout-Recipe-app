import "jsr:@supabase/functions-js/edge-runtime.d.ts";

const corsHeaders = {
  "Access-Control-Allow-Origin": "*",
  "Access-Control-Allow-Headers":
    "authorization, x-client-info, apikey, content-type",
  "Access-Control-Allow-Methods": "POST, GET, OPTIONS",
};

function cleanJson(text: string): string {
  let cleaned = text.trim();
  // Strip code blocks like ```json ... ``` or ``` ... ```
  if (cleaned.startsWith("```json")) {
    cleaned = cleaned.substring(7);
  } else if (cleaned.startsWith("```")) {
    cleaned = cleaned.substring(3);
  }
  if (cleaned.endsWith("```")) {
    cleaned = cleaned.substring(0, cleaned.length - 3);
  }
  cleaned = cleaned.trim();

  // If there are surrounding characters, try to isolate between first {/[ and last }/]
  const firstBrace = cleaned.indexOf("{");
  const firstBracket = cleaned.indexOf("[");
  let start = -1;
  let end = -1;

  if (firstBrace !== -1 && (firstBracket === -1 || firstBrace < firstBracket)) {
    start = firstBrace;
    end = cleaned.lastIndexOf("}");
  } else if (firstBracket !== -1) {
    start = firstBracket;
    end = cleaned.lastIndexOf("]");
  }

  if (start !== -1 && end !== -1 && end > start) {
    cleaned = cleaned.substring(start, end + 1);
  }

  return cleaned.trim();
}

async function callGroq({
  apiKey,
  model,
  messages,
  jsonMode = false,
  temperature = 0.2,
  maxTokens = 1024,
}: {
  apiKey: string;
  model: string;
  messages: Array<{ role: string; content: string }>;
  jsonMode?: boolean;
  temperature?: number;
  maxTokens?: number;
}): Promise<string> {
  const payload: Record<string, unknown> = {
    model: model || "qwen/qwen3.8-27b",
    messages,
    temperature,
    max_tokens: maxTokens,
  };
  if (jsonMode) {
    payload.response_format = { type: "json_object" };
  }

  const res = await fetch("https://api.groq.com/openai/v1/chat/completions", {
    method: "POST",
    headers: {
      "Content-Type": "application/json",
      Authorization: `Bearer ${apiKey}`,
    },
    body: JSON.stringify(payload),
  });

  if (!res.ok) {
    const errText = await res.text();
    throw new Error(`Groq API error (${res.status}): ${errText}`);
  }

  const json = await res.json();
  const choice = json.choices?.[0]?.message?.content;
  if (!choice) throw new Error("Empty response from Groq");
  return choice;
}

async function callGemini({
  apiKey,
  prompt,
  jsonMode = true,
}: {
  apiKey: string;
  prompt: string;
  jsonMode?: boolean;
}): Promise<string> {
  const candidateModels = [
    Deno.env.get("GEMINI_MODEL")?.trim(),
    "gemini-flash-lite-latest",
    "gemini-3.8-flash",
    "gemini-3.1-flash-lite",
  ].filter(Boolean) as string[];

  let lastError: Error | null = null;

  for (const model of candidateModels) {
    try {
      const url = `https://generativelanguage.googleapis.com/v1beta/models/${model}:generateContent?key=${apiKey}`;
      const payload: Record<string, unknown> = {
        contents: [
          {
            parts: [{ text: prompt }],
          },
        ],
        generationConfig: {
          temperature: 0.2,
          ...(jsonMode ? { responseMimeType: "application/json" } : {}),
        },
      };

      const res = await fetch(url, {
        method: "POST",
        headers: {
          "Content-Type": "application/json",
        },
        body: JSON.stringify(payload),
      });

      if (res.ok) {
        const json = await res.json();
        const candidate = json.candidates?.[0]?.content?.parts?.[0]?.text;
        if (candidate) return candidate;
      } else {
        const errText = await res.text();
        lastError = new Error(`Gemini ${model} error (${res.status}): ${errText}`);
      }
    } catch (e) {
      lastError = e as Error;
    }
  }

  throw lastError || new Error("All Gemini candidate models failed");
}

Deno.serve(async (req: Request) => {
  // 1. Handle CORS preflight
  if (req.method === "OPTIONS") {
    return new Response("ok", { headers: corsHeaders });
  }

  if (req.method !== "POST") {
    return new Response(
      JSON.stringify({ error: "Only POST requests are supported" }),
      {
        status: 405,
        headers: { ...corsHeaders, "Content-Type": "application/json" },
      }
    );
  }

  try {
    const groqKey = Deno.env.get("GROQ_API_KEY")?.trim() || "";
    const geminiKey = Deno.env.get("GEMINI_API_KEY")?.trim() || "";
    const groqModel = Deno.env.get("GROQ_MODEL") || "qwen/qwen3.8-27b";

    const body = await req.json();
    const task = body.task;
    const data = body.data || {};

    if (!task) {
      return new Response(
        JSON.stringify({ error: "Missing required 'task' field in payload" }),
        {
          status: 400,
          headers: { ...corsHeaders, "Content-Type": "application/json" },
        }
      );
    }

    // ==========================================
    // TASK 1: NUTRITION ESTIMATION
    // ==========================================
    if (task === "nutrition") {
      const { title, cuisine, servings, ingredients } = data;
      const ingList = Array.isArray(ingredients) ? ingredients : [];

      const prompt = `You are an expert nutritional scientist. Calculate the nutritional breakdown PER SERVING for this recipe:
Recipe: "${title || "Recipe"}"
Cuisine: ${cuisine || "General"}
Default Servings: ${servings && servings > 0 ? servings : 4}
Ingredients:
${ingList.slice(0, 15).join("\n")}

Provide realistic culinary estimates for one average adult serving:
- calories (integer kcal)
- protein (integer grams)
- carbs (integer grams)
- fat (integer grams)
- fiber (integer grams)
- health_note (one punchy phrase under 8 words, e.g., "High in lean protein & potassium" or "Rich in dietary fiber & healthy fats")

Respond ONLY with this JSON schema:
{
  "calories": 420,
  "protein": 24,
  "carbs": 38,
  "fat": 16,
  "fiber": 6,
  "health_note": "High in lean protein & fiber"
}`;

      // 1. Try Groq Qwen first
      if (groqKey) {
        try {
          const raw = await callGroq({
            apiKey: groqKey,
            model: groqModel,
            messages: [
              {
                role: "system",
                content:
                  "You are an expert nutritional scientist. Output valid JSON only matching the schema.",
              },
              { role: "user", content: prompt },
            ],
            jsonMode: true,
          });
          const parsed = JSON.parse(cleanJson(raw));
          return new Response(
            JSON.stringify({
              success: true,
              provider: "groq",
              model: groqModel,
              data: parsed,
            }),
            {
              headers: { ...corsHeaders, "Content-Type": "application/json" },
            }
          );
        } catch (e) {
          console.warn("Groq nutrition failed, attempting Gemini fallback:", e);
        }
      }

      // 2. Fallback to Gemini
      if (geminiKey) {
        try {
          const raw = await callGemini({
            apiKey: geminiKey,
            prompt,
            jsonMode: true,
          });
          const parsed = JSON.parse(cleanJson(raw));
          return new Response(
            JSON.stringify({
              success: true,
              provider: "gemini",
              data: parsed,
            }),
            {
              headers: { ...corsHeaders, "Content-Type": "application/json" },
            }
          );
        } catch (e) {
          console.error("Gemini nutrition failed:", e);
        }
      }

      return new Response(
        JSON.stringify({
          error: "No AI service available or all providers failed",
        }),
        {
          status: 503,
          headers: { ...corsHeaders, "Content-Type": "application/json" },
        }
      );
    }

    // ==========================================
    // TASK 2: TRANSLATE RECIPE (HINDI <-> ENGLISH)
    // ==========================================
    if (task === "translate") {
      const {
        title,
        description,
        ingredients,
        instructions,
        target_language,
      } = data;
      const isTargetHindi = target_language === "hi";
      const targetLangName = isTargetHindi
        ? "Hindi (Devanagari script)"
        : "English";
      const sourceLangName = isTargetHindi ? "English" : "Hindi";

      const prompt = `You are an expert culinary translator for Indian and international cuisines.
Translate the following recipe from ${sourceLangName} to ${targetLangName}.
Guidelines:
1. Translate accurately, keeping cooking instructions natural, appetizing, and clear.
2. For traditional Indian ingredients and dishes, keep customary culinary names recognizable (e.g. Paneer, Tawa, Kadhai, Garam Masala).
3. Output MUST be ONLY valid JSON with this exact schema:
{
  "title": "translated title string",
  "description": "translated description string",
  "ingredients": ["translated ingredient 1", "translated ingredient 2"],
  "instructions": ["translated instruction step 1", "translated instruction step 2"]
}

Recipe Data:
Title: ${JSON.stringify(title || "")}
Description: ${JSON.stringify(description || "")}
Ingredients: ${JSON.stringify(ingredients || [])}
Instructions: ${JSON.stringify(instructions || [])}`;

      // 1. Try Groq Qwen first
      if (groqKey) {
        try {
          const raw = await callGroq({
            apiKey: groqKey,
            model: groqModel,
            messages: [
              {
                role: "system",
                content:
                  "You are an expert culinary translator. Output valid JSON only matching the schema.",
              },
              { role: "user", content: prompt },
            ],
            jsonMode: true,
          });
          const parsed = JSON.parse(cleanJson(raw));
          return new Response(
            JSON.stringify({
              success: true,
              provider: "groq",
              model: groqModel,
              data: parsed,
            }),
            {
              headers: { ...corsHeaders, "Content-Type": "application/json" },
            }
          );
        } catch (e) {
          console.warn("Groq translate failed, attempting Gemini fallback:", e);
        }
      }

      // 2. Fallback to Gemini
      if (geminiKey) {
        try {
          const raw = await callGemini({
            apiKey: geminiKey,
            prompt,
            jsonMode: true,
          });
          const parsed = JSON.parse(cleanJson(raw));
          return new Response(
            JSON.stringify({
              success: true,
              provider: "gemini",
              data: parsed,
            }),
            {
              headers: { ...corsHeaders, "Content-Type": "application/json" },
            }
          );
        } catch (e) {
          console.error("Gemini translate failed:", e);
        }
      }

      return new Response(
        JSON.stringify({
          error: "No AI service available or all providers failed",
        }),
        {
          status: 503,
          headers: { ...corsHeaders, "Content-Type": "application/json" },
        }
      );
    }

    // ==========================================
    // TASK 3: CULINARY SUBSTITUTIONS
    // ==========================================
    if (task === "substitutions") {
      const { recipe_title, missing_ingredients } = data;
      const unhandled = Array.isArray(missing_ingredients)
        ? missing_ingredients
        : [];

      const prompt = `You are Chef Sprout, a culinary substitutions specialist for the Sprout cooking app.
Suggest smart, accessible culinary substitutions for the following missing ingredients for the dish "${
        recipe_title || "Recipe"
      }":
Missing ingredients: ${unhandled.join(", ")}

Return ONLY a valid JSON object matching this schema:
{
  "substitutions": [
    {
      "original_ingredient": "ingredient name",
      "substitute": "recommended substitution",
      "culinary_tip": "actionable tip on proportions or preparation method",
      "rationale": "why this swap works in this specific dish"
    }
  ]
}`;

      // 1. Try Groq Qwen first
      if (groqKey) {
        try {
          const raw = await callGroq({
            apiKey: groqKey,
            model: groqModel,
            messages: [
              {
                role: "system",
                content:
                  "You are an expert culinary scientist. Output strictly a JSON object with a 'substitutions' list.",
              },
              { role: "user", content: prompt },
            ],
            jsonMode: true,
          });
          const parsed = JSON.parse(cleanJson(raw));
          return new Response(
            JSON.stringify({
              success: true,
              provider: "groq",
              model: groqModel,
              data: parsed,
            }),
            {
              headers: { ...corsHeaders, "Content-Type": "application/json" },
            }
          );
        } catch (e) {
          console.warn(
            "Groq substitutions failed, attempting Gemini fallback:",
            e
          );
        }
      }

      // 2. Fallback to Gemini
      if (geminiKey) {
        try {
          const raw = await callGemini({
            apiKey: geminiKey,
            prompt,
            jsonMode: true,
          });
          const parsed = JSON.parse(cleanJson(raw));
          return new Response(
            JSON.stringify({
              success: true,
              provider: "gemini",
              data: parsed,
            }),
            {
              headers: { ...corsHeaders, "Content-Type": "application/json" },
            }
          );
        } catch (e) {
          console.error("Gemini substitutions failed:", e);
        }
      }

      return new Response(
        JSON.stringify({
          error: "No AI service available or all providers failed",
        }),
        {
          status: 503,
          headers: { ...corsHeaders, "Content-Type": "application/json" },
        }
      );
    }

    // ==========================================
    // TASK 4: MULTIMODAL INGREDIENT VISION SCAN
    // ==========================================
    if (task === "vision") {
      const { image_base64, mime_type } = data;
      if (!image_base64) {
        return new Response(
          JSON.stringify({ error: "Missing image_base64 in data payload" }),
          {
            status: 400,
            headers: { ...corsHeaders, "Content-Type": "application/json" },
          }
        );
      }

      if (!geminiKey) {
        return new Response(
          JSON.stringify({ error: "Gemini API key is not configured for vision" }),
          {
            status: 503,
            headers: { ...corsHeaders, "Content-Type": "application/json" },
          }
        );
      }

      const visionPrompt = `You are an expert culinary AI for the Sprout cooking app.
Analyze this photo carefully. The photo may show:
1. A prepared dish or cooked recipe (e.g. salad, bowl, soup, curry, stir-fry, pasta, sandwich): Identify all visible culinary ingredients and components.
2. Fridge interior or pantry shelves: Identify all visible groceries, vegetables, condiments, dairy.
3. Raw groceries: Identify each individual fruit, vegetable, herb, protein, or pantry item.
4. A recipe card, menu, or cookbook page: Extract all individual culinary ingredients listed in the recipe text.

Instructions:
- Return ONLY a valid JSON array of lowercase singular ingredient names (e.g. ["egg", "avocado", "tomato", "chicken", "lettuce"]).
- Output strictly the JSON array without backticks or markdown formatting.`;

      const candidateModels = [
        Deno.env.get("GEMINI_MODEL")?.trim(),
        "gemini-flash-lite-latest",
        "gemini-3.8-flash",
      ].filter(Boolean) as string[];

      for (const model of candidateModels) {
        try {
          const url = `https://generativelanguage.googleapis.com/v1beta/models/${model}:generateContent?key=${geminiKey}`;
          const payload = {
            contents: [
              {
                parts: [
                  {
                    inlineData: {
                      mimeType: mime_type || "image/jpeg",
                      data: image_base64,
                    },
                  },
                  { text: visionPrompt },
                ],
              },
            ],
            generationConfig: {
              temperature: 0.2,
              responseMimeType: "application/json",
            },
          };

          const res = await fetch(url, {
            method: "POST",
            headers: { "Content-Type": "application/json" },
            body: JSON.stringify(payload),
          });

          if (res.ok) {
            const json = await res.json();
            const text = json.candidates?.[0]?.content?.parts?.[0]?.text;
            if (text) {
              const cleaned = cleanJson(text);
              const ingredients = JSON.parse(cleaned);
              return new Response(
                JSON.stringify({
                  success: true,
                  provider: "gemini",
                  model,
                  data: { ingredients },
                }),
                {
                  headers: { ...corsHeaders, "Content-Type": "application/json" },
                }
              );
            }
          }
        } catch (e) {
          console.warn(`Vision model ${model} error:`, e);
        }
      }

      return new Response(
        JSON.stringify({
          error: "Vision recognition failed across candidate models",
        }),
        {
          status: 503,
          headers: { ...corsHeaders, "Content-Type": "application/json" },
        }
      );
    }

    // ==========================================
    // TASK 5: GENERIC CHAT / COMPLETION PROXY
    // ==========================================
    if (task === "chat") {
      const {
        messages,
        model,
        temperature = 0.2,
        json_mode = false,
        max_tokens = 1024,
      } = data;

      if (!Array.isArray(messages)) {
        return new Response(
          JSON.stringify({ error: "Missing or invalid 'messages' array" }),
          {
            status: 400,
            headers: { ...corsHeaders, "Content-Type": "application/json" },
          }
        );
      }

      if (groqKey) {
        try {
          const content = await callGroq({
            apiKey: groqKey,
            model: model || groqModel,
            messages,
            jsonMode: json_mode,
            temperature,
            maxTokens: max_tokens,
          });
          return new Response(
            JSON.stringify({
              success: true,
              provider: "groq",
              content,
            }),
            {
              headers: { ...corsHeaders, "Content-Type": "application/json" },
            }
          );
        } catch (e) {
          console.warn("Groq chat failed:", e);
        }
      }

      if (geminiKey) {
        try {
          const userPrompt = messages
            .map((m: { role: string; content: string }) => `${m.role}: ${m.content}`)
            .join("\n\n");
          const content = await callGemini({
            apiKey: geminiKey,
            prompt: userPrompt,
            jsonMode: json_mode,
          });
          return new Response(
            JSON.stringify({
              success: true,
              provider: "gemini",
              content,
            }),
            {
              headers: { ...corsHeaders, "Content-Type": "application/json" },
            }
          );
        } catch (e) {
          console.error("Gemini chat fallback failed:", e);
        }
      }

      return new Response(
        JSON.stringify({
          error: "No AI service available or all providers failed",
        }),
        {
          status: 503,
          headers: { ...corsHeaders, "Content-Type": "application/json" },
        }
      );
    }

    return new Response(
      JSON.stringify({ error: `Unknown task '${task}'` }),
      {
        status: 400,
        headers: { ...corsHeaders, "Content-Type": "application/json" },
      }
    );
  } catch (err) {
    return new Response(
      JSON.stringify({ error: (err as Error).message || "Internal server error" }),
      {
        status: 500,
        headers: { ...corsHeaders, "Content-Type": "application/json" },
      }
    );
  }
});
