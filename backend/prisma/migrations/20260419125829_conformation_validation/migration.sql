-- DropIndex
DROP INDEX "Position_pelerinId_createdAt_idx";

-- CreateIndex
CREATE INDEX "Pelerin_statut_idx" ON "Pelerin"("statut");

-- CreateIndex
CREATE INDEX "Position_pelerinId_createdAt_idx" ON "Position"("pelerinId", "createdAt" DESC);
