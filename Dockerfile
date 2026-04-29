FROM node:18-alpine

WORKDIR /app

# Copy package files
COPY package*.json ./

# Install dependencies
RUN npm install --production

# Copy application code
COPY server.js .

# Expose port (dynamic via ENV)
EXPOSE 3001

# Start server
CMD ["node", "server.js"]
