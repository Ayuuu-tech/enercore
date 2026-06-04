"use strict";
var __decorate = (this && this.__decorate) || function (decorators, target, key, desc) {
    var c = arguments.length, r = c < 3 ? target : desc === null ? desc = Object.getOwnPropertyDescriptor(target, key) : desc, d;
    if (typeof Reflect === "object" && typeof Reflect.decorate === "function") r = Reflect.decorate(decorators, target, key, desc);
    else for (var i = decorators.length - 1; i >= 0; i--) if (d = decorators[i]) r = (c < 3 ? d(r) : c > 3 ? d(target, key, r) : d(target, key)) || r;
    return c > 3 && r && Object.defineProperty(target, key, r), r;
};
Object.defineProperty(exports, "__esModule", { value: true });
exports.AppModule = void 0;
const common_1 = require("@nestjs/common");
const config_1 = require("@nestjs/config");
const app_controller_1 = require("./app.controller");
const app_service_1 = require("./app.service");
const prisma_module_1 = require("./common/prisma/prisma.module");
const supabase_module_1 = require("./common/supabase/supabase.module");
const auth_module_1 = require("./modules/auth/auth.module");
const users_module_1 = require("./modules/users/users.module");
const plants_module_1 = require("./modules/plants/plants.module");
const telemetry_module_1 = require("./modules/telemetry/telemetry.module");
const billing_module_1 = require("./modules/billing/billing.module");
const vendors_module_1 = require("./modules/vendors/vendors.module");
const marketplace_module_1 = require("./modules/marketplace/marketplace.module");
const orders_module_1 = require("./modules/orders/orders.module");
const ticketing_module_1 = require("./modules/ticketing/ticketing.module");
const notification_module_1 = require("./modules/notification/notification.module");
const admin_module_1 = require("./modules/admin/admin.module");
let AppModule = class AppModule {
};
exports.AppModule = AppModule;
exports.AppModule = AppModule = __decorate([
    (0, common_1.Module)({
        imports: [
            config_1.ConfigModule.forRoot({ isGlobal: true }),
            prisma_module_1.PrismaModule,
            supabase_module_1.SupabaseModule,
            auth_module_1.AuthModule,
            users_module_1.UsersModule,
            plants_module_1.PlantsModule,
            telemetry_module_1.TelemetryModule,
            billing_module_1.BillingModule,
            vendors_module_1.VendorsModule,
            marketplace_module_1.MarketplaceModule,
            orders_module_1.OrdersModule,
            ticketing_module_1.TicketingModule,
            notification_module_1.NotificationModule,
            admin_module_1.AdminModule,
        ],
        controllers: [app_controller_1.AppController],
        providers: [app_service_1.AppService],
    })
], AppModule);
//# sourceMappingURL=app.module.js.map