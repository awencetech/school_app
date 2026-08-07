require('dotenv').config();
const express = require('express');
const { createProxyMiddleware } = require('http-proxy-middleware');
const cors = require('cors');

const app = express();
const PORT = process.env.PORT || 8080;
const TARGET = process.env.TARGET || 'https://coresg-normal.trae.ai';
const ALLOW_ORIGIN = process.env.ALLOW_ORIGIN || 'http://localhost:8000';

app.use(cors({ origin: ALLOW_ORIGIN }));
app.use(express.json());

app.use('/proxy', createProxyMiddleware({
  target: TARGET,
  changeOrigin: true,
  pathRewrite: { '^/proxy': '' },
  onProxyReq: (proxyReq, req, res) => {
    const apiKey = process.env.API_KEY;
    if (apiKey) {
      proxyReq.setHeader('Authorization', `Bearer ${apiKey}`);
    }
  },
  onError: (err, req, res) => {
    console.error('Proxy error:', err);
    res.status(502).json({ error: 'Proxy error' });
  },
}));

app.get('/', (req, res) => res.send('Dev proxy running'));

app.listen(PORT, () => console.log(`Proxy running on http://localhost:${PORT} -> ${TARGET}`));
