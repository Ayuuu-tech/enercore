import { PanelStatus } from '@prisma/client';
export declare class CreatePanelDto {
    row: number;
    column: number;
    status?: PanelStatus;
}
