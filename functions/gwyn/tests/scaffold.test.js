const assert = require("node:assert/strict");
const fs = require("node:fs");
const path = require("node:path");
const test = require("node:test");

const gwynRoot = path.resolve(__dirname, "..");
const readJson = (relativePath) =>
  JSON.parse(fs.readFileSync(path.join(gwynRoot, relativePath), "utf8"));

const manifest = readJson("config/agents.json");
const responseSchema = readJson("schemas/agent-response.schema.json");

test("defines the main agent and all three specialists", () => {
  assert.deepEqual(Object.keys(manifest).sort(), [
    "cope",
    "heal",
    "main",
    "understand",
  ]);
  assert.deepEqual(manifest.main.allowedSpecialists, [
    "cope",
    "understand",
    "heal",
  ]);
});

test("every configured instruction file exists and is substantive", () => {
  for (const config of Object.values(manifest)) {
    for (const relativePath of [config.prompt, ...config.shared]) {
      const absolutePath = path.join(gwynRoot, relativePath);
      assert.equal(fs.existsSync(absolutePath), true, relativePath);
      const contents = fs.readFileSync(absolutePath, "utf8");
      assert.match(contents, /^# /);
      assert.ok(contents.length >= 200, `${relativePath} is unexpectedly short`);
    }
  }
});

test("specialists only expose actions supported by the response schema", () => {
  const supportedActions =
    responseSchema.properties.action.properties.type.enum;

  for (const agentName of manifest.main.allowedSpecialists) {
    for (const action of manifest[agentName].allowedActions) {
      assert.ok(
        supportedActions.includes(action),
        `${agentName} exposes unsupported action ${action}`,
      );
    }
  }
});

test("strict object schemas require every declared property", () => {
  const schemaFiles = [
    "schemas/routing.schema.json",
    "schemas/memory-candidate.schema.json",
    "schemas/agent-response.schema.json",
  ];

  const checkObject = (schema, location) => {
    if (schema.type === "object") {
      assert.equal(
        schema.additionalProperties,
        false,
        `${location} must reject additional properties`,
      );
      assert.deepEqual(
        [...schema.required].sort(),
        Object.keys(schema.properties).sort(),
        `${location} must require every property`,
      );
    }

    for (const [key, child] of Object.entries(schema.properties || {})) {
      checkObject(child, `${location}.${key}`);
    }
  };

  for (const schemaFile of schemaFiles) {
    checkObject(readJson(schemaFile), schemaFile);
  }
});
