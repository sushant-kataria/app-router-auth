#!/usr/bin/env node
import { readFileSync, writeFileSync } from 'node:fs';
import { fileURLToPath } from 'node:url';
import { dirname, join } from 'node:path';

const root = join(dirname(fileURLToPath(import.meta.url)), '..');
const progressPath = join(root, 'data', 'progress.json');
const progress = JSON.parse(readFileSync(progressPath, 'utf8'));

const username = progress.githubUsername || 'sushant-kataria';
const token = process.env.GITHUB_TOKEN || process.env.GH_TOKEN || '';
const since = new Date();
since.setFullYear(since.getFullYear() - 1);
const sinceIso = since.toISOString().slice(0, 10);

const headers = {
  Accept: 'application/vnd.github+json',
  'User-Agent': 'grantpath-progress',
  'X-GitHub-Api-Version': '2022-11-28',
};
if (token) headers.Authorization = `Bearer ${token}`;

const query = `is:pr is:merged author:${username} -user:${username} merged:>=${sinceIso}`;
const url = `https://api.github.com/search/issues?q=${encodeURIComponent(query)}&per_page=1`;
const res = await fetch(url, { headers });
if (!res.ok) {
  console.error(`GitHub API ${res.status}: ${await res.text()}`);
  process.exit(1);
}
const data = await res.json();
const count = data.total_count ?? 0;
const goal = progress.goal?.anthropicMergedExternalPrs ?? 100;

progress.mergedExternalPrs = count;
progress.applications.anthropic.status = count >= goal ? 'ready-to-apply' : 'not-ready';
progress.applications.openai.status =
  count >= 15 ? 'early-apply-possible-if-maintainer-story-strong' : 'not-ready';
progress.lastCountedAt = new Date().toISOString();
writeFileSync(progressPath, JSON.stringify(progress, null, 2) + '\n');

console.log(JSON.stringify({ username, count, goal, progressFile: 'data/progress.json' }, null, 2));
