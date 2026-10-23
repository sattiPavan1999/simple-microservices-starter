FROM node:22-alpine
WORKDIR /app
RUN apk add --no-cache openssl
COPY package*.json ./
RUN npm ci --omit=dev
COPY prisma.config.ts ./
COPY prisma ./prisma
RUN DATABASE_URL="postgresql://build:build@localhost:5432/build?schema=public" npx prisma generate
COPY scripts ./scripts
COPY src ./src
EXPOSE 3001
CMD ["npm", "start"]
