-- CreateEnum
CREATE TYPE "StatutAgence" AS ENUM ('PENDING', 'APPROVED', 'REJECTED', 'SUSPENDED');

-- CreateEnum
CREATE TYPE "PasswordTokenType" AS ENUM ('SET_PASSWORD', 'RESET_PASSWORD');

-- AlterTable
ALTER TABLE "AgenceVoyage" ADD COLUMN     "approvedAt" TIMESTAMP(3),
ADD COLUMN     "rejectedAt" TIMESTAMP(3),
ADD COLUMN     "rejectionReason" TEXT,
ADD COLUMN     "status" "StatutAgence" NOT NULL DEFAULT 'PENDING';

-- AlterTable
ALTER TABLE "Utilisateur" ALTER COLUMN "motDePasse" DROP NOT NULL,
ALTER COLUMN "actif" SET DEFAULT false;

-- CreateTable
CREATE TABLE "PasswordToken" (
    "id" TEXT NOT NULL,
    "utilisateurId" TEXT NOT NULL,
    "tokenHash" TEXT NOT NULL,
    "type" "PasswordTokenType" NOT NULL,
    "expiresAt" TIMESTAMP(3) NOT NULL,
    "usedAt" TIMESTAMP(3),
    "createdAt" TIMESTAMP(3) NOT NULL DEFAULT CURRENT_TIMESTAMP,

    CONSTRAINT "PasswordToken_pkey" PRIMARY KEY ("id")
);

-- CreateTable
CREATE TABLE "Famille" (
    "id" TEXT NOT NULL,
    "utilisateurId" TEXT NOT NULL,
    "agenceId" TEXT NOT NULL,
    "lienParente" TEXT,
    "createdAt" TIMESTAMP(3) NOT NULL DEFAULT CURRENT_TIMESTAMP,
    "updatedAt" TIMESTAMP(3) NOT NULL,

    CONSTRAINT "Famille_pkey" PRIMARY KEY ("id")
);

-- CreateTable
CREATE TABLE "FamillePelerin" (
    "id" TEXT NOT NULL,
    "familleId" TEXT NOT NULL,
    "pelerinId" TEXT NOT NULL,
    "actif" BOOLEAN NOT NULL DEFAULT true,
    "createdAt" TIMESTAMP(3) NOT NULL DEFAULT CURRENT_TIMESTAMP,

    CONSTRAINT "FamillePelerin_pkey" PRIMARY KEY ("id")
);

-- CreateIndex
CREATE UNIQUE INDEX "PasswordToken_tokenHash_key" ON "PasswordToken"("tokenHash");

-- CreateIndex
CREATE UNIQUE INDEX "Famille_utilisateurId_key" ON "Famille"("utilisateurId");

-- CreateIndex
CREATE UNIQUE INDEX "FamillePelerin_familleId_pelerinId_key" ON "FamillePelerin"("familleId", "pelerinId");

-- AddForeignKey
ALTER TABLE "PasswordToken" ADD CONSTRAINT "PasswordToken_utilisateurId_fkey" FOREIGN KEY ("utilisateurId") REFERENCES "Utilisateur"("id") ON DELETE CASCADE ON UPDATE CASCADE;

-- AddForeignKey
ALTER TABLE "Famille" ADD CONSTRAINT "Famille_utilisateurId_fkey" FOREIGN KEY ("utilisateurId") REFERENCES "Utilisateur"("id") ON DELETE CASCADE ON UPDATE CASCADE;

-- AddForeignKey
ALTER TABLE "Famille" ADD CONSTRAINT "Famille_agenceId_fkey" FOREIGN KEY ("agenceId") REFERENCES "AgenceVoyage"("id") ON DELETE RESTRICT ON UPDATE CASCADE;

-- AddForeignKey
ALTER TABLE "FamillePelerin" ADD CONSTRAINT "FamillePelerin_familleId_fkey" FOREIGN KEY ("familleId") REFERENCES "Famille"("id") ON DELETE CASCADE ON UPDATE CASCADE;

-- AddForeignKey
ALTER TABLE "FamillePelerin" ADD CONSTRAINT "FamillePelerin_pelerinId_fkey" FOREIGN KEY ("pelerinId") REFERENCES "Pelerin"("id") ON DELETE CASCADE ON UPDATE CASCADE;
