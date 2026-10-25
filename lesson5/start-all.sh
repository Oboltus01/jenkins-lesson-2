#!/usr/bin/env bash
set -euo pipefail
# One-command launcher for temporary Killercoda Jenkins lab.
BASE=https://raw.githubusercontent.com/Oboltus01/jenkins-lesson-2
# Pin tested versions to avoid raw.githubusercontent.com branch cache.
SETUP_REF=28943ade4c392037528b9f38bb32397aeea863c8
RECOVER_REF=6146c1829e41aabfbfa99ca4fb8e3775c0b26563
STATE_DIR=/root/.jenkins-lesson5-fast
PASS_FILE="$STATE_DIR/admin-password"
mkdir -p "$STATE_DIR"
chmod 700 "$STATE_DIR"

# Reuse the current session's password when present; only ask on a fresh session.
if [ ! -s "$PASS_FILE" ]; then
  if [ -z "${JENKINS_ADMIN_PASSWORD:-}" ]; then
    read -rsp "Choose Jenkins admin password (12+ characters): " JENKINS_ADMIN_PASSWORD
    echo
  fi
  if [ "${#JENKINS_ADMIN_PASSWORD}" -lt 12 ]; then
    echo "Password must have at least 12 characters." >&2
    exit 1
  fi
  export JENKINS_ADMIN_PASSWORD
fi
trap 'unset JENKINS_ADMIN_PASSWORD' EXIT

curl -fsSL "$BASE/$SETUP_REF/lesson5/fast-setup.sh" -o /tmp/jenkins-fast.sh
bash -n /tmp/jenkins-fast.sh
bash /tmp/jenkins-fast.sh

# The recover script supports password+crumb authentication, no API token required.
# Ignore an API_TOKEN leftover from unrelated Jenkins exercises.
unset API_TOKEN
curl -fsSL "$BASE/$RECOVER_REF/lesson5/recover.sh" -o /tmp/jenkins-recover.sh
bash -n /tmp/jenkins-recover.sh
bash /tmp/jenkins-recover.sh

echo "=============================================="
echo "Jenkins ready and lesson5-webhook-demo restored."
echo "Open Traffic / Ports -> 8080."
echo "Username: admin"
echo "Password: the one entered above (or in $PASS_FILE)."
echo "=============================================="
