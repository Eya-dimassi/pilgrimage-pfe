CREATE TABLE "DeviceToken" (
    "id" TEXT NOT NULL,
    "utilisateurId" TEXT NOT NULL,
    "token" TEXT NOT NULL,
    "platform" TEXT NOT NULL,
    "createdAt" TIMESTAMP(3) NOT NULL DEFAULT CURRENT_TIMESTAMP,
    "updatedAt" TIMESTAMP(3) NOT NULL,
    "lastSeenAt" TIMESTAMP(3) NOT NULL DEFAULT CURRENT_TIMESTAMP,

    CONSTRAINT "DeviceToken_pkey" PRIMARY KEY ("id")
);

CREATE UNIQUE INDEX "DeviceToken_token_key" ON "DeviceToken"("token");
CREATE INDEX "DeviceToken_utilisateurId_idx" ON "DeviceToken"("utilisateurId");
CREATE INDEX "DeviceToken_platform_idx" ON "DeviceToken"("platform");

ALTER TABLE "DeviceToken"
ADD CONSTRAINT "DeviceToken_utilisateurId_fkey"
FOREIGN KEY ("utilisateurId") REFERENCES "Utilisateur"("id")
ON DELETE CASCADE ON UPDATE CASCADE;
