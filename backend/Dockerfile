# ---- Build stage ----
FROM node:22-slim AS build
WORKDIR /app

# Install deps (including dev) for building.
COPY package*.json ./
RUN npm ci

# Generate Prisma client + compile TypeScript.
COPY . .
RUN npx prisma generate && npm run build

# ---- Runtime stage ----
FROM node:22-slim AS runtime
WORKDIR /app
ENV NODE_ENV=production

# Only production deps in the final image.
COPY package*.json ./
RUN npm ci --omit=dev

# Prisma client (generated) + compiled app + schema (for migrations if needed).
COPY --from=build /app/node_modules/.prisma ./node_modules/.prisma
COPY --from=build /app/node_modules/@prisma ./node_modules/@prisma
COPY --from=build /app/dist ./dist
COPY --from=build /app/prisma ./prisma
COPY --from=build /app/prisma.config.ts ./prisma.config.ts

EXPOSE 3000
CMD ["node", "dist/src/main"]
