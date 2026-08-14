const express = require('express');
const dotenv = require('dotenv');
const fs = require('fs');
const path = require('path');
const multer = require('multer');
const { Readable } = require('stream');
const { MongoClient, ObjectId, GridFSBucket } = require('mongodb');

dotenv.config({ path: path.join(__dirname, 'env.development') });

const app = express();
app.set('trust proxy', true);
const port = Number(process.env.PORT) || 3001;
const mongoUri = process.env.MONGODB_URI;
const uploadDirectory = path.join(__dirname, 'uploads');

fs.mkdirSync(uploadDirectory, { recursive: true });

app.use(express.json({ limit: '10mb' }));
app.use((req, res, next) => {
  const origin = req.headers.origin || '*';
  res.setHeader('Access-Control-Allow-Origin', origin === '*' ? '*' : origin);
  res.setHeader('Access-Control-Allow-Methods', 'GET,POST,PUT,OPTIONS');
  res.setHeader('Access-Control-Allow-Headers', 'Content-Type, Authorization, X-Requested-With');
  res.setHeader('Access-Control-Allow-Credentials', 'true');

  if (req.method === 'OPTIONS') {
    return res.sendStatus(204);
  }

  return next();
});
app.use('/uploads', express.static(uploadDirectory));

const upload = multer({
  storage: multer.memoryStorage(),
  limits: { fileSize: 10 * 1024 * 1024 },
});

let client;
let mainPageInfoCollection;
let imageBucket;

async function connectMongo() {
  if (!mongoUri) {
    throw new Error('MongoDB URI is not configured');
  }

  if (!client) {
    client = new MongoClient(mongoUri);
    await client.connect();
    const db = client.db('mainpage');
    mainPageInfoCollection = db.collection('mainPageInfo');
    imageBucket = new GridFSBucket(db, { bucketName: 'images' });
  }

  return mainPageInfoCollection;
}

function safeUploadFilename(originalName) {
  const safeName = originalName.replace(/\s+/g, '_');
  return `${Date.now()}-${safeName}`;
}

async function saveFileToGridFS(file) {
  if (!imageBucket) {
    throw new Error('GridFS bucket is not initialized');
  }

  const filename = safeUploadFilename(file.originalname);
  const uploadStream = imageBucket.openUploadStream(filename, {
    metadata: { contentType: file.mimetype || 'application/octet-stream' },
  });

  const readable = Readable.from(file.buffer);
  return new Promise((resolve, reject) => {
    readable.pipe(uploadStream)
      .on('error', reject)
      .on('finish', () => resolve({ id: uploadStream.id, filename }));
  });
}

function buildDefaultDocument() {
  return {
    splashScreen: {
      title: '',
      subtitle: '',
      image: '',
      sinceYear: '',
      enabled: true,
    },
    schoolSettings: {
      schoolName: '',
      schoolQuote: '',
      welcomeText: '',
      schoolWebsite: '',
      runningContent: [],
      schoolLogo: '',
      schoolPoster: '',
      selectedLanguage: '',
      themeColor: '',
    },
    // Home-specific content (editable from Content Edit). Kept separate from
    // schoolContent so the Home page can show its own items without affecting
    // the School page staff content.
    homeContent: [],
    schoolContent: {
      founder: {
        photo: '',
        name: '',
        designation: '',
        visionTitle: '',
        visionDescription: '',
      },
      secretary: {
        photo: '',
        name: '',
        designation: '',
        welcomeTitle: '',
        welcomeMessage: '',
      },
      headmaster: {
        photo: '',
        name: '',
        designation: '',
        messageTitle: '',
        message: '',
      },
      members: [],
    },
    gradePage: {
      grade10: { students: [] },
      grade12: { students: [] },
      sportsAchievements: [],
    },
    updatedAt: new Date().toISOString(),
  };
}

async function getMainPageDocument() {
  const collection = await connectMongo();
  return collection.findOne({});
}

async function upsertMainPageDocument(payload) {
  const collection = await connectMongo();
  const now = new Date().toISOString();
  const normalized = {
    ...buildDefaultDocument(),
    ...payload,
    updatedAt: now,
  };

  const result = await collection.findOneAndUpdate(
    {},
    { $set: normalized },
    { upsert: true, returnDocument: 'after' }
  );

  return result.value || normalized;
}

app.get('/health', (req, res) => {
  res.json({ status: 'ok' });
});

app.post('/api/upload/school-poster', upload.single('file'), async (req, res) => {
  if (!req.file) {
    return res.status(400).json({ message: 'No poster file was uploaded.' });
  }

  try {
    const saved = await saveFileToGridFS(req.file);
    const url = `${req.protocol}://${req.get('host')}/api/images/${saved.id}`;
    return res.status(200).json({
      url,
      filename: saved.filename,
      originalName: req.file.originalname,
    });
  } catch (error) {
    console.error('POST /api/upload/school-poster failed:', error);
    return res.status(500).json({ message: 'Unable to save the poster image.' });
  }
});

app.get('/api/mainpage-info', async (req, res) => {
  try {
    const doc = await getMainPageDocument();
    if (!doc) {
      const created = buildDefaultDocument();
      const collection = await connectMongo();
      const result = await collection.findOneAndUpdate(
        {},
        { $set: created },
        { upsert: true, returnDocument: 'after' }
      );
      return res.json(result.value || created);
    }

    const hasTopLevelHomeContent = Array.isArray(doc.homeContent) && doc.homeContent.length > 0;
    const legacyHomeContent = doc.schoolContent && Array.isArray(doc.schoolContent.homeContent) ? doc.schoolContent.homeContent : [];
    let selectedHomeContent = doc.homeContent;
    if (!hasTopLevelHomeContent && legacyHomeContent.length > 0) {
      selectedHomeContent = legacyHomeContent;
      console.log('GET /api/mainpage-info: promoting legacy schoolContent.homeContent to homeContent', {
        topLevelCount: (doc.homeContent || []).length,
        legacyCount: legacyHomeContent.length,
      });
    } else if (Array.isArray(doc.homeContent) && legacyHomeContent.length > doc.homeContent.length) {
      selectedHomeContent = legacyHomeContent;
      console.log('GET /api/mainpage-info: using longer legacy schoolContent.homeContent over top-level homeContent', {
        topLevelCount: doc.homeContent.length,
        legacyCount: legacyHomeContent.length,
      });
    }
    doc.homeContent = selectedHomeContent;

    console.log('GET /api/mainpage-info: returning document with homeContent count', (doc.homeContent || []).length);
    return res.json(doc);
  } catch (error) {
    console.error('GET /api/mainpage-info failed:', error);
    return res.status(500).json({ message: 'Unable to load the school configuration.' });
  }
});

app.put('/api/mainpage-info', async (req, res) => {
  try {
    const updated = await upsertMainPageDocument(req.body || {});
    return res.json(updated);
  } catch (error) {
    console.error('PUT /api/mainpage-info failed:', error);
    return res.status(500).json({ message: 'Unable to save changes. Please try again.' });
  }
});

app.put('/api/mainpage-info/splash', async (req, res) => {
  try {
    const current = (await getMainPageDocument()) || buildDefaultDocument();
    const updated = await upsertMainPageDocument({
      ...current,
      splashScreen: req.body || current.splashScreen,
    });
    return res.json(updated);
  } catch (error) {
    console.error('PUT /api/mainpage-info/splash failed:', error);
    return res.status(500).json({ message: 'Unable to save changes. Please try again.' });
  }
});

app.put('/api/mainpage-info/settings', async (req, res) => {
  try {
    const current = (await getMainPageDocument()) || buildDefaultDocument();
    const updated = await upsertMainPageDocument({
      ...current,
      schoolSettings: req.body || current.schoolSettings,
    });
    return res.json(updated);
  } catch (error) {
    console.error('PUT /api/mainpage-info/settings failed:', error);
    return res.status(500).json({ message: 'Unable to save changes. Please try again.' });
  }
});

app.put('/api/mainpage-info/content', async (req, res) => {
  try {
    const current = (await getMainPageDocument()) || buildDefaultDocument();
    const body = req.body || {};

    // If payload explicitly provides homeContent, treat it as an update to the
    // separate homeContent array (used by the app Home page). Otherwise treat
    // the payload as the schoolContent object to preserve existing behavior.
    let updatedDoc;
    if (Object.prototype.hasOwnProperty.call(body, 'homeContent')) {
      const homeContent = Array.isArray(body.homeContent) ? body.homeContent : [];
      console.log('PUT /api/mainpage-info/content: saving top-level homeContent count', homeContent.length);
      updatedDoc = await upsertMainPageDocument({
        ...current,
        homeContent,
        schoolContent: {
          ...current.schoolContent,
          homeContent,
        },
      });
    } else {
      const nextSchoolContent = body || current.schoolContent;
      const legacyHomeContent = nextSchoolContent && Array.isArray(nextSchoolContent.homeContent)
        ? nextSchoolContent.homeContent
        : current.homeContent;
      console.log('PUT /api/mainpage-info/content: saving schoolContent with homeContent count', legacyHomeContent.length);

      updatedDoc = await upsertMainPageDocument({
        ...current,
        schoolContent: nextSchoolContent,
        homeContent: legacyHomeContent,
      });
    }

    console.log('PUT /api/mainpage-info/content: stored document with homeContent count', (updatedDoc.homeContent || []).length);
    return res.json(updatedDoc);
  } catch (error) {
    console.error('PUT /api/mainpage-info/content failed:', error);
    return res.status(500).json({ message: 'Unable to save changes. Please try again.' });
  }
});

app.put('/api/mainpage-info/grades', async (req, res) => {
  try {
    const current = (await getMainPageDocument()) || buildDefaultDocument();
    const updated = await upsertMainPageDocument({
      ...current,
      gradePage: req.body || current.gradePage,
    });
    return res.json(updated);
  } catch (error) {
    console.error('PUT /api/mainpage-info/grades failed:', error);
    return res.status(500).json({ message: 'Unable to save changes. Please try again.' });
  }
});

app.get('/api/images/:id', async (req, res) => {
  if (!imageBucket) {
    return res.status(503).json({ message: 'Image storage is not initialized.' });
  }

  const idParam = req.params.id;

  // Try to treat the param as an ObjectId first. If that fails, fall back to
  // searching by filename. This makes the endpoint tolerant to both direct
  // ObjectId URLs and older filename-based references.
  try {
    let downloadStream;
    let fileFound = false;

    try {
      const fileId = new ObjectId(idParam);
      downloadStream = imageBucket.openDownloadStream(fileId);
    } catch (err) {
      // Not a valid ObjectId; attempt to find by filename
      const files = await imageBucket.find({ filename: idParam }).toArray();
      if (!files || files.length === 0) {
        return res.status(404).json({ message: 'Image not found.' });
      }
      const fileDoc = files[0];
      const contentType = fileDoc.metadata?.contentType || fileDoc.contentType || 'application/octet-stream';
      res.setHeader('Content-Type', contentType);
      res.setHeader('Content-Length', fileDoc.length);
      const streamByName = imageBucket.openDownloadStream(fileDoc._id);
      return streamByName.pipe(res);
    }

    downloadStream.on('file', (file) => {
      fileFound = true;
      const contentType = file.metadata?.contentType || 'application/octet-stream';
      res.setHeader('Content-Type', contentType);
      res.setHeader('Content-Length', file.length);
    });

    downloadStream.on('error', (error) => {
      console.error('GET /api/images/:id failed:', error);
      if (error.code === 'ENOENT' || error.message?.includes('FileNotFound')) {
        return res.status(404).json({ message: 'Image not found.' });
      }
      return res.status(500).json({ message: 'Unable to load the image.' });
    });

    downloadStream.on('end', () => {
      if (!fileFound) {
        res.status(404).json({ message: 'Image not found.' });
      }
    });

    return downloadStream.pipe(res);
  } catch (e) {
    console.error('GET /api/images/:id unexpected error:', e);
    return res.status(500).json({ message: 'Unable to load the image.' });
  }
});

app.get('/uploads/:filename', async (req, res) => {
  if (!imageBucket) {
    return res.status(503).json({ message: 'Image storage is not initialized.' });
  }

  try {
    const files = await imageBucket.find({ filename: req.params.filename }).toArray();
    if (!files || files.length === 0) {
      return res.status(404).json({ message: 'Image not found.' });
    }

    const fileDoc = files[0];
    const downloadStream = imageBucket.openDownloadStream(fileDoc._id);
    const contentType = fileDoc.metadata?.contentType || fileDoc.contentType || 'application/octet-stream';
    res.setHeader('Content-Type', contentType);
    res.setHeader('Content-Length', fileDoc.length);
    downloadStream.pipe(res);
  } catch (error) {
    console.error('GET /uploads/:filename fallback failed:', error);
    return res.status(500).json({ message: 'Unable to load the image.' });
  }
});

app.get('/', (req, res) => {
  res.json({
    message: 'Backend is running',
    mongodbUri: process.env.MONGODB_URI ? 'configured' : 'not configured'
  });
});

async function startServer() {
  try {
    await connectMongo();
    console.log('Connected to MongoDB');
  } catch (error) {
    console.warn('MongoDB connection unavailable:', error.message);
  }

  app.listen(port, () => {
    console.log(`Backend running on http://localhost:${port}`);
  });
}

startServer();
