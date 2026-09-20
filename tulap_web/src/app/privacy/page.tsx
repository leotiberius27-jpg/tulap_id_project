import type { Metadata } from 'next';

export const metadata: Metadata = {
  title: 'Kebijakan Privasi - Tulap.id',
  description:
    'Kebijakan Privasi resmi Tulap.id: data yang dikumpulkan, izin perangkat, keamanan data, dan hak pengguna sesuai UU PDP.',
};

const LAST_UPDATED = '20 September 2026';
const OPERATOR = 'Nels Folk / Nels Folk Family';

function SectionHeading({ children }: { children: React.ReactNode }) {
  return (
    <h2 className="mt-10 mb-3 text-lg font-bold text-slate-800">{children}</h2>
  );
}

function P({ children }: { children: React.ReactNode }) {
  return <p className="text-sm leading-relaxed text-slate-600">{children}</p>;
}

function Bullets({ items }: { items: React.ReactNode[] }) {
  return (
    <ul className="list-disc space-y-2 pl-5 text-sm leading-relaxed text-slate-600">
      {items.map((item, i) => (
        <li key={i}>{item}</li>
      ))}
    </ul>
  );
}

const PERMISSIONS = [
  {
    izin: 'Kamera',
    tujuan:
      'Mengambil foto dokumentasi kegiatan dan memindai nota pengeluaran. Kamera hanya aktif saat Anda membuka fitur pengambilan foto.',
  },
  {
    izin: 'Lokasi (GPS)',
    tujuan:
      'Menyematkan watermark geotag pada foto bukti kegiatan dan menampilkan lokasi tugas di peta. Tidak digunakan untuk pelacakan latar belakang.',
  },
  {
    izin: 'Notifikasi',
    tujuan: 'Mengirim pengingat tugas dan status sinkronisasi data.',
  },
  {
    izin: 'Internet & Status Jaringan',
    tujuan:
      'Mengirim dan menerima data antara aplikasi dan server, serta mendeteksi status koneksi untuk mode offline-first.',
  },
  {
    izin: 'Mikrofon',
    tujuan:
      'Diminta oleh salah satu pustaka pihak ketiga yang digunakan untuk fitur kamera/media. Tulap.id tidak merekam maupun memproses audio dari mikrofon Anda — izin ini tidak dipakai aktif oleh fitur apa pun saat ini.',
  },
];

export default function PrivacyPolicyPage() {
  return (
    <main className="min-h-screen bg-slate-50 px-4 py-12">
      <article className="mx-auto max-w-3xl rounded-[24px] bg-white p-8 shadow-sm ring-1 ring-slate-100 sm:p-12">
        <p className="text-sm font-semibold text-[#0d52d7]">Tulap.id</p>
        <h1 className="mt-1 text-2xl font-bold text-slate-800 sm:text-3xl">
          Kebijakan Privasi
        </h1>
        <p className="mt-2 text-sm text-slate-500">
          Terakhir diperbarui: {LAST_UPDATED}
        </p>

        <div className="mt-6 space-y-4">
          <P>
            Kebijakan Privasi ini menjelaskan bagaimana Tulap.id
            (&quot;kami&quot;, &quot;Aplikasi&quot;, &quot;Layanan&quot;)
            mengumpulkan, menggunakan, menyimpan, dan melindungi data pribadi
            Anda sebagai pengguna — baik melalui aplikasi mobile Tulap.id
            (Android/iOS) maupun dasbor web Tulap.id yang digunakan oleh
            instansi/atasan Anda.
          </P>
          <P>
            Tulap.id adalah aplikasi dokumentasi dan akuntabilitas kegiatan
            lapangan bagi pegawai instansi (mis. dinas pemerintah daerah,
            BUMN, atau organisasi lain yang menggunakan layanan kami), dengan
            fitur utama berupa pencatatan tugas, dokumentasi foto ber-geotag,
            pemindaian nota pengeluaran, penyusunan Laporan
            Pertanggungjawaban (LPJ), pencatatan perjalanan dinas, dan dasbor
            verifikasi bagi atasan/verifikator.
          </P>
        </div>

        <SectionHeading>1. Data yang Kami Kumpulkan</SectionHeading>
        <p className="mb-2 text-sm font-semibold text-slate-700">
          a. Data yang Anda berikan langsung
        </p>
        <Bullets
          items={[
            <>
              <b>Data identitas akun</b>: nama lengkap, NIP (jika berlaku),
              email, nomor HP, nama instansi, unit kerja, foto profil.
            </>,
            <>
              <b>Kata sandi</b>: disimpan dalam bentuk hash terenkripsi
              (bcrypt) — kami tidak pernah menyimpan kata sandi dalam bentuk
              teks biasa, dan tidak dapat melihatnya.
            </>,
            <>
              <b>Data kegiatan/tugas</b>: judul dan deskripsi tugas, status
              checklist, catatan lapangan.
            </>,
            <>
              <b>Dokumentasi foto</b>: foto kegiatan yang Anda ambil melalui
              kamera dalam aplikasi, termasuk watermark geotag (koordinat
              GPS, nama wilayah, waktu pengambilan) yang disematkan pada foto
              sebagai bukti keaslian.
            </>,
            <>
              <b>Data nota/pengeluaran</b>: foto struk/nota dan hasil
              pemindaian teks otomatis (OCR) untuk keperluan penyusunan LPJ
              dan pencatatan perjalanan dinas.
            </>,
            <>
              <b>Data pembayaran/langganan</b>: jika Anda atau instansi Anda
              berlangganan paket Tulap.id berbayar, data transaksi (nominal,
              status, referensi pembayaran) diproses melalui mitra payment
              gateway kami (Midtrans). Kami tidak menyimpan detail kartu
              pembayaran Anda.
            </>,
          ]}
        />
        <p className="mt-5 mb-2 text-sm font-semibold text-slate-700">
          b. Data yang dikumpulkan otomatis
        </p>
        <Bullets
          items={[
            <>
              <b>Data lokasi (GPS)</b>: koordinat lokasi hanya direkam pada
              saat Anda menekan tombol rana kamera untuk menyematkan
              watermark geotag, atau saat Anda secara eksplisit membuka
              fitur peta/lokasi tugas.{' '}
              <b>
                Tulap.id tidak melakukan pelacakan lokasi secara
                terus-menerus di latar belakang.
              </b>
            </>,
            <>
              <b>Token notifikasi</b>: token perangkat (Firebase Cloud
              Messaging) untuk mengirimkan notifikasi pengingat tugas dan
              status sinkronisasi.
            </>,
            <>
              <b>Data teknis dasar</b>: jenis perangkat, versi sistem
              operasi, dan log teknis terbatas untuk keperluan diagnosis
              kesalahan aplikasi.
            </>,
            <>
              <b>Data sinkronisasi offline</b>: aplikasi menyimpan data
              sementara di perangkat Anda (database lokal terenkripsi)
              ketika tidak ada koneksi internet, dan mengirimkannya ke
              server pusat begitu koneksi tersedia kembali.
            </>,
          ]}
        />

        <SectionHeading>
          2. Izin Perangkat (Permissions) yang Digunakan
        </SectionHeading>
        <div className="overflow-hidden rounded-xl ring-1 ring-slate-200">
          <table className="w-full border-collapse text-left text-sm">
            <thead className="bg-slate-50">
              <tr>
                <th className="px-4 py-2.5 font-semibold text-slate-700">
                  Izin
                </th>
                <th className="px-4 py-2.5 font-semibold text-slate-700">
                  Tujuan Penggunaan
                </th>
              </tr>
            </thead>
            <tbody className="divide-y divide-slate-100">
              {PERMISSIONS.map((row) => (
                <tr key={row.izin}>
                  <td className="whitespace-nowrap px-4 py-3 align-top font-medium text-slate-700">
                    {row.izin}
                  </td>
                  <td className="px-4 py-3 align-top text-slate-600">
                    {row.tujuan}
                  </td>
                </tr>
              ))}
            </tbody>
          </table>
        </div>
        <p className="mt-3 text-sm leading-relaxed text-slate-600">
          Anda dapat mencabut izin-izin ini kapan saja melalui pengaturan
          sistem operasi perangkat Anda; sebagian fitur (mis. dokumentasi
          foto ber-geotag) tidak akan berfungsi tanpa izin yang relevan.
        </p>

        <SectionHeading>3. Bagaimana Kami Menggunakan Data Anda</SectionHeading>
        <ol className="list-decimal space-y-2 pl-5 text-sm leading-relaxed text-slate-600">
          <li>
            Menyediakan dan mengoperasikan fitur inti Layanan (autentikasi,
            pencatatan tugas, dokumentasi bukti, penyusunan LPJ, perjalanan
            dinas).
          </li>
          <li>
            Memverifikasi keaslian bukti kegiatan lapangan (watermark
            geotag, checksum integritas berkas SHA-256) untuk kebutuhan
            akuntabilitas instansi Anda.
          </li>
          <li>
            Menampilkan data kegiatan Anda kepada atasan/verifikator di
            instansi Anda melalui dasbor web Tulap.id, sebatas yang
            diperlukan untuk proses verifikasi dan pelaporan.
          </li>
          <li>Mengirimkan notifikasi terkait tugas dan status akun.</li>
          <li>
            Menjaga keamanan akun dan mencegah penyalahgunaan (mis.
            mendeteksi upaya masuk yang mencurigakan).
          </li>
          <li>Memproses pembayaran langganan (jika berlaku).</li>
          <li>
            Memenuhi kewajiban hukum dan permintaan resmi dari instansi Anda
            terkait data kepegawaian yang tersimpan di Layanan.
          </li>
        </ol>

        <SectionHeading>4. Berbagi Data dengan Pihak Ketiga</SectionHeading>
        <P>
          Kami <b>tidak menjual</b> data pribadi Anda kepada pihak mana pun.
          Data Anda dapat diakses/diproses oleh pihak ketiga berikut,
          sebatas yang diperlukan untuk menjalankan Layanan:
        </P>
        <div className="mt-3">
          <Bullets
            items={[
              <>
                <b>Google Firebase</b> (Firebase Authentication, Cloud
                Messaging, Firestore) — untuk autentikasi masuk (termasuk
                Masuk dengan Google) dan pengiriman notifikasi.
              </>,
              <>
                <b>Penyedia penyimpanan berkas kompatibel S3</b> — untuk
                menyimpan foto dokumentasi dan berkas nota secara terenkripsi
                dalam pengiriman (HTTPS/TLS).
              </>,
              <>
                <b>Midtrans</b> — sebagai mitra payment gateway untuk
                memproses pembayaran langganan, jika Anda/instansi Anda
                menggunakan fitur berpembayaran.
              </>,
              <>
                <b>Instansi/atasan Anda</b> — data kegiatan dan dokumentasi
                Anda ditampilkan kepada pihak yang berwenang di instansi
                Anda sesuai peran (role) yang ditetapkan instansi.
              </>,
              <>
                <b>Otoritas hukum</b>, apabila diwajibkan oleh proses hukum
                yang sah.
              </>,
            ]}
          />
        </div>

        <SectionHeading>5. Keamanan Data</SectionHeading>
        <Bullets
          items={[
            'Seluruh komunikasi antara aplikasi dan server menggunakan enkripsi HTTPS/TLS 1.3.',
            'Kata sandi disimpan dalam bentuk hash (bcrypt), tidak pernah dalam bentuk teks biasa.',
            'Sesi masuk (token JWT) disimpan pada penyimpanan aman sistem operasi (Encrypted SharedPreferences pada Android, Keychain pada iOS).',
            'Integritas berkas bukti kegiatan diverifikasi menggunakan checksum SHA-256.',
            'Akses ke data di sisi server dibatasi berdasarkan peran (role-based access control) dan dicatat dalam jejak audit (audit trail).',
          ]}
        />

        <SectionHeading>6. Penyimpanan dan Retensi Data</SectionHeading>
        <P>
          Data Anda disimpan selama akun Anda aktif dan selama diperlukan
          untuk memenuhi tujuan yang dijelaskan dalam kebijakan ini,
          termasuk kewajiban penyimpanan dokumen akuntabilitas instansi
          pemerintah sesuai peraturan kearsipan yang berlaku.
        </P>

        <SectionHeading>7. Hak Anda</SectionHeading>
        <P>
          Sesuai UU No. 27 Tahun 2022 tentang Pelindungan Data Pribadi, Anda
          berhak untuk:
        </P>
        <div className="mt-2">
          <Bullets
            items={[
              'Mengakses dan meminta salinan data pribadi Anda yang kami simpan.',
              'Meminta perbaikan data yang tidak akurat (melalui menu "Edit Profil" atau menghubungi Admin instansi Anda).',
              'Meminta penghapusan data pribadi Anda, sepanjang tidak bertentangan dengan kewajiban penyimpanan dokumen akuntabilitas/kearsipan instansi Anda.',
              'Menarik persetujuan penggunaan data tertentu (mis. mencabut izin lokasi/kamera), dengan konsekuensi sebagian fitur tidak dapat digunakan.',
              'Mengajukan keberatan atas pemrosesan data tertentu.',
            ]}
          />
        </div>
        <p className="mt-3 text-sm leading-relaxed text-slate-600">
          Permintaan terkait hak-hak di atas dapat diajukan melalui{' '}
          <a href="mailto:support@tulap.id" className="font-medium text-[#0d52d7]">
            support@tulap.id
          </a>{' '}
          atau melalui Admin instansi Anda.
        </p>

        <SectionHeading>8. Privasi Anak</SectionHeading>
        <P>
          Layanan ini ditujukan untuk pegawai instansi yang telah berusia
          dewasa dan bekerja secara sah, dan tidak ditujukan untuk
          anak-anak di bawah usia yang ditetapkan peraturan
          perundang-undangan yang berlaku. Kami tidak secara sadar
          mengumpulkan data pribadi anak-anak.
        </P>

        <SectionHeading>9. Perubahan Kebijakan Privasi</SectionHeading>
        <P>
          Kami dapat memperbarui Kebijakan Privasi ini dari waktu ke waktu.
          Perubahan signifikan akan diinformasikan melalui aplikasi
          dan/atau email terdaftar Anda. Tanggal &quot;Terakhir
          diperbarui&quot; di bagian atas dokumen ini akan selalu
          mencerminkan versi terbaru.
        </P>

        <SectionHeading>10. Kontak</SectionHeading>
        <P>
          Jika Anda memiliki pertanyaan, keluhan, atau permintaan terkait
          Kebijakan Privasi ini atau data pribadi Anda, silakan hubungi:
        </P>
        <p className="mt-2 text-sm leading-relaxed text-slate-600">
          <b>Email</b>:{' '}
          <a href="mailto:support@tulap.id" className="font-medium text-[#0d52d7]">
            support@tulap.id
          </a>
          <br />
          <b>Operator Layanan</b>: {OPERATOR}
        </p>
      </article>
    </main>
  );
}
