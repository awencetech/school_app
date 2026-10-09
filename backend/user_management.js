const crypto = require('crypto');

const USER_ROLES = new Set(['admin', 'staff', 'teacher', 'student']);

function canonicalRole(value) {
  const role = String(value || '').trim().toLowerCase();
  if (role === 'admins') return 'admin';
  if (role === 'students') return 'student';
  if (role === 'teacher' || role === 'teachers') return 'staff';
  return role;
}

function signAuthPayload(payload, secret) {
  if (typeof secret !== 'string' || secret.length < 32) {
    throw new Error('AUTH_SECRET must contain at least 32 characters.');
  }
  const encoded = Buffer.from(JSON.stringify(payload)).toString('base64url');
  const signature = crypto.createHmac('sha256', secret).update(encoded).digest('base64url');
  return `${encoded}.${signature}`;
}

function verifyAuthToken(token, secret) {
  if (typeof token !== 'string' || token.length > 8192 ||
      typeof secret !== 'string' || secret.length < 32) {
    return null;
  }

  const separator = token.lastIndexOf('.');
  if (separator < 1 || separator === token.length - 1) return null;

  const encoded = token.slice(0, separator);
  const signature = token.slice(separator + 1);
  const expected = crypto.createHmac('sha256', secret).update(encoded).digest();
  let actual;
  try {
    actual = Buffer.from(signature, 'base64url');
  } catch (_) {
    return null;
  }
  if (actual.length !== expected.length || !crypto.timingSafeEqual(actual, expected)) {
    return null;
  }

  try {
    const payload = JSON.parse(Buffer.from(encoded, 'base64url').toString('utf8'));
    if (!payload || typeof payload.userId !== 'string' || !payload.userId ||
        typeof payload.role !== 'string' || !USER_ROLES.has(canonicalRole(payload.role)) ||
        !Number.isInteger(payload.exp) || payload.exp <= Math.floor(Date.now() / 1000)) {
      return null;
    }
    payload.role = canonicalRole(payload.role);
    return payload;
  } catch (_) {
    return null;
  }
}

function readBearerToken(req) {
  const header = req.get('Authorization') || '';
  const match = /^Bearer ([^\s]+)$/.exec(header);
  return match ? match[1] : '';
}

function createAuthenticate({ secret, loadUser }) {
  return async function authenticate(req, res, next) {
    const payload = verifyAuthToken(readBearerToken(req), secret);
    if (!payload) {
      return res.status(401).json({ message: 'Authentication required.' });
    }

    try {
      const user = await loadUser(payload.userId, payload.role);
      if (!user || String(user.userId || user.userID || '') !== payload.userId ||
          !USER_ROLES.has(canonicalRole(user.role))) {
        return res.status(401).json({ message: 'Authentication required.' });
      }

      const acceptedRole = canonicalRole(user.role);
      if (acceptedRole !== payload.role.toLowerCase()) {
        return res.status(401).json({ message: 'Authentication required.' });
      }

      const status = String(user.status ?? user.accountStatus ?? user.State ?? user.state ?? '')
        .trim()
        .toLowerCase();
      if (['inactive', 'disabled', 'blocked', 'suspended', 'deactivated'].includes(status) ||
          user.active === false || user.isActive === false ||
          user.enabled === false || user.isEnabled === false) {
        return res.status(401).json({ message: 'Authentication required.' });
      }

      req.auth = {
        userId: String(user.userId || user.userID),
        email: String(user.email || user.emailAddress || user.userEmail || ''),
        role: acceptedRole,
      };
      return next();
    } catch (error) {
      return next(error);
    }
  };
}

function requireAdmin(req, res, next) {
  if (req.auth?.role !== 'admin') {
    return res.status(403).json({ message: 'Admin access required.' });
  }
  return next();
}

function safeUser(user) {
  if (!user) return null;
  return {
    id: user._id ? user._id.toString() : user.id || null,
    userId: user.userId || user.userID || '',
    email: user.email || user.emailAddress || user.userEmail ||
      user.adminEmail || user.staffEmail || user.studentEmail || '',
    role: canonicalRole(user.role || 'student'),
  };
}

function validEmail(email) {
  return typeof email === 'string' &&
    email.length <= 254 &&
    /^[^\s@]+@[^\s@]+\.[^\s@]+$/.test(email);
}

function validPassword(password) {
  return typeof password === 'string' && password.length >= 8 && password.length <= 128;
}

function createUserManagementRouter({ express, authenticate, repository, bcrypt }) {
  const router = express.Router();
  router.use(authenticate);

  router.get('/', requireAdmin, async (req, res, next) => {
    try {
      const role = req.query.role ? String(req.query.role).toLowerCase() : undefined;
      if (role && !USER_ROLES.has(role)) {
        return res.status(422).json({ message: 'Invalid role.' });
      }
      const users = await repository.list(role);
      return res.json(users.map(safeUser));
    } catch (error) {
      return next(error);
    }
  });

  router.post('/', requireAdmin, async (req, res, next) => {
    try {
      const body = req.body || {};
      const allowedFields = new Set(['userId', 'email', 'password', 'role']);
      if (Object.keys(body).some((key) => !allowedFields.has(key))) {
        return res.status(422).json({ message: 'Unexpected user fields.' });
      }

      const userId = typeof body.userId === 'string' ? body.userId.trim() : '';
      const email = typeof body.email === 'string' ? body.email.trim().toLowerCase() : '';
      const role = typeof body.role === 'string' ? body.role.trim().toLowerCase() : '';
      const canonicalRole = role === 'students' ? 'student' :
        role === 'teachers' || role === 'teacher' ? 'staff' :
          role === 'admins' ? 'admin' : role;

      if (!userId || userId.length > 128 || !validEmail(email) ||
          !validPassword(body.password) || !['admin', 'staff', 'student'].includes(canonicalRole)) {
        return res.status(422).json({ message: 'A valid user ID, email, password, and role are required.' });
      }

      if (await repository.findConflict({ userId })) {
        return res.status(409).json({ message: 'User ID already exists.' });
      }
      if (await repository.findConflict({ email })) {
        return res.status(409).json({ message: 'Email already exists.' });
      }

      const user = await repository.create({
        userId,
        email,
        password: await bcrypt.hash(body.password, 10),
        role: canonicalRole,
        createdAt: new Date().toISOString(),
      });
      return res.status(201).json(safeUser(user));
    } catch (error) {
      return next(error);
    }
  });

  router.get('/:id', async (req, res, next) => {
    try {
      const id = req.params.id;
      if (!id || id.length > 128) {
        return res.status(422).json({ message: 'Invalid user ID.' });
      }
      const found = await repository.findById(id);
      if (!found) return res.status(404).json({ message: 'User not found.' });
      const user = found.credential;
      if (req.auth.role !== 'admin' &&
          String(user.userId || user.userID || '') !== req.auth.userId) {
        return res.status(403).json({ message: 'You may only access your own account.' });
      }
      return res.json(safeUser(user));
    } catch (error) {
      return next(error);
    }
  });

  router.put('/:id', async (req, res, next) => {
    try {
      const id = req.params.id;
      const body = req.body || {};
      if (!id || id.length > 128) {
        return res.status(422).json({ message: 'Invalid user ID.' });
      }
      if (Object.keys(body).some((key) =>
        !['email', 'password', 'currentPassword'].includes(key))) {
        return res.status(403).json({ message: 'Protected or unexpected user fields cannot be changed.' });
      }

      const found = await repository.findById(id);
      if (!found) return res.status(404).json({ message: 'User not found.' });
      if (found.legacy) {
        return res.status(409).json({ message: 'Legacy user credentials are read-only.' });
      }

      const existing = found.credential;
      const isAdmin = req.auth.role === 'admin';
      const isSelf = String(existing.userId || existing.userID || '') === req.auth.userId;
      if (!isAdmin && !isSelf) {
        return res.status(403).json({ message: 'You may only update your own account.' });
      }

      const updates = {};
      if (Object.prototype.hasOwnProperty.call(body, 'email')) {
        if (!validEmail(body.email)) {
          return res.status(422).json({ message: 'A valid email address is required.' });
        }
        const email = body.email.trim().toLowerCase();
        const oldEmail = String(existing.email || existing.emailAddress || '').toLowerCase();
        if (email !== oldEmail) updates.email = email;
      }

      if (Object.prototype.hasOwnProperty.call(body, 'password')) {
        if (!validPassword(body.password)) {
          return res.status(422).json({ message: 'Password must be between 8 and 128 characters.' });
        }
        if (!isAdmin) {
          if (typeof body.currentPassword !== 'string' || !body.currentPassword ||
              !existing.password || !await bcrypt.compare(body.currentPassword, existing.password)) {
            return res.status(403).json({ message: 'Current password is required to change your password.' });
          }
        }
        updates.password = await bcrypt.hash(body.password, 10);
      } else if (Object.prototype.hasOwnProperty.call(body, 'currentPassword')) {
        return res.status(422).json({ message: 'Current password is only accepted with a password change.' });
      }

      if (Object.keys(updates).length === 0) {
        return res.status(422).json({ message: 'No updatable fields provided.' });
      }
      if (updates.email) {
        const conflict = await repository.findConflict({ email: updates.email });
        if (conflict && String(conflict._id) !== String(existing._id)) {
          return res.status(409).json({ message: 'Email already in use.' });
        }
      }

      const updated = await repository.update(found, updates);
      return res.json(safeUser(updated));
    } catch (error) {
      return next(error);
    }
  });

  router.delete('/:id', requireAdmin, async (req, res, next) => {
    try {
      const id = req.params.id;
      if (!id || id.length > 128) {
        return res.status(422).json({ message: 'Invalid user ID.' });
      }
      const found = await repository.findById(id);
      if (!found) return res.status(404).json({ success: false, message: 'User not found.' });
      if (found.legacy) {
        return res.status(409).json({ success: false, message: 'Legacy user credentials are read-only.' });
      }
      if (String(found.credential.userId || found.credential.userID || '') === req.auth.userId) {
        return res.status(409).json({ success: false, message: 'Administrators cannot delete their own account.' });
      }
      await repository.remove(found);
      return res.json({
        success: true,
        message: 'User login credential deleted. Related school records were not deleted.',
      });
    } catch (error) {
      return next(error);
    }
  });

  return router;
}

module.exports = {
  createAuthenticate,
  createUserManagementRouter,
  requireAdmin,
  signAuthPayload,
  verifyAuthToken,
};
