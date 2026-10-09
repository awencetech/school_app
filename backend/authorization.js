function authorizeRequestRole({ req, res, next, authenticate, allowedRoles, normalizeRole }) {
  const authorizeRole = () => {
    if (!req.auth) {
      return res.status(401).json({ message: 'Authentication required.' });
    }
    if (!allowedRoles.includes(normalizeRole(req.auth.role))) {
      return res.status(403).json({ message: 'You are not authorized to perform this action.' });
    }
    req.auth.role = normalizeRole(req.auth.role);
    return next();
  };

  if (req.auth) return authorizeRole();
  return authenticate(req, res, (error) => {
    if (error) return next(error);
    return authorizeRole();
  });
}

function isRecordOwner(auth, record, fields) {
  const userId = String(auth?.userId || '').trim();
  return Boolean(userId && record && fields.some(
    (field) => record[field] != null && String(record[field]).trim() === userId,
  ));
}

module.exports = { authorizeRequestRole, isRecordOwner };
