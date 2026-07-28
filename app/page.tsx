import Link from 'next/link';
import progress from '@/data/progress.json';
import targets from '@/data/targets.json';

const goal = progress.goal.anthropicMergedExternalPrs;
const count = progress.mergedExternalPrs;
const pct = Math.min(100, Math.round((count / goal) * 100));

export default function HomePage() {
  return (
    <main>
      <header className="relative overflow-hidden border-b border-ink/10">
        <div
          aria-hidden
          className="pointer-events-none absolute inset-0 bg-blueprint bg-blueprint opacity-70"
        />
        <div
          aria-hidden
          className="pointer-events-none absolute -right-24 top-0 h-[520px] w-[520px] rounded-full bg-[radial-gradient(circle_at_center,rgba(0,119,200,0.28),transparent_68%)]"
        />
        <div
          aria-hidden
          className="pointer-events-none absolute -left-16 bottom-0 h-[360px] w-[360px] rounded-full bg-[radial-gradient(circle_at_center,rgba(255,107,53,0.2),transparent_70%)]"
        />

        <div className="relative mx-auto flex max-w-6xl items-center justify-between px-6 py-5">
          <p className="font-display text-xl font-extrabold tracking-tight text-ink">Grantpath</p>
          <nav className="flex gap-5 text-sm font-medium text-ink/70">
            <a href="#plan" className="transition hover:text-signal">
              Plan
            </a>
            <a href="#targets" className="transition hover:text-signal">
              Targets
            </a>
            <a href="#apply" className="transition hover:text-signal">
              Apply
            </a>
          </nav>
        </div>

        <section className="relative mx-auto grid max-w-6xl gap-10 px-6 pb-20 pt-10 md:grid-cols-[1.15fr_0.85fr] md:items-end md:pb-24 md:pt-16">
          <div className="animate-rise">
            <p className="font-mono text-xs uppercase tracking-[0.22em] text-signal">
              Claude Max · Codex Pro · OSS route
            </p>
            <h1 className="mt-4 max-w-xl font-display text-5xl font-extrabold leading-[0.95] tracking-tight text-ink md:text-7xl">
              Grantpath
            </h1>
            <p className="mt-5 max-w-lg text-lg leading-relaxed text-ink/70 md:text-xl">
              Fastest honest path with zero history: land 100 merged PRs in repos
              you don’t own, then apply for 6 months of Claude Max 20x.
            </p>
            <div className="mt-8 flex flex-wrap gap-3">
              <a
                href="#plan"
                className="inline-flex items-center bg-ink px-5 py-3 text-sm font-semibold text-paper transition hover:bg-signal"
              >
                Start the plan
              </a>
              <Link
                href="https://github.com/sushant-kataria/app-router-auth"
                className="inline-flex items-center border border-ink/20 bg-white/50 px-5 py-3 text-sm font-semibold text-ink transition hover:border-signal hover:text-signal"
              >
                Open the repo
              </Link>
            </div>
          </div>

          <div className="animate-rise relative border border-ink/15 bg-white/60 p-6 backdrop-blur-sm [animation-delay:120ms]">
            <svg
              viewBox="0 0 240 120"
              className="absolute right-4 top-4 h-16 w-32 text-signal/80"
              fill="none"
              aria-hidden
            >
              <path
                d="M10 90 C40 20, 80 20, 110 70 S180 120, 230 30"
                stroke="currentColor"
                strokeWidth="3"
                strokeDasharray="240"
                className="animate-draw"
              />
            </svg>
            <p className="font-mono text-xs uppercase tracking-widest text-ink/50">
              Anthropic active-contributor track
            </p>
            <p className="mt-3 font-display text-4xl font-700 text-ink">
              {count}
              <span className="text-ink/35"> / {goal}</span>
            </p>
            <p className="mt-1 text-sm text-ink/60">merged external PRs (last 12 months)</p>
            <div className="mt-5 h-2 origin-left overflow-hidden bg-mist">
              <div
                className="h-full origin-left bg-flare animate-pulse-bar"
                style={{ width: `${Math.max(pct, 4)}%` }}
              />
            </div>
            <p className="mt-3 font-mono text-xs text-ink/55">{pct}% toward apply-ready</p>
          </div>
        </section>
      </header>

      <section id="plan" className="mx-auto max-w-6xl px-6 py-16 md:py-20">
        <h2 className="font-display text-3xl font-700 tracking-tight md:text-4xl">
          What to do now
        </h2>
        <p className="mt-3 max-w-2xl text-ink/65">
          Building a random library and hoping for downloads is the slow path.
          Grinding quality external PRs is the controllable Anthropic track.
        </p>

        <ol className="mt-10 grid gap-6 md:grid-cols-3">
          {[
            {
              n: '01',
              t: 'Ship tiny merged PRs',
              d: 'Docs, typos, tests, small bugs. Comment on the issue first. Keep diffs under ~50 lines when you can.',
            },
            {
              n: '02',
              t: 'Track toward 100',
              d: 'Run npm run count-prs. Only PRs merged into repos you do not own count for the Active contributor track.',
            },
            {
              n: '03',
              t: 'Apply both programs',
              d: 'Anthropic at 100 external merges. OpenAI once you are clearly primary maintainer of a public useful project (this repo).',
            },
          ].map((step) => (
            <li key={step.n} className="border-t-2 border-signal pt-4">
              <p className="font-mono text-xs text-signal">{step.n}</p>
              <h3 className="mt-2 font-display text-xl font-700">{step.t}</h3>
              <p className="mt-2 text-sm leading-relaxed text-ink/65">{step.d}</p>
            </li>
          ))}
        </ol>
      </section>

      <section id="targets" className="border-y border-ink/10 bg-white/40">
        <div className="mx-auto max-w-6xl px-6 py-16 md:py-20">
          <h2 className="font-display text-3xl font-700 tracking-tight md:text-4xl">
            First contribution targets
          </h2>
          <p className="mt-3 max-w-2xl text-ink/65">
            Prioritize active repos with labels and recent maintainer replies.
            Avoid abandoned issues and overcrowded “good first issue” threads.
          </p>
          <ul className="mt-10 divide-y divide-ink/10 border-y border-ink/10">
            {targets.map((t) => (
              <li
                key={t.repo}
                className="grid gap-2 py-5 md:grid-cols-[220px_1fr_auto] md:items-center"
              >
                <div>
                  <p className="font-display text-lg font-700">{t.name}</p>
                  <p className="font-mono text-xs text-ink/45">{t.repo}</p>
                </div>
                <p className="text-sm text-ink/70">{t.why}</p>
                <a
                  href={t.findIssues}
                  className="text-sm font-semibold text-signal underline-offset-4 hover:underline"
                  target="_blank"
                  rel="noreferrer"
                >
                  Find issues →
                </a>
              </li>
            ))}
          </ul>
        </div>
      </section>

      <section id="apply" className="mx-auto max-w-6xl px-6 py-16 md:py-20">
        <h2 className="font-display text-3xl font-700 tracking-tight md:text-4xl">
          When to apply
        </h2>
        <div className="mt-8 grid gap-8 md:grid-cols-2">
          <article className="border border-ink/15 bg-white/50 p-6">
            <p className="font-mono text-xs uppercase tracking-widest text-flare">Anthropic</p>
            <h3 className="mt-2 font-display text-2xl font-700">Claude Max 20x · 6 months</h3>
            <p className="mt-3 text-sm leading-relaxed text-ink/65">
              Best fit from zero: Active contributors — 100+ merged PRs into
              repos you don’t own (12 months). Soft lane exists, but empty
              histories usually fail.
            </p>
            <a
              href="https://claude.com/open-source-max"
              className="mt-5 inline-flex text-sm font-semibold text-signal underline-offset-4 hover:underline"
              target="_blank"
              rel="noreferrer"
            >
              Official apply page →
            </a>
          </article>
          <article className="border border-ink/15 bg-white/50 p-6">
            <p className="font-mono text-xs uppercase tracking-widest text-moss">OpenAI</p>
            <h3 className="mt-2 font-display text-2xl font-700">ChatGPT Pro + Codex · 6 months</h3>
            <p className="mt-3 text-sm leading-relaxed text-ink/65">
              Needs a primary/core maintainer story on a used public project.
              Grow this repo in public while you grind external PRs, then apply
              with real metrics only.
            </p>
            <a
              href="https://openai.com/form/codex-for-oss/"
              className="mt-5 inline-flex text-sm font-semibold text-signal underline-offset-4 hover:underline"
              target="_blank"
              rel="noreferrer"
            >
              Official apply form →
            </a>
          </article>
        </div>
      </section>

      <footer className="border-t border-ink/10 px-6 py-10 text-center text-sm text-ink/50">
        Grantpath is a playbook, not a shortcut. No fake metrics. MIT licensed.
      </footer>
    </main>
  );
}
