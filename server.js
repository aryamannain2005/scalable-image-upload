const express = require('express');
const multer = require('multer');
const aws = require('aws-sdk');
const { v4: uuidv4 } = require('uuid');
const path = require('path');
const os = require('os');

const app = express();
const PORT = process.env.PORT || 3001;

// Configure AWS S3
const s3 = new aws.S3({
  accessKeyId: process.env.AWS_ACCESS_KEY_ID,
  secretAccessKey: process.env.AWS_SECRET_ACCESS_KEY,
  region: process.env.AWS_REGION || 'us-east-1'
});

const S3_BUCKET = process.env.AWS_S3_BUCKET || 'your-bucket-name';

// Configure multer for file uploads
const storage = multer.memoryStorage();
const upload = multer({
  storage: storage,
  limits: {
    fileSize: 2 * 1024 * 1024 // 2MB
  },
  fileFilter: (req, file, cb) => {
    // Only allow image files
    const allowedMimes = ['image/jpeg', 'image/png', 'image/jpg'];
    if (allowedMimes.includes(file.mimetype)) {
      cb(null, true);
    } else {
      cb(new Error('Only JPG and PNG images are allowed'));
    }
  }
});

// Middleware
app.use(express.json());
app.use(express.urlencoded({ extended: true }));

// Health check endpoint
app.get('/health', (req, res) => {
  res.status(200).json({
    status: 'ok',
    server: `${os.hostname()}:${PORT}`,
    timestamp: new Date().toISOString()
  });
});

// Upload endpoint
app.post('/upload', upload.single('image'), async (req, res) => {
  try {
    // Validate file exists
    if (!req.file) {
      return res.status(400).json({
        error: 'No image file provided'
      });
    }

    // Generate unique filename
    const timestamp = Date.now();
    const uniqueId = uuidv4();
    const ext = path.extname(req.file.originalname);
    const filename = `${timestamp}-${uniqueId}${ext}`;

    // Upload to S3
    const params = {
      Bucket: S3_BUCKET,
      Key: filename,
      Body: req.file.buffer,
      ContentType: req.file.mimetype,
      ACL: 'public-read'
    };

    const result = await s3.upload(params).promise();

    // Log request distribution
    console.log(`[${new Date().toISOString()}] Upload successful - Server: ${os.hostname()}:${PORT}, File: ${filename}`);

    res.status(200).json({
      url: result.Location,
      bucket: S3_BUCKET,
      key: filename,
      server: `${os.hostname()}:${PORT}`
    });
  } catch (error) {
    console.error(`[${new Date().toISOString()}] Upload error on ${os.hostname()}:${PORT}:`, error.message);
    
    if (error.message.includes('Only JPG and PNG')) {
      return res.status(400).json({
        error: 'Only JPG and PNG images are allowed'
      });
    }
    
    if (error.message.includes('File too large')) {
      return res.status(413).json({
        error: 'File size exceeds 2MB limit'
      });
    }

    res.status(500).json({
      error: 'Failed to upload image',
      message: error.message
    });
  }
});

// Error handling middleware
app.use((err, req, res, next) => {
  console.error(`[${new Date().toISOString()}] Error on ${os.hostname()}:${PORT}:`, err);
  
  if (err instanceof multer.MulterError) {
    if (err.code === 'FILE_TOO_LARGE') {
      return res.status(413).json({
        error: 'File size exceeds 2MB limit'
      });
    }
  }

  res.status(500).json({
    error: 'Internal server error',
    message: err.message
  });
});

app.listen(PORT, () => {
  console.log(`\n========================================`);
  console.log(`Server started on ${os.hostname()}:${PORT}`);
  console.log(`Health check: http://localhost:${PORT}/health`);
  console.log(`Upload endpoint: POST http://localhost:${PORT}/upload`);
  console.log(`========================================\n`);
});
