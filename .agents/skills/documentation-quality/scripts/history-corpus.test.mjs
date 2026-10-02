import { execFile } from "node:child_process";
import { mkdtemp, readFile, rm, writeFile } from "node:fs/promises";
import { tmpdir } from "node:os";
import { resolve } from "node:path";
import { fileURLToPath } from "node:url";
import { promisify } from "node:util";
import { afterEach, describe, expect, it } from "vitest";

import { evaluate } from "./evaluate.mjs";
import { parseArguments, prepareCorpus, scoreCorpus, scoreReport } from "./history-corpus.mjs";

const execute = promisify(execFile);
const script = fileURLToPath(new URL("./history-corpus.mjs", import.meta.url));
const directories = [];
const revision = "a".repeat(40);

async function temporaryDirectory() {
  const directory = await mkdtemp(
    resolve(process.env.JCODE_SCRATCH_DIR ?? tmpdir(), "history-corpus-test-"),
  );
  directories.push(directory);
  return directory;
}

function sample(overrides = {}) {
  return {
    id: "historical-negative",
    documentId: "sample-0001",
    family: "guide-family",
    split: "calibration",
    revision,
    path: "guide.md",
    startLine: 3,
    endLine: 4,
    purpose: "Help the reader configure the tool.",
    audience: "A new user.",
    ruleIds: ["direct"],
    expected: { direct: "fail" },
    ruleScopes: { direct: "section" },
    ...overrides,
  };
}

function evaluation(overrides = {}) {
  return {
    documentId: "sample-0001",
    scope: "section",
    section: { id: "target", sourceRange: { startLine: 3, endLine: 4 } },
    questions: [{ id: "q-1", rule: { id: "direct", scope: "section" } }],
    answers: [{ questionId: "q-1", choice: "fail", confidence: 0.95, reviewRequired: true }],
    status: "complete",
    ...overrides,
  };
}

function score(entries, samples = [sample()]) {
  return scoreReport({ threshold: 0.8, evaluations: entries }, { version: 1, samples });
}

async function repositoryFixture() {
  const repository = await temporaryDirectory();
  const git = (...args) => execute("git", ["-C", repository, ...args]);
  await git("init", "--quiet");
  const page =
    "# Guide\n\n## Configure\nSet the configuration.\n\n## Reference\nFull-page context.\n";
  await writeFile(resolve(repository, "guide.md"), page);
  await git("add", "guide.md");
  await git(
    "-c",
    "user.name=totto2727-ai",
    "-c",
    "user.email=2000.0727.hayato+ai@gmail.com",
    "-c",
    "commit.gpgsign=false",
    "-c",
    "core.hooksPath=/dev/null",
    "commit",
    "--quiet",
    "-m",
    "Create test history",
  );
  const { stdout } = await git("rev-parse", "HEAD");
  const samples = [
    sample({ revision: stdout.trim() }),
    sample({
      id: "independent-positive",
      family: "independent-family",
      split: "holdout",
      revision: stdout.trim(),
      expected: { direct: "pass" },
    }),
  ];
  for (const item of samples) delete item.documentId;
  const specPath = resolve(repository, "corpus.json");
  const rulesPath = resolve(repository, "rules.json");
  await writeFile(specPath, JSON.stringify(samples));
  await writeFile(
    rulesPath,
    JSON.stringify([
      {
        id: "direct",
        scope: "section",
        instructions: "Evaluate directness.",
        pass: "Direct.",
        fail: "Indirect.",
      },
    ]),
  );
  await writeFile(resolve(repository, "guide.md"), "Worktree content must not be used.\n");
  return {
    repository,
    page,
    samples,
    specPath,
    rulesPath,
    outputDir: resolve(repository, "prepared"),
  };
}

afterEach(async () => {
  await Promise.all(
    directories.splice(0).map((directory) => rm(directory, { recursive: true, force: true })),
  );
});

describe("historical document preparation", () => {
  it("extracts pinned full pages, hides labels, preserves ranges, and feeds the evaluator", async () => {
    const fixture = await repositoryFixture();
    const { manifest, labels } = await prepareCorpus({ ...fixture, split: "calibration" });
    expect(manifest).toMatchObject({
      model: "jev-latest",
      threshold: 0.8,
      rulesFile: fixture.rulesPath,
    });
    expect(manifest.documents).toEqual([
      {
        id: "sample-0001",
        path: "sample-0001.md",
        purpose: fixture.samples[0].purpose,
        audience: fixture.samples[0].audience,
        ruleIds: ["direct"],
        sections: [{ id: "target", startLine: 3, endLine: 4, headingPath: [] }],
      },
    ]);
    expect(await readFile(resolve(fixture.outputDir, "sample-0001.md"), "utf8")).toBe(fixture.page);
    expect(labels.samples[0]).toMatchObject({
      id: "historical-negative",
      documentId: "sample-0001",
      expected: { direct: "fail" },
      revision: fixture.samples[0].revision,
    });
    const report = await evaluate({
      manifestPath: resolve(fixture.outputDir, "manifest.json"),
      outputPath: resolve(fixture.outputDir, "dry-run.json"),
      dryRun: true,
      environment: {},
    });
    expect(report.evaluations).toHaveLength(1);
    expect(report.evaluations[0].section).toMatchObject({
      id: "target",
      sourceRange: { startLine: 3, endLine: 4 },
    });
    expect(report.evaluations[0].state.evidence.page.markdown).toBe(fixture.page);
    expect(JSON.stringify(report.evaluations[0].state)).not.toContain("historical-negative");
    expect(JSON.stringify(report.evaluations[0].state)).not.toContain(fixture.samples[0].revision);
    const dryScore = scoreReport(report, labels);
    expect(dryScore.coverage).toMatchObject({ expected: 1, matched: 1, exact: true });
    expect(dryScore.totals.infrastructureError).toBe(1);
    expect(dryScore.rows[0].reason).toBe("not_evaluated");
  });

  it("keeps neutral IDs stable across split selection and refuses to overwrite outputs", async () => {
    const fixture = await repositoryFixture();
    const result = await prepareCorpus({ ...fixture, split: "holdout" });
    expect(result.manifest.documents.map((document) => document.id)).toEqual(["sample-0002"]);
    await expect(prepareCorpus({ ...fixture, split: "holdout" })).rejects.toMatchObject({
      code: "EEXIST",
    });
  });

  it.each([
    ["unpinned revision", { revision: "HEAD" }, "full Git object ID"],
    ["out-of-range excerpt", { endLine: 500 }, "Source range exceeds page"],
    ["unknown rule", { ruleIds: ["missing"], expected: {} }, "Unknown rule"],
    ["unselected label", { expected: { other: "pass" } }, "selected rules"],
  ])("rejects %s before creating artifacts", async (_name, change, message) => {
    const fixture = await repositoryFixture();
    await writeFile(fixture.specPath, JSON.stringify([{ ...fixture.samples[0], ...change }]));
    await expect(prepareCorpus(fixture)).rejects.toThrow(message);
    await expect(readFile(resolve(fixture.outputDir, "manifest.json"))).rejects.toMatchObject({
      code: "ENOENT",
    });
  });

  it("rejects family leakage even when preparing only calibration", async () => {
    const fixture = await repositoryFixture();
    fixture.samples[1].family = fixture.samples[0].family;
    await writeFile(fixture.specPath, JSON.stringify(fixture.samples));
    await expect(prepareCorpus({ ...fixture, split: "calibration" })).rejects.toThrow(
      "Family crosses",
    );
  });

  it("runs the prepare CLI with explicit spec and rule paths", async () => {
    const fixture = await repositoryFixture();
    await execute(process.execPath, [
      script,
      "prepare",
      "--repository",
      fixture.repository,
      "--output-dir",
      fixture.outputDir,
      "--split",
      "all",
      "--spec",
      fixture.specPath,
      "--rules",
      fixture.rulesPath,
    ]);
    const manifest = JSON.parse(
      await readFile(resolve(fixture.outputDir, "manifest.json"), "utf8"),
    );
    expect(manifest.documents).toHaveLength(2);
  });
});

describe("historical judgment scoring", () => {
  it.each([
    ["fail", "fail", "truePositive"],
    ["pass", "pass", "trueNegative"],
    ["fail", "pass", "falseAcceptance"],
    ["pass", "fail", "falseRejection"],
  ])(
    "counts expected %s / predicted %s as %s without mistaking fail review for abstention",
    (expected, predicted, counter) => {
      const result = score(
        [
          evaluation({
            answers: [
              {
                questionId: "q-1",
                choice: predicted,
                confidence: 0.8,
                reviewRequired: predicted === "fail",
              },
            ],
          }),
        ],
        [sample({ expected: { direct: expected } })],
      );
      expect(result.coverage).toMatchObject({
        expected: 1,
        labeled: 1,
        exploratory: 0,
        exact: true,
      });
      expect(result.totals[counter]).toBe(1);
      expect(result.totals.abstention).toBe(0);
      expect(result.perRule.direct[counter]).toBe(1);
      expect(result.perFamily["guide-family"][counter]).toBe(1);
    },
  );

  it.each([
    ["not_applicable", 0.99],
    ["insufficient_context", 0.99],
    ["pass", 0.79],
    ["fail", 0.79],
  ])("keeps %s at confidence %s out of pass/fail statistics", (choice, confidence) => {
    const result = score([
      evaluation({ answers: [{ questionId: "q-1", choice, confidence, reviewRequired: true }] }),
    ]);
    expect(result.totals).toMatchObject({
      total: 1,
      abstention: 1,
      falseAcceptance: 0,
      falseRejection: 0,
      truePositive: 0,
      trueNegative: 0,
    });
  });

  it("reports every missing label rather than dropping absent evaluations", () => {
    const result = score([]);
    expect(result.coverage).toMatchObject({ expected: 1, matched: 0, missing: 1, exact: false });
    expect(result.totals).toMatchObject({ total: 1, infrastructureError: 1, missing: 1 });
  });

  it.each([
    ["error", evaluation({ status: "error", answers: [] }), "evaluation_error"],
    ["dry run", evaluation({ status: "dry_run", answers: [] }), "not_evaluated"],
    ["missing answer", evaluation({ answers: [] }), "missing"],
    [
      "invalid confidence",
      evaluation({ answers: [{ questionId: "q-1", choice: "pass", confidence: 2 }] }),
      "malformed_answer",
    ],
    [
      "unknown choice",
      evaluation({ answers: [{ questionId: "q-1", choice: "maybe", confidence: 0.9 }] }),
      "malformed_answer",
    ],
  ])("records %s as infrastructure instead of model error", (_name, entry, reason) => {
    const result = score([entry]);
    expect(result.totals.infrastructureError).toBe(1);
    expect(result.rows[0].reason).toBe(reason);
    expect(result.totals.falseAcceptance).toBe(0);
  });

  it("detects duplicate evaluations, duplicate answers, and unexpected questions", () => {
    const duplicate = score([evaluation(), evaluation()]);
    expect(duplicate.coverage).toMatchObject({ duplicates: 1, exact: false });
    expect(duplicate.totals.infrastructureError).toBe(1);
    const entry = evaluation();
    entry.answers.push({ ...entry.answers[0] });
    expect(score([entry]).coverage).toMatchObject({ duplicates: 1, exact: false });
    expect(score([evaluation({ documentId: "unexpected" })]).coverage).toMatchObject({
      missing: 1,
      exact: false,
    });
    expect(score([evaluation({ scope: "page", section: null })]).coverage.exact).toBe(false);
  });

  it("rejects ambiguous question identities and mismatched source ranges", () => {
    const duplicateIds = evaluation({
      questions: [
        { id: "q-1", rule: { id: "direct" } },
        { id: "q-1", rule: { id: "flow" } },
      ],
    });
    const result = score([duplicateIds], [sample({ ruleIds: ["direct", "flow"] })]);
    expect(result.coverage).toMatchObject({ expected: 2, missing: 2, exact: false });
    expect(result.totals.infrastructureError).toBe(2);
    const wrongRange = evaluation({
      section: { id: "target", sourceRange: { startLine: 1, endLine: 4 } },
    });
    expect(score([wrongRange]).coverage).toMatchObject({ missing: 1, exact: false });
    const extraAnswer = evaluation();
    extraAnswer.answers.push({ questionId: "unknown", choice: "pass", confidence: 1 });
    expect(score([extraAnswer]).issues).toContainEqual({
      kind: "unexpected_answer",
      documentId: "sample-0001",
      questionId: "unknown",
    });
  });

  it("does not include exploratory judgments in the gold confusion matrix", () => {
    const item = sample({
      ruleIds: ["direct", "flow"],
      ruleScopes: { direct: "section", flow: "page" },
    });
    const entry = evaluation({
      scope: "page",
      section: null,
      questions: [{ id: "q-2", rule: { id: "flow" } }],
      answers: [{ questionId: "q-2", choice: "pass", confidence: 0.9, reviewRequired: false }],
    });
    const result = score([evaluation(), entry], [item]);
    expect(result.coverage).toMatchObject({ expected: 2, labeled: 1, exploratory: 1, exact: true });
    expect(result.totals).toMatchObject({
      total: 2,
      labeled: 1,
      exploratory: 1,
      truePositive: 1,
      trueNegative: 0,
    });
    expect(result.rows[1].expected).toBeNull();
    expect(result.perRule.flow).toMatchObject({
      labeled: 0,
      exploratory: 1,
      predictedPass: 1,
      trueNegative: 0,
    });
  });

  it("writes incomplete coverage from the public CLI and exits nonzero", async () => {
    const directory = await temporaryDirectory();
    const reportPath = resolve(directory, "report.json");
    const labelsPath = resolve(directory, "labels.json");
    const outputPath = resolve(directory, "score.json");
    await writeFile(reportPath, JSON.stringify({ evaluations: [] }));
    await writeFile(labelsPath, JSON.stringify({ samples: [sample()] }));
    await expect(
      execute(process.execPath, [
        script,
        "score",
        "--report",
        reportPath,
        "--labels",
        labelsPath,
        "--output",
        outputPath,
      ]),
    ).rejects.toMatchObject({ code: 1 });
    expect(JSON.parse(await readFile(outputPath, "utf8")).coverage).toMatchObject({
      missing: 1,
      exact: false,
    });
    await expect(scoreCorpus({ reportPath, labelsPath, outputPath })).rejects.toMatchObject({
      code: "EEXIST",
    });
  });

  it("rejects unknown, duplicate, and incomplete command arguments", () => {
    expect(() => parseArguments([])).toThrow("prepare or score");
    expect(() => parseArguments(["score", "--output"])).toThrow("Missing value");
    expect(() => parseArguments(["prepare", "--random", "x"])).toThrow("Unknown argument");
    expect(() => parseArguments(["score", "--report", "x", "--report", "y"])).toThrow(
      "Duplicate argument",
    );
  });
});
