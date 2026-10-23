require("dotenv").config();

const { PrismaClient } = require("@prisma/client");
const { PrismaPg } = require("@prisma/adapter-pg");
const prisma = new PrismaClient({
  adapter: new PrismaPg({ connectionString: process.env.DATABASE_URL })
});

async function main() {
  if (await prisma.product.count() === 0) {
    await prisma.product.createMany({
      data: [
        { name: "Notebook", price: 4.50 },
        { name: "Coffee mug", price: 8.99 }
      ]
    });
  }
}

main()
  .catch((error) => {
    console.error("Failed to seed products:", error);
    process.exitCode = 1;
  })
  .finally(() => prisma.$disconnect());
