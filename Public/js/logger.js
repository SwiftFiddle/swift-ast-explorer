"use strict";

Sentry.init({
  dsn: "https://27b9f9a7ec6f46a6ac6ce4445a6e6783@o938512.ingest.sentry.io/5899228",
  integrations: [new Sentry.Integrations.BrowserTracing()],
  tracesSampleRate: 1.0,
});
