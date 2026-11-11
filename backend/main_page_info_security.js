'use strict';

function createMainPageInfoCacheMiddleware() {
  return (req, res, next) => {
    if (req.method !== 'GET') return next();

    res.setHeader('Cache-Control', 'private, no-store');

    // Express creates an ETag while preparing res.json(). Remove it immediately
    // before the response is committed so role-dependent representations cannot
    // participate in conditional cache validation for this endpoint.
    const originalEnd = res.end;
    res.end = function endWithoutMainPageEtag(...args) {
      res.removeHeader('ETag');
      return originalEnd.apply(this, args);
    };

    return next();
  };
}

function filterMainPageInfoForUser(doc, auth, normalizeRole) {
  if (normalizeRole(auth?.role) === 'admin') return doc;

  const visible = { ...doc };
  delete visible.gradePage;
  if (visible.schoolContent && typeof visible.schoolContent === 'object') {
    visible.schoolContent = { ...visible.schoolContent };
    delete visible.schoolContent.gradePage;
  }
  return visible;
}

module.exports = {
  createMainPageInfoCacheMiddleware,
  filterMainPageInfoForUser,
};
