const { onCall, HttpsError } = require("firebase-functions/v2/https");
const { defineString } = require("firebase-functions/params");
const axios = require("axios");

// ── ANAHTARLAR (Yeni sistem: params) ─────────────────────────────
const RAPIDAPI_KEY = defineString("RAPIDAPI_KEY");
const GEMINI_KEY = defineString("GEMINI_KEY");

// ── 1. KOD ÇALIŞTIRMA (Judge0) ───────────────────────────────────
exports.executeCode = onCall(async (request) => {
  const { sourceCode, languageId } = request.data;

  try {
    const response = await axios.post(
      "https://judge0-ce.p.rapidapi.com/submissions?base64_encoded=false&wait=true",
      {
        source_code: sourceCode,
        language_id: languageId,
        stdin: "",
      },
      {
        headers: {
          "content-type": "application/json",
          "X-RapidAPI-Key": RAPIDAPI_KEY.value(),
          "X-RapidAPI-Host": "judge0-ce.p.rapidapi.com",
        },
      }
    );
    return response.data;
  } catch (error) {
    throw new HttpsError("internal", "Judge0 API Hatası: " + error.message);
  }
});

// ── 2. YAPAY ZEKA YARDIMI (Gemini) ───────────────────────────────
exports.getAiHelp = onCall(async (request) => {
  const { prompt } = request.data;

  try {
    const response = await axios.post(
      `https://generativelanguage.googleapis.com/v1beta/models/gemini-2.5-flash:generateContent?key=${GEMINI_KEY.value()}`,
      {
        contents: [{ parts: [{ text: prompt }] }],
      },
      {
        headers: { "content-type": "application/json" },
      }
    );

    const text =
      response.data?.candidates?.[0]?.content?.parts?.[0]?.text ??
      "Üzgünüm, şu an tavsiye veremiyorum.";

    return { text };
  } catch (error) {
    throw new HttpsError("internal", "Gemini API Hatası: " + error.message);
  }
});