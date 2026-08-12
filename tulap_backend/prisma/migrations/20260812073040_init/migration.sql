-- CreateEnum
CREATE TYPE "role_name" AS ENUM ('PEGAWAI', 'VERIFIKATOR', 'ADMIN', 'SUPER_ADMIN');

-- CreateEnum
CREATE TYPE "task_status" AS ENUM ('DRAFT', 'ONGOING', 'PENDING_VERIFICATION', 'REVISION_NEEDED', 'VERIFIED', 'REJECTED', 'COMPLETED');

-- CreateEnum
CREATE TYPE "expense_category" AS ENUM ('BBM', 'TOL', 'PENGINAPAN', 'RETAIL', 'KONSUMSI', 'TRANSPORTASI_LAIN', 'LAINNYA');

-- CreateEnum
CREATE TYPE "verification_status" AS ENUM ('PENDING', 'VERIFIED', 'REJECTED');

-- CreateTable
CREATE TABLE "roles" (
    "id" TEXT NOT NULL,
    "name" "role_name" NOT NULL,
    "description" TEXT,
    "created_at" TIMESTAMP(3) NOT NULL DEFAULT CURRENT_TIMESTAMP,
    "updated_at" TIMESTAMP(3) NOT NULL,

    CONSTRAINT "roles_pkey" PRIMARY KEY ("id")
);

-- CreateTable
CREATE TABLE "users" (
    "id" TEXT NOT NULL,
    "nip" TEXT,
    "full_name" TEXT NOT NULL,
    "email" TEXT NOT NULL,
    "phone_number" TEXT,
    "password_hash" TEXT NOT NULL,
    "instansi_name" TEXT,
    "unit_kerja" TEXT,
    "role_id" TEXT NOT NULL,
    "is_active" BOOLEAN NOT NULL DEFAULT true,
    "last_login_at" TIMESTAMP(3),
    "created_at" TIMESTAMP(3) NOT NULL DEFAULT CURRENT_TIMESTAMP,
    "updated_at" TIMESTAMP(3) NOT NULL,

    CONSTRAINT "users_pkey" PRIMARY KEY ("id")
);

-- CreateTable
CREATE TABLE "task_sppd" (
    "id" TEXT NOT NULL,
    "task_code" TEXT NOT NULL,
    "task_name" TEXT NOT NULL,
    "destination" TEXT NOT NULL,
    "description" TEXT,
    "start_date" TIMESTAMP(3) NOT NULL,
    "end_date" TIMESTAMP(3) NOT NULL,
    "budget_amount" DECIMAL(15,2) NOT NULL,
    "realized_amount" DECIMAL(15,2) NOT NULL DEFAULT 0,
    "status" "task_status" NOT NULL DEFAULT 'DRAFT',
    "assignee_id" TEXT NOT NULL,
    "creator_id" TEXT NOT NULL,
    "created_at" TIMESTAMP(3) NOT NULL DEFAULT CURRENT_TIMESTAMP,
    "updated_at" TIMESTAMP(3) NOT NULL,

    CONSTRAINT "task_sppd_pkey" PRIMARY KEY ("id")
);

-- CreateTable
CREATE TABLE "task_checklist_items" (
    "id" TEXT NOT NULL,
    "task_id" TEXT NOT NULL,
    "label" TEXT NOT NULL,
    "order" INTEGER NOT NULL,
    "is_mandatory" BOOLEAN NOT NULL DEFAULT true,
    "is_completed" BOOLEAN NOT NULL DEFAULT false,
    "completed_at" TIMESTAMP(3),
    "created_at" TIMESTAMP(3) NOT NULL DEFAULT CURRENT_TIMESTAMP,
    "updated_at" TIMESTAMP(3) NOT NULL,

    CONSTRAINT "task_checklist_items_pkey" PRIMARY KEY ("id")
);

-- CreateTable
CREATE TABLE "geotag_photos" (
    "id" TEXT NOT NULL,
    "task_id" TEXT NOT NULL,
    "uploader_id" TEXT NOT NULL,
    "photo_url" TEXT NOT NULL,
    "latitude" DECIMAL(10,7) NOT NULL,
    "longitude" DECIMAL(10,7) NOT NULL,
    "address" TEXT,
    "server_timestamp" TIMESTAMP(3) NOT NULL,
    "integrity_hash" TEXT NOT NULL,
    "is_mock_location_flag" BOOLEAN NOT NULL DEFAULT false,
    "is_rooted_device_flag" BOOLEAN NOT NULL DEFAULT false,
    "caption" TEXT,
    "created_at" TIMESTAMP(3) NOT NULL DEFAULT CURRENT_TIMESTAMP,

    CONSTRAINT "geotag_photos_pkey" PRIMARY KEY ("id")
);

-- CreateTable
CREATE TABLE "expense_notes" (
    "id" TEXT NOT NULL,
    "task_id" TEXT NOT NULL,
    "owner_id" TEXT NOT NULL,
    "scan_url" TEXT NOT NULL,
    "vendor_name" TEXT NOT NULL,
    "transaction_date" TIMESTAMP(3) NOT NULL,
    "total_amount" DECIMAL(15,2) NOT NULL,
    "category" "expense_category" NOT NULL,
    "ocr_raw_text" TEXT,
    "ocr_confidence" DECIMAL(5,2),
    "verification_status" "verification_status" NOT NULL DEFAULT 'PENDING',
    "verifier_id" TEXT,
    "verified_at" TIMESTAMP(3),
    "rejection_reason" TEXT,
    "created_at" TIMESTAMP(3) NOT NULL DEFAULT CURRENT_TIMESTAMP,
    "updated_at" TIMESTAMP(3) NOT NULL,

    CONSTRAINT "expense_notes_pkey" PRIMARY KEY ("id")
);

-- CreateIndex
CREATE UNIQUE INDEX "roles_name_key" ON "roles"("name");

-- CreateIndex
CREATE UNIQUE INDEX "users_nip_key" ON "users"("nip");

-- CreateIndex
CREATE UNIQUE INDEX "users_email_key" ON "users"("email");

-- CreateIndex
CREATE INDEX "users_role_id_idx" ON "users"("role_id");

-- CreateIndex
CREATE INDEX "users_email_idx" ON "users"("email");

-- CreateIndex
CREATE INDEX "users_is_active_idx" ON "users"("is_active");

-- CreateIndex
CREATE UNIQUE INDEX "task_sppd_task_code_key" ON "task_sppd"("task_code");

-- CreateIndex
CREATE INDEX "task_sppd_assignee_id_idx" ON "task_sppd"("assignee_id");

-- CreateIndex
CREATE INDEX "task_sppd_creator_id_idx" ON "task_sppd"("creator_id");

-- CreateIndex
CREATE INDEX "task_sppd_status_idx" ON "task_sppd"("status");

-- CreateIndex
CREATE INDEX "task_sppd_start_date_end_date_idx" ON "task_sppd"("start_date", "end_date");

-- CreateIndex
CREATE INDEX "task_checklist_items_task_id_idx" ON "task_checklist_items"("task_id");

-- CreateIndex
CREATE INDEX "geotag_photos_task_id_idx" ON "geotag_photos"("task_id");

-- CreateIndex
CREATE INDEX "geotag_photos_uploader_id_idx" ON "geotag_photos"("uploader_id");

-- CreateIndex
CREATE INDEX "geotag_photos_server_timestamp_idx" ON "geotag_photos"("server_timestamp");

-- CreateIndex
CREATE INDEX "expense_notes_task_id_idx" ON "expense_notes"("task_id");

-- CreateIndex
CREATE INDEX "expense_notes_owner_id_idx" ON "expense_notes"("owner_id");

-- CreateIndex
CREATE INDEX "expense_notes_verifier_id_idx" ON "expense_notes"("verifier_id");

-- CreateIndex
CREATE INDEX "expense_notes_verification_status_idx" ON "expense_notes"("verification_status");

-- CreateIndex
CREATE INDEX "expense_notes_transaction_date_idx" ON "expense_notes"("transaction_date");

-- CreateIndex
CREATE INDEX "expense_notes_category_idx" ON "expense_notes"("category");

-- AddForeignKey
ALTER TABLE "users" ADD CONSTRAINT "users_role_id_fkey" FOREIGN KEY ("role_id") REFERENCES "roles"("id") ON DELETE RESTRICT ON UPDATE CASCADE;

-- AddForeignKey
ALTER TABLE "task_sppd" ADD CONSTRAINT "task_sppd_assignee_id_fkey" FOREIGN KEY ("assignee_id") REFERENCES "users"("id") ON DELETE RESTRICT ON UPDATE CASCADE;

-- AddForeignKey
ALTER TABLE "task_sppd" ADD CONSTRAINT "task_sppd_creator_id_fkey" FOREIGN KEY ("creator_id") REFERENCES "users"("id") ON DELETE RESTRICT ON UPDATE CASCADE;

-- AddForeignKey
ALTER TABLE "task_checklist_items" ADD CONSTRAINT "task_checklist_items_task_id_fkey" FOREIGN KEY ("task_id") REFERENCES "task_sppd"("id") ON DELETE CASCADE ON UPDATE CASCADE;

-- AddForeignKey
ALTER TABLE "geotag_photos" ADD CONSTRAINT "geotag_photos_task_id_fkey" FOREIGN KEY ("task_id") REFERENCES "task_sppd"("id") ON DELETE CASCADE ON UPDATE CASCADE;

-- AddForeignKey
ALTER TABLE "geotag_photos" ADD CONSTRAINT "geotag_photos_uploader_id_fkey" FOREIGN KEY ("uploader_id") REFERENCES "users"("id") ON DELETE RESTRICT ON UPDATE CASCADE;

-- AddForeignKey
ALTER TABLE "expense_notes" ADD CONSTRAINT "expense_notes_task_id_fkey" FOREIGN KEY ("task_id") REFERENCES "task_sppd"("id") ON DELETE CASCADE ON UPDATE CASCADE;

-- AddForeignKey
ALTER TABLE "expense_notes" ADD CONSTRAINT "expense_notes_owner_id_fkey" FOREIGN KEY ("owner_id") REFERENCES "users"("id") ON DELETE RESTRICT ON UPDATE CASCADE;

-- AddForeignKey
ALTER TABLE "expense_notes" ADD CONSTRAINT "expense_notes_verifier_id_fkey" FOREIGN KEY ("verifier_id") REFERENCES "users"("id") ON DELETE SET NULL ON UPDATE CASCADE;
