# ---- Base Node Image ----
FROM node:18-alpine AS base

# ---- Build Stage ----
FROM base AS build
WORKDIR /app

# Copy package files
COPY package*.json ./

# Install dependencies
RUN npm install
RUN npm install --production -g pino-syslog

# Copy source code
COPY . .

# Build the project
RUN npm run build


# ---- Production Stage ----
FROM base AS production

WORKDIR /app

# Install only production dependencies
COPY package*.json ./
RUN npm install --omit=dev
RUN npm install --production -g pino-syslog

# Copy built files from the build stage
COPY --from=build /app/dist ./dist

# Expose the API port (default 3000)
EXPOSE 3000

# Start the NestJS application
CMD ["node", "dist/main.js"]
