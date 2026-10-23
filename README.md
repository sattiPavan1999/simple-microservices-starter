# Simple Microservices Starter

A small Node.js project to practise Docker, Jenkins, Kubernetes, and Terraform later.

## Architecture

- `frontend`: a tiny static HTML page served by Node.js on port `3000`
- `users-service`: Node.js API on port `3001`, connected to `users_db`
- `products-service`: Node.js API on port `3002`, connected to `products_db`
- `users-db`: PostgreSQL database
- `products-db`: PostgreSQL database

Each backend has its own PostgreSQL database. Prisma manages each service's schema through checked-in migrations; Compose starts the two databases, runs a migration/seed job for each backend, and then starts the three application services.

## Prerequisites

- Docker Desktop with Docker Compose

## Run

From the project root:

```bash
docker compose up --build
```

Each service has a `.env` file for its runtime configuration. Copy the corresponding `.env.example` to `.env` if needed, then adjust values for your environment. The checked-in `.env` values are intended only for local development.

The local PostgreSQL containers use the `postgres` superuser for these starter services. If you already have the database volumes from an earlier setup, changing `POSTGRES_USER` does not change database roles automatically; migrate the existing database role and object ownership before changing its `DATABASE_URL`. The checked-in local credentials are not suitable for production.

Open:

- Frontend: http://localhost:3000
- Users API health: http://localhost:3001/health
- Users API data: http://localhost:3001/users
- Products API health: http://localhost:3002/health
- Products API data: http://localhost:3002/products

Stop:

```bash
docker compose down
```

To create and apply a migration after changing a Prisma schema, start the service's database with Compose. For example, run `docker compose up -d users-db` from the project root, then run this from the service directory in PowerShell:

```powershell
cd users-service
npm ci
$env:DATABASE_URL = "postgresql://users_app:local_users_password@localhost:5433/users_db?schema=public"
npx prisma migrate dev --name describe-your-change
Remove-Item Env:DATABASE_URL
```

Use `products-service` instead for product schema changes; start `products-db` and use port `5434` with the products credentials. Compose runs `npm run db:migrate` and the service seed script at startup. The migration command baselines the existing starter tables (without deleting data) when no Prisma migration history is present, then deploys pending migrations.

Remove containers and database data (destructive):

```bash
docker compose down -v
```

## Test the APIs

```bash
curl http://localhost:3001/users
curl http://localhost:3002/products
```

The frontend page calls both APIs from the browser. For this starter, CORS is enabled on the backend services for local learning.

## Run unit tests

Each service has simple Node.js built-in tests; backend tests use mocked Prisma clients and do not require a running database:

```bash
cd frontend
npm test

cd ../users-service
npm test

cd ../products-service
npm test
```

## Suggested next enhancements

1. Add automated tests and a Jenkins CI pipeline.
2. Add environment-specific configuration and proper secrets management.
3. Deploy to Kubernetes, then replace local PostgreSQL containers with Amazon RDS.
4. Add logging, readiness endpoints, metrics, and security hardening.

## Important

This is a learning starter, not production-ready. Credentials in the service `.env` files are for local practice only. Do not reuse them in production. When moving to AWS, use private networking and a secret manager, and configure each service with least-privilege database credentials.
