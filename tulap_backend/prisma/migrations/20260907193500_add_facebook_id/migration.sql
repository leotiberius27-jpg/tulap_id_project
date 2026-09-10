-- AlterTable
ALTER TABLE "users" ADD COLUMN "facebook_id" TEXT;

-- CreateIndex
CREATE UNIQUE INDEX "users_facebook_id_key" ON "users"("facebook_id");
