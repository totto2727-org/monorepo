#!/usr/bin/env node

import { execFile } from "node:child_process";
import { mkdir, readFile, writeFile } from "node:fs/promises";
import { dirname, isAbsolute, resolve } from "node:path";
import { fileURLToPath } from "node:url";
import { promisify } from "node:util";

const execute = promisify(execFile);
const scriptDirectory = dirname(fileURLToPath(import.meta.url));
const defaultSpec = resolve(scriptDirectory, "../references/history-corpus.json");
const defaultRules = resolve(scriptDirectory, "../references/rules.json");
const choices = new Set(["pass", "fail", "not_applicable", "insufficient_context"]);

function requireValue(condition, message) {
  if (!condition) throw new Error(message);
}

function nonempty(value) {
  return typeof value === "string" && value.trim().length > 0;
}

function record(value) {
  return value !== null && typeof value === "object" && !Array.isArray(value);
}

function validateSamples(raw) {
  const samples = Array.isArray(raw) ? raw : raw?.samples;
  requireValue(Array.isArray(samples) && samples.length > 0, "Corpus must contain samples");
  const ids = new Set();
  const families = new Map();
  for (const sample of samples) {
    requireValue(record(sample), "Each sample must be an object");
    for (const field of ["id", "family", "purpose", "audience", "path"])
      requireValue(nonempty(sample[field]), `Sample ${field} must be non-empty`);
    requireValue(!ids.has(sample.id), `Duplicate sample id: ${sample.id}`);
    ids.add(sample.id);
    requireValue(["calibration", "holdout"].includes(sample.split), "Invalid sample split");
    requireValue(
      !families.has(sample.family) || families.get(sample.family) === sample.split,
      `Family crosses calibration and holdout: ${sample.family}`,
    );
    families.set(sample.family, sample.split);
    requireValue(
      typeof sample.revision === "string" && /^(?:[a-f\d]{40}|[a-f\d]{64})$/i.test(sample.revision),
      "Each revision must be a full Git object ID",
    );
    requireValue(
      !isAbsolute(sample.path) &&
        !sample.path.includes("\0") &&
        !sample.path.split("/").some((part) => part === ".." || part === ""),
      "Sample path must be repository-relative without traversal",
    );
    requireValue(
      Number.isInteger(sample.startLine) &&
        Number.isInteger(sample.endLine) &&
        sample.startLine > 0 &&
        sample.endLine >= sample.startLine,
      "Invalid source line range",
    );
    requireValue(
      Array.isArray(sample.ruleIds) &&
        sample.ruleIds.length > 0 &&
        sample.ruleIds.every(nonempty) &&
        new Set(sample.ruleIds).size === sample.ruleIds.length,
      "Sample ruleIds must be unique non-empty strings",
    );
    requireValue(
      record(sample.expected) &&
        Object.entries(sample.expected).every(
          ([id, value]) => sample.ruleIds.includes(id) && ["pass", "fail"].includes(value),
        ),
      "Expected labels must map selected rules to pass or fail",
    );
    requireValue(
      sample.headingPath === undefined ||
        (Array.isArray(sample.headingPath) && sample.headingPath.every(nonempty)),
      "headingPath must be an array of non-empty strings",
    );
  }
  return samples;
}

export async function prepareCorpus({
  repository,
  outputDir,
  split = "all",
  specPath = defaultSpec,
  rulesPath = defaultRules,
}) {
  requireValue(
    nonempty(repository) && nonempty(outputDir),
    "repository and outputDir are required",
  );
  requireValue(["calibration", "holdout", "all"].includes(split), "Invalid split");
  const samples = validateSamples(JSON.parse(await readFile(specPath, "utf8")));
  const rules = JSON.parse(await readFile(rulesPath, "utf8"));
  requireValue(Array.isArray(rules), "Rules must be an array");
  const scopes = new Map();
  for (const rule of rules) {
    requireValue(nonempty(rule?.id) && !scopes.has(rule.id), "Rules must have unique IDs");
    requireValue(["section", "page"].includes(rule.scope ?? "section"), "Invalid rule scope");
    scopes.set(rule.id, rule.scope ?? "section");
  }
  const selected = samples
    .map((sample, index) => ({
      sample,
      documentId: `sample-${String(index + 1).padStart(4, "0")}`,
    }))
    .filter(({ sample }) => split === "all" || sample.split === split);
  requireValue(selected.length > 0, "No samples selected");
  const documents = [];
  const labels = [];
  const pages = [];
  for (const { sample, documentId } of selected) {
    requireValue(
      sample.ruleIds.every((id) => scopes.has(id)),
      `Unknown rule in ${sample.id}`,
    );
    const { stdout: page } = await execute(
      "git",
      [
        "-C",
        resolve(repository),
        "show",
        "--no-ext-diff",
        "--no-textconv",
        `${sample.revision}:${sample.path}`,
      ],
      { encoding: "utf8", maxBuffer: 16 * 1024 * 1024 },
    );
    requireValue(
      sample.endLine <= page.split(/(?<=\n)/).length && page.trim().length > 0,
      `Source range exceeds page: ${sample.id}`,
    );
    const path = `${documentId}.md`;
    pages.push({ path, page });
    documents.push({
      id: documentId,
      path,
      purpose: sample.purpose,
      audience: sample.audience,
      sections: [
        {
          id: "target",
          startLine: sample.startLine,
          endLine: sample.endLine,
          headingPath: sample.headingPath ?? [],
        },
      ],
      ruleIds: sample.ruleIds,
    });
    labels.push({
      ...sample,
      documentId,
      ruleScopes: Object.fromEntries(sample.ruleIds.map((id) => [id, scopes.get(id)])),
    });
  }
  const manifest = {
    rulesFile: resolve(rulesPath),
    model: "jev-latest",
    threshold: 0.8,
    documents,
  };
  const labelFile = { version: 1, samples: labels };
  await mkdir(outputDir, { recursive: true });
  for (const { path, page } of pages)
    await writeFile(resolve(outputDir, path), page, { flag: "wx" });
  await writeFile(resolve(outputDir, "manifest.json"), `${JSON.stringify(manifest, null, 2)}\n`, {
    flag: "wx",
  });
  await writeFile(resolve(outputDir, "labels.json"), `${JSON.stringify(labelFile, null, 2)}\n`, {
    flag: "wx",
  });
  return { manifest, labels: labelFile };
}

function counters() {
  return {
    total: 0,
    labeled: 0,
    exploratory: 0,
    expectedPass: 0,
    expectedFail: 0,
    predictedPass: 0,
    predictedFail: 0,
    truePositive: 0,
    trueNegative: 0,
    falseAcceptance: 0,
    falseRejection: 0,
    abstention: 0,
    infrastructureError: 0,
    missing: 0,
  };
}

function addCount(count, row) {
  count.total += 1;
  count[row.expected === null ? "exploratory" : "labeled"] += 1;
  if (row.expected !== null) count[row.expected === "pass" ? "expectedPass" : "expectedFail"] += 1;
  if (row.outcome === "pass" || row.outcome === "fail") {
    count[row.outcome === "pass" ? "predictedPass" : "predictedFail"] += 1;
    if (row.expected === "fail")
      count[row.outcome === "fail" ? "truePositive" : "falseAcceptance"] += 1;
    else if (row.expected === "pass")
      count[row.outcome === "pass" ? "trueNegative" : "falseRejection"] += 1;
  } else count[row.outcome] += 1;
  if (row.reason === "missing") count.missing += 1;
}

export function scoreReport(report, labels) {
  requireValue(
    record(report) && Array.isArray(report.evaluations),
    "Report must contain evaluations",
  );
  const samples = validateSamples(labels);
  const threshold = report.threshold ?? 0.8;
  requireValue(
    Number.isFinite(threshold) && threshold >= 0 && threshold <= 1,
    "Invalid report threshold",
  );
  const expected = new Map();
  const documents = new Set();
  const key = (documentId, ruleId) => JSON.stringify([documentId, ruleId]);
  for (const sample of samples) {
    requireValue(
      nonempty(sample.documentId) && !documents.has(sample.documentId),
      "Labels need unique documentIds",
    );
    documents.add(sample.documentId);
    for (const ruleId of sample.ruleIds) {
      const scope = sample.ruleScopes?.[ruleId] ?? "section";
      requireValue(["section", "page"].includes(scope), "Invalid label rule scope");
      expected.set(key(sample.documentId, ruleId), { sample, ruleId, scope, matches: [] });
    }
  }
  const issues = [];
  for (const evaluation of report.evaluations) {
    if (!record(evaluation) || !Array.isArray(evaluation.questions)) {
      issues.push({ kind: "malformed_evaluation" });
      continue;
    }
    if (!documents.has(evaluation.documentId))
      issues.push({ kind: "unexpected_document", documentId: evaluation.documentId });
    const answers = Array.isArray(evaluation.answers) ? evaluation.answers : [];
    const questionIds = new Set(evaluation.questions.map((question) => question?.id));
    const ambiguousIds = new Set(
      evaluation.questions
        .filter(
          (question, index, all) => all.findIndex((other) => other?.id === question?.id) !== index,
        )
        .map((question) => question?.id),
    );
    for (const answer of answers) {
      if (!questionIds.has(answer?.questionId))
        issues.push({
          kind: "unexpected_answer",
          documentId: evaluation.documentId,
          questionId: answer?.questionId,
        });
    }
    for (const question of evaluation.questions) {
      if (!nonempty(question?.id) || ambiguousIds.has(question.id)) {
        issues.push({
          kind: "ambiguous_question_id",
          documentId: evaluation.documentId,
          questionId: question?.id,
        });
        continue;
      }
      const target = expected.get(key(evaluation.documentId, question?.rule?.id));
      if (
        !target ||
        evaluation.scope !== target.scope ||
        (target.scope === "section" &&
          (evaluation.section?.id !== "target" ||
            evaluation.section.sourceRange?.startLine !== target.sample.startLine ||
            evaluation.section.sourceRange?.endLine !== target.sample.endLine))
      ) {
        issues.push({
          kind: "unexpected_question",
          documentId: evaluation.documentId,
          questionId: question?.id,
        });
        continue;
      }
      target.matches.push({
        evaluation,
        question,
        answers: answers.filter((answer) => answer?.questionId === question.id),
      });
    }
  }
  const rows = [];
  let missing = 0;
  let duplicates = 0;
  for (const { sample, ruleId, matches } of expected.values()) {
    const row = {
      documentId: sample.documentId,
      sampleId: sample.id,
      family: sample.family,
      split: sample.split,
      ruleId,
      expected: Object.hasOwn(sample.expected, ruleId) ? sample.expected[ruleId] : null,
      outcome: "infrastructureError",
    };
    if (matches.length === 0) {
      row.reason = "missing";
      missing += 1;
    } else if (matches.length > 1) {
      row.reason = "duplicate_question";
      duplicates += matches.length - 1;
    } else {
      const { evaluation, answers } = matches[0];
      const answer = answers[0];
      if (evaluation.status !== "complete")
        row.reason = evaluation.status === "error" ? "evaluation_error" : "not_evaluated";
      else if (answers.length !== 1) {
        row.reason = answers.length === 0 ? "missing" : "duplicate_answer";
        if (answers.length === 0) missing += 1;
        else duplicates += answers.length - 1;
      } else if (
        !choices.has(answer.choice) ||
        !Number.isFinite(answer.confidence) ||
        answer.confidence < 0 ||
        answer.confidence > 1
      ) {
        row.reason = "malformed_answer";
      } else {
        row.choice = answer.choice;
        row.confidence = answer.confidence;
        if (
          !["pass", "fail"].includes(answer.choice) ||
          answer.confidence < threshold ||
          (answer.choice === "pass" && answer.reviewRequired === true)
        ) {
          row.outcome = "abstention";
          row.reason =
            answer.confidence < threshold
              ? "low_confidence"
              : answer.choice === "pass"
                ? "review_required"
                : answer.choice;
        } else row.outcome = answer.choice;
      }
    }
    rows.push(row);
  }
  const totals = counters();
  const perRule = new Map();
  const perFamily = new Map();
  for (const row of rows) {
    if (!perRule.has(row.ruleId)) perRule.set(row.ruleId, counters());
    if (!perFamily.has(row.family)) perFamily.set(row.family, counters());
    for (const count of [totals, perRule.get(row.ruleId), perFamily.get(row.family)])
      addCount(count, row);
  }
  return {
    version: 1,
    positiveClass: "fail",
    threshold,
    coverage: {
      expected: expected.size,
      labeled: rows.filter((row) => row.expected !== null).length,
      exploratory: rows.filter((row) => row.expected === null).length,
      matched: [...expected.values()].filter((target) => target.matches.length > 0).length,
      missing,
      duplicates,
      unexpected: issues.length,
      exact: missing === 0 && duplicates === 0 && issues.length === 0,
    },
    totals,
    perRule: Object.fromEntries(perRule),
    perFamily: Object.fromEntries(perFamily),
    rows,
    issues,
  };
}

export async function scoreCorpus({ reportPath, labelsPath, outputPath }) {
  const report = JSON.parse(await readFile(reportPath, "utf8"));
  const labels = JSON.parse(await readFile(labelsPath, "utf8"));
  const result = scoreReport(report, labels);
  await writeFile(outputPath, `${JSON.stringify(result, null, 2)}\n`, { flag: "wx" });
  return result;
}

export function parseArguments(argv) {
  const [command, ...argumentsList] = argv;
  const allowed =
    command === "prepare"
      ? new Set(["repository", "output-dir", "split", "spec", "rules"])
      : command === "score"
        ? new Set(["report", "labels", "output"])
        : null;
  requireValue(allowed, "Expected prepare or score command");
  const options = {};
  for (let index = 0; index < argumentsList.length; index += 2) {
    const flags = argumentsList[index];
    const flag = typeof flags === "string" ? flags : "";
    const value = argumentsList[index + 1];
    requireValue(flag.startsWith("--") && allowed.has(flag.slice(2)), `Unknown argument: ${flag}`);
    requireValue(nonempty(value) && !value.startsWith("--"), `Missing value for ${flag}`);
    requireValue(options[flag.slice(2)] === undefined, `Duplicate argument: ${flag}`);
    options[flag.slice(2)] = value;
  }
  for (const required of command === "prepare"
    ? ["repository", "output-dir"]
    : ["report", "labels", "output"])
    requireValue(options[required], `--${required} is required`);
  return { command, options };
}

async function main() {
  try {
    const { command, options } = parseArguments(process.argv.slice(2));
    if (command === "prepare") {
      await prepareCorpus({
        repository: options.repository,
        outputDir: options["output-dir"],
        split: options.split,
        specPath: options.spec,
        rulesPath: options.rules,
      });
    } else {
      const result = await scoreCorpus({
        reportPath: options.report,
        labelsPath: options.labels,
        outputPath: options.output,
      });
      if (!result.coverage.exact || result.totals.infrastructureError > 0) process.exitCode = 1;
    }
  } catch (error) {
    console.error(error instanceof Error ? error.message : "History corpus operation failed");
    process.exitCode = 2;
  }
}

if (process.argv[1] && resolve(process.argv[1]) === fileURLToPath(import.meta.url)) await main();
