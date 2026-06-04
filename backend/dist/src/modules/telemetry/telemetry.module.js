"use strict";
var __decorate = (this && this.__decorate) || function (decorators, target, key, desc) {
    var c = arguments.length, r = c < 3 ? target : desc === null ? desc = Object.getOwnPropertyDescriptor(target, key) : desc, d;
    if (typeof Reflect === "object" && typeof Reflect.decorate === "function") r = Reflect.decorate(decorators, target, key, desc);
    else for (var i = decorators.length - 1; i >= 0; i--) if (d = decorators[i]) r = (c < 3 ? d(r) : c > 3 ? d(target, key, r) : d(target, key)) || r;
    return c > 3 && r && Object.defineProperty(target, key, r), r;
};
Object.defineProperty(exports, "__esModule", { value: true });
exports.TelemetryModule = void 0;
const common_1 = require("@nestjs/common");
const telemetry_service_1 = require("./application/telemetry.service");
const telemetry_controller_1 = require("./presentation/telemetry.controller");
const prisma_telemetry_repository_1 = require("./infrastructure/prisma-telemetry.repository");
const prisma_module_1 = require("../../common/prisma/prisma.module");
let TelemetryModule = class TelemetryModule {
};
exports.TelemetryModule = TelemetryModule;
exports.TelemetryModule = TelemetryModule = __decorate([
    (0, common_1.Module)({
        imports: [prisma_module_1.PrismaModule],
        controllers: [telemetry_controller_1.TelemetryController],
        providers: [
            telemetry_service_1.TelemetryService,
            {
                provide: 'ITelemetryRepository',
                useClass: prisma_telemetry_repository_1.PrismaTelemetryRepository,
            },
        ],
        exports: [telemetry_service_1.TelemetryService, 'ITelemetryRepository'],
    })
], TelemetryModule);
//# sourceMappingURL=telemetry.module.js.map