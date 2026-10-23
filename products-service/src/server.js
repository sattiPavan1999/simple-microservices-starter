require("dotenv").config();

const express = require("express");
const { PrismaClient } = require("@prisma/client");
const { PrismaPg } = require("@prisma/adapter-pg");

function createApp(prisma, corsOrigin) {
  const app = express();
  app.use(express.json());
  app.use((req, res, next) => {
    res.setHeader("Access-Control-Allow-Origin", corsOrigin);
    res.setHeader("Access-Control-Allow-Methods", "GET,OPTIONS");
    res.setHeader("Access-Control-Allow-Headers", "Content-Type");
    if (req.method === "OPTIONS") return res.sendStatus(204);
    next();
  });

  app.get("/health", async (_req, res) => {
    try {
      await prisma.$queryRaw`SELECT 1`;
      res.json({ status: "ok", service: "products-service", database: "connected" });
    } catch {
      res.status(503).json({ status: "error", service: "products-service", database: "disconnected" });
    }
  });

  app.get("/products", async (_req, res) => {
    try {
      const products = await prisma.product.findMany({
        select: { id: true, name: true, price: true },
        orderBy: { id: "asc" }
      });
      res.json(products);
    } catch (error) {
      console.error("Failed to fetch products:", error.message);
      res.status(500).json({ error: "Could not fetch products" });
    }
  });

  return app;
}

function start() {
  const port = Number(process.env.PORT);
  if (!process.env.DATABASE_URL || !process.env.CORS_ORIGIN || !Number.isInteger(port) || port < 1 || port > 65535) {
    throw new Error("PORT, DATABASE_URL, and CORS_ORIGIN must be configured with valid values");
  }

  const prisma = new PrismaClient({
    adapter: new PrismaPg({ connectionString: process.env.DATABASE_URL })
  });
  const server = createApp(prisma, process.env.CORS_ORIGIN)
    .listen(port, () => console.log(`products-service listening on ${port}`));

  async function shutdown() {
    server.close();
    await prisma.$disconnect();
  }

  process.on("SIGTERM", shutdown);
  process.on("SIGINT", shutdown);
}

if (require.main === module) {
  start();
}

module.exports = { createApp, start };
