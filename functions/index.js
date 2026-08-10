const {onRequest} = require("firebase-functions/v2/https");
const {onMessagePublished} = require("firebase-functions/v2/pubsub");
const {defineSecret} = require("firebase-functions/params");
const logger = require("firebase-functions/logger");
const {GoogleAuth} = require("google-auth-library");
require("firebase-admin/app");

const geminiApiKey = defineSecret("GEMINI_API_KEY");
const model = "gemini-2.5-flash";
const playRtdnTopic = "play-rtdn";
const defaultPlayPackageName = "nl.mlmasters.anxietyslayer";
const androidPublisherScope = "https://www.googleapis.com/auth/androidpublisher";
const reviewRefundPreference = "NEUTRAL";
const maxRequestBodyBytes = 3 * 1024 * 1024;
const maxDrawingBytes = 2 * 1024 * 1024;
const maxDrawingBase64Chars = Math.ceil(maxDrawingBytes / 3) * 4;
const maxRecentJokes = 10;
const fieldLimits = {
  userMessage: 4000,
  pageTitle: 200,
  pageContext: 4000,
  journalEntries: 50000,
  summary: 10000,
  question: 4000,
  pngBase64: maxDrawingBase64Chars,
  guess: 500,
  userReply: 2000,
  recentJoke: 500,
  orderId: 256,
  pendingRefundToken: 4096,
};

const playAuth = new GoogleAuth({
  scopes: [androidPublisherScope],
});

exports.gwenAi = onRequest(
  {
    secrets: [geminiApiKey],
    timeoutSeconds: 60,
    memory: "512MiB",
    cors: true,
  },
  async (req, res) => {
    if (req.method !== "POST") {
      res.status(405).json({error: "Method not allowed."});
      return;
    }

    try {
      enforceRequestBodyLimit(req);
      const {operation, payload} = requireRequestBody(req.body);
      const geminiBody = buildGeminiBody(operation, payload);
      const text = await callGemini(geminiBody);
      res.status(200).json({text});
    } catch (error) {
      const statusCode = error.statusCode || 500;
      if (statusCode < 500) {
        logger.warn("Rejected invalid Gwyn AI request.", {
          statusCode,
          reason: error.message,
        });
      } else {
        logger.error("Gwyn AI request failed", error);
      }
      res.status(statusCode).json({
        error: error.publicMessage || "Gwyn could not respond right now.",
      });
    }
  },
);

exports.googlePlayRtdn = onMessagePublished(
  {
    topic: playRtdnTopic,
    timeoutSeconds: 60,
    memory: "256MiB",
    retry: true,
  },
  async (event) => {
    const message = event.data.message;
    const notification = message.json;

    logger.info("Received Google Play RTDN.", {
      messageId: message.messageId,
      packageName: notification.packageName,
      eventTimeMillis: notification.eventTimeMillis,
      notificationKind: notificationKind(notification),
    });

    const expectedPackageName = getPlayPackageName();
    if (notification.packageName !== expectedPackageName) {
      logger.warn("Ignoring RTDN for unexpected package.", {
        expectedPackageName,
        receivedPackageName: notification.packageName,
      });
      return;
    }

    if (!notification.pendingRefundReviewNotification) {
      logger.info("RTDN does not require refund review.", {
        notificationKind: notificationKind(notification),
      });
      return;
    }

    await reviewPendingRefund(notification);
  },
);

async function reviewPendingRefund(notification) {
  const pendingReview = notification.pendingRefundReviewNotification;
  const requestBody = buildReviewRefundRequest(notification);
  const packageName = notification.packageName;
  const orderId = requireString(
    pendingReview.orderId,
    "orderId",
    fieldLimits.orderId,
  );
  const url =
    `https://androidpublisher.googleapis.com/androidpublisher/v3/applications/` +
    `${encodeURIComponent(packageName)}/orders/${encodeURIComponent(orderId)}` +
    `:reviewrefund`;

  const headers = await playAuth.getRequestHeaders(url);
  const response = await fetch(
    url,
    {
      method: "POST",
      headers: {
        ...toPlainHeaders(headers),
        "Content-Type": "application/json",
      },
      body: JSON.stringify(requestBody),
    },
  );

  if (!response.ok) {
    const responseText = await response.text();
    throw new Error(
      `ReviewRefund failed for ${orderId}: ${response.status} ${responseText}`,
    );
  }

  logger.info("Submitted Google Play refund review suggestion.", {
    orderId,
    refundPreference: requestBody.refundPreference,
    usageEventCount: requestBody.consumptionUsageEvents?.length ?? 0,
  });
}

function buildReviewRefundRequest(notification) {
  const pendingReview = notification.pendingRefundReviewNotification;
  const usageEvents = buildConsumptionUsageEvents(notification);
  const requestBody = {
    pendingRefundToken: requireString(
      pendingReview.pendingRefundToken,
      "pendingRefundToken",
      fieldLimits.pendingRefundToken,
    ),
    sampleContentProvided: true,
    refundPreference: reviewRefundPreference,
  };

  if (usageEvents.length > 0) {
    requestBody.consumptionUsageEvents = usageEvents;
  }

  return requestBody;
}

function buildConsumptionUsageEvents() {
  return [];
}

function notificationKind(notification) {
  if (notification.pendingRefundReviewNotification) {
    return "pendingRefundReviewNotification";
  }
  if (notification.subscriptionNotification) {
    return "subscriptionNotification";
  }
  if (notification.oneTimeProductNotification) {
    return "oneTimeProductNotification";
  }
  if (notification.voidedPurchaseNotification) {
    return "voidedPurchaseNotification";
  }
  if (notification.testNotification) {
    return "testNotification";
  }
  return "unknown";
}

function toPlainHeaders(headers) {
  if (headers && typeof headers.entries === "function") {
    return Object.fromEntries(headers.entries());
  }
  return headers || {};
}

function getPlayPackageName() {
  return process.env.PLAY_PACKAGE_NAME || defaultPlayPackageName;
}

function buildGeminiBody(operation, payload) {
  switch (operation) {
    case "generateGwenResponse":
      return textRequest(
        baseGwynInstruction(),
        requireString(
          payload.userMessage,
          "userMessage",
          fieldLimits.userMessage,
        ),
        1024,
        0.8,
      );

    case "generateContextualGwenResponse": {
      const pageTitle = requireString(
        payload.pageTitle,
        "pageTitle",
        fieldLimits.pageTitle,
      );
      const pageContext = requireString(
        payload.pageContext,
        "pageContext",
        fieldLimits.pageContext,
      );
      return textRequest(
        `${baseGwynInstruction()} The user opened Gwyn from the "${pageTitle}" page, so tailor the answer to that page context. Page context: ${pageContext}`,
        requireString(
          payload.userMessage,
          "userMessage",
          fieldLimits.userMessage,
        ),
        1024,
        0.8,
      );
    }

    case "summarizeJournalEntries":
      return textRequest(
        "You are Gwyn, a warm anxiety-support companion in a Flutter app. Summarize the user journal entries with care and emotional sensitivity. Do not diagnose, do not overstate patterns, and do not replace professional care. Focus on recurring feelings, possible triggers, coping strengths, and one gentle next step. Use the user-provided journal text only. Keep the response concise: 4 short bullet points maximum.",
        `Please summarize these journal entries as Gwyn:\n\n${requireString(
          payload.journalEntries,
          "journalEntries",
          fieldLimits.journalEntries,
        )}`,
        1024,
        0.5,
      );

    case "respondToJournalSummaryQuestion": {
      const journalEntries = requireString(
        payload.journalEntries,
        "journalEntries",
        fieldLimits.journalEntries,
      );
      const summary = requireString(
        payload.summary,
        "summary",
        fieldLimits.summary,
      );
      const question = requireString(
        payload.question,
        "question",
        fieldLimits.question,
      );
      return textRequest(
        "You are Gwyn, a warm anxiety-support companion in a Flutter app. Answer follow-up questions about the user journal summary with care and emotional sensitivity. Use only the supplied journal entries and summary as context. Do not diagnose, do not overstate patterns, and do not replace professional care. If the user sounds in immediate danger, encourage them to contact local emergency help or a trusted person now. Keep replies concise: 2 short paragraphs maximum.",
        `Journal entries:\n${journalEntries}\n\nGwyn summary:\n${summary}\n\nUser question:\n${question}`,
        1024,
        0.7,
      );
    }

    case "guessDrawing":
      return drawingRequest(requirePngBase64(payload.pngBase64));

    case "respondToDrawingGuess": {
      const guess = requireString(
        payload.guess,
        "guess",
        fieldLimits.guess,
      );
      const userReply = requireString(
        payload.userReply,
        "userReply",
        fieldLimits.userReply,
      );
      return textRequest(
        "You are Gwyn, a playful anxiety-support companion in a drawing guessing game. React to the user in a warm, funny way. If they correct your guess, happily accept the correction. If they say you were right, celebrate briefly. Keep the reply to 1 or 2 short sentences.",
        `Gwyn guessed: "${guess}"\nThe user replied: "${userReply}"\nRespond as Gwyn.`,
        1024,
        0.8,
      );
    }

    case "generateRelaxingJoke": {
      const recentJokes = requireStringArray(
        payload.recentJokes,
        "recentJokes",
        maxRecentJokes,
        fieldLimits.recentJoke,
      );
      const topics = [
        "tea",
        "clouds",
        "plants",
        "blankets",
        "socks",
        "stars",
        "books",
        "rain",
        "pillows",
        "sunlight",
      ];
      const topic = topics[Date.now() % topics.length];
      const recentJokesText = recentJokes.length === 0 ?
        "No previous jokes yet." :
        recentJokes.map((joke) => `- ${joke}`).join("\n");

      return textRequest(
        "You are Gwyn, a warm anxiety-support companion in a Flutter app. Tell exactly one gentle, relaxing joke that is light, kind, and suitable for someone feeling anxious. Avoid dark humor, insults, medical jokes, emergency themes, and anything mean. Do not repeat or closely paraphrase any recent jokes provided by the user. Keep it short: 1 or 2 sentences maximum.",
        `Please tell me one calming joke to help someone soften a tense moment. Use this loose theme to keep it fresh: ${topic}.\n\nRecent jokes to avoid:\n${recentJokesText}`,
        512,
        0.9,
        {thinkingConfig: {thinkingBudget: 0}},
      );
    }

    default: {
      const error = new Error(`Unsupported operation: ${operation}`);
      error.statusCode = 400;
      error.publicMessage = "Unsupported Gwyn request.";
      throw error;
    }
  }
}

function baseGwynInstruction() {
  return "You are Gwyn, a warm anxiety-support companion in a Flutter app. Answer with kindness, practical grounding suggestions, and light encouragement. Do not claim to diagnose or replace professional care. If the user sounds in immediate danger, encourage them to contact local emergency help or a trusted person now. Keep replies concise: 2 short paragraphs maximum.";
}

function textRequest(systemInstruction, text, maxOutputTokens, temperature, extraConfig = {}) {
  return {
    system_instruction: {
      parts: [{text: systemInstruction}],
    },
    contents: [
      {
        parts: [{text}],
      },
    ],
    generationConfig: {
      maxOutputTokens,
      temperature,
      ...extraConfig,
    },
  };
}

function drawingRequest(pngBase64) {
  return {
    system_instruction: {
      parts: [
        {
          text: "You are Gwyn, a playful anxiety-support companion. The user drew a picture for a light stress-relief game. Guess what the drawing is with warmth and humor. If it is unclear, make one cheerful best guess. Reply with exactly one complete sentence under 20 words. End the sentence with punctuation.",
        },
      ],
    },
    contents: [
      {
        parts: [
          {
            text: "What do you think this drawing is? Reply as Gwyn with one complete playful sentence.",
          },
          {
            inline_data: {
              mime_type: "image/png",
              data: pngBase64,
            },
          },
        ],
      },
    ],
    generationConfig: {maxOutputTokens: 1024, temperature: 0.8},
  };
}

async function callGemini(body) {
  const apiKey = geminiApiKey.value();
  if (!apiKey) {
    const error = new Error("Missing GEMINI_API_KEY secret.");
    error.statusCode = 500;
    error.publicMessage = "Gwyn is not configured yet.";
    throw error;
  }

  const response = await fetch(
    `https://generativelanguage.googleapis.com/v1beta/models/${model}:generateContent`,
    {
      method: "POST",
      headers: {
        "Content-Type": "application/json",
        "x-goog-api-key": apiKey,
      },
      body: JSON.stringify(body),
    },
  );

  const responseText = await response.text();
  if (!response.ok) {
    const error = new Error(`Gemini request failed: ${response.status} ${responseText}`);
    error.statusCode = 502;
    error.publicMessage = "Gwyn could not respond right now.";
    throw error;
  }

  return extractText(responseText);
}

function extractText(responseText) {
  const decoded = JSON.parse(responseText);
  const text = decoded.candidates
    ?.flatMap((candidate) => candidate.content?.parts || [])
    ?.map((part) => part.text)
    ?.filter((partText) => typeof partText === "string")
    ?.join("\n")
    ?.trim();

  if (!text) {
    const error = new Error("Gemini returned an empty response.");
    error.statusCode = 502;
    error.publicMessage = "Gwyn returned an empty response.";
    throw error;
  }

  return text;
}

function enforceRequestBodyLimit(req) {
  const contentLength = Number(req.get("content-length") || 0);
  const rawBodyLength = Buffer.isBuffer(req.rawBody) ? req.rawBody.length : 0;

  if (contentLength > maxRequestBodyBytes || rawBodyLength > maxRequestBodyBytes) {
    throwHttpError(413, "Request body too large.", "Request body too large.");
  }
}

function requireRequestBody(body) {
  if (!isPlainObject(body)) {
    throwHttpError(400, "Invalid request body.", "Invalid Gwyn request data.");
  }
  if (typeof body.operation !== "string" || body.operation.length === 0) {
    throwHttpError(400, "Missing operation.", "Missing Gwyn request data.");
  }
  if (!isPlainObject(body.payload)) {
    throwHttpError(400, "Invalid payload.", "Invalid Gwyn request data.");
  }
  return {operation: body.operation, payload: body.payload};
}

function requireString(value, fieldName, maxChars) {
  if (typeof value !== "string" || value.trim().length === 0) {
    throwHttpError(
      400,
      `Missing required field: ${fieldName}`,
      "Missing Gwyn request data.",
    );
  }
  const trimmed = value.trim();
  if (trimmed.length > maxChars) {
    throwHttpError(
      413,
      `Field too long: ${fieldName}`,
      `${fieldName} is too long.`,
    );
  }
  return trimmed;
}

function requireStringArray(value, fieldName, maxItems, maxItemChars) {
  if (value === undefined) return [];
  if (!Array.isArray(value)) {
    throwHttpError(
      400,
      `Invalid array: ${fieldName}`,
      `${fieldName} is invalid.`,
    );
  }
  if (value.length > maxItems) {
    throwHttpError(
      413,
      `Too many items: ${fieldName}`,
      `${fieldName} contains too many items.`,
    );
  }
  return value.map((item, index) =>
    requireString(item, `${fieldName}[${index}]`, maxItemChars));
}

function requirePngBase64(value) {
  const encoded = requireString(
    value,
    "pngBase64",
    fieldLimits.pngBase64,
  );
  const isValidBase64 = encoded.length % 4 === 0 &&
    /^[A-Za-z0-9+/]*={0,2}$/.test(encoded);
  if (!isValidBase64) {
    throwHttpError(400, "Invalid PNG encoding.", "Drawing data is invalid.");
  }
  if (Buffer.byteLength(encoded, "base64") > maxDrawingBytes) {
    throwHttpError(413, "Oversized PNG.", "Drawing is too large.");
  }
  return encoded;
}

function isPlainObject(value) {
  return value !== null && typeof value === "object" && !Array.isArray(value);
}

function throwHttpError(statusCode, message, publicMessage) {
  const error = new Error(message);
  error.statusCode = statusCode;
  error.publicMessage = publicMessage;
  throw error;
}
