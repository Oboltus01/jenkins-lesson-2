# Jenkins Lesson 5 — Webhook JSON Parsing (18 October 2026)

Source: [Sergey's lesson5.md](https://github.com/sirgray/specter-jen/blob/main/lesson5.md).

This directory saves the **Hours 3–4 final job configuration** and a standalone recovery script. It does not modify the older Lesson 2 bootstrap or Jenkins jobs.

## What we completed

- Freestyle job: `lesson5-webhook-demo`
- Parameter: `PAYLOAD_JSON`
- Groovy provisioning using administrator API `POST /scriptText`
- Hours 1–2: receive and print a JSON payload
- Hours 3–4: extract `event`, `repo`, `action` and select a shell branch
- Verified 5 successful builds: two ingestion tests, then `release`, `push`, and `ping`

Actions in the shell script are **messages only**: it does not actually deploy software or run unit tests. `buildWithParameters` is a Jenkins API call used to simulate a webhook; this example does not register an external webhook receiver. The grep/cut parser works for the compact sample format, but is not a general JSON parser.

## Recreate in a fresh Killercoda session

Start a temporary Jenkins instance, configure a protected administrator account, create an API token through the Jenkins UI, and set the token in your shell:

```bash
read -rsp "Jenkins API token: " API_TOKEN; echo
export API_TOKEN
```

**Never commit tokens/passwords to GitHub.** Then download and execute the standalone provisioning script:

```bash
curl -fsSL https://raw.githubusercontent.com/Oboltus01/jenkins-lesson-2/main/lesson5/recover.sh -o /tmp/lesson5-recover.sh
bash /tmp/lesson5-recover.sh
```

The script starts Jenkins if absent, waits for readiness, and provisions the final configuration using an authenticated API token. It deliberately does not disable CSRF or configure an insecure anonymous administrative account.

## Send test data

```bash
JOB=http://localhost:8080/job/lesson5-webhook-demo
for payload in \
  '{"event":"release","repo":"org/core-service","action":"published"}' \
  '{"event":"push","repo":"org/core-service","action":"synchronize"}' \
  '{"event":"ping","repo":"org/core-service","action":"created"}'
do
  curl -fsS -u "admin:$API_TOKEN" -X POST "$JOB/buildWithParameters" \
    --data-urlencode "PAYLOAD_JSON=$payload"
done
```

Check build numbers and completion before requesting logs (queueing is asynchronous):

```bash
curl -gsS -u "admin:$API_TOKEN" \
  'http://localhost:8080/job/lesson5-webhook-demo/api/json?tree=builds[number,result,building]' \
  | python3 -m json.tool
```

Read a **specific** build number `N` using `$JOB/N/consoleText`. Avoid relying on `sleep 3` followed by `lastBuild`, because it can show an earlier run.

## Notes

- `provision.groovy` is re-runnable and updates the same job.
- The old `jenkins-lesson-2` recovery scripts are left untouched.
- For a real Jenkins installation, keep authentication and CSRF protection enabled.
