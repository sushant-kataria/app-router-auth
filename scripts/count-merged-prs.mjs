#!/usr/bin/env node
/**
 * Count merged PRs authored by a user in repositories they do NOT own.
 * This maps to Anthropic's "Active contributors" track (100+ in last 12 months).
 *
 * Usage:
 *   node scripts/count-merged-prs.mjs [githubUsername]
 *   GITHUB_TOKEN=... node scripts/count-merged-prs.mjs
 *
 * A token raises rate limits; public unauthenticated works for small counts.
 */

const username = process.argv[2] || process.env.GITHUB_USERNAME || 'sushant-kataria';
const token = process.env.GITHUB_TOKEN || process.env.GH_TOKEN || '';
const since = new Date();
since.setFullYear(since.getFullYear() - 1);
const sinceIso = since.toISOString().slice(0, 10);

const headers = {
  Accept: 'application/vnd.github+json',
  'User-Agent': 'grantpath-pr-counter',
  'X-GitHub-Api-Version': '2022-11-28',
};
if (token) headers.Authorization = `Bearer ${token}`;

async function searchCount(query) {
  const url = `https://api.github.com/search/issues?q=${encodeURIComponent(query)}&per_page=1`;
  const res = await fetch(url, { headers });
  if (!res.ok) {
    const body = await res.text();
    throw new Error(`GitHub API ${res.status}: ${body}`);
  }
  const data = await res.json();
  return data.total_count ?? 0;
}

async function main() {
  // PRs authored by user, merged, updated in last year, excluding their own user namespace repos.
  // Note: -user:USERNAME excludes repos owned by that user.
  const query = `is:pr is:merged author:${username} -user:${username} merged:>=${sinceIso}`;
  const count = await searchCount(query);
  const goal = 100;
  const remaining = Math.max(goal - count, 0);
  const pct = Math.min(100, Math.round((count / goal) * 100));

  console.log(`User: ${username}`);
  console.log(`Window: merged since ${sinceIso}`);
  console.log(`Merged external PRs: ${count}`);
  console.log(`Anthropic active-contributor goal: ${goal}`);
  console.log(`Progress: ${pct}% (${remaining} remaining)`);
  console.log(`Search: https://github.com/search?q=${encodeURIComponent(query)}&type=pullrequests`);

  if (count >= goal) {
    console.log('\nYou likely meet Anthropic’s Active contributors track. Review apply/anthropic-draft.md and submit.');
  } else {
    console.log('\nKeep landing small, high-quality PRs in repos you do not own. See data/targets.json');
  }
}

main().catch((err) => {
  console.error(err.message || err);
  process.exit(1);
});
