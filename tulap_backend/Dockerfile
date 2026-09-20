# ----------------------------------------------------------------------
# Tulap.id Backend Production Multi-Stage Dockerfile
# ----------------------------------------------------------------------

# Stage 1: Build & Prune
FROM node:20-alpine AS builder

WORKDIR /app

# Prisma's query/schema engine needs OpenSSL present to detect the right
# engine binary - without it, alpine's musl libc has no libssl at all and
# `prisma generate`/`migrate deploy` crash with an unparseable engine
# response instead of a clear error.
RUN apk add --no-cache openssl

# Install build dependencies
COPY package*.json ./
COPY prisma ./prisma/

RUN npm ci

COPY . .

# Generate Prisma Client & Build TypeScript
RUN npx prisma generate
RUN npm run build

# Stage 2: Production Runner
FROM node:20-alpine AS runner

WORKDIR /app

# Same OpenSSL requirement as the builder stage - this is the stage that
# actually runs `prisma migrate deploy` at container startup (see CMD).
RUN apk add --no-cache openssl

ENV NODE_ENV=production
ENV PORT=3000

# Security: Non-root user
USER node

# Copy build artifacts & dependencies from builder
COPY --chown=node:node --from=builder /app/package*.json ./
COPY --chown=node:node --from=builder /app/node_modules ./node_modules
COPY --chown=node:node --from=builder /app/dist ./dist
COPY --chown=node:node --from=builder /app/prisma ./prisma

EXPOSE 3000

# tsconfig.json has no rootDir set, so tsc preserves the src/ prefix in
# its output (dist/src/main.js), not dist/main.js.
#
# `prisma db seed` runs on every startup, not just the first - it's
# idempotent (upserts the 4 roles, only creates the Super Admin account
# if it doesn't already exist yet), and a fresh database has an EMPTY
# Role table until this runs at least once. Without it, every single
# registration path (self-register, Google/Apple/Facebook OAuth) fails
# with "Role PEGAWAI belum terdaftar di master data" - confirmed for
# real on the first fresh Railway deploy, 2026-09-20/21.
CMD ["sh", "-c", "npx prisma migrate deploy && npx prisma db seed && node dist/src/main"]
