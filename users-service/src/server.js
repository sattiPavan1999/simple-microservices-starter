require("dotenv").config();

const express = require("express");
const { PrismaClient } = require("@prisma/client");
const { PrismaPg } = require("@prisma/adapter-pg");

const port = Number(process.env.PORT);
if (!process.env.DATABASE_URL || !process.env.CORS_ORIGIN || !Number.isInteger(port) || port < 1 || port > 65535) {
  throw new Error("PORT, DATABASE_URL, and CORS_ORIGIN must be configured with valid values");
}

const app = express();
const prisma = new PrismaClient({
  adapter: new PrismaPg({ connectionString: process.env.DATABASE_URL })
});
app.use(express.json());
app.use((req, res, next) => {
  res.setHeader("Access-Control-Allow-Origin", process.env.CORS_ORIGIN);
  res.setHeader("Access-Control-Allow-Methods", "GET,OPTIONS");
  res.setHeader("Access-Control-Allow-Headers", "Content-Type");
  if (req.method === "OPTIONS") return res.sendStatus(204);
  next();
});

app.get("/health", async (_req, res) => {
  try {
    await prisma.$queryRaw`SELECT 1`;
    res.json({ status: "ok", service: "users-service", database: "connected" });
  } catch {
    res.status(503).json({ status: "error", service: "users-service", database: "disconnected" });
  }
});

app.get("/users", async (_req, res) => {
  try {
    const users = await prisma.user.findMany({
      select: { id: true, name: true, email: true },
      orderBy: { id: "asc" }
    });
    res.json(users);
  } catch (error) {
    console.error("Failed to fetch users:", error.message);
    res.status(500).json({ error: "Could not fetch users" });
  }
});

app.listen(port, () => console.log(`users-service listening on ${port}`));

async function shutdown() {
  await prisma.$disconnect();
  process.exit(0);
}

process.on("SIGTERM", shutdown);
process.on("SIGINT", shutdown);
