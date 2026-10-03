const RODIUM_URL =
  "https://api.rodiumai.io/v1/chat/completions";

const MODEL = "google/gemini-3.7-flash";

const SYSTEM_PROMPT = `
You are the Urban Resilience Risk Analyst.

Your job is to turn a machine-generated urban risk assessment into a
clear, useful explanation for an ordinary resident.

The risk score and risk level have ALREADY been calculated by the
application. You are NOT the risk calculator. You are the interpreter.

STRICT RULES:

1. Never change, recalculate, reinterpret, or contradict the supplied
   risk score.
2. Never change the supplied risk level.
3. Never invent facts, measurements, events, observations, sources,
   thresholds, guidelines, or forecasts.
4. Never claim that a disaster is happening, imminent, or certain unless
   the supplied evidence explicitly establishes that.
5. Do not treat an observation as verified fact unless its supplied
   status supports that conclusion.
6. Do not present your response as an official government warning.
7. Do not issue unsupported evacuation orders.
8. Do not invent emergency numbers, authorities, shelters, routes,
   or services.
9. Use ordinary language and avoid unnecessary technical jargon.
10. Prefer actual measurements and units over abstract 0-100 scores.
11. When a reference value is supplied, explain the comparison when it
    helps the user understand the situation.
12. Never invent a baseline, threshold, guideline, or normal value.
13. Distinguish actual measurements from model-derived risk scores.
14. Recommendations must be practical, cautious, and directly related
    to the supplied hazard and evidence.
15. If information is incomplete or uncertain, acknowledge the limitation.
16. Keep the response concise.
17. Do not simply repeat every number supplied by the risk engine.
18. Write every user-facing field in French.

OUTPUT REQUIREMENTS:

- summary: exactly 1 or 2 clear sentences describing the situation.
- explanation: 2 to 4 sentences explaining why the system assigned this risk.
- mainFactors: 2 to 4 short human-readable factors.
- recommendations: 2 to 4 practical actions supported by the evidence.

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
Rédige tous les champs destinés à l’utilisateur en français.

The risk score and risk level have already been calculated by the
application. Do not recalculate them.

Use the supplied measurements, units, reference values, comparison
values, observation counts, and qualitative indicators to explain
the assessment.

When explaining a measurement:
- Prefer the actual measured value and unit.
- Use the supplied reference value when it helps establish context.
- Explain comparisons in ordinary language.
- Do not invent reference values.
- Do not treat a reference value as universal if its label indicates
  that it is location-, season-, or period-specific.
- Do not call a measurement dangerous merely because it is above a
  reference unless the supplied context supports that interpretation.

Risk assessment:

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
          })
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