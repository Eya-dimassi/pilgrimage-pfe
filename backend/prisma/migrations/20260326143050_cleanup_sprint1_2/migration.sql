/*
  Warnings:

  - You are about to drop the column `guideId` on the `Groupe` table. All the data in the column will be lost.
  - You are about to drop the column `groupeId` on the `Pelerin` table. All the data in the column will be lost.
  - Made the column `codeUnique` on table `Pelerin` required. This step will fail if there are existing NULL values in that column.

*/
-- DropForeignKey
ALTER TABLE "Groupe" DROP CONSTRAINT "Groupe_guideId_fkey";

-- DropForeignKey
ALTER TABLE "Pelerin" DROP CONSTRAINT "Pelerin_groupeId_fkey";

-- DropIndex
DROP INDEX "Groupe_guideId_idx";

-- DropIndex
DROP INDEX "Pelerin_groupeId_idx";

-- AlterTable
ALTER TABLE "Groupe" DROP COLUMN "guideId";

-- AlterTable
ALTER TABLE "Pelerin" DROP COLUMN "groupeId",
ALTER COLUMN "codeUnique" SET NOT NULL;
