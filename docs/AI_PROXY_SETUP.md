# LOGZINE AI Proxy Setup

## Why this changed

Previously each teammate ran Gemini features with their own local API key.
For shared demos and deployment, the app now routes Gemini requests through one
Cloudflare Worker proxy:

```text
Flutter app -> Cloudflare Worker -> Gemini API
```

This lets the team use one paid Gemini API key without committing the key to
the repository or embedding it directly in Flutter web/mobile builds.

## Current deployed proxy

```text
https://logzine-gemini-proxy.logzine-sua38.workers.dev
```

The Gemini key must be stored only as the Worker secret named
`GEMINI_API_KEY`. Do not add the key to GitHub, screenshots, README files, or
Flutter source code.

## Verified status

As of July 8, 2026, the Cloudflare Worker has been deployed and the app was
successfully run with:

```powershell
flutter run --dart-define=GEMINI_PROXY_URL=https://logzine-gemini-proxy.logzine-sua38.workers.dev
```

The MY COVER image-generation flow was confirmed to work through the proxy
after registering the Worker secret.

## Supported request formats

The Worker accepts both formats below so teammate branches can use either the
shared Flutter proxy helper or a Gemini REST-like path.

Proxy envelope:

```http
POST /
```

```json
{
  "model": "gemini-2.0-flash",
  "body": {
    "contents": []
  }
}
```

Gemini REST-like path:

```http
POST /v1beta/models/gemini-2.0-flash:generateContent
```

```json
{
  "contents": []
}
```

## How teammates run the app

Create or update `logzine_app/env.json`:

```json
{
  "GEMINI_PROXY_URL": "https://logzine-gemini-proxy.logzine-sua38.workers.dev"
}
```

Then run:

```powershell
cd logzine_app
flutter run --dart-define-from-file=env.json
```

Or run without `env.json`:

```powershell
flutter run --dart-define=GEMINI_PROXY_URL=https://logzine-gemini-proxy.logzine-sua38.workers.dev
```

## How to build web

```powershell
cd logzine_app
flutter build web --dart-define=GEMINI_PROXY_URL=https://logzine-gemini-proxy.logzine-sua38.workers.dev
```

## If the proxy must be redeployed

Only the proxy owner needs to do this:

```powershell
cd logzine_app/cloudflare-worker
npx.cmd wrangler login
npx.cmd wrangler secret put GEMINI_API_KEY
npx.cmd wrangler deploy
```

No teammate needs a Gemini API key or Cloudflare account just to run the app.

## Important limitations

This is a free-serverless demo setup. It protects the API key from client-side
exposure, but a fully public production app should add stronger abuse controls
such as authentication, origin restrictions, request quotas, or Cloudflare rate
limiting.
