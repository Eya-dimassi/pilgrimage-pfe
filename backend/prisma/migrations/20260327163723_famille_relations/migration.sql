/*
  Warnings:

  - Added the required column `agenceId` to the `Famille` table without a default value. This is not possible if the table is not empty.

*/
-- AlterTable
ALTER TABLE "Famille" ADD COLUMN     "agenceId" TEXT NOT NULL;

-- CreateIndex
CREATE INDEX "Famille_agenceId_idx" ON "Famille"("agenceId");

-- AddForeignKey
ALTER TABLE "Famille" ADD CONSTRAINT "Famille_agenceId_fkey" FOREIGN KEY ("agenceId") REFERENCES "AgenceVoyage"("id") ON DELETE RESTRICT ON UPDATE CASCADE;
