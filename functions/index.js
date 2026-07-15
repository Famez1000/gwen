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
      const {operation, payload = {}} = req.body || {};
      const geminiBody = buildGeminiBody(operation, payload);
      const text = await callGemini(geminiBody);
      res.status(200).json({text});
    } catch (error) {
      logger.error("Gwyn AI request failed", error);
      res.status(error.statusCode || 500).json({
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
  const orderId = requireString(pendingReview.orderId, "orderId");
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
        requireString(payload.userMessage, "userMessage"),
        1024,
        0.8,
      );

    case "generateContextualGwenResponse": {
      const pageTitle = requireString(payload.pageTitle, "pageTitle");
      const pageContext = requireString(payload.pageContext, "pageContext");
      return textRequest(
        `${baseGwynInstruction()} The user opened Gwyn from the "${pageTitle}" page, so tailor the answer to that page context. Page context: ${pageContext}`,
        requireString(payload.userMessage, "userMessage"),
        1024,
        0.8,
      );
    }

    case "summarizeJournalEntries":
      return textRequest(
        "You are Gwyn, a warm anxiety-support companion in a Flutter app. Summarize the user journal entries with care and emotional sensitivity. Do not diagnose, do not overstate patterns, and do not replace professional care. Focus on recurring feelings, possible triggers, coping strengths, and one gentle next step. Use the user-provided journal text only. Keep the response concise: 4 short bullet points maximum.",
        `Please summarize these journal entries as Gwyn:\n\n${requireString(payload.journalEntries, "journalEntries")}`,
        1024,
        0.5,
      );

    case "respondToJournalSummaryQuestion": {
      const journalEntries = requireString(payload.journalEntries, "journalEntries");
      const summary = requireString(payload.summary, "summary");
      const question = requireString(payload.question, "question");
      return textRequest(
        "You are Gwyn, a warm anxiety-support companion in a Flutter app. Answer follow-up questions about the user journal summary with care and emotional sensitivity. Use only the supplied journal entries and summary as context. Do not diagnose, do not overstate patterns, and do not replace professional care. If the user sounds in immediate danger, encourage them to contact local emergency help or a trusted person now. Keep replies concise: 2 short paragraphs maximum.",
        `Journal entries:\n${journalEntries}\n\nGwyn summary:\n${summary}\n\nUser question:\n${question}`,
        1024,
        0.7,
      );
    }

    case "guessDrawing":
      return drawingRequest(requireString(payload.pngBase64, "pngBase64"));

    case "respondToDrawingGuess": {
      const guess = requireString(payload.guess, "guess");
      const userReply = requireString(payload.userReply, "userReply");
      return textRequest(
        "You are Gwyn, a playful anxiety-support companion in a drawing guessing game. React to the user in a warm, funny way. If they correct your guess, happily accept the correction. If they say you were right, celebrate briefly. Keep the reply to 1 or 2 short sentences.",
        `Gwyn guessed: "${guess}"\nThe user replied: "${userReply}"\nRespond as Gwyn.`,
        1024,
        0.8,
      );
    }

    case "generateRelaxingJoke": {
      const recentJokes = Array.isArray(payload.recentJokes) ?
        payload.recentJokes.filter((joke) => typeof joke === "string") :
        [];
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

function requireString(value, fieldName) {
  if (typeof value !== "string" || value.trim().length === 0) {
    const error = new Error(`Missing required field: ${fieldName}`);
    error.statusCode = 400;
    error.publicMessage = "Missing Gwyn request data.";
    throw error;
  }
  return value.trim();
}
