#!/bin/bash
# Quick Start Guide for Scalable Image Upload Server

echo "==================================================="
echo "Scalable Image Upload Server - Quick Start"
echo "==================================================="
echo ""

# Step 1: Environment Setup
echo "STEP 1: Setting up environment variables"
echo "-----"
if [ ! -f .env ]; then
    echo "Creating .env file from .env.example..."
    cp .env.example .env
    echo "✓ .env file created. Please edit it with your AWS credentials."
else
    echo "✓ .env file already exists"
fi
echo ""

# Step 2: Dependencies
echo "STEP 2: Installing dependencies"
echo "-----"
if [ -d node_modules ]; then
    echo "✓ Dependencies already installed"
else
    echo "Installing npm packages..."
    npm install
    echo "✓ Dependencies installed"
fi
echo ""

# Step 3: Run Servers
echo "STEP 3: Running backend servers"
echo "-----"
echo "Starting two server instances..."
echo "  • Server 1: http://localhost:3001"
echo "  • Server 2: http://localhost:3002"
echo ""
echo "Run this command in the project root:"
echo "  npm run start:both"
echo ""

# Step 4: NGINX Setup (optional for local testing)
echo "STEP 4: NGINX Load Balancer (Optional)"
echo "-----"
echo "To test with NGINX load balancer:"
echo "  1. Start the servers (from Step 3)"
echo "  2. In another terminal, run:"
echo "     sudo nginx -c \$(pwd)/nginx.conf"
echo "  3. Access through load balancer:"
echo "     http://localhost/upload"
echo ""

# Step 5: Testing
echo "STEP 5: Test the server"
echo "-----"
echo "Upload an image:"
echo "  curl -X POST -F 'image=@path/to/image.jpg' http://localhost:3001/upload"
echo ""
echo "Check health:"
echo "  curl http://localhost:3001/health"
echo ""

# Step 6: Push to GitHub
echo "STEP 6: Push to GitHub"
echo "-----"
echo "1. Create a new repository on GitHub"
echo "2. Add the remote and push:"
echo "   git remote add origin https://github.com/your-username/scalable-image-upload.git"
echo "   git branch -M main"
echo "   git push -u origin main"
echo ""
echo "3. Add GitHub Secrets in repository Settings:"
echo "   - AWS_ACCESS_KEY_ID"
echo "   - AWS_SECRET_ACCESS_KEY"
echo "   - AWS_S3_BUCKET"
echo ""

echo "==================================================="
echo "Setup Summary"
echo "==================================================="
echo "Project: scalable-image-upload"
echo "Status: ✓ Ready to run"
echo ""
echo "Next steps:"
echo "1. Edit .env file with AWS credentials"
echo "2. Run: npm run start:both"
echo "3. Test endpoints with curl or Postman"
echo "4. Push to GitHub and submit repository link"
echo "==================================================="
