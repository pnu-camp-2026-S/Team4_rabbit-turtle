const ALLOWED_MODELS = new Set([
  "gemini-2.5-flash",
  "gemini-2.0-flash",
  "gemini-flash-latest",
  "gemini-2.5-flash-image",
]);

export default {
  async fetch(request, env) {
    const corsHeaders = {
      "access-control-allow-origin": env.ALLOWED_ORIGIN || "*",
      "access-control-allow-methods": "POST, OPTIONS",
      "access-control-allow-headers": "content-type",
      "access-control-max-age": "86400",
    };

    if (request.method === "OPTIONS") {
      return new Response(null, {headers: corsHeaders});
    }

    if (request.method !== "POST") {
      return json({error: "Use POST."}, 405, corsHeaders);
    }

    if (!env.GEMINI_API_KEY) {
      return json({error: "GEMINI_API_KEY secret is missing."}, 500, corsHeaders);
    }

    let payload;
    try {
      payload = await request.json();
    } catch (_) {
      return json({error: "Invalid JSON."}, 400, corsHeaders);
    }

    const {model, body} = payload || {};
    if (typeof model !== "string" || !ALLOWED_MODELS.has(model)) {
      return json({error: "Unsupported Gemini model."}, 400, corsHeaders);
    }
    if (!body || typeof body !== "object" || Array.isArray(body)) {
      return json({error: "Gemini request body is required."}, 400, corsHeaders);
    }

    const url =
      `https://generativelanguage.googleapis.com/v1beta/models/${model}:generateContent`;
    const geminiResponse = await fetch(url, {
      method: "POST",
      headers: {
        "content-type": "application/json",
        "x-goog-api-key": env.GEMINI_API_KEY,
      },
      body: JSON.stringify(body),
    });

    return new Response(await geminiResponse.text(), {
      status: geminiResponse.status,
      headers: {
        ...corsHeaders,
        "content-type":
          geminiResponse.headers.get("content-type") || "application/json",
      },
    });
  },
};

function json(data, status, headers) {
  return new Response(JSON.stringify(data), {
    status,
    headers: {
      ...headers,
      "content-type": "application/json",
    },
  });
}
