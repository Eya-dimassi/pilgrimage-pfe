-- CreateEnum
CREATE TYPE "StatutEvenement" AS ENUM ('PLANIFIE', 'EN_COURS', 'TERMINE', 'ANNULE');

-- AlterTable
ALTER TABLE "EvenementPlanning" ADD COLUMN     "status" "StatutEvenement" NOT NULL DEFAULT 'PLANIFIE';
