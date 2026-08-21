import { BadRequestException, Injectable, NotFoundException } from '@nestjs/common';
import PDFDocument = require('pdfkit');
import { PrismaService } from '../../infrastructure/prisma/prisma.service';
import { AuditService } from '../audit/audit.service';
import { NotificationsService } from '../notifications/notifications.service';
import { AuthenticatedUser } from '../auth/interfaces/authenticated-user.interface';
import { GenerateLpjDto } from './dto/generate-lpj.dto';

const rupiahFormatter = new Intl.NumberFormat('id-ID', {
  style: 'currency',
  currency: 'IDR',
  minimumFractionDigits: 0,
});

const dateFormatter = new Intl.DateTimeFormat('id-ID', {
  day: '2-digit',
  month: 'long',
  year: 'numeric',
});

/// LpjService
/// ----------------------------------------------------------------------
/// Menyusun PDF LPJ (Laporan Pertanggungjawaban) sederhana dari data
/// tugas yang SUDAH ada - checklist, bukti foto, dan nota (Bagian 24
/// LPJ Flow: "Sistem Kumpulkan Data (foto, nota, checklist, verifikasi)
/// -> Generate"). TIDAK menyimpan record LPJ baru ke database maupun
/// mengunggah file ke S3 - ini murni generator laporan on-demand,
/// selaras dengan skema Prisma saat ini yang belum punya model
/// `LPJ`/`LPJTemplate` (disebut di Bagian 27 dokumen spesifikasi,
/// namun belum diimplementasikan - di luar cakupan modul ini).
/// Transisi status tugas ke COMPLETED tetap lewat endpoint terpisah
/// `POST /tasks/:id/complete` yang sudah ada, BUKAN otomatis di sini.
/// ----------------------------------------------------------------------
@Injectable()
export class LpjService {
  constructor(
    private readonly prisma: PrismaService,
    private readonly audit: AuditService,
    private readonly notifications: NotificationsService,
  ) {}

  async generate(
    dto: GenerateLpjDto,
    actor: AuthenticatedUser,
  ): Promise<{ buffer: Buffer; fileName: string }> {
    const task = await this.prisma.task_SPPD.findUnique({
      where: { id: dto.taskId },
      include: {
        assignee: { select: { id: true, fullName: true, instansiName: true, unitKerja: true } },
        creator: { select: { id: true } },
        checklistItems: { orderBy: { order: 'asc' } },
        expenseNotes: { orderBy: { transactionDate: 'asc' } },
        geotagPhotos: { orderBy: { serverTimestamp: 'asc' } },
      },
    });

    if (!task) {
      throw new NotFoundException('Tugas tidak ditemukan.');
    }

    // Sesuai permintaan: LPJ hanya boleh dibuat dari tugas yang sudah
    // diverifikasi - mencegah laporan pertanggungjawaban terbit dari
    // data yang belum melalui Verification Workspace (Bagian 15).
    if (task.status !== 'VERIFIED') {
      throw new BadRequestException(
        `LPJ hanya dapat dibuat untuk tugas berstatus VERIFIED. Status tugas saat ini: '${task.status}'.`,
      );
    }

    const buffer = await this._renderPdf(task);
    const fileName = `LPJ-${task.taskCode}.pdf`;

    await this.audit.log({
      actorId: actor.id,
      action: 'LPJ_GENERATED',
      entity: 'Task_SPPD',
      entityId: task.id,
      metadata: { fileName },
    });

    // Notifikasi ke Petugas (Bagian 25: "LPJ untuk [Judul] sudah bisa
    // diunduh") - dan ke pembuat tugas jika berbeda dari yang generate,
    // supaya Admin yang membuat penugasan juga tahu LPJ-nya sudah terbit.
    const recipientIds = new Set([task.assignee.id, task.creator.id]);
    for (const userId of recipientIds) {
      await this.notifications.notify({
        userId,
        type: 'LPJ_READY',
        title: 'LPJ siap diunduh',
        body: `LPJ untuk ${task.taskName} sudah bisa diunduh.`,
        relatedTaskId: task.id,
      });
    }

    return { buffer, fileName };
  }

  private _renderPdf(task: any): Promise<Buffer> {
    return new Promise((resolve, reject) => {
      const doc = new PDFDocument({ margin: 50 });
      const chunks: Buffer[] = [];

      doc.on('data', (chunk: Buffer) => chunks.push(chunk));
      doc.on('end', () => resolve(Buffer.concat(chunks)));
      doc.on('error', reject);

      this._writeHeader(doc, task);
      this._writeChecklistSection(doc, task);
      this._writeEvidenceSection(doc, task);
      this._writeExpenseSection(doc, task);
      this._writeFooter(doc);

      doc.end();
    });
  }

  private _writeHeader(doc: PDFKit.PDFDocument, task: any): void {
    doc.fontSize(16).font('Helvetica-Bold').text('LAPORAN PERTANGGUNGJAWABAN (LPJ)', { align: 'center' });
    doc.fontSize(10).font('Helvetica').text(task.taskCode, { align: 'center' });
    doc.moveDown(1.5);

    doc.fontSize(12).font('Helvetica-Bold').text('Informasi Tugas');
    doc.moveDown(0.3);
    doc.fontSize(10).font('Helvetica');
    this._writeField(doc, 'Nama Tugas', task.taskName);
    this._writeField(doc, 'Instansi', task.assignee?.instansiName ?? '-');
    this._writeField(doc, 'Petugas', task.assignee?.fullName ?? '-');
    this._writeField(doc, 'Lokasi Tujuan', task.destination);
    this._writeField(
      doc,
      'Jadwal',
      `${dateFormatter.format(task.startDate)} - ${dateFormatter.format(task.endDate)}`,
    );
    this._writeField(doc, 'Anggaran', rupiahFormatter.format(task.budgetAmount.toNumber()));
    doc.moveDown(1);
  }

  private _writeChecklistSection(doc: PDFKit.PDFDocument, task: any): void {
    doc.fontSize(12).font('Helvetica-Bold').text('Checklist Tugas');
    doc.moveDown(0.3);
    doc.fontSize(10).font('Helvetica');

    if (task.checklistItems.length === 0) {
      doc.text('Tidak ada item checklist.');
    } else {
      for (const item of task.checklistItems) {
        const mark = item.isCompleted ? '[x]' : '[ ]';
        doc.text(`${mark} ${item.label}${item.isMandatory ? ' (wajib)' : ''}`);
      }
    }
    doc.moveDown(1);
  }

  private _writeEvidenceSection(doc: PDFKit.PDFDocument, task: any): void {
    doc.fontSize(12).font('Helvetica-Bold').text('Bukti Foto Kegiatan');
    doc.moveDown(0.3);
    doc.fontSize(10).font('Helvetica');

    if (task.geotagPhotos.length === 0) {
      doc.text('Tidak ada bukti foto.');
    } else {
      for (const photo of task.geotagPhotos) {
        doc.text(
          `- ${dateFormatter.format(photo.serverTimestamp)} · ${photo.latitude}, ${photo.longitude}` +
            (photo.address ? ` · ${photo.address}` : ''),
        );
      }
    }
    doc.moveDown(1);
  }

  private _writeExpenseSection(doc: PDFKit.PDFDocument, task: any): void {
    doc.fontSize(12).font('Helvetica-Bold').text('Rincian Pengeluaran (Nota)');
    doc.moveDown(0.3);
    doc.fontSize(10).font('Helvetica');

    if (task.expenseNotes.length === 0) {
      doc.text('Tidak ada nota pengeluaran.');
      doc.moveDown(1);
      return;
    }

    let total = 0;
    for (const note of task.expenseNotes) {
      const amount = note.totalAmount.toNumber();
      total += amount;
      doc.text(
        `- ${dateFormatter.format(note.transactionDate)} · ${note.vendorName} (${note.category}) · ` +
          `${rupiahFormatter.format(amount)} · ${note.verificationStatus}`,
      );
    }

    doc.moveDown(0.5);
    doc.font('Helvetica-Bold').text(`Total Realisasi: ${rupiahFormatter.format(total)}`);
    doc.moveDown(1);
  }

  private _writeFooter(doc: PDFKit.PDFDocument): void {
    doc
      .fontSize(8)
      .font('Helvetica-Oblique')
      .text(
        `Dokumen dibuat otomatis oleh Tulap.id pada ${dateFormatter.format(new Date())}.`,
        { align: 'center' },
      );
  }

  private _writeField(doc: PDFKit.PDFDocument, label: string, value: string): void {
    doc.text(`${label}: ${value}`);
  }
}
