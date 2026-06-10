const express = require('express');
const multer = require('multer');
const { S3Client, PutObjectCommand } = require('@aws-sdk/client-s3');

const app = express();
const PORT = process.env.PORT || 3000;
const BUCKET = process.env.S3_BUCKET_NAME || 'terrawiz-uploads';
const REGION = process.env.AWS_REGION || 'us-east-1';

const s3 = new S3Client({ region: REGION });

const upload = multer({
  storage: multer.memoryStorage(),
  fileFilter: (req, file, cb) => {
    if (!['image/jpeg', 'image/png'].includes(file.mimetype)) {
      return cb(new Error('only jpg and png allowed'));
    }
    cb(null, true);
  },
  limits: { fileSize: 5 * 1024 * 1024 }, // 5 MB max
});

app.get('/', (req, res) => {
  const environment = process.env.NODE_ENV || 'development';
  const uptime = Math.floor(process.uptime());
  const uptimeStr = uptime < 60
    ? `${uptime}s`
    : uptime < 3600
      ? `${Math.floor(uptime / 60)}m ${uptime % 60}s`
      : `${Math.floor(uptime / 3600)}h ${Math.floor((uptime % 3600) / 60)}m`;

  res.setHeader('Content-Type', 'text/html');
  res.send(`<!DOCTYPE html>
<html lang="en">
<head>
  <meta charset="UTF-8">
  <meta name="viewport" content="width=device-width, initial-scale=1.0">
  <title>TerraWiz Dashboard</title>
  <style>
    *, *::before, *::after { box-sizing: border-box; margin: 0; padding: 0; }
    body {
      font-family: -apple-system, BlinkMacSystemFont, 'Segoe UI', Roboto, sans-serif;
      background: #0f1117;
      color: #e2e8f0;
      min-height: 100vh;
      padding: 2rem;
    }
    header {
      display: flex;
      align-items: center;
      gap: 1rem;
      margin-bottom: 2rem;
    }
    .logo {
      width: 48px; height: 48px;
      background: linear-gradient(135deg, #6366f1, #8b5cf6);
      border-radius: 12px;
      display: flex; align-items: center; justify-content: center;
      font-size: 1.5rem;
    }
    h1 { font-size: 1.75rem; font-weight: 700; letter-spacing: -0.5px; }
    h1 span { color: #818cf8; }
    .badge {
      font-size: 0.7rem; font-weight: 600; text-transform: uppercase;
      padding: 2px 8px; border-radius: 99px;
      background: #1e293b; color: #94a3b8; border: 1px solid #334155;
    }
    .badge.ok { background: #052e16; color: #4ade80; border-color: #166534; }
    .grid {
      display: grid;
      grid-template-columns: repeat(auto-fill, minmax(280px, 1fr));
      gap: 1rem;
      margin-bottom: 2rem;
    }
    .card {
      background: #1e293b;
      border: 1px solid #334155;
      border-radius: 12px;
      padding: 1.25rem;
    }
    .card-label {
      font-size: 0.72rem; font-weight: 600; text-transform: uppercase;
      color: #64748b; letter-spacing: 0.8px; margin-bottom: 0.5rem;
    }
    .card-value {
      font-size: 1.5rem; font-weight: 700; color: #f1f5f9;
      font-variant-numeric: tabular-nums;
    }
    .card-value.mono { font-family: 'Menlo', 'Consolas', monospace; font-size: 0.9rem; }
    .card-sub { font-size: 0.8rem; color: #64748b; margin-top: 0.25rem; }
    .section-title {
      font-size: 0.8rem; font-weight: 600; text-transform: uppercase;
      color: #64748b; letter-spacing: 0.8px; margin-bottom: 0.75rem;
    }
    table { width: 100%; border-collapse: collapse; }
    th, td {
      text-align: left; padding: 0.6rem 0.75rem;
      border-bottom: 1px solid #1e293b; font-size: 0.875rem;
    }
    th { color: #64748b; font-weight: 500; font-size: 0.75rem; text-transform: uppercase; }
    td:first-child { color: #818cf8; font-family: monospace; }
    tr:last-child td { border-bottom: none; }
    .method {
      display: inline-block; font-size: 0.65rem; font-weight: 700;
      padding: 1px 6px; border-radius: 4px; font-family: monospace;
      background: #0f3460; color: #60a5fa;
    }
    .method.post { background: #1a2e1a; color: #4ade80; }
    .upload-section {
      background: #1e293b; border: 1px solid #334155; border-radius: 12px;
      padding: 1.5rem; margin-top: 1rem;
    }
    .upload-area {
      border: 2px dashed #334155; border-radius: 8px;
      padding: 2rem; text-align: center; margin-bottom: 1rem;
      transition: border-color 0.2s;
    }
    .upload-area:hover { border-color: #818cf8; }
    .upload-area p { color: #64748b; font-size: 0.875rem; margin-top: 0.5rem; }
    input[type="file"] { display: none; }
    label.btn, button.btn {
      display: inline-block; padding: 0.5rem 1.25rem;
      background: linear-gradient(135deg, #6366f1, #8b5cf6);
      color: #fff; border: none; border-radius: 8px;
      font-size: 0.875rem; font-weight: 600; cursor: pointer;
      transition: opacity 0.2s;
    }
    label.btn:hover, button.btn:hover { opacity: 0.85; }
    #upload-result {
      margin-top: 0.75rem; padding: 0.75rem;
      border-radius: 8px; font-size: 0.85rem; font-family: monospace;
      display: none;
    }
    #upload-result.success { background: #052e16; color: #4ade80; border: 1px solid #166534; }
    #upload-result.error   { background: #2d0a0a; color: #f87171; border: 1px solid #7f1d1d; }
    footer {
      margin-top: 2rem; text-align: center;
      color: #334155; font-size: 0.75rem;
    }
  </style>
</head>
<body>
  <header>
    <div class="logo">&#9889;</div>
    <div>
      <h1>Terra<span>Wiz</span></h1>
      <div style="margin-top:4px; display:flex; gap:6px; align-items:center;">
        <span class="badge ok">&#x25cf; running</span>
        <span class="badge">${environment}</span>
        <span class="badge">${REGION}</span>
      </div>
    </div>
  </header>

  <div class="grid">
    <div class="card">
      <div class="card-label">Uptime</div>
      <div class="card-value">${uptimeStr}</div>
      <div class="card-sub">since last container start</div>
    </div>
    <div class="card">
      <div class="card-label">S3 Bucket</div>
      <div class="card-value mono">${BUCKET}</div>
      <div class="card-sub">file uploads target</div>
    </div>
    <div class="card">
      <div class="card-label">Region</div>
      <div class="card-value mono">${REGION}</div>
      <div class="card-sub">AWS deployment region</div>
    </div>
    <div class="card">
      <div class="card-label">Runtime</div>
      <div class="card-value mono">Node ${process.version}</div>
      <div class="card-sub">on ECS Fargate</div>
    </div>
  </div>

  <div class="card">
    <div class="section-title">API Endpoints</div>
    <table>
      <thead>
        <tr><th>Method</th><th>Path</th><th>Description</th></tr>
      </thead>
      <tbody>
        <tr>
          <td><span class="method">GET</span></td>
          <td>/</td>
          <td style="color:#94a3b8">This dashboard</td>
        </tr>
        <tr>
          <td><span class="method">GET</span></td>
          <td>/health</td>
          <td style="color:#94a3b8">Health check — returns <code style="color:#818cf8">{"status":"ok"}</code></td>
        </tr>
        <tr>
          <td><span class="method">GET</span></td>
          <td>/api/status</td>
          <td style="color:#94a3b8">JSON status payload (infrastructure metadata)</td>
        </tr>
        <tr>
          <td><span class="method post">POST</span></td>
          <td>/upload</td>
          <td style="color:#94a3b8">Upload a JPG or PNG (multipart/form-data, field: <code style="color:#818cf8">file</code>, max 5 MB)</td>
        </tr>
      </tbody>
    </table>
  </div>

  <div class="upload-section">
    <div class="section-title">Upload a file</div>
    <div class="upload-area" id="drop-zone">
      <div style="font-size:2rem;">&#128228;</div>
      <p>JPG or PNG &mdash; max 5 MB</p>
      <br>
      <label class="btn" for="file-input">Choose file</label>
      <input type="file" id="file-input" accept="image/jpeg,image/png">
    </div>
    <div id="selected-name" style="color:#94a3b8; font-size:0.85rem; margin-bottom:0.75rem; display:none;"></div>
    <button class="btn" id="upload-btn" disabled>Upload to S3</button>
    <div id="upload-result"></div>
  </div>

  <footer>TerraWiz &mdash; deployed on AWS ECS Fargate via Terraform &mdash; ${new Date().toUTCString()}</footer>

  <script>
    const fileInput = document.getElementById('file-input');
    const uploadBtn = document.getElementById('upload-btn');
    const selectedName = document.getElementById('selected-name');
    const result = document.getElementById('upload-result');

    fileInput.addEventListener('change', () => {
      if (fileInput.files.length) {
        selectedName.textContent = 'Selected: ' + fileInput.files[0].name;
        selectedName.style.display = 'block';
        uploadBtn.disabled = false;
      }
    });

    uploadBtn.addEventListener('click', async () => {
      if (!fileInput.files.length) return;
      uploadBtn.disabled = true;
      uploadBtn.textContent = 'Uploading…';
      result.style.display = 'none';

      const fd = new FormData();
      fd.append('file', fileInput.files[0]);

      try {
        const resp = await fetch('/upload', { method: 'POST', body: fd });
        const data = await resp.json();
        result.className = resp.ok ? 'success' : 'error';
        result.textContent = JSON.stringify(data, null, 2);
        result.style.display = 'block';
      } catch (e) {
        result.className = 'error';
        result.textContent = 'Network error: ' + e.message;
        result.style.display = 'block';
      } finally {
        uploadBtn.disabled = false;
        uploadBtn.textContent = 'Upload to S3';
      }
    });
  </script>
</body>
</html>`);
});

app.get('/health', (req, res) => {
  res.status(200).json({ status: 'ok' });
});

app.get('/api/status', (req, res) => {
  res.json({
    project: 'TerraWiz',
    environment: process.env.NODE_ENV || 'development',
    region: REGION,
    bucket: BUCKET,
    uptime: Math.floor(process.uptime()),
    nodeVersion: process.version,
    timestamp: new Date().toISOString(),
  });
});

app.post('/upload', upload.single('file'), async (req, res) => {
  if (!req.file) {
    return res.status(400).json({ error: 'no file provided' });
  }

  const key = `uploads/${Date.now()}-${req.file.originalname}`;

  try {
    await s3.send(new PutObjectCommand({
      Bucket: BUCKET,
      Key: key,
      Body: req.file.buffer,
      ContentType: req.file.mimetype,
    }));
    res.json({ message: 'upload successful', key });
  } catch (err) {
    res.status(500).json({ error: 'S3 upload failed', detail: err.message });
  }
});

// Handle file type rejection from multer
app.use((err, req, res, next) => {
  if (err.message === 'only jpg and png allowed') {
    return res.status(400).json({ error: err.message });
  }
  next(err);
});

app.listen(PORT, () => {
  console.log(`TerraWiz server running on port ${PORT}`);
});
