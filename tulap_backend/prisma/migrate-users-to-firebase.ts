import 'dotenv/config';
import { PrismaClient } from '@prisma/client';
import { cert, initializeApp } from 'firebase-admin/app';
import { getAuth, UserImportRecord } from 'firebase-admin/auth';

const prisma = new PrismaClient();

/// migrate-users-to-firebase.ts
/// ----------------------------------------------------------------------
/// Migrasi SATU KALI (one-time, idempotent) untuk seluruh user Tulap.id
/// yang sudah punya `passwordHash` bcrypt di PostgreSQL tapi BELUM
/// pernah punya akun Firebase (`firebaseUid` masih null) - dibutuhkan
/// karena layar login utama Android sekarang memicu Firebase Client SDK
/// LEBIH DULU untuk Email/Password (lihat AuthService.loginWithFirebase).
/// Tanpa migrasi ini, akun lama akan gagal masuk dengan
/// `auth/user-not-found` walau passwordnya benar.
///
/// Memakai `admin.auth().importUsers()` dengan algoritma BCRYPT -
/// Firebase mendukung impor hash bcrypt APA ADANYA (didokumentasikan
/// resmi), jadi TIDAK ADA password yang perlu di-reset/diketahui ulang.
/// UID Firebase yang di-import SENGAJA disamakan persis dengan `User.id`
/// Postgres milik masing-masing user (bukan UID acak) - supaya begitu
/// mereka login lewat /auth/firebase-login, `firebaseUid` langsung
/// cocok tanpa perlu fallback pencarian by-email, dan identitas Firebase
/// mereka konsisten dengan skema "Firebase UID == Tulap.id user id" yang
/// sudah dipakai jalur "Masuk dengan Google" (custom token) sebelumnya.
///
/// Jalankan manual: `npx ts-node prisma/migrate-users-to-firebase.ts`
/// ----------------------------------------------------------------------

async function main() {
  const raw = process.env.FIREBASE_SERVICE_ACCOUNT_JSON;
  if (!raw) {
    console.error(
      'FIREBASE_SERVICE_ACCOUNT_JSON kosong di .env - migrasi dibatalkan.',
    );
    process.exit(1);
  }

  const credentials = JSON.parse(raw);
  const app = initializeApp(
    { credential: cert(credentials) },
    'tulap-migrate-users',
  );
  const auth = getAuth(app);

  const users = await prisma.user.findMany({
    where: { passwordHash: { not: null }, firebaseUid: null },
    select: { id: true, email: true, fullName: true, passwordHash: true },
  });

  if (users.length === 0) {
    console.log('Tidak ada user yang perlu dimigrasi. Selesai.');
    return;
  }

  console.log(`Ditemukan ${users.length} user untuk dimigrasi ke Firebase...`);

  const records: UserImportRecord[] = users.map((user) => ({
    uid: user.id,
    email: user.email,
    emailVerified: true,
    displayName: user.fullName,
    passwordHash: Buffer.from(user.passwordHash as string, 'utf8'),
  }));

  const result = await auth.importUsers(records, {
    hash: { algorithm: 'BCRYPT' },
  });

  console.log(`Berhasil: ${result.successCount}, Gagal: ${result.failureCount}`);
  for (const err of result.errors) {
    const failedUser = users[err.index];
    console.error(`  - Gagal migrasi ${failedUser?.email}: ${err.error}`);
  }

  const succeededIds = users
    .filter((_, idx) => !result.errors.some((e) => e.index === idx))
    .map((u) => u.id);

  if (succeededIds.length > 0) {
    // Prisma updateMany tidak bisa set nilai berbeda per-row dalam satu
    // panggilan - firebaseUid harus sama dengan id masing-masing baris,
    // jadi di-update satu per satu (jumlah user kecil, aman secara performa).
    for (const id of succeededIds) {
      await prisma.user.update({ where: { id }, data: { firebaseUid: id } });
    }
    console.log(`firebaseUid diset untuk ${succeededIds.length} user di PostgreSQL.`);
  }
}

main()
  .catch((err) => {
    console.error('Migrasi gagal total:', err);
    process.exitCode = 1;
  })
  .finally(async () => {
    await prisma.$disconnect();
  });
