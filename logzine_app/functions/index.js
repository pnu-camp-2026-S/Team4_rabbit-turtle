// LOGZINE Gemini 프록시 — Cloud Functions(us-central1) 버전.
// Cloudflare Worker와 동일한 두 가지 요청 형식을 받는다:
//   1) POST /            { "model": "...", "body": { Gemini 요청 } }
//   2) POST /v1beta/models/{model}:generateContent  { Gemini 요청 }
// 미국 리전의 Google IP에서 나가므로 위치 차단(FAILED_PRECONDITION)이 발생하지 않는다.

const {onRequest} = require("firebase-functions/v2/https");
const {defineSecret} = require("firebase-functions/params");

const geminiApiKey = defineSecret("GEMINI_API_KEY");

const ALLOWED_MODELS = new Set([
  "gemini-2.5-flash",
  "gemini-flash-latest",
  "gemini-2.5-flash-image",
]);

exports.geminiProxy = onRequest(
  {
    region: "us-central1",
    secrets: [geminiApiKey],
    cors: true,
    timeoutSeconds: 120,
    memory: "256MiB",
    maxInstances: 5,
  },
  async (req, res) => {
    if (req.method === "OPTIONS") {
      res.status(204).send("");
      return;
    }
    if (req.method !== "POST") {
      res.status(405).json({error: {status: "METHOD_NOT_ALLOWED", message: "Use POST."}});
      return;
    }

    const payload = req.body;
    if (!payload || typeof payload !== "object") {
      res.status(400).json({error: {status: "BAD_REQUEST", message: "Invalid JSON."}});
      return;
    }

    const {model, body} = normalizeRequest(req.path, payload);
    if (typeof model !== "string" || !ALLOWED_MODELS.has(model)) {
      res.status(400).json({
        error: {
          status: "BAD_MODEL",
          message: `Unsupported Gemini model: ${model || "(none)"}`,
        },
      });
      return;
    }
    if (!body || typeof body !== "object" || Array.isArray(body)) {
      res.status(400).json({
        error: {status: "BAD_REQUEST", message: "Gemini request body is required."},
      });
      return;
    }

    const url =
      `https://generativelanguage.googleapis.com/v1beta/models/${model}:generateContent`;
    const geminiResponse = await fetch(url, {
      method: "POST",
      headers: {
        "content-type": "application/json",
        "x-goog-api-key": geminiApiKey.value(),
      },
      body: JSON.stringify(body),
    });

    const text = await geminiResponse.text();
    res
      .status(geminiResponse.status)
      .set("content-type", geminiResponse.headers.get("content-type") || "application/json")
      .send(text || JSON.stringify({
        error: {status: "EMPTY_RESPONSE", message: `Gemini returned empty body (${geminiResponse.status}).`},
      }));
  },
);

function normalizeRequest(path, payload) {
  const match = (path || "").match(/^\/(?:v1beta\/)?models\/([^/]+):generateContent$/);
  if (match) {
    return {model: decodeURIComponent(match[1]), body: payload};
  }
  return {model: payload.model, body: payload.body};
}
