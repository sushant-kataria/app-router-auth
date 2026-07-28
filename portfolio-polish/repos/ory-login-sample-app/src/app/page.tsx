export default function Home() {
  return (
    <main className="min-h-screen bg-zinc-50 text-zinc-900 flex items-center justify-center p-8">
      <div className="max-w-lg w-full space-y-6">
        <p className="text-sm font-medium tracking-wide text-zinc-500 uppercase">
          Ory JWT Sample
        </p>
        <h1 className="text-3xl font-semibold tracking-tight">
          Protect Next.js APIs with Ory JWTs
        </h1>
        <p className="text-zinc-600 leading-relaxed">
          This sample verifies bearer tokens against Ory JWKS and gates protected
          API routes. Use it as a reference for App Router + middleware auth.
        </p>
        <div className="rounded-md border border-zinc-200 bg-white p-4 text-sm text-zinc-700 space-y-2">
          <p className="font-medium text-zinc-900">Try it</p>
          <ol className="list-decimal list-inside space-y-1">
            <li>Copy <code>.env.example</code> → <code>.env.local</code> and set your Ory URL</li>
            <li>Run <code>npm run dev</code></li>
            <li>Call the protected API with <code>Authorization: Bearer &lt;token&gt;</code></li>
          </ol>
        </div>
      </div>
    </main>
  );
}
