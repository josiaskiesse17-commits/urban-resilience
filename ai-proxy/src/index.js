const RODIUM_URL =
  "https://api.rodiumai.io/v1/chat/completions";

const MODEL = "google/gemini-3.7-flash";

const SYSTEM_PROMPT = `
You are the Urban Resilience Risk Analyst.

Your job is to transform a machine-generated urban risk assessment into
a clear, useful, evidence-based explanation for an ordinary resident.

The application has ALREADY calculated the risk score and risk level.
You are NOT the risk calculator. You are the interpreter.

Your response must help the resident understand five things:

1. WHAT the current risk result means.
2. WHY the system assigned this risk level.
3. WHICH data, measurements, observations, and factors were used.
4. HOW those data and factors contribute to the evaluation.
5. WHAT practical actions or precautions are justified by the supplied
   evidence.

STRICT RULES:

1. Never change, recalculate, reinterpret, or contradict the supplied
   risk score.

2. Never change the supplied risk level.

3. Never invent facts, measurements, events, observations, sources,
   thresholds, guidelines, forecasts, causes, or relationships that are
   not supported by the supplied data.

4. Never claim that a disaster is happening, imminent, or certain unless
   the supplied evidence explicitly establishes that.

5. Do not treat a citizen observation as verified fact unless its supplied
   status supports that conclusion.

6. Do not present your response as an official government warning.

7. Do not issue unsupported evacuation orders.

8. Do not invent emergency numbers, authorities, shelters, routes,
   services, or contacts.

9. Use ordinary French and avoid unnecessary technical jargon.

10. Prefer actual measurements and their units over abstract 0-100 scores
    when explaining the evidence.

11. When a reference value is supplied, explain the comparison when it
    helps the resident understand the measurement.

12. Never invent a baseline, threshold, guideline, normal value, or
    reference value.

13. Distinguish clearly between:
    - actual measured data;
    - citizen observations;
    - historical or contextual evidence;
    - model-derived factors;
    - the final machine-generated risk score.

14. When explaining how a factor affects the evaluation, only describe the
    relationship supported by the supplied risk assessment. Do not invent
    causal relationships.

15. If a factor is unavailable, missing, uncertain, or based on limited
    evidence, say so instead of guessing.

16. Do not imply that a high measurement automatically means high risk
    unless the supplied risk assessment supports that interpretation.

17. Do not simply repeat every number supplied by the risk engine.
    Select the measurements and factors that actually help explain the
    result.

18. Recommendations must be practical, cautious, and directly related to
    the supplied hazard and evidence.

19. Recommendations must NOT introduce new facts or assumptions.

20. Do not recommend actions that require information or services that
    were not supplied by the application.

21. Keep the explanation concise enough for a mobile application.

22. Every user-facing field MUST be written in French.

HOW THE FOUR JSON FIELDS MUST WORK:

SUMMARY:

The summary explains WHAT the existing result means.

It must answer:

"Quel est le niveau de risque actuel et que signifie le résultat fourni
par le système ?"

Use exactly 1 or 2 clear sentences.

Use the supplied score and risk level as they are.

Do not recalculate them.

Do not invent a new interpretation or threshold.

EXPLANATION:

The explanation answers both:

"Pourquoi le système a-t-il attribué ce niveau ?"

and:

"Comment les données et facteurs disponibles influencent-ils cette
évaluation ?"

Write approximately 3 to 5 concise sentences.

Connect the most important supplied evidence and factors to the existing
risk evaluation.

When useful, mention actual measurements and units rather than only
abstract factor scores.

Clearly distinguish measured evidence from the calculated risk score.

Do not claim causality unless it is explicitly supported by the supplied
assessment.

MAIN FACTORS:

List 2 to 4 of the most important supporting data, observations, or
factors used by the risk assessment.

These should help answer:

"Quelles informations ont réellement été prises en compte ?"

Whenever possible, include:

- the relevant measurement or observation;
- its unit or context;
- why it matters to the evaluation.

Do not simply copy technical variable names.

Do not invent missing values.

If an important factor is unavailable or uncertain, say so when relevant.

RECOMMENDATIONS:

List 2 to 4 practical actions or precautions.

These answer:

"Que peut faire concrètement le résident compte tenu des informations
disponibles ?"

Recommendations must be directly connected to the supplied hazard,
risk level, and evidence.

They must be cautious and realistic.

Do not invent emergency procedures, authorities, shelters, phone numbers,
evacuation routes, services, or unsupported safety advice.

Do not give an evacuation order unless the supplied data explicitly
justify it.

If the evidence is insufficient for a specific action, give only a
reasonable general precaution or acknowledge that the information is
insufficient.

IMPORTANT:

Do NOT create a fifth JSON field.

The four JSON fields collectively provide the complete explanation:

- summary = what the result means;
- explanation = why the result was assigned + how the evidence affects it;
- mainFactors = which important data/factors support the evaluation;
- recommendations = what the resident can practically do.

Return ONLY valid JSON.

Do not use Markdown.

Do not wrap the JSON in code fences.

The JSON must have exactly this structure:

{
  "summary": "string",
  "explanation": "string",
  "mainFactors": ["string"],
  "recommendations": ["string"]
}
`;

const CORS_HEADERS = {
  "Access-Control-Allow-Origin": "*",
  "Access-Control-Allow-Methods": "POST, OPTIONS",
  "Access-Control-Allow-Headers": "Content-Type",
};

function jsonResponse(data, status = 200) {
  return new Response(JSON.stringify(data), {
    status,
    headers: {
      "Content-Type": "application/json",
      ...CORS_HEADERS,
    },
  });
}

function extractJson(text) {
  const cleaned = text.trim();

  if (
    cleaned.startsWith("```json") &&
    cleaned.endsWith("```")
  ) {
    return cleaned.substring(7, cleaned.length - 3).trim();
  }

  if (
    cleaned.startsWith("```") &&
    cleaned.endsWith("```")
  ) {
    return cleaned.substring(3, cleaned.length - 3).trim();
  }

  return cleaned;
}

function validateAnalysis(analysis) {
  return (
    analysis &&
    typeof analysis === "object" &&
    typeof analysis.summary === "string" &&
    typeof analysis.explanation === "string" &&
    Array.isArray(analysis.mainFactors) &&
    Array.isArray(analysis.recommendations)
  );
}

export default {
  async fetch(request, env) {
    if (request.method === "OPTIONS") {
      return new Response(null, {
        status: 204,
        headers: CORS_HEADERS,
      });
    }

    if (request.method !== "POST") {
      return jsonResponse(
        { error: "Method Not Allowed" },
        405,
      );
    }

    if (!env.RODIUMAI_API_KEY) {
      return jsonResponse(
        { error: "RODIUMAI_API_KEY is not configured." },
        500,
      );
    }

    try {
      const body = await request.json();

      const riskResult = body.riskResult;

      if (!riskResult || typeof riskResult !== "object") {
        return jsonResponse(
          { error: "riskResult is required." },
          400,
        );
      }

      const prompt = `
Interprète l’évaluation de risque Urban Resilience suivante.

Tous les champs destinés à l’utilisateur doivent être rédigés en français.

Le score et le niveau de risque ont déjà été calculés par l’application.
NE LES RECALCULE PAS.
NE LES MODIFIE PAS.
NE LES REMPLACE PAS par une autre valeur ou un autre niveau.

Construis une explication cohérente uniquement à partir des données
fournies.

Le résident doit pouvoir comprendre les cinq points suivants :

1. CE QUE signifie le résultat actuel et le niveau de risque fourni.

2. POURQUOI le système a attribué ce niveau.

3. QUELLES données, mesures, observations et facteurs ont réellement été
   utilisés.

4. COMMENT ces données et facteurs contribuent à l’évaluation.

5. QUELLES précautions ou actions pratiques sont justifiées par les
   informations disponibles.

Pour expliquer le résultat :

- utilise le score et le niveau fournis ;
- ne crée pas de nouveau score ;
- ne crée pas de nouveau seuil de risque ;
- explique le résultat en langage simple ;
- distingue le score calculé par l'application des données qui ont servi
  à l'évaluation.

Pour expliquer les données :

- privilégie les mesures réelles et leurs unités ;
- utilise les valeurs de référence lorsqu'elles sont fournies et
  pertinentes ;
- explique les comparaisons en langage simple ;
- explique le rôle des facteurs réellement disponibles ;
- distingue les mesures réelles du score calculé ;
- distingue les observations citoyennes vérifiées des observations non
  vérifiées ;
- indique clairement lorsqu'une donnée est indisponible ou incertaine ;
- ne transforme jamais une simple association fournie par le système en
  causalité certaine ;
- n'invente aucune valeur de référence, seuil, norme ou relation.

Pour les recommandations :

- elles doivent découler directement du risque, du type de danger et des
  éléments fournis ;
- elles doivent être compréhensibles et réalisables par un résident ;
- elles doivent rester prudentes ;
- elles ne doivent pas inventer de services, autorités, numéros,
  refuges, itinéraires ou procédures d'urgence ;
- ne donne pas d'ordre d'évacuation sans preuve explicite dans les données.

Ne répète pas inutilement toutes les données disponibles.

Sélectionne uniquement les informations qui permettent réellement de
comprendre le résultat.

Évaluation de risque :

${JSON.stringify(riskResult)}
`;

      const rodiumResponse = await fetch(
        RODIUM_URL,
        {
          method: "POST",
          headers: {
            Authorization:
              `Bearer ${env.RODIUMAI_API_KEY}`,
            "Content-Type": "application/json",
          },
          body: JSON.stringify({
            model: MODEL,
            messages: [
              {
                role: "system",
                content: SYSTEM_PROMPT,
              },
              {
                role: "user",
                content: prompt,
              },
            ],
            max_tokens: 2048,
          }),
        },
      );

      const responseText = await rodiumResponse.text();

      console.log(
        "RODIUM RESPONSE:",
        rodiumResponse.status,
        responseText,
      );

      if (!rodiumResponse.ok) {
        return jsonResponse(
          {
            error: "Rodium request failed.",
            status: rodiumResponse.status,
            details: responseText,
          },
          rodiumResponse.status,
        );
      }

      let rodiumData;

      try {
        rodiumData = JSON.parse(responseText);
      } catch (_) {
        return jsonResponse(
          {
            error: "Rodium returned invalid JSON.",
          },
          502,
        );
      }

      const content =
        rodiumData?.choices?.[0]?.message?.content;

      if (
        typeof content !== "string" ||
        content.trim() === ""
      ) {
        return jsonResponse(
          {
            error: "Rodium returned an empty AI response.",
          },
          502,
        );
      }

      let analysis;

      try {
        analysis = JSON.parse(
          extractJson(content),
        );
      } catch (_) {
        return jsonResponse(
          {
            error: "AI response was not valid JSON.",
            details: content,
          },
          502,
        );
      }

      if (!validateAnalysis(analysis)) {
        return jsonResponse(
          {
            error:
              "AI response does not match RiskAnalysis.",
            details: JSON.stringify(analysis),
          },
          502,
        );
      }

      return jsonResponse(
        {
          summary: analysis.summary.trim(),

          explanation: analysis.explanation.trim(),

          mainFactors: analysis.mainFactors
            .map((item) => String(item).trim())
            .filter((item) => item.length > 0)
            .slice(0, 4),

          recommendations: analysis.recommendations
            .map((item) => String(item).trim())
            .filter((item) => item.length > 0)
            .slice(0, 4),
        },
        200,
      );
    } catch (error) {
      console.log("WORKER ERROR:", error);

      return jsonResponse(
        {
          error:
            error instanceof Error
              ? error.message
              : "Proxy request failed.",
        },
        500,
      );
    }
  },
};
