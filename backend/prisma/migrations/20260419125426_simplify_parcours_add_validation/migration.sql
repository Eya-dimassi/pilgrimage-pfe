/*
  Warnings:

  - You are about to drop the column `etapeActuelle` on the `Groupe` table. All the data in the column will be lost.
  - You are about to drop the `EtapeValideeGroupe` table. If the table is not empty, all the data it contains will be lost.

*/
-- DropForeignKey
ALTER TABLE "EtapeValideeGroupe" DROP CONSTRAINT "EtapeValideeGroupe_groupeId_fkey";

-- DropForeignKey
ALTER TABLE "EtapeValideeGroupe" DROP CONSTRAINT "EtapeValideeGroupe_valideParGuideId_fkey";

-- AlterTable
ALTER TABLE "EvenementPlanning" ADD COLUMN     "estValide" BOOLEAN NOT NULL DEFAULT false,
ADD COLUMN     "etape" "EtapeVoyage",
ADD COLUMN     "valideParGuideId" TEXT,
ADD COLUMN     "valideeAt" TIMESTAMP(3);

-- AlterTable
ALTER TABLE "Groupe" DROP COLUMN "etapeActuelle";

-- DropTable
DROP TABLE "EtapeValideeGroupe";

-- CreateIndex
CREATE INDEX "EvenementPlanning_valideParGuideId_idx" ON "EvenementPlanning"("valideParGuideId");

-- CreateIndex
CREATE INDEX "EvenementPlanning_etape_idx" ON "EvenementPlanning"("etape");

-- AddForeignKey
ALTER TABLE "EvenementPlanning" ADD CONSTRAINT "EvenementPlanning_valideParGuideId_fkey" FOREIGN KEY ("valideParGuideId") REFERENCES "Guide"("id") ON DELETE SET NULL ON UPDATE CASCADE;
