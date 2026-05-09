-- CreateEnum
CREATE TYPE "DisponibiliteGuide" AS ENUM ('DISPONIBLE', 'INDISPONIBLE');

-- AlterTable
ALTER TABLE "Guide" ADD COLUMN     "disponibilite" "DisponibiliteGuide" NOT NULL DEFAULT 'DISPONIBLE',
ADD COLUMN     "disponibiliteMajAt" TIMESTAMP(3);
