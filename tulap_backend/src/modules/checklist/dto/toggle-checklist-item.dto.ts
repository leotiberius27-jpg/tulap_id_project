import { IsBoolean, IsNotEmpty } from 'class-validator';

export class ToggleChecklistItemDto {
  @IsBoolean()
  @IsNotEmpty()
  isCompleted: boolean;
}
