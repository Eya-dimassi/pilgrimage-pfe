ALTER TABLE "AlerteSOS"
ADD COLUMN IF NOT EXISTS "groupeId" TEXT,
ADD COLUMN IF NOT EXISTS "type" "TypeIncident" NOT NULL DEFAULT 'AUTRE',
ADD COLUMN IF NOT EXISTS "description" TEXT;

UPDATE "AlerteSOS" AS a
SET
  "groupeId" = i."groupeId",
  "type" = i."type",
  "description" = i."description"
FROM "Incident" AS i
WHERE i."alerteSOSId" = a."id";

UPDATE "AlerteSOS" AS a
SET "groupeId" = gp."groupeId"
FROM (
  SELECT DISTINCT ON ("pelerinId")
    "pelerinId",
    "groupeId"
  FROM "GroupePelerin"
  ORDER BY "pelerinId", "actif" DESC, "dateDebut" DESC
) AS gp
WHERE a."groupeId" IS NULL
  AND gp."pelerinId" = a."pelerinId";

DO $$
BEGIN
  IF EXISTS (
    SELECT 1
    FROM "AlerteSOS"
    WHERE "groupeId" IS NULL
  ) THEN
    RAISE EXCEPTION 'Cannot make AlerteSOS.groupeId NOT NULL because some rows could not be backfilled.';
  END IF;
END $$;

ALTER TABLE "AlerteSOS"
ALTER COLUMN "groupeId" SET NOT NULL;

CREATE INDEX IF NOT EXISTS "AlerteSOS_groupeId_idx" ON "AlerteSOS"("groupeId");

DO $$
BEGIN
  IF NOT EXISTS (
    SELECT 1
    FROM pg_constraint
    WHERE conname = 'AlerteSOS_groupeId_fkey'
  ) THEN
    ALTER TABLE "AlerteSOS"
    ADD CONSTRAINT "AlerteSOS_groupeId_fkey"
    FOREIGN KEY ("groupeId") REFERENCES "Groupe"("id") ON DELETE RESTRICT ON UPDATE CASCADE;
  END IF;
END $$;

DROP TABLE IF EXISTS "Incident";
