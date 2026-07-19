import { Module } from '@nestjs/common';
import { ConfigModule } from '@nestjs/config';
import { APP_GUARD } from '@nestjs/core';
import { ThrottlerGuard, ThrottlerModule } from '@nestjs/throttler';
import { AppController } from './app.controller';
import { AppService } from './app.service';

// Import Feature Modules
import { PrismaModule } from './common/prisma/prisma.module';
import { StorageModule } from './common/storage/storage.module';
import { PlantAccessModule } from './common/access/plant-access.module';
import { AuditModule } from './common/audit/audit.module';
import { AuthModule } from './modules/auth/auth.module';
import { UsersModule } from './modules/users/users.module';
import { PlantsModule } from './modules/plants/plants.module';
import { TelemetryModule } from './modules/telemetry/telemetry.module';
import { BillingModule } from './modules/billing/billing.module';
import { VendorsModule } from './modules/vendors/vendors.module';
import { MarketplaceModule } from './modules/marketplace/marketplace.module';
import { OrdersModule } from './modules/orders/orders.module';
import { TicketingModule } from './modules/ticketing/ticketing.module';
import { NotificationModule } from './modules/notification/notification.module';
import { AdminModule } from './modules/admin/admin.module';
import { SettingsModule } from './modules/settings/settings.module';

@Module({
  imports: [
    // Global rate limit. Auth routes tighten this further with @Throttle.
    ThrottlerModule.forRoot([{ ttl: 60_000, limit: 120 }]),
    ConfigModule.forRoot({ isGlobal: true }),
    PrismaModule,
    StorageModule,
    PlantAccessModule,
    AuditModule,
    AuthModule,
    UsersModule,
    PlantsModule,
    TelemetryModule,
    BillingModule,
    VendorsModule,
    MarketplaceModule,
    OrdersModule,
    TicketingModule,
    NotificationModule,
    AdminModule,
    SettingsModule,
  ],
  controllers: [AppController],
  providers: [
    AppService,
    // Apply the rate limiter to every route.
    { provide: APP_GUARD, useClass: ThrottlerGuard },
  ],
})
export class AppModule {}
