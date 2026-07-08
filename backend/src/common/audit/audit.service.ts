import { Injectable, Logger } from '@nestjs/common';
import { PrismaService } from '../prisma/prisma.service';

export interface AuditActor {
  id: string;
  name: string;
}

/** Records admin actions into an immutable audit trail. */
@Injectable()
export class AuditService {
  private readonly logger = new Logger(AuditService.name);

  constructor(private readonly prisma: PrismaService) {}

  async log(
    actor: AuditActor,
    action: string,
    opts: { targetType?: string; targetId?: string; detail?: string } = {},
  ): Promise<void> {
    try {
      await this.prisma.auditLog.create({
        data: {
          actorId: actor.id,
          actorName: actor.name,
          action,
          targetType: opts.targetType,
          targetId: opts.targetId,
          detail: opts.detail,
        },
      });
    } catch (err) {
      // Never let audit failures break the primary action.
      this.logger.error(`Failed to write audit log for "${action}"`, err as Error);
    }
  }

  async list(limit = 100) {
    return this.prisma.auditLog.findMany({
      orderBy: { createdAt: 'desc' },
      take: Math.min(Math.max(limit, 1), 500),
    });
  }
}
