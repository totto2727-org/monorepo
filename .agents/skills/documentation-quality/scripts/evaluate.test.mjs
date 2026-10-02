import { chmod, mkdtemp, readFile, rm, writeFile } from "node:fs/promises";
import { tmpdir } from "node:os";
import { resolve } from "node:path";
import { afterEach, describe, expect, it } from "vitest";

import { evaluate, segmentMarkdown, validateResponse } from "./evaluate.mjs";

const temporaryDirectories = [];

async function fixture() {
  const directory = await mkdtemp(resolve(tmpdir(), "documentation-quality-test-"));
  temporaryDirectories.push(directory);
  await writeFile(
    resolve(directory, "guide.md"),
    "# Start\n\nUse the tool.\n\n## Details\n\n```md\n# Not a heading\n```\n\nMore detail.\n",
  );
  const manifest = {
    model: "jev-latest",
    threshold: 0.8,
    rules: [
      {
        id: "direct",
        scope: "section",
        instructions: "Evaluate directness.",
        pass: "Direct.",
        fail: "Indirect.",
        expected: "pass",
      },
      {
        id: "flow",
        scope: "page",
        instructions: "Evaluate flow.",
        pass: "Coherent.",
        fail: "Fragmented.",
      },
    ],
    documents: [
      {
        id: "guide",
        path: "guide.md",
        purpose: "Teach setup.",
        audience: "A new user.",
        context: "Evidence only.",
        ruleIds: ["direct", "flow"],
        expected: { direct: "pass" },
      },
    ],
  };
  const manifestPath = resolve(directory, "manifest.json");
  await writeFile(manifestPath, JSON.stringify(manifest));
  return { directory, manifestPath, outputPath: resolve(directory, "report.json") };
}

async function installCurlMock(directory, mode = "valid") {
  const script = resolve(directory, "curl");
  await writeFile(
    script,
    `#!/usr/bin/env node
const fs = require("node:fs");
const config = fs.readFileSync(0, "utf8");
const value = (name) => new RegExp("^" + name + " = \\"([^\\"]+)\\"", "m").exec(config)?.[1];
const requestPath = value("data-binary").slice(1);
const headersPath = value("dump-header");
const payload = JSON.parse(fs.readFileSync(requestPath, "utf8"));
fs.appendFileSync(process.env.CURL_LOG, JSON.stringify({ config, payload, at: Date.now() }) + "\\n");
const answer = () => ({ type: "choice", choice: "pass", confidence: 0.94, probabilities: { pass: 0.96, fail: 0.03, not_applicable: 0, insufficient_context: 0.01 } });
const response = ${JSON.stringify(mode)} === "malformed"
  ? { success: true, data: { model: "jev-1.13.0", answers: { wrong: { type: "choice", choice: "pass", confidence: 1, probabilities: { pass: 1, fail: 0, not_applicable: 0, insufficient_context: 0 } } } } }
  : { success: true, data: { model: "jev-1.13.0", usage: { inputTokens: 1 }, answers: Object.fromEntries(Object.keys(payload.input.questions).map((id) => [id, answer()])) } };
fs.writeFileSync(headersPath, "HTTP/1.1 200 OK\\r\\n\\r\\n");
setTimeout(() => process.stdout.write(JSON.stringify(response) + "\\n200"), 20);
`,
  );
  await chmod(script, 0o755);
  return script;
}

afterEach(async () => {
  await Promise.all(
    temporaryDirectories
      .splice(0)
      .map((directory) => rm(directory, { recursive: true, force: true })),
  );
});

describe("documentation quality evaluator public pipeline", () => {
  it("segments heading units without splitting fenced code and retains hierarchy", () => {
    const sections = segmentMarkdown(
      "# Parent\n\n## Child\n\n````md\n~~~\n# Example only\n```\n~~~\n````\n\nText.\n",
    );
    expect(sections).toHaveLength(2);
    expect(sections[1]).toMatchObject({ headingPath: ["Parent", "Child"] });
    expect(sections[1].text).toContain("# Example only");
    expect(sections[0].sourceRange.endLine).toBe(2);
  });

  it("accepts two-decimal probability rounding without accepting invalid distributions", () => {
    const questions = { "q-000001": { type: "choice" } };
    const response = (probabilities) => ({
      success: true,
      data: {
        answers: {
          "q-000001": { type: "choice", choice: "pass", confidence: 0.99, probabilities },
        },
      },
    });
    expect(() =>
      validateResponse(
        response({ pass: 0.99, fail: 0.01, not_applicable: 0, insufficient_context: 0 }),
        questions,
      ),
    ).not.toThrow();
    expect(() =>
      validateResponse(
        response({ pass: 0.99, fail: 0.02, not_applicable: 0, insufficient_context: 0 }),
        questions,
      ),
    ).not.toThrow();
    expect(() =>
      validateResponse(
        response({ pass: 0.8, fail: 0, not_applicable: 0, insufficient_context: 0 }),
        questions,
      ),
    ).toThrow("probabilities must sum to 1");
  });

  it("evaluates bounded work concurrently and never leaks calibration labels into model state", async () => {
    const paths = await fixture();
    const log = resolve(paths.directory, "curl.log");
    await installCurlMock(paths.directory);
    const originalPath = process.env.PATH;
    process.env.PATH = `${paths.directory}:${originalPath}`;
    process.env.CURL_LOG = log;
    try {
      const report = await evaluate({
        manifestPath: paths.manifestPath,
        outputPath: paths.outputPath,
        concurrency: 2,
        environment: {
          OPENCONNECTOR_BASE_URL: "https://connector.example",
          OPENCONNECTOR_TOKEN: "secret",
        },
      });
      expect(report.reviewRequired).toBe(false);
      expect(report.evaluations).toHaveLength(3);
      expect(report.evaluations.at(-1)).toMatchObject({ scope: "page", model: "jev-1.13.0" });
      const calls = (await readFile(log, "utf8")).trim().split("\n").map(JSON.parse);
      expect(calls).toHaveLength(3);
      expect(
        calls.every(
          ({ config }) =>
            !config.includes("--location") && config.includes("Authorization: Bearer secret"),
        ),
      ).toBe(true);
      expect(
        calls.every(
          ({ payload }) => JSON.stringify(payload.input.state).includes("expected") === false,
        ),
      ).toBe(true);
      expect(
        calls.every(({ payload }) => JSON.stringify(payload.input.state).includes("old") === false),
      ).toBe(true);
      expect(calls.every(({ payload }) => Object.keys(payload.input.questions).length > 0)).toBe(
        true,
      );
    } finally {
      process.env.PATH = originalPath;
      delete process.env.CURL_LOG;
    }
  });

  it("writes a review-required report when the public transport returns malformed answers", async () => {
    const paths = await fixture();
    const log = resolve(paths.directory, "curl.log");
    await installCurlMock(paths.directory, "malformed");
    const originalPath = process.env.PATH;
    process.env.PATH = `${paths.directory}:${originalPath}`;
    process.env.CURL_LOG = log;
    try {
      const report = await evaluate({
        manifestPath: paths.manifestPath,
        outputPath: paths.outputPath,
        environment: {
          OPENCONNECTOR_BASE_URL: "https://connector.example",
          OPENCONNECTOR_TOKEN: "secret",
        },
      });
      expect(report.reviewRequired).toBe(true);
      expect(report.evaluations.every((entry) => entry.status === "error")).toBe(true);
      expect(JSON.parse(await readFile(paths.outputPath, "utf8")).evaluations).toHaveLength(3);
    } finally {
      process.env.PATH = originalPath;
      delete process.env.CURL_LOG;
    }
  });

  it("performs zero network calls in dry-run mode", async () => {
    const paths = await fixture();
    const report = await evaluate({
      manifestPath: paths.manifestPath,
      outputPath: paths.outputPath,
      dryRun: true,
      environment: {},
    });
    expect(report).toMatchObject({ dryRun: true, reviewRequired: false });
    expect(report.evaluations.every((entry) => entry.status === "dry_run")).toBe(true);
  });

  it("resolves an exclusive rulesFile relative to the manifest", async () => {
    const paths = await fixture();
    const manifest = JSON.parse(await readFile(paths.manifestPath, "utf8"));
    await writeFile(resolve(paths.directory, "rules.json"), JSON.stringify(manifest.rules));
    delete manifest.rules;
    manifest.rulesFile = "rules.json";
    await writeFile(paths.manifestPath, JSON.stringify(manifest));
    const report = await evaluate({
      manifestPath: paths.manifestPath,
      outputPath: paths.outputPath,
      dryRun: true,
      environment: {},
    });
    expect(report.evaluations).toHaveLength(3);
  });

  it("derives explicit sections from source ranges and rejects an empty list", async () => {
    const paths = await fixture();
    const manifest = JSON.parse(await readFile(paths.manifestPath, "utf8"));
    manifest.documents[0].sections = [
      { id: "detail", startLine: 5, endLine: 10, headingPath: ["Start", "Details"] },
    ];
    await writeFile(paths.manifestPath, JSON.stringify(manifest));
    const report = await evaluate({
      manifestPath: paths.manifestPath,
      outputPath: paths.outputPath,
      dryRun: true,
      environment: {},
    });
    expect(report.evaluations[0].section).toMatchObject({
      id: "detail",
      sourceRange: { startLine: 5, endLine: 10 },
    });
    manifest.documents[0].sections = [];
    await writeFile(paths.manifestPath, JSON.stringify(manifest));
    await expect(
      evaluate({
        manifestPath: paths.manifestPath,
        outputPath: paths.outputPath,
        dryRun: true,
        environment: {},
      }),
    ).rejects.toThrow("sections must not be empty");
  });
});
