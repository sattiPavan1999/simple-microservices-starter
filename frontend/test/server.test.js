const assert = require("node:assert/strict");
const { after, before, test } = require("node:test");
const { createApp } = require("../server");

const app = createApp({
  USERS_API_URL: "http://users.test",
  PRODUCTS_API_URL: "http://products.test"
});

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

test("health endpoint reports frontend status", async () => {
  const response = await fetch(`${baseUrl}/health`);

  assert.equal(response.status, 200);
  assert.deepEqual(await response.json(), { status: "ok", service: "frontend" });
});

test("runtime config endpoint returns configured backend URLs", async () => {
  const response = await fetch(`${baseUrl}/config.js`);

  assert.equal(response.status, 200);
  assert.match(response.headers.get("content-type"), /application\/javascript/);
  assert.equal(
    await response.text(),
    'window.APP_CONFIG = {"USERS_API_URL":"http://users.test","PRODUCTS_API_URL":"http://products.test"};'
  );
});

test("serves the frontend page", async () => {
  const response = await fetch(baseUrl);

  assert.equal(response.status, 200);
  assert.match(await response.text(), /Microservices Starter/);
});
