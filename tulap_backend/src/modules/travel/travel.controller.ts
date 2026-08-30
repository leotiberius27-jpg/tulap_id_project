import {
  Body,
  Controller,
  Delete,
  Get,
  Param,
  Patch,
  Post,
  Query,
  UploadedFile,
  UseGuards,
  UseInterceptors,
} from '@nestjs/common';
import { FileInterceptor } from '@nestjs/platform-express';
import { CurrentUser } from '../../common/decorators/current-user.decorator';
import { JwtAuthGuard } from '../../common/guards/jwt-auth.guard';
import { AuthenticatedUser } from '../auth/interfaces/authenticated-user.interface';
import { CreateLpjPackageDto } from './dto/create-lpj-package.dto';
import { CreateSupportingDocumentDto } from './dto/create-supporting-document.dto';
import { CreateTravelMissionDto } from './dto/create-travel-mission.dto';
import { UpdateTravelMissionDto } from './dto/update-travel-mission.dto';
import { TravelService } from './travel.service';

@Controller('travel')
@UseGuards(JwtAuthGuard)
export class TravelController {
  constructor(private readonly travelService: TravelService) {}

  @Post()
  async create(
    @CurrentUser() user: AuthenticatedUser,
    @Body() dto: CreateTravelMissionDto,
  ) {
    return this.travelService.createTravelMission(user.id, dto);
  }

  @Get()
  async findAll(
    @CurrentUser() user: AuthenticatedUser,
    @Query('search') search?: string,
    @Query('status') status?: string,
    @Query('year') year?: string,
  ) {
    const yearNum = year ? parseInt(year, 10) : undefined;
    return this.travelService.findAllTravelMissions(
      user.id,
      search,
      status,
      yearNum,
    );
  }

  @Get(':id')
  async findOne(
    @CurrentUser() user: AuthenticatedUser,
    @Param('id') id: string,
  ) {
    return this.travelService.findOneTravelMission(user.id, id);
  }

  @Patch(':id')
  async update(
    @CurrentUser() user: AuthenticatedUser,
    @Param('id') id: string,
    @Body() dto: UpdateTravelMissionDto,
  ) {
    return this.travelService.updateTravelMission(user.id, id, dto);
  }

  @Delete(':id')
  async delete(
    @CurrentUser() user: AuthenticatedUser,
    @Param('id') id: string,
  ) {
    return this.travelService.deleteTravelMission(user.id, id);
  }

  @Post('document')
  @UseInterceptors(FileInterceptor('file'))
  async uploadDocument(
    @CurrentUser() user: AuthenticatedUser,
    @Body() dto: CreateSupportingDocumentDto,
    @UploadedFile() file?: Express.Multer.File,
  ) {
    return this.travelService.uploadSupportingDocument(user.id, dto, file);
  }

  @Get(':id/documents')
  async findDocuments(
    @CurrentUser() user: AuthenticatedUser,
    @Param('id') id: string,
  ) {
    return this.travelService.findSupportingDocuments(user.id, id);
  }

  @Delete('document/:id')
  async deleteDocument(
    @CurrentUser() user: AuthenticatedUser,
    @Param('id') id: string,
  ) {
    return this.travelService.deleteSupportingDocument(user.id, id);
  }

  @Post('lpj')
  @UseInterceptors(FileInterceptor('file'))
  async createLpj(
    @CurrentUser() user: AuthenticatedUser,
    @Body() dto: CreateLpjPackageDto,
    @UploadedFile() file?: Express.Multer.File,
  ) {
    return this.travelService.createOrUpdateLpjPackage(user.id, dto, file);
  }

  @Get(':id/lpj')
  async findLpjPackages(
    @CurrentUser() user: AuthenticatedUser,
    @Param('id') id: string,
  ) {
    return this.travelService.findLpjPackages(user.id, id);
  }

  @Get('lpj/:id')
  async findOneLpj(
    @CurrentUser() user: AuthenticatedUser,
    @Param('id') id: string,
  ) {
    return this.travelService.findOneLpjPackage(user.id, id);
  }
}
