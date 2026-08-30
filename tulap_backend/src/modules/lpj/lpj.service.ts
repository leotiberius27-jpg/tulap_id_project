import { BadRequestException, Injectable, NotFoundException } from '@nestjs/common';
import { randomUUID } from 'crypto';
import PDFDocument = require('pdfkit');
import { PrismaService } from '../../infrastructure/prisma/prisma.service';
import { S3StorageService } from '../../infrastructure/storage/s3-storage.service';
import { AuditService } from '../audit/audit.service';
import { NotificationsService } from '../notifications/notifications.service';
import { AuthenticatedUser } from '../auth/interfaces/authenticated-user.interface';
import { GenerateLpjDto } from './dto/generate-lpj.dto';
import { UploadReportDto } from './dto/upload-report.dto';

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

@Injectable()
export class LpjService {
  constructor(
    private readonly prisma: PrismaService,
    private readonly audit: AuditService,
    private readonly notifications: NotificationsService,
    private readonly s3Storage: S3StorageService,
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

  async uploadReport(
    dto: UploadReportDto,
    file: Express.Multer.File | undefined,
    actor: AuthenticatedUser,
  ) {
    const task = await this.prisma.task_SPPD.findUnique({
      where: { id: dto.taskId },
      select: { id: true, taskCode: true, taskName: true, assigneeId: true, creatorId: true },
    });

    if (!task) {
      throw new NotFoundException('Tugas tidak ditemukan.');
    }

    const reportId = dto.id || randomUUID();
    let pdfUrl = '';
    let s3Key = '';

    if (file && file.buffer) {
      const uploadResult = await this.s3Storage.uploadFile({
        buffer: file.buffer,
        mimeType: file.mimetype || 'application/pdf',
        category: 'report',
        originalFilename: file.originalname || `${dto.reportCode}.pdf`,
      });
      pdfUrl = uploadResult.url;
      s3Key = uploadResult.key;
    }

    const serverTimestamp = new Date().toISOString();

    const reportPayload = {
      id: reportId,
      taskId: dto.taskId,
      userId: actor.id,
      reportCode: dto.reportCode,
      title: dto.title,
      reportType: dto.reportType || 'ACTIVITY_REPORT',
      templateId: dto.templateId || 'default_activity',
      templateVersion: dto.templateVersion || 1,
      versionNumber: dto.versionNumber || 1,
      reportSha256: dto.reportSha256,
      summary: dto.summary || '',
      narrative: dto.narrative || '',
      contentSnapshotJson: dto.contentSnapshotJson,
      totalExpense: dto.totalExpense || 0,
      evidenceCount: dto.evidenceCount || 0,
      receiptCount: dto.receiptCount || 0,
      pdfRemoteUrl: pdfUrl,
      s3Key,
      serverTimestamp,
    };

    await this.audit.log({
      actorId: actor.id,
      action: 'REPORT_GENERATED',
      entity: 'Activity_Report',
      entityId: reportId,
      metadata: reportPayload,
    });

    return reportPayload;
  }

  async getTaskReports(taskId: string, actor: AuthenticatedUser) {
    const logs = await this.prisma.audit_Log.findMany({
      where: {
        entity: 'Activity_Report',
        action: 'REPORT_GENERATED',
      },
      orderBy: { createdAt: 'desc' },
    });

    const matchingReports = logs
      .filter((log) => {
        const meta = log.metadata as any;
        return meta && meta.taskId === taskId;
      })
      .map((log) => log.metadata);

    return matchingReports;
  }

  async getReportById(reportId: string, actor: AuthenticatedUser) {
    const log = await this.prisma.audit_Log.findFirst({
      where: {
        entity: 'Activity_Report',
        entityId: reportId,
        action: 'REPORT_GENERATED',
      },
    });

    if (!log) {
      throw new NotFoundException('Laporan kegiatan tidak ditemukan.');
    }

    return log.metadata;
  }

  async deleteReport(reportId: string, actor: AuthenticatedUser) {
    const log = await this.prisma.audit_Log.findFirst({
      where: {
        entity: 'Activity_Report',
        entityId: reportId,
        action: 'REPORT_GENERATED',
      },
    });

    if (!log) {
      throw new NotFoundException('Laporan kegiatan tidak ditemukan.');
    }

    const meta = log.metadata as any;
    if (meta && meta.s3Key) {
      try {
        await this.s3Storage.deleteFile(meta.s3Key);
      } catch (_) {}
    }

    await this.audit.log({
      actorId: actor.id,
      action: 'REPORT_DELETED',
      entity: 'Activity_Report',
      entityId: reportId,
      metadata: { deletedAt: new Date().toISOString(), reportCode: meta?.reportCode },
    });

    return { success: true, message: 'Laporan berhasil dihapus.' };
  }
}

