-- CreateEnum
CREATE TYPE "Role" AS ENUM ('PELERIN', 'GUIDE', 'AGENCE', 'FAMILLE', 'SUPER_ADMIN');

-- CreateEnum
CREATE TYPE "TypeVoyage" AS ENUM ('HAJJ', 'UMRAH');

-- CreateEnum
CREATE TYPE "EtapeHajj" AS ENUM ('IHRAM', 'ARRIVEE_MECQUE', 'TAWAF', 'SAI', 'ARAFAT', 'MUZDALIFA', 'MINA', 'RAMI_JAMARAT', 'TAWAF_IFADA');

-- CreateEnum
CREATE TYPE "TypeEvenement" AS ENUM ('PRIERE', 'TRANSPORT', 'REPAS', 'RITE', 'REPOS', 'AUTRE');

-- CreateTable
CREATE TABLE "Utilisateur" (
    "id" TEXT NOT NULL,
    "email" TEXT NOT NULL,
    "motDePasse" TEXT NOT NULL,
    "nom" TEXT NOT NULL,
    "prenom" TEXT NOT NULL,
    "telephone" TEXT,
    "role" "Role" NOT NULL,
    "actif" BOOLEAN NOT NULL DEFAULT true,
    "createdAt" TIMESTAMP(3) NOT NULL DEFAULT CURRENT_TIMESTAMP,
    "updatedAt" TIMESTAMP(3) NOT NULL,
    "createdById" TEXT,

    CONSTRAINT "Utilisateur_pkey" PRIMARY KEY ("id")
);

-- CreateTable
CREATE TABLE "RefreshToken" (
    "id" TEXT NOT NULL,
    "token" TEXT NOT NULL,
    "utilisateurId" TEXT NOT NULL,
    "expiresAt" TIMESTAMP(3) NOT NULL,
    "createdAt" TIMESTAMP(3) NOT NULL DEFAULT CURRENT_TIMESTAMP,

    CONSTRAINT "RefreshToken_pkey" PRIMARY KEY ("id")
);

-- CreateTable
CREATE TABLE "AgenceVoyage" (
    "id" TEXT NOT NULL,
    "utilisateurId" TEXT NOT NULL,
    "nomAgence" TEXT NOT NULL,
    "adresse" TEXT,
    "siteWeb" TEXT,
    "logo" TEXT,
    "createdAt" TIMESTAMP(3) NOT NULL DEFAULT CURRENT_TIMESTAMP,
    "updatedAt" TIMESTAMP(3) NOT NULL,

    CONSTRAINT "AgenceVoyage_pkey" PRIMARY KEY ("id")
);

-- CreateTable
CREATE TABLE "Guide" (
    "id" TEXT NOT NULL,
    "utilisateurId" TEXT NOT NULL,
    "agenceId" TEXT NOT NULL,
    "specialite" TEXT,
    "createdAt" TIMESTAMP(3) NOT NULL DEFAULT CURRENT_TIMESTAMP,
    "updatedAt" TIMESTAMP(3) NOT NULL,

    CONSTRAINT "Guide_pkey" PRIMARY KEY ("id")
);

-- CreateTable
CREATE TABLE "Groupe" (
    "id" TEXT NOT NULL,
    "nom" TEXT NOT NULL,
    "description" TEXT,
    "annee" INTEGER NOT NULL,
    "typeVoyage" "TypeVoyage" NOT NULL DEFAULT 'HAJJ',
    "agenceId" TEXT NOT NULL,
    "guideId" TEXT,
    "createdAt" TIMESTAMP(3) NOT NULL DEFAULT CURRENT_TIMESTAMP,
    "updatedAt" TIMESTAMP(3) NOT NULL,

    CONSTRAINT "Groupe_pkey" PRIMARY KEY ("id")
);

-- CreateTable
CREATE TABLE "Pelerin" (
    "id" TEXT NOT NULL,
    "utilisateurId" TEXT NOT NULL,
    "codeUnique" TEXT,
    "agenceId" TEXT NOT NULL,
    "groupeId" TEXT,
    "dateNaissance" TIMESTAMP(3),
    "nationalite" TEXT,
    "numeroPasseport" TEXT,
    "photoUrl" TEXT,
    "etapeActuelle" "EtapeHajj",
    "createdAt" TIMESTAMP(3) NOT NULL DEFAULT CURRENT_TIMESTAMP,
    "updatedAt" TIMESTAMP(3) NOT NULL,

    CONSTRAINT "Pelerin_pkey" PRIMARY KEY ("id")
);

-- CreateTable
CREATE TABLE "EtapeValidee" (
    "id" TEXT NOT NULL,
    "pelerinId" TEXT NOT NULL,
    "etape" "EtapeHajj" NOT NULL,
    "valideeAt" TIMESTAMP(3) NOT NULL DEFAULT CURRENT_TIMESTAMP,
    "note" TEXT,

    CONSTRAINT "EtapeValidee_pkey" PRIMARY KEY ("id")
);

-- CreateTable
CREATE TABLE "PlanningQuotidien" (
    "id" TEXT NOT NULL,
    "groupeId" TEXT NOT NULL,
    "date" TIMESTAMP(3) NOT NULL,
    "titre" TEXT,
    "createdAt" TIMESTAMP(3) NOT NULL DEFAULT CURRENT_TIMESTAMP,
    "updatedAt" TIMESTAMP(3) NOT NULL,

    CONSTRAINT "PlanningQuotidien_pkey" PRIMARY KEY ("id")
);

-- CreateTable
CREATE TABLE "EvenementPlanning" (
    "id" TEXT NOT NULL,
    "planningQuotidienId" TEXT NOT NULL,
    "type" "TypeEvenement" NOT NULL,
    "titre" TEXT NOT NULL,
    "description" TEXT,
    "heureDebut" TIMESTAMP(3) NOT NULL,
    "heureFin" TIMESTAMP(3),
    "lieu" TEXT,
    "createdAt" TIMESTAMP(3) NOT NULL DEFAULT CURRENT_TIMESTAMP,

    CONSTRAINT "EvenementPlanning_pkey" PRIMARY KEY ("id")
);

-- CreateIndex
CREATE UNIQUE INDEX "Utilisateur_email_key" ON "Utilisateur"("email");

-- CreateIndex
CREATE UNIQUE INDEX "RefreshToken_token_key" ON "RefreshToken"("token");

-- CreateIndex
CREATE UNIQUE INDEX "AgenceVoyage_utilisateurId_key" ON "AgenceVoyage"("utilisateurId");

-- CreateIndex
CREATE UNIQUE INDEX "Guide_utilisateurId_key" ON "Guide"("utilisateurId");

-- CreateIndex
CREATE UNIQUE INDEX "Pelerin_utilisateurId_key" ON "Pelerin"("utilisateurId");

-- CreateIndex
CREATE UNIQUE INDEX "Pelerin_codeUnique_key" ON "Pelerin"("codeUnique");

-- CreateIndex
CREATE UNIQUE INDEX "EtapeValidee_pelerinId_etape_key" ON "EtapeValidee"("pelerinId", "etape");

-- CreateIndex
CREATE UNIQUE INDEX "PlanningQuotidien_groupeId_date_key" ON "PlanningQuotidien"("groupeId", "date");

-- AddForeignKey
ALTER TABLE "RefreshToken" ADD CONSTRAINT "RefreshToken_utilisateurId_fkey" FOREIGN KEY ("utilisateurId") REFERENCES "Utilisateur"("id") ON DELETE CASCADE ON UPDATE CASCADE;

-- AddForeignKey
ALTER TABLE "AgenceVoyage" ADD CONSTRAINT "AgenceVoyage_utilisateurId_fkey" FOREIGN KEY ("utilisateurId") REFERENCES "Utilisateur"("id") ON DELETE CASCADE ON UPDATE CASCADE;

-- AddForeignKey
ALTER TABLE "Guide" ADD CONSTRAINT "Guide_utilisateurId_fkey" FOREIGN KEY ("utilisateurId") REFERENCES "Utilisateur"("id") ON DELETE CASCADE ON UPDATE CASCADE;

-- AddForeignKey
ALTER TABLE "Guide" ADD CONSTRAINT "Guide_agenceId_fkey" FOREIGN KEY ("agenceId") REFERENCES "AgenceVoyage"("id") ON DELETE RESTRICT ON UPDATE CASCADE;

-- AddForeignKey
ALTER TABLE "Groupe" ADD CONSTRAINT "Groupe_agenceId_fkey" FOREIGN KEY ("agenceId") REFERENCES "AgenceVoyage"("id") ON DELETE RESTRICT ON UPDATE CASCADE;

-- AddForeignKey
ALTER TABLE "Groupe" ADD CONSTRAINT "Groupe_guideId_fkey" FOREIGN KEY ("guideId") REFERENCES "Guide"("id") ON DELETE SET NULL ON UPDATE CASCADE;

-- AddForeignKey
ALTER TABLE "Pelerin" ADD CONSTRAINT "Pelerin_utilisateurId_fkey" FOREIGN KEY ("utilisateurId") REFERENCES "Utilisateur"("id") ON DELETE CASCADE ON UPDATE CASCADE;

-- AddForeignKey
ALTER TABLE "Pelerin" ADD CONSTRAINT "Pelerin_agenceId_fkey" FOREIGN KEY ("agenceId") REFERENCES "AgenceVoyage"("id") ON DELETE RESTRICT ON UPDATE CASCADE;

-- AddForeignKey
ALTER TABLE "Pelerin" ADD CONSTRAINT "Pelerin_groupeId_fkey" FOREIGN KEY ("groupeId") REFERENCES "Groupe"("id") ON DELETE SET NULL ON UPDATE CASCADE;

-- AddForeignKey
ALTER TABLE "EtapeValidee" ADD CONSTRAINT "EtapeValidee_pelerinId_fkey" FOREIGN KEY ("pelerinId") REFERENCES "Pelerin"("id") ON DELETE CASCADE ON UPDATE CASCADE;

-- AddForeignKey
ALTER TABLE "PlanningQuotidien" ADD CONSTRAINT "PlanningQuotidien_groupeId_fkey" FOREIGN KEY ("groupeId") REFERENCES "Groupe"("id") ON DELETE CASCADE ON UPDATE CASCADE;

-- AddForeignKey
ALTER TABLE "EvenementPlanning" ADD CONSTRAINT "EvenementPlanning_planningQuotidienId_fkey" FOREIGN KEY ("planningQuotidienId") REFERENCES "PlanningQuotidien"("id") ON DELETE CASCADE ON UPDATE CASCADE;
