import { Controller, Get } from '@nestjs/common';
import { AppService } from './app.service';
import { PrismaService } from './common/prisma/prisma.service';

@Controller()
export class AppController {
  constructor(
    private readonly appService: AppService,
    private readonly prisma: PrismaService,
  ) {}

  @Get()
  getHello(): string {
    return this.appService.getHello();
  }

  /**
   * Liveness + readiness probe. Returns 200 only when the process is up AND the
   * database answers a trivial query — so Azure "Always On" and any uptime
   * monitor can tell a real outage (DB down) from a healthy instance.
   */
  @Get('health')
  async health() {
    let database = 'up';
    let ok = true;
    try {
      await this.prisma.$queryRaw`SELECT 1`;
    } catch {
      database = 'down';
      ok = false;
    }
    return {
      status: ok ? 'ok' : 'degraded',
      database,
      uptime: Math.round(process.uptime()),
      timestamp: new Date().toISOString(),
    };
  }
}
