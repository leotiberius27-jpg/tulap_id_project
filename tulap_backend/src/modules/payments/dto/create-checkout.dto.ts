import { BillingCycle, PaymentMethod, PlanCode } from '@prisma/client';
import { IsEnum, IsNotEmpty, IsOptional, IsString } from 'class-validator';

/// CreateCheckoutDto
/// ----------------------------------------------------------------------
/// SENGAJA TIDAK punya field `amount` - harga SELALU dihitung server
/// dari plan-catalog.ts (Bagian 8 instruksi payment). `whitelist: true` +
/// `forbidNonWhitelisted: true` di main.ts akan menolak request yang
/// mencoba menyertakan `amount` sama sekali (400 Bad Request), bukan
/// diam-diam mengabaikannya.
/// ----------------------------------------------------------------------
export class CreateCheckoutDto {
  @IsEnum(PlanCode)
  @IsNotEmpty()
  planCode: PlanCode;

  @IsEnum(BillingCycle)
  @IsNotEmpty()
  billingCycle: BillingCycle;

  @IsEnum(PaymentMethod)
  @IsNotEmpty()
  paymentMethod: PaymentMethod;

  /// Wajib diisi dari client (UUID v4 dibuat sekali per tap tombol
  /// "Lanjutkan Pembayaran", dipakai ulang saat retry) - mencegah
  /// double-tap membuat dua transaksi provider (Bagian 32).
  @IsString()
  @IsNotEmpty()
  checkoutAttemptId: string;

  /// Kode bank VA (mis. "bca") - wajib diisi jika paymentMethod = VA,
  /// diabaikan jika QRIS. Divalidasi terhadap daftar bank yang didukung
  /// di PaymentsService, bukan di sini (agar pesan error lebih spesifik).
  @IsOptional()
  @IsString()
  vaBank?: string;
}
