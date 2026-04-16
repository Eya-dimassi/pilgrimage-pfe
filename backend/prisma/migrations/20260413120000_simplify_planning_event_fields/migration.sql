ALTER TABLE "EvenementPlanning"
DROP CONSTRAINT IF EXISTS "EvenementPlanning_updatedByGuideId_fkey";

DROP INDEX IF EXISTS "EvenementPlanning_statut_idx";
DROP INDEX IF EXISTS "EvenementPlanning_updatedByGuideId_idx";

ALTER TABLE "EvenementPlanning"
DROP COLUMN IF EXISTS "heureFinPrevue",
DROP COLUMN IF EXISTS "heureDebutReelle",
DROP COLUMN IF EXISTS "heureFinReelle",
DROP COLUMN IF EXISTS "statut",
DROP COLUMN IF EXISTS "noteChangement",
DROP COLUMN IF EXISTS "updatedByGuideId";

DROP TYPE IF EXISTS "StatutEvenement";
