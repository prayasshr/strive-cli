#!/bin/bash
# Fixture tests for strive-sync 1.4 (bash). Builds temp bare remotes and
# clones, puts fake package managers and a fake nvm on PATH, runs a sync
# with installs, and checks each repo's final status.
#
# Usage: bash test/v1/run.sh

ROOT="$(cd "$(dirname "$0")/../.." && pwd)"
TMP=$(mktemp -d -t strive_v1_test.XXXXXX)
trap 'rm -rf "$TMP"' EXIT

PASS=0
FAIL=0
check() {
    if eval "$2"; then
        PASS=$((PASS + 1)); echo "  ok    $1"
    else
        FAIL=$((FAIL + 1)); echo "  FAIL  $1"
    fi
}

G() { git -c user.name=Ana -c user.email=ana@example.com "$@"; }

# ---------------------------------------------------------------- fakes
mkdir -p "$TMP/fake" "$TMP/ctl" "$TMP/nvm"
CALLS="$TMP/calls.log"
for tool in npm yarn pnpm bun; do
    cat > "$TMP/fake/$tool" <<EOF
#!/bin/bash
name=\$(basename "\$PWD")
echo "$tool \$* | dir=\$name | node=\$FAKE_NODE" >> "$CALLS"
[ -f "$TMP/ctl/\$name.fail" ] && { echo "boom"; exit 1; }
[ -f "$TMP/ctl/\$name.mismatch" ] && { echo "npm ERR! package.json and package-lock.json are in sync"; exit 1; }
[ -f "$TMP/ctl/\$name.touch" ] && echo "rewritten" >> package-lock.json
mkdir -p node_modules
exit 0
EOF
    chmod +x "$TMP/fake/$tool"
done
cat > "$TMP/fake/node" <<'EOF'
#!/bin/bash
echo "${FAKE_NODE:-none}"
EOF
chmod +x "$TMP/fake/node"
# Fake nvm: `nvm use --silent <version>` exports FAKE_NODE; v99 is "not installed"
cat > "$TMP/nvm/nvm.sh" <<'EOF'
nvm() {
    [ "$1" == "use" ] || return 0
    local v=$3
    [ "$v" == "v99" ] && { echo "N/A: version v99 is not yet installed"; return 3; }
    export FAKE_NODE=$v
}
EOF

# ---------------------------------------------------------------- repos
# make_repo <name> <setup-fn> <change-fn>: remote gets setup, clone is made,
# then the remote gets the change so the clone is one commit behind.
make_repo() {
    local name=$1 seed="$TMP/seed/$1"
    mkdir -p "$seed"
    G init -q -b main "$seed"
    (cd "$seed" && "$2" && G add -A && G commit -qm init)
    G clone -q --bare "$seed" "$TMP/remote/$name.git"
    G clone -q "$TMP/remote/$name.git" "$TMP/ws/$name"
    (cd "$seed" && G remote add origin "$TMP/remote/$name.git" && "$3" && G add -A && G commit -qm change && G push -q origin main)
}

# web-app: npm at the root, a yarn 1 package in a subfolder, .nvmrc at the root
web_setup()  { echo v20 > .nvmrc; echo '{}' > package.json; echo 1 > package-lock.json
               mkdir ui; echo '{}' > ui/package.json; echo 1 > ui/yarn.lock; }
web_change() { echo 2 > ui/yarn.lock; }

# api-service: npm, root lockfile changes, Node 18
api_setup()  { echo v18 > .nvmrc; echo '{}' > package.json; echo 1 > package-lock.json; }
api_change() { echo 2 > package-lock.json; }

# berry-app: yarn 2+ via .yarnrc.yml
berry_setup()  { echo '{}' > package.json; echo 1 > yarn.lock; echo 'nodeLinker: node-modules' > .yarnrc.yml; }
berry_change() { echo 2 > yarn.lock; }

# pm-app: packageManager wins over lockfiles
pm_setup()  { echo '{ "packageManager": "pnpm@9.1.0" }' > package.json; echo 1 > pnpm-lock.yaml; echo 1 > yarn.lock; }
pm_change() { echo 2 > pnpm-lock.yaml; }

# quiet-app: change does not touch any manifest or lockfile
quiet_setup()  { echo '{}' > package.json; echo 1 > package-lock.json; echo a > README.md; }
quiet_change() { echo b > README.md; }

# old-node: wants a Node version that is not installed
old_setup()  { echo v99 > .nvmrc; echo '{}' > package.json; echo 1 > package-lock.json; }
old_change() { echo 2 > package-lock.json; }

for r in broken-app mismatch-app dirty-app; do :; done
plain_setup()  { echo '{}' > package.json; echo 1 > package-lock.json; }
plain_change() { echo 2 > package-lock.json; }

make_repo web-app      web_setup   web_change
make_repo api-service  api_setup   api_change
make_repo berry-app    berry_setup berry_change
make_repo pm-app       pm_setup    pm_change
make_repo quiet-app    quiet_setup quiet_change
make_repo old-node     old_setup   old_change
make_repo broken-app   plain_setup plain_change
make_repo mismatch-app plain_setup plain_change
make_repo dirty-app    plain_setup plain_change
touch "$TMP/ctl/broken-app.fail" "$TMP/ctl/mismatch-app.mismatch" "$TMP/ctl/dirty-app.touch"

cat > "$TMP/ws/.repos" <<'EOF'
web-app
web-app/ui
api-service
berry-app
pm-app
quiet-app
old-node
broken-app
mismatch-app
dirty-app
EOF

# ---------------------------------------------------------------- run
run_sync() {
    (cd "$TMP/ws" && PATH="$TMP/fake:$PATH" NVM_DIR="$TMP/nvm" XDG_STATE_HOME="$TMP/state" \
        /bin/bash "$ROOT/bin/strive-sync" -y "$@" < /dev/null) 2>&1 \
        | sed $'s/\x1b\\[[0-9;?]*[A-Za-z]//g' > "$TMP/out.txt"
}
status_of() { grep -E "^   $1 +\|" "$TMP/out.txt" | tail -n 1 | sed 's/^[^|]*| //'; }

echo "strive-sync v1 fixtures"
run_sync -i

check "SYNC-03 subfolder entry shares the repo's git run (no fetch clash)" \
    '[[ "$(status_of web-app)" == *SUCCESS* ]]'
check "SYNC-03 subfolder entry installs in its own folder" \
    'grep -q "^yarn install --frozen-lockfile --non-interactive | dir=ui" "$CALLS"'
check "SYNC-03 subfolder row reports its parent repo" \
    '[[ "$(status_of web-app/ui)" == *"part of web-app"* ]]'
check "SYNC-14 root lockfile unchanged, so no root install" \
    '! grep -q "dir=web-app" "$CALLS"'
check "SYNC-16 subfolder uses the nearest .nvmrc up to the repo root" \
    'grep -q "dir=ui | node=v20" "$CALLS"'
check "SYNC-15 npm repos install with npm ci" \
    'grep -q "^npm ci | dir=api-service" "$CALLS"'
check "SYNC-16 install runs under the .nvmrc version" \
    'grep -q "dir=api-service | node=v18" "$CALLS"'
check "SYNC-15 yarn 2+ installs with --immutable" \
    'grep -q "^yarn install --immutable | dir=berry-app" "$CALLS"'
check "SYNC-15 packageManager wins over other lockfiles" \
    'grep -q "^pnpm install --frozen-lockfile | dir=pm-app" "$CALLS"'
check "SYNC-14 no install when no manifest or lockfile changed" \
    '! grep -q "dir=quiet-app" "$CALLS"'
check "SYNC-16 missing Node version fails with the fix" \
    '[[ "$(status_of old-node)" == *"FAILED"*"nvm install v99"* ]]'
check "CORE-10 failed install shows FAILED, not SUCCESS" \
    '[[ "$(status_of broken-app)" == *"FAILED"*"failed"* ]]'
check "CORE-10 failed install log is kept after the run" \
    '[ -s "$TMP/state/strive-sync/logs/broken-app.log" ]'
check "SYNC-15 lockfile mismatch is named as such" \
    '[[ "$(status_of mismatch-app)" == *"Lockfile out of sync"* ]]'
check "SYNC-05 an install that changes tracked files is reported" \
    '[[ "$(status_of dirty-app)" == *"Install changed files: package-lock.json"* ]]'
check "SYNC-05 sync leaves those files as they are" \
    '[ -n "$(git -C "$TMP/ws/dirty-app" status --porcelain)" ]'
check "SYNC-15 no lockfile rewritten in clean repos" \
    '[ -z "$(git -C "$TMP/ws/api-service" status --porcelain)$(git -C "$TMP/ws/web-app" status --porcelain)" ]'

# Second run, no installs: everything is current; the subfolder row mirrors its repo
: > "$CALLS"
run_sync
check "SYNC-03 subfolder row is resolved when no install runs" \
    '[[ "$(status_of web-app/ui)" == *"SYNCED"*"part of web-app"* ]]'
check "SYNC-13 no installs without -i" \
    '[ ! -s "$CALLS" ]'

echo
echo "$PASS passed, $FAIL failed"
[ "$FAIL" -eq 0 ]
