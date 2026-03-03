import dotenv from 'dotenv';
dotenv.config();
import { PrismaClient } from "../generated/prisma";
import { PrismaPg } from "@prisma/adapter-pg";
import bcrypt from "bcrypt";

const adapter = new PrismaPg({
  connectionString: process.env.DATABASE_URL!,
});
const prisma = new PrismaClient({ adapter });

async function main() {
  const hash = await bcrypt.hash("password123", 10);

  // step 1 — create agency user + agency profile in one go
  const agenceUser = await prisma.utilisateur.create({
    data: {
      email: "agence@test.com",
      motDePasse: hash,
      nom: "Benali",
      prenom: "Karim",
      role: "AGENCE",
      agence: {
        create: {
          nomAgence: "Agence Hajj Alger",
          adresse: "Alger, Algérie",
        },
      },
    },
    include: { agence: true }, // ← include so we can read agence.id below
  });

  const agenceId = agenceUser.agence!.id;
  console.log("✅ Agency created with id:", agenceId);

  // step 2 — create guide user + guide profile
  await prisma.utilisateur.create({
    data: {
      email: "guide@test.com",
      motDePasse: hash,
      nom: "Ziani",
      prenom: "Omar",
      role: "GUIDE",
      guide: {
        create: {
          agenceId,
          specialite: "Hajj",
        },
      },
    },
  });

  console.log("✅ Guide created");

  // step 3 — create pilgrim user + pilgrim profile
  await prisma.utilisateur.create({
    data: {
      email: "pelerin@test.com",
      motDePasse: hash,
      nom: "Mansouri",
      prenom: "Youssef",
      role: "PELERIN",
      pelerin: {
        create: {
          agenceId,
          nationalite: "Algérienne",
          numeroPasseport: "AB123456",
        },
      },
    },
  });

  console.log("✅ Pilgrim created");
}

main()
  .catch(console.error)
  .finally(() => prisma.$disconnect());