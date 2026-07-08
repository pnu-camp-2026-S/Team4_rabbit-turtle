# LOGZINE Gemini Proxy on Cloudflare Workers

This is the free-serverless path for sharing one paid Gemini API key without
putting the key in the Flutter app.

## One-time setup

```powershell
cd cloudflare-worker
npx.cmd wrangler login
npx.cmd wrangler secret put GEMINI_API_KEY
npx.cmd wrangler deploy
```

Copy the deployed Worker URL, then run/build Flutter with:

```powershell
flutter run --dart-define=GEMINI_PROXY_URL=https://logzine-gemini-proxy.logzine-sua38.workers.dev
```

For web deployment:

```powershell
flutter build web --dart-define=GEMINI_PROXY_URL=https://logzine-gemini-proxy.logzine-sua38.workers.dev
```

## Notes

- The Gemini API key stays in Cloudflare as a Worker secret.
- No Firebase Blaze plan is required for this proxy.
- This is suitable for demos and low-traffic class projects. A fully public
  production app should add stronger abuse controls.
