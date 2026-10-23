const assert = require("node:assert/strict");
const { after, before, test } = require("node:test");
const { createApp } = require("../src/server");

const products = [
  { id: 1, name: "Notebook", price: "4.50" },
  { id: 2, name: "Coffee mug", price: "8.99" }
];
const prisma = {
  $queryRaw: async () => [{ "?column?": 1 }],
  product: { findMany: async () => products }
};
const app = createApp(prisma, "http://frontend.test");

let server;
let baseUrl;

before(async () => {
  server = app.listen(0, "127.0.0.1");
  await new Promise((resolve) => server.once("listening", resolve));
  baseUrl = `http://127.0.0.1:${server.address().port}`;
});

after(async () => {
  await new Promise((resolve, reject) => {
    server.close((error) => error ? reject(error) : resolve());
  });
});

test("health endpoint reports database connectivity", async () => {
  const response = await fetch(`${baseUrl}/health`);

  assert.equal(response.status, 200);
  assert.deepEqual(await response.json(), {
    status: "ok",
    service: "products-service",
    database: "connected"
  });
});

test("products endpoint returns Prisma results in order", async () => {
  const response = await fetch(`${baseUrl}/products`);

  assert.equal(response.status, 200);
  assert.deepEqual(await response.json(), products);
  assert.equal(response.headers.get("access-control-allow-origin"), "http://frontend.test");
});

test("health endpoint reports a database failure", async () => {
  const failingApp = createApp({
    $queryRaw: async () => {
      throw new Error("database unavailable");
    },
    product: { findMany: async () => products }
  }, "http://frontend.test");
  const failingServer = failingApp.listen(0, "127.0.0.1");
  await new Promise((resolve) => failingServer.once("listening", resolve));

  try {
    const response = await fetch(`http://127.0.0.1:${failingServer.address().port}/health`);

    assert.equal(response.status, 503);
    assert.deepEqual(await response.json(), {
      status: "error",
      service: "products-service",
      database: "disconnected"
    });
  } finally {
    await new Promise((resolve, reject) => {
      failingServer.close((error) => error ? reject(error) : resolve());
    });
  }
});

test("products endpoint returns an error when Prisma fails", async (t) => {
  const errorApp = createApp({
    $queryRaw: prisma.$queryRaw,
    product: {
      findMany: async () => {
        throw new Error("database unavailable");
      }
    }
  }, "http://frontend.test");
  const errorServer = errorApp.listen(0, "127.0.0.1");
  await new Promise((resolve) => errorServer.once("listening", resolve));
  t.mock.method(console, "error", () => {});

  try {
    const response = await fetch(`http://127.0.0.1:${errorServer.address().port}/products`);

    assert.equal(response.status, 500);
    assert.deepEqual(await response.json(), { error: "Could not fetch products" });
  } finally {
    await new Promise((resolve, reject) => {
      errorServer.close((error) => error ? reject(error) : resolve());
    });
  }
});
