function createSplashRouter({
  express,
  requireAdmin,
  getMainPageDocument,
  buildDefaultDocument,
  upsertMainPageDocument,
}) {
  const router = express.Router();

  router.get('/', requireAdmin, async (_req, res) => {
    try {
      const current = (await getMainPageDocument()) || buildDefaultDocument();
      const defaults = buildDefaultDocument();
      return res.json({
        splashScreen: current.splashScreen || defaults.splashScreen,
      });
    } catch (error) {
      console.error(
        'GET /api/mainpage-info/splash failed:',
        error instanceof Error ? error.name : 'Unknown error',
      );
      return res.status(500).json({
        message: 'Unable to load splash screen configuration.',
      });
    }
  });

  router.put('/', requireAdmin, async (req, res) => {
    try {
      const current = (await getMainPageDocument()) || buildDefaultDocument();
      const updated = await upsertMainPageDocument({
        ...current,
        splashScreen: {
          ...(current.splashScreen || {}),
          ...(req.body || {}),
        },
      });
      return res.json(updated);
    } catch (error) {
      console.error(
        'PUT /api/mainpage-info/splash failed:',
        error instanceof Error ? error.name : 'Unknown error',
      );
      return res.status(500).json({
        message: 'Unable to save changes. Please try again.',
      });
    }
  });

  return router;
}

module.exports = { createSplashRouter };
