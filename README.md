# Scalable Image Upload Server

A production-ready image upload server with NGINX load balancing, AWS S3 integration, and GitHub Actions CI/CD pipeline. No database required.

## Features

- **Multiple Backend Instances**: Run 2+ instances on different ports
- **NGINX Load Balancing**: Round-robin load balancing on port 80
- **AWS S3 Integration**: Secure image storage with unique filenames
- **Image Validation**: Only JPG/PNG files, max 2MB
- **GitHub Actions CI**: Automated testing on push/PR
- **Error Handling**: Comprehensive error messages and logging
- **Health Check**: Monitor server status

## System Architecture

```
┌─────────────┐
│   Client    │
└──────┬──────┘
       │
       ▼
┌─────────────────────────────────┐
│    NGINX Load Balancer          │
│    (Port 80 - Round Robin)      │
└────────┬────────────────────────┘
         │
    ┌────┴────┐
    ▼         ▼
┌────────┐ ┌────────┐
│Backend │ │Backend │
│:3001   │ │:3002   │
└────┬───┘ └───┬────┘
     │         │
     └────┬────┘
          ▼
      ┌────────┐
      │ AWS S3 │
      └────────┘
```

## Prerequisites

- Node.js 16.x or 18.x
- NGINX
- AWS Account with S3 bucket
- Git & GitHub

## Setup Steps

### 1. Clone Repository
```bash
git clone <your-repo-url>
cd scalable-image-upload
```

### 2. Install Dependencies
```bash
npm install
```

### 3. Configure AWS Credentials
Create a `.env` file from `.env.example`:
```bash
cp .env.example .env
```

Edit `.env` with your AWS credentials:
```env
AWS_ACCESS_KEY_ID=your-access-key
AWS_SECRET_ACCESS_KEY=your-secret-key
AWS_S3_BUCKET=your-bucket-name
AWS_REGION=us-east-1
```

### 4. Create S3 Bucket (if needed)
```bash
# Via AWS CLI
aws s3 mb s3://your-bucket-name --region us-east-1
```

## Running the Application

### Option 1: Run Both Instances Concurrently
```bash
npm run start:both
```

This will start:
- Server 1 on `http://localhost:3001`
- Server 2 on `http://localhost:3002`

### Option 2: Run Individual Instances
```bash
# Terminal 1
npm run start:instance1

# Terminal 2
npm run start:instance2
```

### Option 3: Single Instance
```bash
npm start
```

## NGINX Configuration

### Start NGINX with Custom Config
```bash
# Copy nginx.conf to NGINX config directory
sudo cp nginx.conf /etc/nginx/sites-available/scalable-upload

# Create symbolic link
sudo ln -s /etc/nginx/sites-available/scalable-upload /etc/nginx/sites-enabled/

# Test configuration
sudo nginx -t

# Reload NGINX
sudo systemctl reload nginx
```

### NGINX Config Location
- **macOS**: `/usr/local/etc/nginx/nginx.conf`
- **Linux**: `/etc/nginx/nginx.conf`

### Minimal NGINX Setup for macOS
If you want to test locally without system NGINX:
```bash
# Start NGINX in foreground for testing
sudo nginx -c $(pwd)/nginx.conf -g "daemon off;"
```

## API Endpoints

### Health Check
```bash
curl http://localhost:80/health
```

**Response:**
```json
{
  "status": "ok",
  "server": "MacBook-Pro:3001",
  "timestamp": "2024-04-29T10:30:45.123Z"
}
```

### Upload Image
```bash
curl -X POST \
  -F "image=@/path/to/image.jpg" \
  http://localhost:80/upload
```

**Request:**
- Method: `POST`
- Endpoint: `/upload`
- Content-Type: `multipart/form-data`
- Field: `image` (file)

**Success Response (200):**
```json
{
  "url": "https://your-bucket-name.s3.amazonaws.com/1619682645123-a1b2c3d4-e5f6-7890-abcd-ef1234567890.jpg",
  "bucket": "your-bucket-name",
  "key": "1619682645123-a1b2c3d4-e5f6-7890-abcd-ef1234567890.jpg",
  "server": "MacBook-Pro:3001"
}
```

**Error Responses:**
- **400**: No file provided / Invalid file type
```json
{
  "error": "Only JPG and PNG images are allowed"
}
```

- **413**: File too large
```json
{
  "error": "File size exceeds 2MB limit"
}
```

- **500**: Server error
```json
{
  "error": "Failed to upload image",
  "message": "Bucket not found"
}
```

## Testing Load Balancing

### Using cURL
```bash
# Upload multiple images to see distribution
for i in {1..10}; do
  echo "Request $i:"
  curl -X POST -F "image=@test-image.jpg" http://localhost:80/upload
  echo "\n"
done
```

### Using Postman
1. Create a new POST request
2. URL: `http://localhost:80/upload`
3. Body → form-data
4. Key: `image` | Type: `File` | Select image
5. Send
6. Check logs to see which server handled the request

### Verify Distribution
Check server logs:
```bash
# Terminal running server 1
[2024-04-29T10:30:45.123Z] Upload successful - Server: MacBook-Pro:3001, File: ...

# Terminal running server 2
[2024-04-29T10:30:46.456Z] Upload successful - Server: MacBook-Pro:3002, File: ...
```

## GitHub Actions CI Pipeline

### Workflow File
Location: `.github/workflows/ci.yml`

### Triggers
- On push to `main` or `develop` branches
- On pull requests to `main` or `develop` branches

### Steps
1. **Checkout code**
2. **Setup Node.js** (tests on 16.x and 18.x)
3. **Install dependencies**
4. **Lint check** (eslint)
5. **Run tests** (jest)
6. **Build check**

### GitHub Secrets (Required)
Add these in GitHub repo Settings → Secrets and variables → Actions:
- `AWS_ACCESS_KEY_ID`
- `AWS_SECRET_ACCESS_KEY`
- `AWS_S3_BUCKET`

### View Workflow Runs
1. Go to GitHub repo
2. Click "Actions" tab
3. Select workflow run
4. View logs for each step

## Project Structure

```
scalable-image-upload/
├── server.js                    # Main application server
├── package.json                 # Dependencies & scripts
├── nginx.conf                   # NGINX configuration
├── .env.example                 # Environment variables template
├── .gitignore                   # Git ignore file
├── .github/
│   └── workflows/
│       └── ci.yml              # GitHub Actions workflow
└── README.md                    # This file
```

## Code Quality & Error Handling

### Image Validation
- ✓ File type check (JPEG/PNG only)
- ✓ File size validation (max 2MB)
- ✓ Required field validation

### Error Handling
- ✓ Multer error handling
- ✓ AWS S3 error handling
- ✓ Global error middleware
- ✓ Comprehensive logging with timestamps

### Logging
Every request logs:
- Timestamp
- Server hostname and port
- Action (upload success/error)
- Filename or error message

```
[2024-04-29T10:30:45.123Z] Upload successful - Server: MacBook-Pro:3001, File: 1619682645123-a1b2c3d4.jpg
[2024-04-29T10:30:46.456Z] Upload error on MacBook-Pro:3002: File too large
```

## Troubleshooting

### Issue: NGINX connection refused
```bash
# Check if NGINX is running
nginx -v

# Start NGINX
sudo systemctl start nginx
```

### Issue: AWS credentials not working
```bash
# Verify credentials in .env file
cat .env

# Check AWS permissions for S3:PutObject
```

### Issue: Port already in use
```bash
# Kill process on port
lsof -ti:3001 | xargs kill -9
lsof -ti:3002 | xargs kill -9
lsof -ti:80 | xargs kill -9
```

### Issue: Requests not distributing evenly
- Check NGINX logs: `/var/log/nginx/scalable-upload-access.log`
- Ensure both backend servers are running
- Restart NGINX: `sudo systemctl reload nginx`

## Performance Metrics

Expected behavior:
- **Throughput**: ~100-200 requests/second (per instance)
- **Latency**: 100-500ms (varies with S3 network)
- **Load Distribution**: Should alternate between servers

## Bonus Features (Optional)

- [ ] Image resizing before upload
- [ ] Generate signed S3 URLs
- [ ] Dockerize the setup
- [ ] Deploy on EC2

## Security Considerations

⚠️ **Note**: This is a learning project. For production:
- [ ] Add authentication/authorization
- [ ] Use AWS IAM roles instead of access keys
- [ ] Implement rate limiting
- [ ] Add HTTPS/SSL
- [ ] Validate file signatures
- [ ] Implement request signing

## License

MIT

## Support

For issues or questions, create a GitHub issue in this repository.
