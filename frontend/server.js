require("dotenv").config();

const express = require("express");
const path = require("path");

function createApp(config) {
  const app = express();
  app.use(express.static(path.join(__dirname, "public")));

  app.get("/health", (_req, res) => res.json({ status: "ok", service: "frontend" }));

  app.get("/config.js", (_req, res) => {
    res.type("application/javascript").send(
      `window.APP_CONFIG = ${JSON.stringify({
        USERS_API_URL: config.USERS_API_URL,
        PRODUCTS_API_URL: config.PRODUCTS_API_URL
      })};`
    );
  });

  return app;
}

function start() {
  const port = Number(process.env.PORT);
  if (!process.env.USERS_API_URL || !process.env.PRODUCTS_API_URL || !Number.isInteger(port) || port < 1 || port > 65535) {
    throw new Error("PORT, USERS_API_URL, and PRODUCTS_API_URL must be configured with valid values");
  }

  createApp({
    USERS_API_URL: process.env.USERS_API_URL,
    PRODUCTS_API_URL: process.env.PRODUCTS_API_URL
  }).listen(port, () => console.log(`frontend listening on ${port}`));
}

if (require.main === module) {
  start();
}

module.exports = { createApp, start };
