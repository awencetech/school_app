const ALLOWED_METHODS = ['GET', 'POST', 'PUT', 'PATCH', 'DELETE', 'OPTIONS'];
const ALLOWED_HEADERS = ['Content-Type', 'Authorization', 'X-Requested-With'];
const DEVELOPMENT_ORIGINS = [
  'http://localhost:8000',
  'http://127.0.0.1:8000',
];

function createCorsMiddleware({
  cors,
  allowedOrigins = [],
  onRejectedOrigin = (origin, method) => {
    console.warn(`Rejected CORS ${method} request from unconfigured origin: ${origin}`);
  },
}) {
  if (typeof cors !== 'function') {
    throw new TypeError('A CORS middleware factory is required.');
  }

  const originAllowlist = new Set([...DEVELOPMENT_ORIGINS, ...allowedOrigins]);
  const configuredCors = cors({
    origin(origin, callback) {
      if (!origin) return callback(null, false);
      callback(null, origin);
    },
    credentials: true,
    methods: ALLOWED_METHODS,
    allowedHeaders: ALLOWED_HEADERS,
    optionsSuccessStatus: 204,
  });

  return (req, res, next) => {
    const origin = req.get('Origin');
    if (origin && !originAllowlist.has(origin)) {
      onRejectedOrigin(origin, req.method);
      return res.status(403).json({ message: 'Origin is not allowed.' });
    }
    return configuredCors(req, res, next);
  };
}

module.exports = { createCorsMiddleware };
