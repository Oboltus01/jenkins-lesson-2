# Lesson 6 — Jenkins Artifacts & Validation Gates

Оригинальное задание Сергея: [lesson6.md](https://github.com/sirgray/specter-jen/blob/main/lesson6.md).

## Файлы

- [provision.groovy](provision.groovy) — Hours 1–2, генерация файлов в Workspace.
- [validation.groovy](validation.groovy) — Hours 3–4, проверки манифеста.
- [restore.sh](restore.sh) — восстановление двух конфигураций в уже работающем Jenkins (конечная — Validation Gates).

## Восстановление в новой Killercoda

Установка Jenkins (пока он отсутствует):

```bash
curl -fsSL https://raw.githubusercontent.com/Oboltus01/jenkins-lesson-2/main/lesson5/fast-setup.sh -o /tmp/jenkins-fast.sh
bash /tmp/jenkins-fast.sh
```

Когда Jenkins доступен (HTTP 200) и известен локальный пароль:

```bash
curl -fsSL https://raw.githubusercontent.com/Oboltus01/jenkins-lesson-2/main/lesson6/restore.sh -o /tmp/lesson6-restore.sh
bash /tmp/lesson6-restore.sh
```

Скрипт **не запускает сборку автоматически** и не уничтожает текущую Job или историю сборок. Он заменяет Shell-конфигурацию существующего `lesson6-artifact-demo` на финальную версию Hours 3–4.

Для проверки из API:
```bash
PASS=$(cat /root/.jenkins-lesson5-fast/admin-password)
curl -fsS -u "admin:$PASS" http://localhost:8080/job/lesson6-artifact-demo/lastBuild/consoleText
```

**Важно:** примерная строка `"checksum_verified": true` не является криптографической проверкой SHA-256. Скачивание из `/ws/` относится к текущему Workspace, а не к архиву конкретной сборки.

## Результаты практики 25.10.2026

Build #1 с PRODUCTION — SUCCESS; Build #2 с STAGING — SUCCESS. ZIP с Workspace был скачан, проверен и распакован. В уроке использовались Crumb + cookies одной сессии для POST-вызовов.
