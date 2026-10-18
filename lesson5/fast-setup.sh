#!/usr/bin/env bash
set -euo pipefail

# Lesson 5 fast setup, for ephemeral Killercoda labs only.
# Jenkins is secured with a generated admin password; CSRF remains enabled.
NAME=my-jenkins
STATE_DIR=/root/.jenkins-lesson5-fast
PASS_FILE="$STATE_DIR/admin-password"
INIT_DIR="$STATE_DIR/init.groovy.d"
mkdir -p "$INIT_DIR"
chmod 700 "$STATE_DIR"
chmod 755 "$INIT_DIR"

if docker ps -a --format '{{.Names}}' | grep -Fxq "$NAME"; then
  echo "Existing $NAME detected. Keeping its configuration (no reset)."
  if ! docker ps --format '{{.Names}}' | grep -Fxq "$NAME"; then docker start "$NAME"; fi
else
  command -v openssl >/dev/null || { echo "openssl required"; exit 1; }
  if [ ! -s "$PASS_FILE" ]; then
    (umask 077; openssl rand -hex 20 > "$PASS_FILE")
  fi
  chmod 600 "$PASS_FILE"
  # Container Jenkins runs as UID 1000; allow it to read the bind-mounted secret.
  chown 1000:1000 "$PASS_FILE"
  cat > "$INIT_DIR/security.groovy" <<'GROOVY'
import jenkins.model.Jenkins
import hudson.security.HudsonPrivateSecurityRealm
import hudson.security.FullControlOnceLoggedInAuthorizationStrategy

def j = Jenkins.get()
def realm = j.getSecurityRealm()
if (!(realm instanceof HudsonPrivateSecurityRealm)) {
    realm = new HudsonPrivateSecurityRealm(false)
    j.setSecurityRealm(realm)
}
if (realm.getUser('admin') == null) {
    def password = new File('/run/lesson5-admin-password').text.trim()
    if (!password) throw new IllegalStateException('Missing admin password')
    realm.createAccount('admin', password)
}
def auth = new FullControlOnceLoggedInAuthorizationStrategy()
auth.setAllowAnonymousRead(false)
j.setAuthorizationStrategy(auth)
j.save()
println('LESSON5_FAST_ADMIN_READY')
GROOVY
  chmod 644 "$INIT_DIR/security.groovy"
  docker volume create jenkins_home >/dev/null
  docker run -d --name "$NAME" \
    -p 8080:8080 -p 50000:50000 \
    -v jenkins_home:/var/jenkins_home \
    -v "$INIT_DIR:/usr/share/jenkins/ref/init.groovy.d:ro" \
    -v "$PASS_FILE:/run/lesson5-admin-password:ro" \
    -e JAVA_OPTS="-Djenkins.install.runSetupWizard=false" \
    jenkins/jenkins:lts-jdk17 >/dev/null
  echo "Created Jenkins without installing suggested plugins."
fi

ready=false
for i in $(seq 1 90); do
  if curl -fsS -o /dev/null http://localhost:8080/login; then ready=true; break; fi
  sleep 3
done
[ "$ready" = true ] || { echo "Jenkins not ready. Check: docker logs my-jenkins --tail 50"; exit 1; }
if [ -f "$PASS_FILE" ]; then
  result=$(curl -fsS -u "admin:$(cat "$PASS_FILE")" http://localhost:8080/whoAmI/api/json || true)
  if ! printf '%s' "$result" | grep -q '"authenticated":true'; then
    echo "Admin not verified yet; inspect docker logs my-jenkins --tail 50" >&2
    exit 1
  fi
fi
echo "Jenkins ready. Open port 8080 in Killercoda."
echo "Username: admin"
echo "Password is stored locally at: $PASS_FILE"
echo "To view it privately: cat $PASS_FILE"
echo "In Jenkins: admin > Security > API Token > Add new Token."
echo 'Then in terminal: read -rsp "Jenkins token: " API_TOKEN; echo; export API_TOKEN'
echo 'Restore Lesson 5 final job:'
echo 'curl -fsSL https://raw.githubusercontent.com/Oboltus01/jenkins-lesson-2/main/lesson5/recover.sh | bash'
