/*
  Warnings:

  - You are about to drop the column `heureDebut` on the `EvenementPlanning` table. All the data in the column will be lost.
  - You are about to drop the column `heureFin` on the `EvenementPlanning` table. All the data in the column will be lost.
  - You are about to drop the column `agenceId` on the `Famille` table. All the data in the column will be lost.
  - You are about to drop the column `etapeActuelle` on the `Pelerin` table. All the data in the column will be lost.
  - You are about to drop the `EtapeValidee` table. If the table is not empty, all the data it contains will be lost.
  - Added the required column `heureDebutPrevue` to the `EvenementPlanning` table without a default value. This is not possible if the table is not empty.
  - Added the required column `updatedAt` to the `EvenementPlanning` table without a default value. This is not possible if the table is not empty.
  - Added the required column `updatedAt` to the `FamillePelerin` table without a default value. This is not possible if the table is not empty.

*/
-- CreateEnum
CREATE TYPE "StatutGroupe" AS ENUM ('PLANIFIE', 'EN_COURS', 'TERMINE', 'ANNULE');

-- CreateEnum
CREATE TYPE "EtapeVoyage" AS ENUM ('IHRAM', 'TAWAF_AL_QUDUM', 'SAI', 'ARAFAT', 'MUZDALIFAH', 'MINA', 'RAMI_JAMARAT', 'TAWAF_AL_IFADA', 'TAWAF_AL_WADA', 'TAHALLUL');

-- CreateEnum
CREATE TYPE "StatutEvenement" AS ENUM ('PLANIFIE', 'EN_COURS', 'TERMINE', 'RETARDE', 'ANNULE');

-- CreateEnum
CREATE TYPE "StatutPelerin" AS ENUM ('PRESENT', 'EN_DEPLACEMENT', 'BESOIN_AIDE', 'SOS');

-- CreateEnum
CREATE TYPE "StatutAppel" AS ENUM ('EN_COURS', 'CLOTURE');

-- CreateEnum
CREATE TYPE "StatutPresence" AS ENUM ('EN_ATTENTE', 'PRESENT', 'ABSENT', 'EXCUSE');

-- CreateEnum
CREATE TYPE "ModeConfirmation" AS ENUM ('AUTOMATIQUE', 'MANUEL');

-- CreateEnum
CREATE TYPE "StatutAlerte" AS ENUM ('EN_COURS', 'RESOLUE', 'ANNULEE');

-- CreateEnum
CREATE TYPE "TypeIncident" AS ENUM ('SOS', 'MALADIE', 'PERTE', 'LOGISTIQUE', 'AUTRE');

-- CreateEnum
CREATE TYPE "Gravite" AS ENUM ('FAIBLE', 'MOYENNE', 'ELEVEE', 'CRITIQUE');

-- DropForeignKey
ALTER TABLE "EtapeValidee" DROP CONSTRAINT "EtapeValidee_pelerinId_fkey";

-- DropForeignKey
ALTER TABLE "Famille" DROP CONSTRAINT "Famille_agenceId_fkey";

-- AlterTable
ALTER TABLE "AgenceVoyage" ADD COLUMN     "approvedById" TEXT,
ADD COLUMN     "rejectedById" TEXT;

-- AlterTable
ALTER TABLE "EvenementPlanning" DROP COLUMN "heureDebut",
DROP COLUMN "heureFin",
ADD COLUMN     "heureDebutPrevue" TIMESTAMP(3) NOT NULL,
ADD COLUMN     "heureDebutReelle" TIMESTAMP(3),
ADD COLUMN     "heureFinPrevue" TIMESTAMP(3),
ADD COLUMN     "heureFinReelle" TIMESTAMP(3),
ADD COLUMN     "noteChangement" TEXT,
ADD COLUMN     "statut" "StatutEvenement" NOT NULL DEFAULT 'PLANIFIE',
ADD COLUMN     "updatedAt" TIMESTAMP(3) NOT NULL,
ADD COLUMN     "updatedByGuideId" TEXT;

-- AlterTable
ALTER TABLE "Famille" DROP COLUMN "agenceId";

-- AlterTable
ALTER TABLE "FamillePelerin" ADD COLUMN     "updatedAt" TIMESTAMP(3) NOT NULL;

-- AlterTable
ALTER TABLE "Groupe" ADD COLUMN     "dateDepart" TIMESTAMP(3),
ADD COLUMN     "dateRetour" TIMESTAMP(3),
ADD COLUMN     "etapeActuelle" "EtapeVoyage",
ADD COLUMN     "nbMax" INTEGER,
ADD COLUMN     "status" "StatutGroupe" NOT NULL DEFAULT 'PLANIFIE';

-- AlterTable
ALTER TABLE "Pelerin" DROP COLUMN "etapeActuelle",
ADD COLUMN     "statut" "StatutPelerin" NOT NULL DEFAULT 'PRESENT';

-- DropTable
DROP TABLE "EtapeValidee";

-- DropEnum
DROP TYPE "EtapeHajj";

-- CreateTable
CREATE TABLE "GroupeGuide" (
    "id" TEXT NOT NULL,
    "groupeId" TEXT NOT NULL,
    "guideId" TEXT NOT NULL,
    "dateDebut" TIMESTAMP(3) NOT NULL DEFAULT CURRENT_TIMESTAMP,
    "dateFin" TIMESTAMP(3),
    "actif" BOOLEAN NOT NULL DEFAULT true,

    CONSTRAINT "GroupeGuide_pkey" PRIMARY KEY ("id")
);

-- CreateTable
CREATE TABLE "GroupePelerin" (
    "id" TEXT NOT NULL,
    "groupeId" TEXT NOT NULL,
    "pelerinId" TEXT NOT NULL,
    "dateDebut" TIMESTAMP(3) NOT NULL DEFAULT CURRENT_TIMESTAMP,
    "dateFin" TIMESTAMP(3),
    "actif" BOOLEAN NOT NULL DEFAULT true,

    CONSTRAINT "GroupePelerin_pkey" PRIMARY KEY ("id")
);

-- CreateTable
CREATE TABLE "EtapeValideeGroupe" (
    "id" TEXT NOT NULL,
    "groupeId" TEXT NOT NULL,
    "etape" "EtapeVoyage" NOT NULL,
    "valideeAt" TIMESTAMP(3) NOT NULL DEFAULT CURRENT_TIMESTAMP,
    "valideParGuideId" TEXT,
    "note" TEXT,

    CONSTRAINT "EtapeValideeGroupe_pkey" PRIMARY KEY ("id")
);

-- CreateTable
CREATE TABLE "AppelPresence" (
    "id" TEXT NOT NULL,
    "groupeId" TEXT NOT NULL,
    "guideId" TEXT NOT NULL,
    "date" TIMESTAMP(3) NOT NULL DEFAULT CURRENT_TIMESTAMP,
    "statut" "StatutAppel" NOT NULL DEFAULT 'EN_COURS',
    "createdAt" TIMESTAMP(3) NOT NULL DEFAULT CURRENT_TIMESTAMP,
    "clotureAt" TIMESTAMP(3),

    CONSTRAINT "AppelPresence_pkey" PRIMARY KEY ("id")
);

-- CreateTable
CREATE TABLE "ConfirmationPresence" (
    "id" TEXT NOT NULL,
    "appelPresenceId" TEXT NOT NULL,
    "pelerinId" TEXT NOT NULL,
    "statut" "StatutPresence" NOT NULL DEFAULT 'EN_ATTENTE',
    "confirmeAt" TIMESTAMP(3),
    "confirmeMode" "ModeConfirmation",
    "note" TEXT,
    "createdAt" TIMESTAMP(3) NOT NULL DEFAULT CURRENT_TIMESTAMP,

    CONSTRAINT "ConfirmationPresence_pkey" PRIMARY KEY ("id")
);

-- CreateTable
CREATE TABLE "Position" (
    "id" TEXT NOT NULL,
    "pelerinId" TEXT NOT NULL,
    "latitude" DOUBLE PRECISION NOT NULL,
    "longitude" DOUBLE PRECISION NOT NULL,
    "createdAt" TIMESTAMP(3) NOT NULL DEFAULT CURRENT_TIMESTAMP,

    CONSTRAINT "Position_pkey" PRIMARY KEY ("id")
);

-- CreateTable
CREATE TABLE "AlerteSOS" (
    "id" TEXT NOT NULL,
    "pelerinId" TEXT NOT NULL,
    "latitude" DOUBLE PRECISION NOT NULL,
    "longitude" DOUBLE PRECISION NOT NULL,
    "statut" "StatutAlerte" NOT NULL DEFAULT 'EN_COURS',
    "message" TEXT,
    "createdAt" TIMESTAMP(3) NOT NULL DEFAULT CURRENT_TIMESTAMP,
    "resolueAt" TIMESTAMP(3),
    "resolueParGuideId" TEXT,

    CONSTRAINT "AlerteSOS_pkey" PRIMARY KEY ("id")
);

-- CreateTable
CREATE TABLE "Incident" (
    "id" TEXT NOT NULL,
    "alerteSOSId" TEXT,
    "groupeId" TEXT NOT NULL,
    "guideId" TEXT,
    "type" "TypeIncident" NOT NULL,
    "description" TEXT NOT NULL,
    "gravite" "Gravite" NOT NULL DEFAULT 'MOYENNE',
    "statut" "StatutAlerte" NOT NULL DEFAULT 'EN_COURS',
    "createdAt" TIMESTAMP(3) NOT NULL DEFAULT CURRENT_TIMESTAMP,
    "resolueAt" TIMESTAMP(3),

    CONSTRAINT "Incident_pkey" PRIMARY KEY ("id")
);

-- CreateIndex
CREATE INDEX "GroupeGuide_groupeId_actif_idx" ON "GroupeGuide"("groupeId", "actif");

-- CreateIndex
CREATE INDEX "GroupeGuide_guideId_actif_idx" ON "GroupeGuide"("guideId", "actif");

-- CreateIndex
CREATE INDEX "GroupePelerin_groupeId_actif_idx" ON "GroupePelerin"("groupeId", "actif");

-- CreateIndex
CREATE INDEX "GroupePelerin_pelerinId_actif_idx" ON "GroupePelerin"("pelerinId", "actif");

-- CreateIndex
CREATE INDEX "EtapeValideeGroupe_groupeId_idx" ON "EtapeValideeGroupe"("groupeId");

-- CreateIndex
CREATE INDEX "EtapeValideeGroupe_valideParGuideId_idx" ON "EtapeValideeGroupe"("valideParGuideId");

-- CreateIndex
CREATE UNIQUE INDEX "EtapeValideeGroupe_groupeId_etape_key" ON "EtapeValideeGroupe"("groupeId", "etape");

-- CreateIndex
CREATE INDEX "AppelPresence_groupeId_idx" ON "AppelPresence"("groupeId");

-- CreateIndex
CREATE INDEX "AppelPresence_guideId_idx" ON "AppelPresence"("guideId");

-- CreateIndex
CREATE INDEX "AppelPresence_date_idx" ON "AppelPresence"("date");

-- CreateIndex
CREATE INDEX "ConfirmationPresence_appelPresenceId_idx" ON "ConfirmationPresence"("appelPresenceId");

-- CreateIndex
CREATE INDEX "ConfirmationPresence_pelerinId_idx" ON "ConfirmationPresence"("pelerinId");

-- CreateIndex
CREATE UNIQUE INDEX "ConfirmationPresence_appelPresenceId_pelerinId_key" ON "ConfirmationPresence"("appelPresenceId", "pelerinId");

-- CreateIndex
CREATE INDEX "Position_pelerinId_createdAt_idx" ON "Position"("pelerinId", "createdAt");

-- CreateIndex
CREATE INDEX "AlerteSOS_pelerinId_idx" ON "AlerteSOS"("pelerinId");

-- CreateIndex
CREATE INDEX "AlerteSOS_statut_idx" ON "AlerteSOS"("statut");

-- CreateIndex
CREATE INDEX "AlerteSOS_resolueParGuideId_idx" ON "AlerteSOS"("resolueParGuideId");

-- CreateIndex
CREATE INDEX "Incident_alerteSOSId_idx" ON "Incident"("alerteSOSId");

-- CreateIndex
CREATE INDEX "Incident_groupeId_idx" ON "Incident"("groupeId");

-- CreateIndex
CREATE INDEX "Incident_guideId_idx" ON "Incident"("guideId");

-- CreateIndex
CREATE INDEX "Incident_statut_idx" ON "Incident"("statut");

-- CreateIndex
CREATE INDEX "AgenceVoyage_status_idx" ON "AgenceVoyage"("status");

-- CreateIndex
CREATE INDEX "EvenementPlanning_planningQuotidienId_idx" ON "EvenementPlanning"("planningQuotidienId");

-- CreateIndex
CREATE INDEX "EvenementPlanning_statut_idx" ON "EvenementPlanning"("statut");

-- CreateIndex
CREATE INDEX "EvenementPlanning_updatedByGuideId_idx" ON "EvenementPlanning"("updatedByGuideId");

-- CreateIndex
CREATE INDEX "FamillePelerin_familleId_idx" ON "FamillePelerin"("familleId");

-- CreateIndex
CREATE INDEX "FamillePelerin_pelerinId_idx" ON "FamillePelerin"("pelerinId");

-- CreateIndex
CREATE INDEX "Groupe_agenceId_idx" ON "Groupe"("agenceId");

-- CreateIndex
CREATE INDEX "Groupe_annee_idx" ON "Groupe"("annee");

-- CreateIndex
CREATE INDEX "Groupe_status_idx" ON "Groupe"("status");

-- CreateIndex
CREATE INDEX "Groupe_guideId_idx" ON "Groupe"("guideId");

-- CreateIndex
CREATE INDEX "Guide_agenceId_idx" ON "Guide"("agenceId");

-- CreateIndex
CREATE INDEX "PasswordToken_utilisateurId_idx" ON "PasswordToken"("utilisateurId");

-- CreateIndex
CREATE INDEX "Pelerin_agenceId_idx" ON "Pelerin"("agenceId");

-- CreateIndex
CREATE INDEX "Pelerin_groupeId_idx" ON "Pelerin"("groupeId");

-- CreateIndex
CREATE INDEX "PlanningQuotidien_groupeId_date_idx" ON "PlanningQuotidien"("groupeId", "date");

-- CreateIndex
CREATE INDEX "RefreshToken_utilisateurId_idx" ON "RefreshToken"("utilisateurId");

-- CreateIndex
CREATE INDEX "Utilisateur_role_idx" ON "Utilisateur"("role");

-- AddForeignKey
ALTER TABLE "GroupeGuide" ADD CONSTRAINT "GroupeGuide_groupeId_fkey" FOREIGN KEY ("groupeId") REFERENCES "Groupe"("id") ON DELETE CASCADE ON UPDATE CASCADE;

-- AddForeignKey
ALTER TABLE "GroupeGuide" ADD CONSTRAINT "GroupeGuide_guideId_fkey" FOREIGN KEY ("guideId") REFERENCES "Guide"("id") ON DELETE CASCADE ON UPDATE CASCADE;

-- AddForeignKey
ALTER TABLE "GroupePelerin" ADD CONSTRAINT "GroupePelerin_groupeId_fkey" FOREIGN KEY ("groupeId") REFERENCES "Groupe"("id") ON DELETE CASCADE ON UPDATE CASCADE;

-- AddForeignKey
ALTER TABLE "GroupePelerin" ADD CONSTRAINT "GroupePelerin_pelerinId_fkey" FOREIGN KEY ("pelerinId") REFERENCES "Pelerin"("id") ON DELETE CASCADE ON UPDATE CASCADE;

-- AddForeignKey
ALTER TABLE "EtapeValideeGroupe" ADD CONSTRAINT "EtapeValideeGroupe_groupeId_fkey" FOREIGN KEY ("groupeId") REFERENCES "Groupe"("id") ON DELETE CASCADE ON UPDATE CASCADE;

-- AddForeignKey
ALTER TABLE "EtapeValideeGroupe" ADD CONSTRAINT "EtapeValideeGroupe_valideParGuideId_fkey" FOREIGN KEY ("valideParGuideId") REFERENCES "Guide"("id") ON DELETE SET NULL ON UPDATE CASCADE;

-- AddForeignKey
ALTER TABLE "EvenementPlanning" ADD CONSTRAINT "EvenementPlanning_updatedByGuideId_fkey" FOREIGN KEY ("updatedByGuideId") REFERENCES "Guide"("id") ON DELETE SET NULL ON UPDATE CASCADE;

-- AddForeignKey
ALTER TABLE "AppelPresence" ADD CONSTRAINT "AppelPresence_groupeId_fkey" FOREIGN KEY ("groupeId") REFERENCES "Groupe"("id") ON DELETE RESTRICT ON UPDATE CASCADE;

-- AddForeignKey
ALTER TABLE "AppelPresence" ADD CONSTRAINT "AppelPresence_guideId_fkey" FOREIGN KEY ("guideId") REFERENCES "Guide"("id") ON DELETE RESTRICT ON UPDATE CASCADE;

-- AddForeignKey
ALTER TABLE "ConfirmationPresence" ADD CONSTRAINT "ConfirmationPresence_appelPresenceId_fkey" FOREIGN KEY ("appelPresenceId") REFERENCES "AppelPresence"("id") ON DELETE CASCADE ON UPDATE CASCADE;

-- AddForeignKey
ALTER TABLE "ConfirmationPresence" ADD CONSTRAINT "ConfirmationPresence_pelerinId_fkey" FOREIGN KEY ("pelerinId") REFERENCES "Pelerin"("id") ON DELETE RESTRICT ON UPDATE CASCADE;

-- AddForeignKey
ALTER TABLE "Position" ADD CONSTRAINT "Position_pelerinId_fkey" FOREIGN KEY ("pelerinId") REFERENCES "Pelerin"("id") ON DELETE CASCADE ON UPDATE CASCADE;

-- AddForeignKey
ALTER TABLE "AlerteSOS" ADD CONSTRAINT "AlerteSOS_pelerinId_fkey" FOREIGN KEY ("pelerinId") REFERENCES "Pelerin"("id") ON DELETE CASCADE ON UPDATE CASCADE;

-- AddForeignKey
ALTER TABLE "AlerteSOS" ADD CONSTRAINT "AlerteSOS_resolueParGuideId_fkey" FOREIGN KEY ("resolueParGuideId") REFERENCES "Guide"("id") ON DELETE SET NULL ON UPDATE CASCADE;

-- AddForeignKey
ALTER TABLE "Incident" ADD CONSTRAINT "Incident_alerteSOSId_fkey" FOREIGN KEY ("alerteSOSId") REFERENCES "AlerteSOS"("id") ON DELETE SET NULL ON UPDATE CASCADE;

-- AddForeignKey
ALTER TABLE "Incident" ADD CONSTRAINT "Incident_groupeId_fkey" FOREIGN KEY ("groupeId") REFERENCES "Groupe"("id") ON DELETE RESTRICT ON UPDATE CASCADE;

-- AddForeignKey
ALTER TABLE "Incident" ADD CONSTRAINT "Incident_guideId_fkey" FOREIGN KEY ("guideId") REFERENCES "Guide"("id") ON DELETE SET NULL ON UPDATE CASCADE;
