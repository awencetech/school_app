Dev proxy for forwarding image API requests (avoids CORS in local dev)

Usage

1. Install dependencies

```bash
cd dev-proxy
npm install
```

2. Configure environment

Copy `.env.example` to `.env` and set `API_KEY` if the upstream requires authentication.

3. Run proxy

```bash
npm start
# or for auto-reload during development
npm run dev
```

4. Update your Flutter web requests

Replace external origin with the proxy prefix. Example:

From:
`https://coresg-normal.trae.ai/api/ide/v1/text_to_image?...`

To:
`http://localhost:8080/proxy/api/ide/v1/text_to_image?...`

Notes

- This proxy is for local development only. For production, implement a proper backend that secures API keys and enforces rate limits.
- If upstream requires additional headers or special signing, add that logic in `index.js`.
