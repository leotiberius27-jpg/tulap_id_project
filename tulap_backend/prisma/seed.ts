import { PrismaClient, RoleName } from '@prisma/client';
import * as bcrypt from 'bcrypt';

const prisma = new PrismaClient();

/// seed.ts
/// ----------------------------------------------------------------------
/// WAJIB dijalankan sekali di awal (npx prisma db seed) sebelum
/// aplikasi bisa dipakai sama sekali - tanpa ini, AuthService.register
/// akan selalu gagal dengan "Role tidak terdaftar di master data",
/// karena self-registration memang sengaja dimatikan (Anda tidak bisa
/// membuat role/akun pertama lewat endpoint API biasa).
///
/// Seed ini membuat:
///   1. Keempat Role dasar (PEGAWAI, VERIFIKATOR, ADMIN, SUPER_ADMIN)
///   2. Satu akun SUPER_ADMIN awal untuk login pertama kali - PASSWORD
///      DEFAULT INI WAJIB DIGANTI segera setelah login pertama di
///      lingkungan produksi.
/// ----------------------------------------------------------------------
async function main() {
  console.log('Memulai seeding database...');

  // --- 1. Seed Role ---
  const roleNames = Object.values(RoleName);
  for (const name of roleNames) {
    await prisma.role.upsert({
      where: { name },
      update: {},
      create: { name },
    });
    console.log(`Role '${name}' siap.`);
  }

  // --- 2. Seed akun Super Admin awal ---
  const superAdminRole = await prisma.role.findUniqueOrThrow({
    where: { name: RoleName.SUPER_ADMIN },
  });

  const defaultEmail = 'superadmin@tulap.id';
  const defaultPassword = 'GantiSegeraSetelahLogin!123'; // GANTI setelah login pertama

  const existing = await prisma.user.findUnique({ where: { email: defaultEmail } });

  if (!existing) {
    const passwordHash = await bcrypt.hash(defaultPassword, 12);
    await prisma.user.create({
      data: {
        fullName: 'Super Admin',
        email: defaultEmail,
        passwordHash,
        roleId: superAdminRole.id,
        instansiName: 'Tulap.id Pusat',
      },
    });
    console.log(`Akun Super Admin awal dibuat: ${defaultEmail} / ${defaultPassword}`);
    console.log('PENTING: Ganti password ini segera setelah login pertama!');
  } else {
    console.log('Akun Super Admin sudah ada, dilewati.');
  }

  console.log('Seeding selesai.');
}

main()
  .catch((e) => {
    console.error('Seeding gagal:', e);
    process.exit(1);
  })
  .finally(async () => {
    await prisma.$disconnect();
  });
