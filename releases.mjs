// @ts-check

import { appendFile } from "node:fs/promises";
import { createWriteStream } from "node:fs";
import { finished } from "node:stream/promises";
import { Readable } from "node:stream";
import { resolve } from "node:path";
import assert from "node:assert";

const KEEP_RECENT_RELEASES = 30;
const KEEP_RECENT_NIGHTLY_RELEASES = 10;

const EXTRA_RELEASES = [
  // "nightly-2024-01-01"
  "stable",
  // "beta",
  "nightly",
  // "lean-toolchain",
];

const SKIPPED_RELEASES = [
  // "4.0.0"
  // "nightly-2024-01-01"
];

const REQUEST_HEADERS = {
  Accept: "application/vnd.github.v3+json",
  "X-GitHub-Api-Version": "2022-11-28",
};
if (process.env.GITHUB_TOKEN) {
  REQUEST_HEADERS.Authorization = `Bearer ${process.env.GITHUB_TOKEN}`;
}

/** @typedef {{ tag_name: string, published_at: string }} GitHubRelease */

/**
 * Fetches releases from GitHub API
 * @param {string} repo - Repository name in format "owner/repo"
 * @param {number|null} limit - Maximum number of releases to return
 * @returns {Promise<string[]>} Array of release tag names
 */
async function fetchReleases(repo, limit = null) {
  /** @type {GitHubRelease[]} */
  const allReleases = [];
  for (let page = 1; ; page++) {
    const url = new URL(`https://api.github.com/repos/${repo}/releases`);
    url.searchParams.set("page", String(page));
    const response = await fetch(url, {
      headers: { ...REQUEST_HEADERS },
    });
    assert(response.ok, `Failed to fetch releases from ${repo}`);

    /** @type {GitHubRelease[]} */
    const releases = await response.json();
    console.info(`Got ${releases.length} releases from ${repo}`);
    allReleases.push(...releases);

    if (!releases.length || (limit !== null && allReleases.length >= limit)) {
      break;
    }
  }

  allReleases.sort(
    (a, b) =>
      new Date(b.published_at).getTime() - new Date(a.published_at).getTime()
  );

  if (limit !== null) {
    allReleases.splice(limit);
  }

  return allReleases.map((release) => release.tag_name);
}

/** @typedef {{ name: string, browser_download_url: string }} GitHubAsset */

/**
 * Downloads Lean 4 releases
 * @param {string} tag - Release tag name
 * @param {string} outputDir - Directory to save the release
 * @param {string|null} arch - Architecture to download
 * @returns {Promise<string>}
 **/
async function downloadReleases(tag, outputDir = ".", arch = null) {
  assert(process.platform === "linux", "Only Linux is supported");
  arch ??= process.arch;
  const suffix = {
    x86: "linux_x86",
    x64: "linux",
    arm64: "linux_aarch64",
  }[arch];
  assert(suffix, `Unsupported architecture: ${arch}`);

  const repo = tag.startsWith("nightly")
    ? "leanprover/lean4-nightly"
    : "leanprover/lean4";

  let url = `https://api.github.com/repos/${repo}/releases`;
  switch (tag) {
    case "stable":
      url += "/latest";
      break;
    case "nightly":
      const [latest] = await fetchReleases(repo, 1);
      url += `/tags/${latest}`;
      break;
    default:
      url += `/tags/${tag}`;
      break;
  }

  const response = await fetch(url, {
    headers: { ...REQUEST_HEADERS },
  });
  assert(
    response.ok,
    `Failed to fetch release from ${repo}, ${response.statusText}`
  );
  const release = await response.json();
  const /**@type {GitHubAsset} */
    asset = release.assets.find(
      (/**@type {GitHubAsset} */ asset) =>
        asset.name.includes(suffix) && asset.name.match(/\.tar\.\w+$/)
    );
  assert(asset, `Failed to find asset for ${arch} in ${release.tag_name}`);
  console.info(`Found asset ${asset.name} for ${arch} in ${release.tag_name}`);

  const downloadUrl = new URL(asset.browser_download_url);
  const download = await fetch(downloadUrl, {
    headers: { ...REQUEST_HEADERS },
  });
  assert(download.ok, `Failed to download asset from ${downloadUrl}`);

  const filepath = resolve(outputDir, asset.name),
    start = Date.now();

  const fileStream = createWriteStream(filepath, { flags: "w" });
  await finished(
    //@ts-ignore
    Readable.fromWeb(download.body).pipe(fileStream)
  );

  const len = download.headers.get("content-length");
  console.info(
    `Downloaded ${downloadUrl} (${len} bytes) in ${Date.now() - start}ms`
  );

  return filepath;
}

async function main() {
  const mode = process.argv[2];
  if (mode === "download") {
    const tag = process.argv[3];
    const outputDir = process.argv[4] ?? ".";

    await downloadReleases(tag, outputDir);
    return;
  } else if (mode !== "discover") {
    console.error(`${process.argv[1]} download <tag> [outputDir]`);
    console.error(`${process.argv[1]} discover`);
    process.exit(1);
  }

  const prodReleases = (
    await fetchReleases("leanprover/lean4", KEEP_RECENT_RELEASES)
  ).filter((tag) => tag.startsWith("v"));

  console.info(
    `Following toolchain releases will be used: ${JSON.stringify(prodReleases)}`
  );

  const nightlyReleases = (
    await fetchReleases(
      "leanprover/lean4-nightly",
      KEEP_RECENT_NIGHTLY_RELEASES
    )
  ).filter((tag) => tag.startsWith("nightly"));

  console.info(
    `Following nightly toolchain releases will be used: ${JSON.stringify(
      nightlyReleases
    )}`
  );

  const allReleases = [
    ...new Set(
      [...prodReleases, ...nightlyReleases, ...EXTRA_RELEASES].filter(
        (tag) => !SKIPPED_RELEASES.includes(tag)
      )
    ),
  ].sort((a, b) => a.localeCompare(b));

  const outputPath = process.env.GITHUB_OUTPUT;
  if (outputPath) {
    await appendFile(
      resolve(outputPath),
      `matrix=${JSON.stringify({ toolchain: allReleases })}\n`
    );
  }
}

main().catch((err) => {
  console.error(err);
  process.exit(1);
});
