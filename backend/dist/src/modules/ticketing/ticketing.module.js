"use strict";
var __decorate = (this && this.__decorate) || function (decorators, target, key, desc) {
    var c = arguments.length, r = c < 3 ? target : desc === null ? desc = Object.getOwnPropertyDescriptor(target, key) : desc, d;
    if (typeof Reflect === "object" && typeof Reflect.decorate === "function") r = Reflect.decorate(decorators, target, key, desc);
    else for (var i = decorators.length - 1; i >= 0; i--) if (d = decorators[i]) r = (c < 3 ? d(r) : c > 3 ? d(target, key, r) : d(target, key)) || r;
    return c > 3 && r && Object.defineProperty(target, key, r), r;
};
Object.defineProperty(exports, "__esModule", { value: true });
exports.TicketingModule = void 0;
const common_1 = require("@nestjs/common");
const ticketing_service_1 = require("./application/ticketing.service");
const ticketing_controller_1 = require("./presentation/ticketing.controller");
const prisma_ticket_repository_1 = require("./infrastructure/prisma-ticket.repository");
const prisma_module_1 = require("../../common/prisma/prisma.module");
let TicketingModule = class TicketingModule {
};
exports.TicketingModule = TicketingModule;
exports.TicketingModule = TicketingModule = __decorate([
    (0, common_1.Module)({
        imports: [prisma_module_1.PrismaModule],
        controllers: [ticketing_controller_1.TicketingController],
        providers: [
            ticketing_service_1.TicketingService,
            {
                provide: 'ITicketRepository',
                useClass: prisma_ticket_repository_1.PrismaTicketRepository,
            },
        ],
        exports: [ticketing_service_1.TicketingService, 'ITicketRepository'],
    })
], TicketingModule);
//# sourceMappingURL=ticketing.module.js.map