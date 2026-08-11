import { IsNotEmpty, IsUUID } from 'class-validator';

export class GenerateLpjDto {
  @IsUUID()
  @IsNotEmpty()
  taskId: string;
}
