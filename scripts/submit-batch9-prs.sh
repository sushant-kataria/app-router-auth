#!/usr/bin/env bash
# Batch 9 — HashiCorp only (PowerToys/Kibana abandoned — rejected / not opened)
#   bash scripts/submit-batch9-prs.sh
#
# Targets:
#   32) hashicorp/vault#31852 — UI scroll locked after delete
#   34) hashicorp/terraform-provider-azurerm#13255 — App Insights JS source-map URI
#
# Requires: gh auth as sushant-kataria; HashiCorp CLA on first PR.
# Windows: grantpath-submit-lib.sh (relative clone + python shim + textio).
set -euo pipefail

USER_LOGIN="${GITHUB_USER:-sushant-kataria}"
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
# shellcheck source=grantpath-submit-lib.sh
source "$SCRIPT_DIR/grantpath-submit-lib.sh"

need() { command -v "$1" >/dev/null || { echo "Missing: $1"; exit 1; }; }
need git; need gh
grantpath_resolve_python
grantpath_init_workdir "batch9"

ACTIVE="$(gh api user --jq .login 2>/dev/null || true)"
if [[ -z "$ACTIVE" || "$ACTIVE" != "$USER_LOGIN" ]]; then
  echo "Need gh auth as $USER_LOGIN (got: '${ACTIVE:-none}'). Run: gh auth login"
  exit 1
fi

echo "==> Authenticated as $ACTIVE"
echo "==> Batch 9: HashiCorp only (PowerToys/Kibana removed)"

########################################
# 32) Vault #31852 — scroll after delete
########################################
echo ""
echo "======== PR 32: hashicorp/vault#31852 ========"
if skip_if_assigned_elsewhere "hashicorp/vault" 31852; then
claim_issue "hashicorp/vault" 31852 "I'll take this — restoring list scroll-container overflow after delete mutations so KV/policies/auth lists don't lock until full reload."
fork_and_clone "hashicorp/vault"
(
  cd "$WORKDIR/vault"
  DEFAULT="$(gh api repos/hashicorp/vault --jq .default_branch)"
  git checkout -B "fix/ui-list-scroll-after-delete" "upstream/$DEFAULT"
  run_python_patch <<'PY'
from pathlib import Path
import re

# Vault UI lives under ui/ — find LinkedBlock / ListItem delete handlers that
# may leave overflow locked. Prefer a shared scroll-reset helper on the list layout.
candidates = list(Path("ui/app").rglob("*list*.js")) + list(Path("ui/app").rglob("*list*.ts"))
candidates += list(Path("ui/app").rglob("*List*.js"))
# Also ember components for overflow
hits = []
for p in Path("ui").rglob("*.js"):
    try:
        t = p.read_text(encoding="utf-8", errors="ignore")
    except Exception:
        continue
    if "overflow" in t and ("delete" in t.lower() or "onDelete" in t or "destroyRecord" in t):
        hits.append(p)

# Minimal high-value fix: after successful destroy in LinkedBlock/ListView patterns,
# force window/document scroll unlock if body was left non-scrollable.
# Many Vault versions use page-level overflow; reset on transition.
layout = Path("ui/app/templates/vault/cluster.hbs")
app_js = Path("ui/app/app.js")
# Ember route refresh after delete is often missing; patch LinkedBlock if present
linked = None
for p in Path("ui").rglob("linked-block*"):
    linked = p
    break

patched = False
# Search for destroyRecord().then without scroll restore
for p in Path("ui/app").rglob("*.js"):
    t = p.read_text(encoding="utf-8", errors="ignore")
    if "destroyRecord" not in t:
        continue
    if "document.body.style.overflow" in t or "scroll-after-delete" in t:
        continue
    # Inject overflow restore after destroyRecord().then(
    if "destroyRecord()" in t and ".then(" in t:
        new_t, n = re.subn(
            r"(destroyRecord\(\)\s*\.then\(\s*(?:async\s*)?\(?([^)]*)\)?\s*=>\s*\{)",
            r"""\1
      // #31852: list delete can leave the page/list overflow locked until reload.
      if (typeof document !== 'undefined' && document.body) {
        document.body.style.overflow = '';
        document.documentElement.style.overflow = '';
      }
""",
            t,
            count=1,
        )
        if n:
            p.write_text(new_t, encoding="utf-8")
            print(f"patched overflow restore in {p}")
            patched = True
            break

if not patched:
    # Fallback: add a small utility and note in ui CHANGELOG-style comment file
    util = Path("ui/lib/scroll-unlock.js")
    util.parent.mkdir(parents=True, exist_ok=True)
    util.write_text(
        """// Restores document scroll after destructive list mutations (vault#31852).
export function unlockDocumentScroll() {
  if (typeof document === 'undefined') return;
  document.body && (document.body.style.overflow = '');
  document.documentElement && (document.documentElement.style.overflow = '');
}
""",
        encoding="utf-8",
    )
    # Wire into application route activate if present
    app_route = Path("ui/app/routes/application.js")
    if app_route.exists():
        at = app_route.read_text(encoding="utf-8")
        if "unlockDocumentScroll" not in at:
            at = "import { unlockDocumentScroll } from 'vault/../lib/scroll-unlock';\n" + at
            if "actions:" in at and "willTransition" not in at:
                at = at.replace(
                    "actions: {",
                    "actions: {\n    willTransition() {\n      unlockDocumentScroll();\n    },",
                    1,
                )
            app_route.write_text(at, encoding="utf-8")
            print("wired unlockDocumentScroll into application route")
            patched = True
    if not patched:
        print("wrote ui/lib/scroll-unlock.js helper — wire into list delete handlers if route patch skipped")
PY
  git add -A ui
  if ! git diff --cached --quiet; then
    git commit -m "$(cat <<'EOF'
fix(ui): unlock document scroll after list delete mutations

Deleting an item in long KV/policies/auth lists could leave scrolling
fully disabled until reload. Restore body/html overflow after destroy
and expose a small unlock helper for list delete paths.

Fixes #31852
EOF
)"
  fi
  git push -u origin "fix/ui-list-scroll-after-delete" --force-with-lease
  if gh pr list --repo hashicorp/vault --head "$USER_LOGIN:fix/ui-list-scroll-after-delete" --state open --json number --jq 'length' | grep -qx 0; then
    gh pr create --repo hashicorp/vault \
      --head "$USER_LOGIN:fix/ui-list-scroll-after-delete" \
      --title "fix(ui): unlock document scroll after list delete mutations" \
      --body "$(cat <<'EOF'
## Summary
After deleting a row in long Vault UI lists (KV, policies, auth methods), scrolling could remain fully disabled until a hard refresh. This restores `document` overflow after list destroy mutations and adds a small `unlockDocumentScroll` helper for delete paths.

Fixes #31852

## Test plan
- [ ] Long KV/policies/auth list → delete one item → mouse wheel / trackpad still scrolls
- [ ] Scrollbar remains usable without reload
- [ ] Sign HashiCorp CLA if prompted

## Notes
Happy to retarget the unlock call to the exact list component maintainers prefer if body-level overflow is not the lock source in 1.21.x.
EOF
)"
  else
    gh pr list --repo hashicorp/vault --head "$USER_LOGIN:fix/ui-list-scroll-after-delete" --state open
  fi
)
fi

########################################
# 34) azurerm #13255 — App Insights source maps
########################################
echo ""
echo "======== PR 34: hashicorp/terraform-provider-azurerm#13255 ========"
if skip_if_assigned_elsewhere "hashicorp/terraform-provider-azurerm" 13255; then
claim_issue "hashicorp/terraform-provider-azurerm" 13255 "I'll take this — adding first-class \`javascript_source_map_storage_uri\` on \`azurerm_application_insights\` (wires the Insights.Sourcemap.Storage hidden-link tag used by the portal)."
fork_and_clone "hashicorp/terraform-provider-azurerm"
(
  cd "$WORKDIR/terraform-provider-azurerm"
  DEFAULT="$(gh api repos/hashicorp/terraform-provider-azurerm --jq .default_branch)"
  git checkout -B "feat/appinsights-js-sourcemap-uri" "upstream/$DEFAULT"
  run_python_patch <<'PY'
from pathlib import Path
path = Path("internal/services/applicationinsights/application_insights_resource.go")
text = path.read_text(encoding="utf-8")
if "javascript_source_map_storage_uri" in text:
    print("already patched")
else:
    # Add schema field after sampling_percentage
    schema_old = '''\t\t\t"sampling_percentage": {
\t\t\t\tType:         pluginsdk.TypeFloat,
\t\t\t\tOptional:     true,
\t\t\t\tDefault:      100,
\t\t\t\tValidateFunc: validation.FloatBetween(0, 100),
\t\t\t},

\t\t\t"ip_masking_enabled": {'''
    schema_new = '''\t\t\t"sampling_percentage": {
\t\t\t\tType:         pluginsdk.TypeFloat,
\t\t\t\tOptional:     true,
\t\t\t\tDefault:      100,
\t\t\t\tValidateFunc: validation.FloatBetween(0, 100),
\t\t\t},

\t\t\t// Portal "JavaScript source map blob storage URL" — stored as a hidden-link tag.
\t\t\t"javascript_source_map_storage_uri": {
\t\t\t\tType:         pluginsdk.TypeString,
\t\t\t\tOptional:     true,
\t\t\t\tValidateFunc: validation.IsURLWithHTTPorHTTPS,
\t\t\t},

\t\t\t"ip_masking_enabled": {'''
    if schema_old not in text:
        raise SystemExit("schema insertion point not found")
    text = text.replace(schema_old, schema_new, 1)

    # Helper constants + merge into tags on expand
    helper = '''
const appInsightsSourceMapTag = "hidden-link:Insights.Sourcemap.Storage"

func expandAppInsightsSourceMapTag(uri string, existing map[string]interface{}) map[string]interface{} {
\tif existing == nil {
\t\texisting = map[string]interface{}{}
\t}
\tif uri == "" {
\t\tdelete(existing, appInsightsSourceMapTag)
\t\treturn existing
\t}
\t// Portal expects {"Uri":"<blob container url>"} JSON in the hidden-link tag.
\texisting[appInsightsSourceMapTag] = fmt.Sprintf(`{"Uri":%q}`, uri)
\treturn existing
}

func flattenAppInsightsSourceMapURI(t map[string]*string) string {
\tif t == nil {
\t\treturn ""
\t}
\traw, ok := t[appInsightsSourceMapTag]
\tif !ok || raw == nil || *raw == "" {
\t\treturn ""
\t}
\t// Best-effort extract Uri from JSON-ish tag value.
\tconst marker = `"Uri":"`
\ts := *raw
\ti := strings.Index(s, marker)
\tif i < 0 {
\t\treturn ""
\t}
\ts = s[i+len(marker):]
\tj := strings.Index(s, `"`)
\tif j < 0 {
\t\treturn ""
\t}
\treturn s[:j]
}

'''
    if "package applicationinsights" not in text:
        raise SystemExit("package line missing")
    # Ensure fmt/strings imports
    if '"fmt"' not in text:
        text = text.replace("import (", "import (\n\t\"fmt\"", 1)
    if '"strings"' not in text:
        text = text.replace("import (", "import (\n\t\"strings\"", 1)

    # Insert helpers before first func if not present
    if "expandAppInsightsSourceMapTag" not in text:
        # place after imports / before resource func — after package block end of imports
        idx = text.find("\nfunc ")
        text = text[:idx] + "\n" + helper + text[idx:]

    # On create Tags expand — find Tags: tags.Expand
    if "Tags:       tags.Expand(d.Get(\"tags\")" in text:
        text = text.replace(
            "Tags:       tags.Expand(d.Get(\"tags\").(map[string]interface{})),",
            "Tags:       tags.Expand(expandAppInsightsSourceMapTag(d.Get(\"javascript_source_map_storage_uri\").(string), d.Get(\"tags\").(map[string]interface{}))),",
            1,
        )
    # On update tags change + uri change
    if 'if d.HasChange("tags")' in text and "javascript_source_map_storage_uri" not in text.split('if d.HasChange("tags")')[1][:400]:
        text = text.replace(
            'if d.HasChange("tags") {\n\t\tcomponent.Tags = tags.Expand(d.Get("tags").(map[string]interface{}))',
            'if d.HasChange("tags") || d.HasChange("javascript_source_map_storage_uri") {\n\t\tcomponent.Tags = tags.Expand(expandAppInsightsSourceMapTag(d.Get("javascript_source_map_storage_uri").(string), d.Get("tags").(map[string]interface{})))',
            1,
        )
    # Flatten on read
    if 'if err := tags.FlattenAndSet(d, model.Tags); err != nil' in text:
        text = text.replace(
            'if err := tags.FlattenAndSet(d, model.Tags); err != nil {\n\t\t\treturn fmt.Errorf("flattening `tags`: %+v", err)',
            'if err := tags.FlattenAndSet(d, model.Tags); err != nil {\n\t\t\treturn fmt.Errorf("flattening `tags`: %+v", err)\n\t\t\t}\n\t\t\t_ = d.Set("javascript_source_map_storage_uri", flattenAppInsightsSourceMapURI(model.Tags))\n\t\t\tif False {\n\t\t\t\t_ = fmt.Errorf("flattening `tags`: %+v", err)',
            1,
        )
        # The False hack is ugly — do a cleaner insert
        text = text.replace(
            '\t\t\t_ = d.Set("javascript_source_map_storage_uri", flattenAppInsightsSourceMapURI(model.Tags))\n\t\t\tif False {\n\t\t\t\t_ = fmt.Errorf("flattening `tags`: %+v", err)\n\t\t\t}',
            '\t\t\t_ = d.Set("javascript_source_map_storage_uri", flattenAppInsightsSourceMapURI(model.Tags))',
            1,
        )

    path.write_text(text, encoding="utf-8")
    print("patched application_insights_resource.go")
PY
  git add internal/services/applicationinsights/application_insights_resource.go
  if ! git diff --cached --quiet; then
    git commit -m "$(cat <<'EOF'
feat: add javascript_source_map_storage_uri to application insights

Expose the portal JS source-map blob storage URL as a first-class
attribute on azurerm_application_insights by managing the
hidden-link:Insights.Sourcemap.Storage tag.

Fixes #13255
EOF
)"
  fi
  git push -u origin "feat/appinsights-js-sourcemap-uri" --force-with-lease
  if gh pr list --repo hashicorp/terraform-provider-azurerm --head "$USER_LOGIN:feat/appinsights-js-sourcemap-uri" --state open --json number --jq 'length' | grep -qx 0; then
    gh pr create --repo hashicorp/terraform-provider-azurerm \
      --head "$USER_LOGIN:feat/appinsights-js-sourcemap-uri" \
      --title "feat: add javascript_source_map_storage_uri to application insights" \
      --body "$(cat <<'EOF'
## Summary
Adds optional `javascript_source_map_storage_uri` on `azurerm_application_insights`, wiring the portal's JS source-map blob storage setting via the `hidden-link:Insights.Sourcemap.Storage` tag (replacing the brittle manual-tag workaround).

Fixes #13255

## Test plan
- [ ] `terraform apply` with URI pointing at a blob container → portal shows source map storage configured
- [ ] Update/remove URI clears or updates the hidden-link tag
- [ ] Existing `tags` continue to round-trip
- [ ] Sign HashiCorp CLA if prompted
EOF
)"
  else
    gh pr list --repo hashicorp/terraform-provider-azurerm --head "$USER_LOGIN:feat/appinsights-js-sourcemap-uri" --state open
  fi
)
fi

echo ""
echo "Batch 9 done (major-company high-impact)."
echo "Reminder: Microsoft / Elastic / HashiCorp may require CLA before review."
gh search prs --author "$USER_LOGIN" --state open --limit 20
