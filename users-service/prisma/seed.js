require("dotenv").config();

const { PrismaClient } = require("@prisma/client");
const { PrismaPg } = require("@prisma/adapter-pg");
const prisma = new PrismaClient({
  adapter: new PrismaPg({ connectionString: process.env.DATABASE_URL })
});

async function main() {
  if (await prisma.user.count() === 0) {
    await prisma.user.createMany({
      data: [
        { name: "Pavan", email: "pavan@example.com" },
        { name: "Alex", email: "alex@example.com" }
      ]
    });
  }
}

main()
  .catch((error) => {
    console.error("Failed to seed users:", error);
    process.exitCode = 1;
  })
  .finally(() => prisma.$disconnect());
