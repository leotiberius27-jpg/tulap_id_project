-- CreateEnum
CREATE TYPE "plan_code" AS ENUM ('GRATIS', 'BASIC', 'PRO', 'PRO_PLUS');

-- CreateEnum
CREATE TYPE "billing_cycle" AS ENUM ('MONTHLY', 'ANNUAL');

-- CreateEnum
CREATE TYPE "subscription_status" AS ENUM ('ACTIVE', 'INACTIVE', 'EXPIRED', 'CANCELLED');

-- CreateEnum
CREATE TYPE "subscription_owner_type" AS ENUM ('PERSONAL');

-- CreateEnum
CREATE TYPE "payment_method" AS ENUM ('QRIS', 'VA');

-- CreateEnum
CREATE TYPE "payment_transaction_status" AS ENUM ('CREATED', 'PENDING', 'PAID', 'EXPIRED', 'FAILED', 'CANCELLED', 'REFUNDED');

-- CreateTable
CREATE TABLE "subscriptions" (
    "id" TEXT NOT NULL,
    "owner_type" "subscription_owner_type" NOT NULL DEFAULT 'PERSONAL',
    "user_id" TEXT NOT NULL,
    "plan_code" "plan_code" NOT NULL DEFAULT 'GRATIS',
    "billing_cycle" "billing_cycle" NOT NULL DEFAULT 'MONTHLY',
    "status" "subscription_status" NOT NULL DEFAULT 'ACTIVE',
    "current_period_start" TIMESTAMP(3) NOT NULL,
    "current_period_end" TIMESTAMP(3) NOT NULL,
    "created_at" TIMESTAMP(3) NOT NULL DEFAULT CURRENT_TIMESTAMP,
    "updated_at" TIMESTAMP(3) NOT NULL,

    CONSTRAINT "subscriptions_pkey" PRIMARY KEY ("id")
);

-- CreateTable
CREATE TABLE "payment_transactions" (
    "id" TEXT NOT NULL,
    "public_reference" TEXT NOT NULL,
    "user_id" TEXT NOT NULL,
    "subscription_id" TEXT,
    "plan_code" "plan_code" NOT NULL,
    "billing_cycle" "billing_cycle" NOT NULL,
    "amount" INTEGER NOT NULL,
    "currency" TEXT NOT NULL DEFAULT 'IDR',
    "payment_method" "payment_method" NOT NULL,
    "provider" TEXT NOT NULL,
    "provider_transaction_id" TEXT,
    "provider_reference" TEXT,
    "va_bank" TEXT,
    "va_number" TEXT,
    "qr_string" TEXT,
    "status" "payment_transaction_status" NOT NULL DEFAULT 'CREATED',
    "checkout_attempt_id" TEXT NOT NULL,
    "settlement_status" TEXT,
    "settlement_reference" TEXT,
    "settled_at" TIMESTAMP(3),
    "created_at" TIMESTAMP(3) NOT NULL DEFAULT CURRENT_TIMESTAMP,
    "updated_at" TIMESTAMP(3) NOT NULL,
    "expires_at" TIMESTAMP(3),
    "paid_at" TIMESTAMP(3),
    "failed_at" TIMESTAMP(3),
    "cancelled_at" TIMESTAMP(3),
    "refunded_at" TIMESTAMP(3),

    CONSTRAINT "payment_transactions_pkey" PRIMARY KEY ("id")
);

-- CreateTable
CREATE TABLE "processed_webhook_events" (
    "id" TEXT NOT NULL,
    "provider" TEXT NOT NULL,
    "event_id" TEXT NOT NULL,
    "received_at" TIMESTAMP(3) NOT NULL DEFAULT CURRENT_TIMESTAMP,

    CONSTRAINT "processed_webhook_events_pkey" PRIMARY KEY ("id")
);

-- CreateIndex
CREATE UNIQUE INDEX "subscriptions_user_id_key" ON "subscriptions"("user_id");

-- CreateIndex
CREATE INDEX "subscriptions_user_id_idx" ON "subscriptions"("user_id");

-- CreateIndex
CREATE UNIQUE INDEX "payment_transactions_public_reference_key" ON "payment_transactions"("public_reference");

-- CreateIndex
CREATE UNIQUE INDEX "payment_transactions_checkout_attempt_id_key" ON "payment_transactions"("checkout_attempt_id");

-- CreateIndex
CREATE INDEX "payment_transactions_user_id_idx" ON "payment_transactions"("user_id");

-- CreateIndex
CREATE INDEX "payment_transactions_status_idx" ON "payment_transactions"("status");

-- CreateIndex
CREATE UNIQUE INDEX "processed_webhook_events_provider_event_id_key" ON "processed_webhook_events"("provider", "event_id");

-- AddForeignKey
ALTER TABLE "subscriptions" ADD CONSTRAINT "subscriptions_user_id_fkey" FOREIGN KEY ("user_id") REFERENCES "users"("id") ON DELETE CASCADE ON UPDATE CASCADE;

-- AddForeignKey
ALTER TABLE "payment_transactions" ADD CONSTRAINT "payment_transactions_user_id_fkey" FOREIGN KEY ("user_id") REFERENCES "users"("id") ON DELETE RESTRICT ON UPDATE CASCADE;

-- AddForeignKey
ALTER TABLE "payment_transactions" ADD CONSTRAINT "payment_transactions_subscription_id_fkey" FOREIGN KEY ("subscription_id") REFERENCES "subscriptions"("id") ON DELETE SET NULL ON UPDATE CASCADE;

