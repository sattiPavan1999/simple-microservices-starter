const assert = require("node:assert/strict");
const { after, before, test } = require("node:test");
const { createApp } = require("../src/server");

const users = [
  { id: 1, name: "Pavan", email: "pavan@example.com" },
  { id: 2, name: "Alex", email: "alex@example.com" }
];
const prisma = {
  $queryRaw: async () => [{ "?column?": 1 }],
  user: { findMany: async () => users }
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
    service: "users-service",
    database: "connected"
  });
});

test("users endpoint returns Prisma results in order", async () => {
  const response = await fetch(`${baseUrl}/users`);

  assert.equal(response.status, 200);
  assert.deepEqual(await response.json(), users);
  assert.equal(response.headers.get("access-control-allow-origin"), "http://frontend.test");
});

test("health endpoint reports a database failure", async () => {
  const failingApp = createApp({
    $queryRaw: async () => {
      throw new Error("database unavailable");
    },
    user: { findMany: async () => users }
  }, "http://frontend.test");
  const failingServer = failingApp.listen(0, "127.0.0.1");
  await new Promise((resolve) => failingServer.once("listening", resolve));

  try {
    const response = await fetch(`http://127.0.0.1:${failingServer.address().port}/health`);

    assert.equal(response.status, 503);
    assert.deepEqual(await response.json(), {
      status: "error",
      service: "users-service",
      database: "disconnected"
    });
  } finally {
    await new Promise((resolve, reject) => {
      failingServer.close((error) => error ? reject(error) : resolve());
    });
  }
});

test("users endpoint returns an error when Prisma fails", async (t) => {
  const errorApp = createApp({
    $queryRaw: prisma.$queryRaw,
    user: {
      findMany: async () => {
        throw new Error("database unavailable");
      }
    }
  }, "http://frontend.test");
  const errorServer = errorApp.listen(0, "127.0.0.1");
  await new Promise((resolve) => errorServer.once("listening", resolve));
  t.mock.method(console, "error", () => {});

  try {
    const response = await fetch(`http://127.0.0.1:${errorServer.address().port}/users`);

    assert.equal(response.status, 500);
    assert.deepEqual(await response.json(), { error: "Could not fetch users" });
  } finally {
    await new Promise((resolve, reject) => {
      errorServer.close((error) => error ? reject(error) : resolve());
    });
  }
});
