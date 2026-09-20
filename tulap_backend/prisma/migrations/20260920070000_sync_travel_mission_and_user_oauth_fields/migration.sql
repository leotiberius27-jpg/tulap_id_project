-- CreateEnum
CREATE TYPE "travel_mission_status" AS ENUM ('DRAFT', 'PLANNED', 'ONGOING', 'COMPLETED', 'LPJ_INCOMPLETE', 'LPJ_READY', 'ARCHIVED');

-- AlterTable
ALTER TABLE "task_sppd" ADD COLUMN     "travel_mission_id" TEXT;

-- AlterTable
ALTER TABLE "users" ADD COLUMN     "apple_id" TEXT,
ADD COLUMN     "google_id" TEXT,
ADD COLUMN     "is_self_registered" BOOLEAN NOT NULL DEFAULT false,
ADD COLUMN     "password_reset_code_hash" TEXT,
ADD COLUMN     "password_reset_expires_at" TIMESTAMP(3),
ALTER COLUMN "password_hash" DROP NOT NULL;

-- CreateTable
CREATE TABLE "travel_missions" (
    "id" TEXT NOT NULL,
    "display_id" TEXT NOT NULL,
    "user_id" TEXT NOT NULL,
    "organization_id" TEXT,
    "assignment_letter_number" TEXT NOT NULL,
    "assignment_letter_date" TIMESTAMP(3) NOT NULL,
    "title" TEXT NOT NULL,
    "purpose" TEXT NOT NULL,
    "origin" TEXT NOT NULL,
    "destination" TEXT NOT NULL,
    "destinations" JSONB,
    "departure_date" TIMESTAMP(3) NOT NULL,
    "return_date" TIMESTAMP(3) NOT NULL,
    "transport_mode" TEXT NOT NULL,
    "transport_details" TEXT,
    "status" "travel_mission_status" NOT NULL DEFAULT 'DRAFT',
    "budget_estimate" JSONB,
    "notes" TEXT,
    "personnel_snapshot" JSONB,
    "created_at" TIMESTAMP(3) NOT NULL DEFAULT CURRENT_TIMESTAMP,
    "updated_at" TIMESTAMP(3) NOT NULL,

    CONSTRAINT "travel_missions_pkey" PRIMARY KEY ("id")
);

-- CreateTable
CREATE TABLE "supporting_documents" (
    "id" TEXT NOT NULL,
    "travel_mission_id" TEXT NOT NULL,
    "activity_id" TEXT,
    "document_type" TEXT NOT NULL,
    "title" TEXT NOT NULL,
    "document_url" TEXT NOT NULL,
    "sha256" TEXT NOT NULL,
    "created_at" TIMESTAMP(3) NOT NULL DEFAULT CURRENT_TIMESTAMP,
    "updated_at" TIMESTAMP(3) NOT NULL,

    CONSTRAINT "supporting_documents_pkey" PRIMARY KEY ("id")
);

-- CreateTable
CREATE TABLE "lpj_packages" (
    "id" TEXT NOT NULL,
    "travel_mission_id" TEXT NOT NULL,
    "package_code" TEXT NOT NULL,
    "version_number" INTEGER NOT NULL DEFAULT 1,
    "title" TEXT NOT NULL,
    "pdf_url" TEXT,
    "package_sha256" TEXT NOT NULL,
    "completeness_score" DECIMAL(5,2) NOT NULL,
    "total_actual_expense" DECIMAL(15,2) NOT NULL,
    "activity_count" INTEGER NOT NULL DEFAULT 0,
    "evidence_count" INTEGER NOT NULL DEFAULT 0,
    "receipt_count" INTEGER NOT NULL DEFAULT 0,
    "document_count" INTEGER NOT NULL DEFAULT 0,
    "content_snapshot" JSONB NOT NULL,
    "status" TEXT NOT NULL DEFAULT 'GENERATED',
    "created_at" TIMESTAMP(3) NOT NULL DEFAULT CURRENT_TIMESTAMP,
    "updated_at" TIMESTAMP(3) NOT NULL,

    CONSTRAINT "lpj_packages_pkey" PRIMARY KEY ("id")
);

-- CreateIndex
CREATE UNIQUE INDEX "travel_missions_display_id_key" ON "travel_missions"("display_id");

-- CreateIndex
CREATE INDEX "travel_missions_user_id_idx" ON "travel_missions"("user_id");

-- CreateIndex
CREATE INDEX "travel_missions_status_idx" ON "travel_missions"("status");

-- CreateIndex
CREATE INDEX "travel_missions_departure_date_return_date_idx" ON "travel_missions"("departure_date", "return_date");

-- CreateIndex
CREATE INDEX "supporting_documents_travel_mission_id_idx" ON "supporting_documents"("travel_mission_id");

-- CreateIndex
CREATE INDEX "supporting_documents_document_type_idx" ON "supporting_documents"("document_type");

-- CreateIndex
CREATE UNIQUE INDEX "lpj_packages_package_code_key" ON "lpj_packages"("package_code");

-- CreateIndex
CREATE INDEX "lpj_packages_travel_mission_id_idx" ON "lpj_packages"("travel_mission_id");

-- CreateIndex
CREATE INDEX "lpj_packages_package_code_idx" ON "lpj_packages"("package_code");

-- CreateIndex
CREATE INDEX "task_sppd_travel_mission_id_idx" ON "task_sppd"("travel_mission_id");

-- CreateIndex
CREATE UNIQUE INDEX "users_google_id_key" ON "users"("google_id");

-- CreateIndex
CREATE UNIQUE INDEX "users_apple_id_key" ON "users"("apple_id");

-- AddForeignKey
ALTER TABLE "task_sppd" ADD CONSTRAINT "task_sppd_travel_mission_id_fkey" FOREIGN KEY ("travel_mission_id") REFERENCES "travel_missions"("id") ON DELETE SET NULL ON UPDATE CASCADE;

-- AddForeignKey
ALTER TABLE "travel_missions" ADD CONSTRAINT "travel_missions_user_id_fkey" FOREIGN KEY ("user_id") REFERENCES "users"("id") ON DELETE RESTRICT ON UPDATE CASCADE;

-- AddForeignKey
ALTER TABLE "supporting_documents" ADD CONSTRAINT "supporting_documents_travel_mission_id_fkey" FOREIGN KEY ("travel_mission_id") REFERENCES "travel_missions"("id") ON DELETE CASCADE ON UPDATE CASCADE;

-- AddForeignKey
ALTER TABLE "lpj_packages" ADD CONSTRAINT "lpj_packages_travel_mission_id_fkey" FOREIGN KEY ("travel_mission_id") REFERENCES "travel_missions"("id") ON DELETE CASCADE ON UPDATE CASCADE;

