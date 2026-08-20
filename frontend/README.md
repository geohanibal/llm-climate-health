# Frontend — LLM-Climate-Health

Flutter web UI for the Climate-Health Data Integration Platform. Single page:
a "describe your request" free-text box (AI-assisted prefill) above a
structured request form, followed by the integration results once a run
completes.

## Run locally

```bash
cd frontend
flutter pub get
flutter run -d chrome --web-port=5173
```

Talks to a backend at `http://127.0.0.1:8000` by default (see
`../backend/README.md` to run it). Point at a different backend with:

```bash
flutter run -d chrome --web-port=5173 --dart-define=BACKEND_URL=https://your-deployment
```

For a production build, the same flag matters — an empty `BACKEND_URL`
makes the app call same-origin relative paths, which is what the single
Docker image deployment (`../Dockerfile`) uses:

```bash
flutter build web --release --dart-define=BACKEND_URL=
```

## Tests

```bash
flutter test
flutter analyze
```

## Layout

```text
lib/
  main.dart, app.dart      entry point, MaterialApp shell
  pages/home_page.dart     top-level page: loads options, hosts form + results
  widgets/                 one file per UI section (form, natural-language
                            card, results, chart, table, sources, ...)
  services/                api_client.dart (HTTP), PDF/CSV export, world-map
                            GeoJSON loading
  models/                  plain data classes mirroring the backend's JSON
  core/                    responsive layout + formatting helpers
test/                      model round-trip tests + a smoke test
```
