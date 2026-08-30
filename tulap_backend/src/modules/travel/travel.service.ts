import {
  ForbiddenException,
  Injectable,
  NotFoundException,
} from '@nestjs/common';
import { PrismaService } from '../../infrastructure/prisma/prisma.service';
import { S3StorageService } from '../../infrastructure/storage/s3-storage.service';
import { AuditService } from '../audit/audit.service';
import { CreateLpjPackageDto } from './dto/create-lpj-package.dto';
import { CreateSupportingDocumentDto } from './dto/create-supporting-document.dto';
import { CreateTravelMissionDto } from './dto/create-travel-mission.dto';
import { UpdateTravelMissionDto } from './dto/update-travel-mission.dto';
import { TravelMissionStatus } from '@prisma/client';

@Injectable()
export class TravelService {
  constructor(
    private readonly prisma: PrismaService,
    private readonly storageService: S3StorageService,
    private readonly auditService: AuditService,
  ) {}

  async createTravelMission(userId: string, dto: CreateTravelMissionDto) {
    const existing = await this.prisma.travel_Mission.findUnique({
      where: { id: dto.id },
    });

    if (existing) {
      if (existing.userId !== userId) {
        throw new ForbiddenException('Akses ke perjalanan dinas ditolak.');
      }
      return existing;
    }

    const mission = await this.prisma.travel_Mission.create({
      data: {
        id: dto.id,
        displayId: dto.displayId,
        userId: userId,
        assignmentLetterNumber: dto.assignmentLetterNumber,
        assignmentLetterDate: new Date(dto.assignmentLetterDate),
        title: dto.title,
        purpose: dto.purpose,
        origin: dto.origin,
        destination: dto.destination,
        destinations: dto.destinations ? JSON.stringify(dto.destinations) : undefined,
        departureDate: new Date(dto.departureDate),
        returnDate: new Date(dto.returnDate),
        transportMode: dto.transportMode,
        transportDetails: dto.transportDetails,
        status: (dto.status as TravelMissionStatus) || TravelMissionStatus.DRAFT,
        budgetEstimate: dto.budgetEstimate ? JSON.stringify(dto.budgetEstimate) : undefined,
        notes: dto.notes,
        personnelSnapshot: dto.personnelSnapshot
          ? JSON.stringify(dto.personnelSnapshot)
          : undefined,
      },
    });

    await this.auditService.log({
      actorId: userId,
      action: 'TRAVEL_CREATED',
      entity: 'Travel_Mission',
      entityId: mission.id,
      metadata: {
        displayId: mission.displayId,
        title: mission.title,
        origin: mission.origin,
        destination: mission.destination,
      },
    });

    return mission;
  }

  async findAllTravelMissions(
    userId: string,
    search?: string,
    status?: string,
    year?: number,
  ) {
    const where: any = { userId };

    if (status) {
      where.status = status;
    }

    if (search && search.trim().length > 0) {
      where.OR = [
        { title: { contains: search, mode: 'insensitive' } },
        { destination: { contains: search, mode: 'insensitive' } },
        { displayId: { contains: search, mode: 'insensitive' } },
        { assignmentLetterNumber: { contains: search, mode: 'insensitive' } },
      ];
    }

    if (year) {
      where.departureDate = {
        gte: new Date(`${year}-01-01T00:00:00.000Z`),
        lte: new Date(`${year}-12-31T23:59:59.999Z`),
      };
    }

    return this.prisma.travel_Mission.findMany({
      where,
      orderBy: { departureDate: 'desc' },
      include: {
        tasks: {
          select: {
            id: true,
            taskCode: true,
            taskName: true,
            destination: true,
            status: true,
          },
        },
        supportingDocuments: true,
        lpjPackages: {
          orderBy: { versionNumber: 'desc' },
          take: 1,
        },
      },
    });
  }

  async findOneTravelMission(userId: string, id: string) {
    const mission = await this.prisma.travel_Mission.findUnique({
      where: { id },
      include: {
        tasks: {
          include: {
            geotagPhotos: true,
            expenseNotes: true,
          },
        },
        supportingDocuments: true,
        lpjPackages: {
          orderBy: { versionNumber: 'desc' },
        },
      },
    });

    if (!mission) {
      throw new NotFoundException('Perjalanan dinas tidak ditemukan.');
    }

    if (mission.userId !== userId) {
      throw new ForbiddenException('Akses ke perjalanan dinas ditolak.');
    }

    return mission;
  }

  async updateTravelMission(
    userId: string,
    id: string,
    dto: UpdateTravelMissionDto,
  ) {
    await this.findOneTravelMission(userId, id);

    const updated = await this.prisma.travel_Mission.update({
      where: { id },
      data: {
        assignmentLetterNumber: dto.assignmentLetterNumber,
        assignmentLetterDate: dto.assignmentLetterDate
          ? new Date(dto.assignmentLetterDate)
          : undefined,
        title: dto.title,
        purpose: dto.purpose,
        origin: dto.origin,
        destination: dto.destination,
        destinations: dto.destinations ? JSON.stringify(dto.destinations) : undefined,
        departureDate: dto.departureDate ? new Date(dto.departureDate) : undefined,
        returnDate: dto.returnDate ? new Date(dto.returnDate) : undefined,
        transportMode: dto.transportMode,
        transportDetails: dto.transportDetails,
        status: (dto.status as TravelMissionStatus) || undefined,
        budgetEstimate: dto.budgetEstimate ? JSON.stringify(dto.budgetEstimate) : undefined,
        notes: dto.notes,
        personnelSnapshot: dto.personnelSnapshot
          ? JSON.stringify(dto.personnelSnapshot)
          : undefined,
      },
    });

    await this.auditService.log({
      actorId: userId,
      action: 'TRAVEL_UPDATED',
      entity: 'Travel_Mission',
      entityId: id,
      metadata: { status: updated.status },
    });

    return updated;
  }

  async deleteTravelMission(userId: string, id: string) {
    const mission = await this.findOneTravelMission(userId, id);

    if (mission.status === TravelMissionStatus.COMPLETED) {
      // Archive instead of hard delete for completed missions
      return this.prisma.travel_Mission.update({
        where: { id },
        data: { status: TravelMissionStatus.ARCHIVED },
      });
    }

    return this.prisma.travel_Mission.delete({
      where: { id },
    });
  }

  async uploadSupportingDocument(
    userId: string,
    dto: CreateSupportingDocumentDto,
    file?: Express.Multer.File,
  ) {
    const mission = await this.findOneTravelMission(userId, dto.travelMissionId);

    let documentUrl = '';
    if (file) {
      const uploadResult = await this.storageService.uploadFile({
        buffer: file.buffer,
        mimeType: file.mimetype,
        category: 'report',
        originalFilename: file.originalname,
      });
      documentUrl = uploadResult.url;
    }

    const existing = await this.prisma.supporting_Document.findUnique({
      where: { id: dto.id },
    });

    if (existing) {
      return existing;
    }

    const doc = await this.prisma.supporting_Document.create({
      data: {
        id: dto.id,
        travelMissionId: mission.id,
        activityId: dto.activityId,
        documentType: dto.documentType,
        title: dto.title,
        documentUrl: documentUrl || 'local_only',
        sha256: dto.sha256,
      },
    });

    await this.auditService.log({
      actorId: userId,
      action: 'DOCUMENT_ADDED',
      entity: 'Supporting_Document',
      entityId: doc.id,
      metadata: {
        travelMissionId: mission.id,
        documentType: doc.documentType,
        title: doc.title,
      },
    });

    return doc;
  }

  async findSupportingDocuments(userId: string, travelMissionId: string) {
    await this.findOneTravelMission(userId, travelMissionId);

    return this.prisma.supporting_Document.findMany({
      where: { travelMissionId },
      orderBy: { createdAt: 'asc' },
    });
  }

  async deleteSupportingDocument(userId: string, id: string) {
    const doc = await this.prisma.supporting_Document.findUnique({
      where: { id },
      include: { travelMission: true },
    });

    if (!doc) {
      throw new NotFoundException('Dokumen tidak ditemukan.');
    }

    if (doc.travelMission.userId !== userId) {
      throw new ForbiddenException('Akses ke dokumen ditolak.');
    }

    return this.prisma.supporting_Document.delete({
      where: { id },
    });
  }

  async createOrUpdateLpjPackage(
    userId: string,
    dto: CreateLpjPackageDto,
    file?: Express.Multer.File,
  ) {
    const mission = await this.findOneTravelMission(userId, dto.travelMissionId);

    let pdfUrl = '';
    if (file) {
      const uploadResult = await this.storageService.uploadFile({
        buffer: file.buffer,
        mimeType: file.mimetype,
        category: 'report',
        originalFilename: file.originalname,
      });
      pdfUrl = uploadResult.url;
    }

    const existing = await this.prisma.lPJ_Package.findUnique({
      where: { id: dto.id },
    });

    if (existing) {
      return existing;
    }

    const pkg = await this.prisma.lPJ_Package.create({
      data: {
        id: dto.id,
        travelMissionId: mission.id,
        packageCode: dto.packageCode,
        versionNumber: dto.versionNumber,
        title: dto.title,
        pdfUrl: pdfUrl || undefined,
        packageSha256: dto.packageSha256,
        completenessScore: dto.completenessScore,
        totalActualExpense: dto.totalActualExpense,
        activityCount: dto.activityCount || 0,
        evidenceCount: dto.evidenceCount || 0,
        receiptCount: dto.receiptCount || 0,
        documentCount: dto.documentCount || 0,
        contentSnapshot: JSON.stringify(dto.contentSnapshot),
        status: dto.status || 'GENERATED',
      },
    });

    // Update travel mission status to LPJ_READY if 100% complete or COMPLETED
    if (dto.completenessScore >= 1.0) {
      await this.prisma.travel_Mission.update({
        where: { id: mission.id },
        data: { status: TravelMissionStatus.LPJ_READY },
      });
    }

    await this.auditService.log({
      actorId: userId,
      action: 'LPJ_GENERATED',
      entity: 'LPJ_Package',
      entityId: pkg.id,
      metadata: {
        travelMissionId: mission.id,
        packageCode: pkg.packageCode,
        versionNumber: pkg.versionNumber,
        packageSha256: pkg.packageSha256,
      },
    });

    return pkg;
  }

  async findLpjPackages(userId: string, travelMissionId: string) {
    await this.findOneTravelMission(userId, travelMissionId);

    return this.prisma.lPJ_Package.findMany({
      where: { travelMissionId },
      orderBy: { versionNumber: 'desc' },
    });
  }

  async findOneLpjPackage(userId: string, id: string) {
    const pkg = await this.prisma.lPJ_Package.findUnique({
      where: { id },
      include: { travelMission: true },
    });

    if (!pkg) {
      throw new NotFoundException('Paket LPJ tidak ditemukan.');
    }

    if (pkg.travelMission.userId !== userId) {
      throw new ForbiddenException('Akses ke paket LPJ ditolak.');
    }

    return pkg;
  }
}
