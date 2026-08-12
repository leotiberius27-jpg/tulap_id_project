import 'dotenv/config';
import {
  ExpenseCategory,
  PrismaClient,
  RoleName,
  TaskStatus,
  VerificationStatus,
} from '@prisma/client';
import * as bcrypt from 'bcrypt';

const prisma = new PrismaClient();

/// seed-dummy.ts
/// ----------------------------------------------------------------------
/// Data uji TAHAP 2 (RUNBOOK.md) — bukan bagian dari seed wajib
/// (`prisma/seed.ts`, yang hanya membuat Role + Super Admin). Skrip ini
/// dijalankan manual (`npx ts-node prisma/seed-dummy.ts`) untuk mengisi
/// akun pegawai/verifikator/admin, tugas SPPD di berbagai status, serta
/// bukti (foto geotag + nota) dummy — supaya endpoint & RBAC bisa
/// divalidasi end-to-end tanpa harus mengetik data lewat API satu per
/// satu. Idempotent: aman dijalankan berulang (upsert user/task by
/// unique key, checklist & evidence dibersihkan lalu dibuat ulang).
/// ----------------------------------------------------------------------

const DUMMY_PASSWORD = 'Password123!';

async function upsertUser(params: {
  email: string;
  fullName: string;
  nip?: string;
  roleName: RoleName;
  instansiName: string;
  unitKerja: string;
}) {
  const role = await prisma.role.findUniqueOrThrow({
    where: { name: params.roleName },
  });
  const passwordHash = await bcrypt.hash(DUMMY_PASSWORD, 12);

  return prisma.user.upsert({
    where: { email: params.email },
    update: {},
    create: {
      email: params.email,
      fullName: params.fullName,
      nip: params.nip,
      passwordHash,
      roleId: role.id,
      instansiName: params.instansiName,
      unitKerja: params.unitKerja,
    },
  });
}

const CHECKLIST_TEMPLATE = [
  { label: 'Tiba di lokasi tugas', order: 1, isMandatory: true },
  { label: 'Foto kondisi awal lokasi', order: 2, isMandatory: true },
  { label: 'Foto kondisi akhir lokasi', order: 3, isMandatory: true },
  { label: 'Catatan tambahan (opsional)', order: 4, isMandatory: false },
];

async function seedChecklist(taskId: string, completedCount: number) {
  await prisma.task_Checklist_Item.deleteMany({ where: { taskId } });
  await prisma.task_Checklist_Item.createMany({
    data: CHECKLIST_TEMPLATE.map((item, idx) => ({
      taskId,
      label: item.label,
      order: item.order,
      isMandatory: item.isMandatory,
      isCompleted: idx < completedCount,
      completedAt: idx < completedCount ? new Date() : null,
    })),
  });
}

async function seedEvidence(params: {
  taskId: string;
  uploaderId: string;
  ownerId: string;
  lat: number;
  lng: number;
  address: string;
  vendorName: string;
  category: ExpenseCategory;
  amount: number;
  verificationStatus: VerificationStatus;
  verifierId?: string;
  rejectionReason?: string;
}) {
  await prisma.geotag_Photo.deleteMany({ where: { taskId: params.taskId } });
  await prisma.expense_Note.deleteMany({ where: { taskId: params.taskId } });

  await prisma.geotag_Photo.create({
    data: {
      taskId: params.taskId,
      uploaderId: params.uploaderId,
      photoUrl: `https://storage.jakarta.example.com/tulap-storage-prod/dummy/geotag/${params.taskId}.jpg`,
      latitude: params.lat,
      longitude: params.lng,
      address: params.address,
      serverTimestamp: new Date(),
      integrityHash: `dummyhash-${params.taskId}`,
      isMockLocationFlag: false,
      isRootedDeviceFlag: false,
      caption: 'Foto bukti kegiatan (dummy — tanpa file fisik).',
    },
  });

  await prisma.expense_Note.create({
    data: {
      taskId: params.taskId,
      ownerId: params.ownerId,
      scanUrl: `https://storage.jakarta.example.com/tulap-storage-prod/dummy/nota/${params.taskId}.jpg`,
      vendorName: params.vendorName,
      transactionDate: new Date(),
      totalAmount: params.amount,
      category: params.category,
      ocrRawText: `[DUMMY OCR] ${params.vendorName} - Total: ${params.amount}`,
      ocrConfidence: 92.5,
      verificationStatus: params.verificationStatus,
      verifierId: params.verifierId,
      verifiedAt: params.verifierId ? new Date() : null,
      rejectionReason: params.rejectionReason,
    },
  });
}

async function upsertTask(params: {
  taskCode: string;
  taskName: string;
  destination: string;
  description: string;
  startDate: Date;
  endDate: Date;
  budgetAmount: number;
  realizedAmount?: number;
  status: TaskStatus;
  assigneeId: string;
  creatorId: string;
}) {
  return prisma.task_SPPD.upsert({
    where: { taskCode: params.taskCode },
    update: {
      status: params.status,
      realizedAmount: params.realizedAmount ?? 0,
    },
    create: {
      taskCode: params.taskCode,
      taskName: params.taskName,
      destination: params.destination,
      description: params.description,
      startDate: params.startDate,
      endDate: params.endDate,
      budgetAmount: params.budgetAmount,
      realizedAmount: params.realizedAmount ?? 0,
      status: params.status,
      assigneeId: params.assigneeId,
      creatorId: params.creatorId,
    },
  });
}

async function main() {
  console.log('Memulai seeding data uji (TAHAP 2)...');

  // --- 1. Akun uji: 3 PEGAWAI, 1 VERIFIKATOR, 1 ADMIN ---
  const budi = await upsertUser({
    email: 'budi.santoso@tulap.id',
    fullName: 'Budi Santoso',
    nip: '198501012010011001',
    roleName: RoleName.PEGAWAI,
    instansiName: 'Dinas Pekerjaan Umum dan Penataan Ruang Provinsi Papua',
    unitKerja: 'Bidang Bina Marga',
  });
  const yohanes = await upsertUser({
    email: 'yohanes.kayame@tulap.id',
    fullName: 'Yohanes Kayame',
    nip: '199002152012011002',
    roleName: RoleName.PEGAWAI,
    instansiName: 'Dinas Pekerjaan Umum dan Penataan Ruang Provinsi Papua',
    unitKerja: 'Bidang Sumber Daya Air',
  });
  const fitria = await upsertUser({
    email: 'fitria.wenda@tulap.id',
    fullName: 'Fitria Wenda',
    nip: '199308202015012003',
    roleName: RoleName.PEGAWAI,
    instansiName: 'Dinas Pekerjaan Umum dan Penataan Ruang Provinsi Papua',
    unitKerja: 'Bidang Cipta Karya',
  });
  const maria = await upsertUser({
    email: 'maria.rumbewas@tulap.id',
    fullName: 'Maria Rumbewas',
    nip: '198207102008012004',
    roleName: RoleName.VERIFIKATOR,
    instansiName: 'Dinas Pekerjaan Umum dan Penataan Ruang Provinsi Papua',
    unitKerja: 'Bagian Keuangan',
  });
  const agus = await upsertUser({
    email: 'agus.pranowo@tulap.id',
    fullName: 'Agus Pranowo',
    nip: '197611052005011005',
    roleName: RoleName.ADMIN,
    instansiName: 'Dinas Pekerjaan Umum dan Penataan Ruang Provinsi Papua',
    unitKerja: 'Sekretariat Dinas',
  });
  console.log('5 akun uji siap: Budi, Yohanes, Fitria (PEGAWAI), Maria (VERIFIKATOR), Agus (ADMIN).');
  console.log(`Password seluruh akun uji: ${DUMMY_PASSWORD}`);

  // --- 2. Task SPPD di setiap status pada state machine ---
  const day = 24 * 60 * 60 * 1000;
  const today = new Date();

  const taskDraft = await upsertTask({
    taskCode: 'TL-202608-D001',
    taskName: 'Survei Kondisi Jalan Trans Papua Ruas Jayapura-Wamena',
    destination: 'Jayapura, Papua',
    description: 'Survei kondisi fisik jalan untuk usulan pemeliharaan tahun anggaran berikutnya.',
    startDate: new Date(today.getTime() + 3 * day),
    endDate: new Date(today.getTime() + 5 * day),
    budgetAmount: 15_000_000,
    status: TaskStatus.DRAFT,
    assigneeId: budi.id,
    creatorId: agus.id,
  });
  await seedChecklist(taskDraft.id, 0);

  const taskOngoing = await upsertTask({
    taskCode: 'TL-202608-D002',
    taskName: 'Inspeksi Jembatan Youtefa',
    destination: 'Kota Jayapura, Papua',
    description: 'Inspeksi rutin kondisi struktur jembatan.',
    startDate: new Date(today.getTime() - 1 * day),
    endDate: new Date(today.getTime() + 1 * day),
    budgetAmount: 8_000_000,
    status: TaskStatus.ONGOING,
    assigneeId: yohanes.id,
    creatorId: agus.id,
  });
  await seedChecklist(taskOngoing.id, 1);
  await seedEvidence({
    taskId: taskOngoing.id,
    uploaderId: yohanes.id,
    ownerId: yohanes.id,
    lat: -2.5333,
    lng: 140.7181,
    address: 'Jembatan Youtefa, Kota Jayapura, Papua',
    vendorName: 'SPBU Entrop',
    category: ExpenseCategory.BBM,
    amount: 250_000,
    verificationStatus: VerificationStatus.PENDING,
  });

  const taskPendingVerification = await upsertTask({
    taskCode: 'TL-202608-D003',
    taskName: 'Monitoring Proyek Irigasi Koya Barat',
    destination: 'Distrik Muara Tami, Jayapura',
    description: 'Monitoring progres fisik proyek irigasi.',
    startDate: new Date(today.getTime() - 4 * day),
    endDate: new Date(today.getTime() - 2 * day),
    budgetAmount: 12_500_000,
    status: TaskStatus.PENDING_VERIFICATION,
    assigneeId: fitria.id,
    creatorId: agus.id,
  });
  await seedChecklist(taskPendingVerification.id, 3);
  await seedEvidence({
    taskId: taskPendingVerification.id,
    uploaderId: fitria.id,
    ownerId: fitria.id,
    lat: -2.6011,
    lng: 140.6534,
    address: 'Saluran Irigasi Koya Barat, Muara Tami, Jayapura',
    vendorName: 'Rumah Makan Koya Barat',
    category: ExpenseCategory.KONSUMSI,
    amount: 180_000,
    verificationStatus: VerificationStatus.PENDING,
  });

  const taskRevisionNeeded = await upsertTask({
    taskCode: 'TL-202608-D004',
    taskName: 'Pemeliharaan Saluran Drainase Abepura',
    destination: 'Abepura, Kota Jayapura',
    description: 'Pemeliharaan rutin saluran drainase yang tersumbat sedimen.',
    startDate: new Date(today.getTime() - 6 * day),
    endDate: new Date(today.getTime() - 4 * day),
    budgetAmount: 6_000_000,
    status: TaskStatus.REVISION_NEEDED,
    assigneeId: budi.id,
    creatorId: agus.id,
  });
  await seedChecklist(taskRevisionNeeded.id, 3);
  await seedEvidence({
    taskId: taskRevisionNeeded.id,
    uploaderId: budi.id,
    ownerId: budi.id,
    lat: -2.5729,
    lng: 140.6417,
    address: 'Saluran Drainase Abepura, Kota Jayapura',
    vendorName: 'Toko Bangunan Abepura Jaya',
    category: ExpenseCategory.RETAIL,
    amount: 420_000,
    verificationStatus: VerificationStatus.REJECTED,
    verifierId: maria.id,
    rejectionReason: 'Nominal nota tidak sesuai dengan rekap harian. Mohon lampirkan ulang nota asli.',
  });

  const taskVerified = await upsertTask({
    taskCode: 'TL-202608-D005',
    taskName: 'Pengecekan Kondisi Dermaga Hamadi',
    destination: 'Jayapura, Papua',
    description: 'Pengecekan kondisi fisik dermaga rakyat pasca musim hujan.',
    startDate: new Date(today.getTime() - 10 * day),
    endDate: new Date(today.getTime() - 8 * day),
    budgetAmount: 9_200_000,
    status: TaskStatus.VERIFIED,
    assigneeId: yohanes.id,
    creatorId: agus.id,
  });
  await seedChecklist(taskVerified.id, 3);
  await seedEvidence({
    taskId: taskVerified.id,
    uploaderId: yohanes.id,
    ownerId: yohanes.id,
    lat: -2.5378,
    lng: 140.7239,
    address: 'Dermaga Hamadi, Kota Jayapura',
    vendorName: 'Penginapan Hamadi Indah',
    category: ExpenseCategory.PENGINAPAN,
    amount: 350_000,
    verificationStatus: VerificationStatus.VERIFIED,
    verifierId: maria.id,
  });

  const taskCompleted = await upsertTask({
    taskCode: 'TL-202608-D006',
    taskName: 'Survei Lokasi Pembangunan Kantor Distrik Muara Tami',
    destination: 'Muara Tami, Jayapura',
    description: 'Survei kelayakan lahan untuk pembangunan kantor distrik baru.',
    startDate: new Date(today.getTime() - 20 * day),
    endDate: new Date(today.getTime() - 17 * day),
    budgetAmount: 20_000_000,
    realizedAmount: 18_750_000,
    status: TaskStatus.COMPLETED,
    assigneeId: fitria.id,
    creatorId: agus.id,
  });
  await seedChecklist(taskCompleted.id, 3);
  await seedEvidence({
    taskId: taskCompleted.id,
    uploaderId: fitria.id,
    ownerId: fitria.id,
    lat: -2.6127,
    lng: 140.6289,
    address: 'Muara Tami, Kota Jayapura',
    vendorName: 'Ojek Online Jayapura',
    category: ExpenseCategory.TRANSPORTASI_LAIN,
    amount: 75_000,
    verificationStatus: VerificationStatus.VERIFIED,
    verifierId: maria.id,
  });

  const taskRejected = await upsertTask({
    taskCode: 'TL-202608-D007',
    taskName: 'Perbaikan Talud Sungai Acai',
    destination: 'Heram, Kota Jayapura',
    description: 'Perbaikan talud yang longsor akibat curah hujan tinggi.',
    startDate: new Date(today.getTime() - 15 * day),
    endDate: new Date(today.getTime() - 13 * day),
    budgetAmount: 5_000_000,
    status: TaskStatus.REJECTED,
    assigneeId: budi.id,
    creatorId: agus.id,
  });
  await seedChecklist(taskRejected.id, 3);
  await seedEvidence({
    taskId: taskRejected.id,
    uploaderId: budi.id,
    ownerId: budi.id,
    lat: -2.5145,
    lng: 140.6801,
    address: 'Sungai Acai, Heram, Kota Jayapura',
    vendorName: 'Toko Material Heram',
    category: ExpenseCategory.LAINNYA,
    amount: 600_000,
    verificationStatus: VerificationStatus.REJECTED,
    verifierId: maria.id,
    rejectionReason: 'Pekerjaan di lapangan tidak sesuai dengan rencana awal tanpa persetujuan.',
  });

  console.log('7 Task SPPD siap (satu untuk tiap status: DRAFT, ONGOING, PENDING_VERIFICATION, REVISION_NEEDED, VERIFIED, COMPLETED, REJECTED).');
  console.log('Checklist + bukti (foto geotag & nota, metadata saja) siap untuk task yang relevan.');
  console.log('Seeding data uji selesai.');
}

main()
  .catch((e) => {
    console.error('Seeding data uji gagal:', e);
    process.exit(1);
  })
  .finally(async () => {
    await prisma.$disconnect();
  });
