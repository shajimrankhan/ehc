FROM mcr.microsoft.com/playwright:v1.58.0-noble

WORKDIR /app

# Install root-level dependencies (Playwright test runner)
COPY package.json package-lock.json ./
RUN npm ci

# Copy test code and config
COPY playwright.config.ts ./
COPY tests/ ./tests/

CMD ["npm", "run", "test"]
