require("dotenv").config();

const { execFileSync } = require("child_process");
const fs = require("fs");
const path = require("path");
const { Client } = require("pg");

async function main() {
  const tableName = process.env.PRISMA_BASELINE_TABLE;
  if (!process.env.DATABASE_URL || !tableName || !/^[a-z_][a-z0-9_]*$/i.test(tableName)) {
    throw new Error("DATABASE_URL and a valid PRISMA_BASELINE_TABLE must be configured");
  }

  const migrationsPath = path.join(__dirname, "..", "prisma", "migrations");
  const migrations = fs.readdirSync(migrationsPath)
    .filter((name) => fs.statSync(path.join(migrationsPath, name)).isDirectory())
    .sort();
  if (migrations.length === 0) {
    throw new Error("No Prisma migrations were found");
  }

  const client = new Client({ connectionString: process.env.DATABASE_URL });
  let shouldBaseline = false;
  try {
    await client.connect();
    const { rows } = await client.query(
      `SELECT to_regclass($1) IS NOT NULL AS app_table_exists,
              to_regclass('public._prisma_migrations') IS NOT NULL AS history_exists`,
      [`public.${tableName}`]
    );

    if (rows[0].app_table_exists) {
      if (!rows[0].history_exists) {
        shouldBaseline = true;
      } else {
        const history = await client.query(
          'SELECT COUNT(*)::int AS count FROM "public"."_prisma_migrations"'
        );
        shouldBaseline = history.rows[0].count === 0;
      }
    }
  } finally {
    await client.end();
  }

  const prismaCli = require.resolve("prisma/build/index.js");
  if (shouldBaseline) {
    console.log(`Existing "${tableName}" table found with no Prisma history; baselining ${migrations[0]}.`);
    execFileSync(process.execPath, [prismaCli, "migrate", "resolve", "--applied", migrations[0]], {
      stdio: "inherit",
      env: process.env
    });
  }

  execFileSync(process.execPath, [prismaCli, "migrate", "deploy"], {
    stdio: "inherit",
    env: process.env
  });
}

main().catch((error) => {
  console.error("Database migration failed:", error);
  process.exitCode = 1;
});
