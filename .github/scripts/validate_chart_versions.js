const { execFileSync } = require("node:child_process");
const fs = require("node:fs");

function git(args, options = {}) {
  return execFileSync("git", ["-c", "safe.directory=*", ...args], {
    encoding: "utf8",
    stdio: ["ignore", "pipe", options.allowFailure ? "pipe" : "inherit"],
  }).trimEnd();
}

function gitMaybe(args) {
  try {
    return git(args, { allowFailure: true });
  } catch {
    return null;
  }
}

function readAt(ref, filePath) {
  return gitMaybe(["show", `${ref}:${filePath}`]);
}

function parseSimpleYamlField(content, key) {
  if (!content) {
    return "";
  }

  const re = new RegExp(`^${key}:\\s*"?([^"\\n#]+)"?\\s*$`, "m");
  const match = content.match(re);
  return match ? match[1].trim() : "";
}

function parseTopLevelImageTag(content) {
  if (!content) {
    return "";
  }

  const lines = content.split(/\r?\n/);
  let inImageBlock = false;

  for (const line of lines) {
    if (!inImageBlock) {
      if (/^image:\s*$/.test(line)) {
        inImageBlock = true;
      }
      continue;
    }

    if (line.trim() === "" || line.trim().startsWith("#")) {
      continue;
    }

    if (/^\S/.test(line)) {
      break;
    }

    const tagMatch = line.match(/^\s+tag:\s*"?([^"\s#]+)"?/);
    if (tagMatch) {
      return tagMatch[1].trim();
    }
  }

  return "";
}

function parseSemver(version) {
  const match = String(version || "").trim().match(/^(\d+)\.(\d+)\.(\d+)$/);
  if (!match) {
    return null;
  }

  return {
    major: Number(match[1]),
    minor: Number(match[2]),
    patch: Number(match[3]),
  };
}

function classifyVersionBump(previousVersion, nextVersion) {
  const previous = parseSemver(previousVersion);
  const next = parseSemver(nextVersion);

  if (!previous || !next) {
    return "invalid";
  }
  if (next.major > previous.major) {
    return "major";
  }
  if (next.major < previous.major) {
    return "downgrade";
  }
  if (next.minor > previous.minor) {
    return "minor";
  }
  if (next.minor < previous.minor) {
    return "downgrade";
  }
  if (next.patch > previous.patch) {
    return "patch";
  }
  if (next.patch < previous.patch) {
    return "downgrade";
  }
  return "none";
}

function bumpMeetsRequirement(actual, required) {
  const rank = {
    none: 0,
    patch: 1,
    minor: 2,
    major: 3,
  };
  return (rank[actual] || 0) >= rank[required];
}

function minimumVersionForBump(previousVersion, requiredBump) {
  const previous = parseSemver(previousVersion);
  if (!previous) {
    return "";
  }

  if (requiredBump === "major") {
    return `${previous.major + 1}.0.0`;
  }
  if (requiredBump === "minor") {
    return `${previous.major}.${previous.minor + 1}.0`;
  }
  return `${previous.major}.${previous.minor}.${previous.patch + 1}`;
}

function getFallbackBaseSha(headSha) {
  return gitMaybe(["rev-parse", `${headSha}^`]);
}

const headSha = process.env.HEAD_SHA || "HEAD";
let baseSha = process.env.BASE_SHA || getFallbackBaseSha(headSha);
const diffStyle = process.env.DIFF_STYLE || "range";

if (!baseSha) {
  console.log("No base SHA available; skipping chart version validation.");
  process.exit(0);
}

if (!gitMaybe(["rev-parse", "--verify", `${headSha}^{commit}`])) {
  console.log(`Head SHA ${headSha} is not available; skipping chart version validation.`);
  process.exit(0);
}

if (!gitMaybe(["rev-parse", "--verify", `${baseSha}^{commit}`])) {
  const fallbackBaseSha = getFallbackBaseSha(headSha);
  if (!fallbackBaseSha) {
    console.log(`Base SHA ${baseSha} is not available and no fallback base could be resolved; skipping chart version validation.`);
    process.exit(0);
  }

  console.log(`Base SHA ${baseSha} is not available; falling back to ${fallbackBaseSha}.`);
  baseSha = fallbackBaseSha;
}

if (diffStyle === "range" && !gitMaybe(["merge-base", "--is-ancestor", baseSha, headSha])) {
  const fallbackBaseSha = getFallbackBaseSha(headSha);
  if (!fallbackBaseSha) {
    console.log(`Base SHA ${baseSha} is not an ancestor of ${headSha} and no fallback base could be resolved; skipping chart version validation.`);
    process.exit(0);
  }

  console.log(`Base SHA ${baseSha} is not an ancestor of ${headSha}; falling back to ${fallbackBaseSha}.`);
  baseSha = fallbackBaseSha;
}

const diffArgs = ["diff", "--name-only"];
if (diffStyle === "merge-base") {
  diffArgs.push(`${baseSha}...${headSha}`);
} else {
  diffArgs.push(baseSha, headSha);
}
const diffOutput = git(diffArgs);
const changedFiles = diffOutput.split(/\r?\n/).filter(Boolean);
const changedCharts = new Map();

for (const filePath of changedFiles) {
  const match = filePath.match(/^charts\/([^/]+)\//);
  if (!match) {
    continue;
  }

  const chart = match[1];
  const files = changedCharts.get(chart) || [];
  files.push(filePath);
  changedCharts.set(chart, files);
}

if (changedCharts.size === 0) {
  console.log("No chart changes detected.");
  process.exit(0);
}

const failures = [];
const results = [];

for (const [chart, files] of Array.from(changedCharts.entries()).sort()) {
  const chartPath = `charts/${chart}/Chart.yaml`;
  const valuesPath = `charts/${chart}/values.yaml`;
  const previousChartYaml = readAt(baseSha, chartPath);
  const nextChartYaml = readAt(headSha, chartPath);

  if (!previousChartYaml || !nextChartYaml) {
    console.log(`Skipping ${chart}: chart was added or removed.`);
    continue;
  }

  const previousVersion = parseSimpleYamlField(previousChartYaml, "version");
  const nextVersion = parseSimpleYamlField(nextChartYaml, "version");
  const previousAppVersion = parseSimpleYamlField(previousChartYaml, "appVersion");
  const nextAppVersion = parseSimpleYamlField(nextChartYaml, "appVersion");
  const previousImageTag = parseTopLevelImageTag(readAt(baseSha, valuesPath));
  const nextImageTag = parseTopLevelImageTag(readAt(headSha, valuesPath));
  const appVersionChanged = previousAppVersion !== nextAppVersion;
  const imageTagChanged = previousImageTag !== nextImageTag;
  const requiredBump = appVersionChanged || imageTagChanged ? "minor" : "patch";
  const actualBump = classifyVersionBump(previousVersion, nextVersion);
  const suggestedVersion = minimumVersionForBump(previousVersion, requiredBump);
  const chartFailures = [];

  console.log(`${chart}: changed files=${files.length}, chart version ${previousVersion || "n/a"} -> ${nextVersion || "n/a"}, appVersion ${previousAppVersion || "n/a"} -> ${nextAppVersion || "n/a"}, image.tag ${previousImageTag || "n/a"} -> ${nextImageTag || "n/a"}`);

  if (actualBump === "invalid") {
    chartFailures.push(`Chart.yaml version must be simple semver x.y.z (${previousVersion || "missing"} -> ${nextVersion || "missing"}).`);
    failures.push(`${chart}: ${chartFailures[chartFailures.length - 1]}`);
    results.push({
      chart,
      previousVersion,
      nextVersion,
      previousAppVersion,
      nextAppVersion,
      previousImageTag,
      nextImageTag,
      requiredBump,
      actualBump,
      suggestedVersion,
      failures: chartFailures,
    });
    continue;
  }

  if (actualBump === "downgrade" || actualBump === "none") {
    chartFailures.push(`Chart files changed, so Chart.yaml version must increase at least a ${requiredBump} version (${previousVersion} -> ${suggestedVersion || "a higher version"}).`);
  } else if (!bumpMeetsRequirement(actualBump, requiredBump)) {
    chartFailures.push(`${appVersionChanged || imageTagChanged ? "appVersion or image.tag changed" : "Chart files changed"}, so Chart.yaml version must increase by at least ${requiredBump} (${previousVersion} -> ${suggestedVersion || "a higher version"}; submitted ${nextVersion}, which was ${actualBump}).`);
  }

  if (imageTagChanged && !appVersionChanged) {
    chartFailures.push(`values.yaml image.tag changed (${previousImageTag || "n/a"} -> ${nextImageTag || "n/a"}), so Chart.yaml appVersion must also change.`);
  }

  if (imageTagChanged && nextAppVersion && nextImageTag && nextAppVersion !== nextImageTag) {
    chartFailures.push(`values.yaml image.tag changed to ${nextImageTag}, but Chart.yaml appVersion is ${nextAppVersion}. Keep appVersion aligned with the primary app image tag.`);
  }

  for (const failure of chartFailures) {
    failures.push(`${chart}: ${failure}`);
  }

  results.push({
    chart,
    previousVersion,
    nextVersion,
    previousAppVersion,
    nextAppVersion,
    previousImageTag,
    nextImageTag,
    requiredBump,
    actualBump,
    suggestedVersion,
    failures: chartFailures,
  });
}

if (process.env.REPORT_PATH) {
  fs.writeFileSync(process.env.REPORT_PATH, JSON.stringify({
    ok: failures.length === 0,
    baseSha,
    headSha,
    diffStyle,
    results,
    failures,
  }, null, 2));
}

if (failures.length > 0) {
  for (const failure of failures) {
    console.error(`::error::${failure}`);
  }
  console.error(["Chart version validation failed:", ...failures.map((failure) => `- ${failure}`)].join("\n"));
  process.exit(1);
}
