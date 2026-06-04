"use strict";
var __createBinding = (this && this.__createBinding) || (Object.create ? (function(o, m, k, k2) {
    if (k2 === undefined) k2 = k;
    var desc = Object.getOwnPropertyDescriptor(m, k);
    if (!desc || ("get" in desc ? !m.__esModule : desc.writable || desc.configurable)) {
      desc = { enumerable: true, get: function() { return m[k]; } };
    }
    Object.defineProperty(o, k2, desc);
}) : (function(o, m, k, k2) {
    if (k2 === undefined) k2 = k;
    o[k2] = m[k];
}));
var __setModuleDefault = (this && this.__setModuleDefault) || (Object.create ? (function(o, v) {
    Object.defineProperty(o, "default", { enumerable: true, value: v });
}) : function(o, v) {
    o["default"] = v;
});
var __importStar = (this && this.__importStar) || (function () {
    var ownKeys = function(o) {
        ownKeys = Object.getOwnPropertyNames || function (o) {
            var ar = [];
            for (var k in o) if (Object.prototype.hasOwnProperty.call(o, k)) ar[ar.length] = k;
            return ar;
        };
        return ownKeys(o);
    };
    return function (mod) {
        if (mod && mod.__esModule) return mod;
        var result = {};
        if (mod != null) for (var k = ownKeys(mod), i = 0; i < k.length; i++) if (k[i] !== "default") __createBinding(result, mod, k[i]);
        __setModuleDefault(result, mod);
        return result;
    };
})();
Object.defineProperty(exports, "__esModule", { value: true });
require("dotenv/config");
const client_1 = require("@prisma/client");
const adapter_pg_1 = require("@prisma/adapter-pg");
const pg_1 = require("pg");
const bcrypt = __importStar(require("bcrypt"));
const pool = new pg_1.Pool({ connectionString: process.env.DATABASE_URL });
const adapter = new adapter_pg_1.PrismaPg(pool);
const prisma = new client_1.PrismaClient({ adapter });
async function main() {
    console.log('Seeding database...');
    await prisma.notification.deleteMany();
    await prisma.ticketComment.deleteMany();
    await prisma.ticket.deleteMany();
    await prisma.orderItem.deleteMany();
    await prisma.order.deleteMany();
    await prisma.product.deleteMany();
    await prisma.invoice.deleteMany();
    await prisma.telemetry.deleteMany();
    await prisma.panel.deleteMany();
    await prisma.plant.deleteMany();
    await prisma.vendor.deleteMany();
    await prisma.user.deleteMany();
    console.log('Existing data cleared.');
    const passwordHash = await bcrypt.hash('password123', 10);
    const clientUser = await prisma.user.create({
        data: {
            email: 'client@enercore.com',
            password: passwordHash,
            name: 'Aditya Sharma',
            role: client_1.Role.CLIENT,
            phone: '+91-98765-43210',
            company: 'Verdant Energy Corp',
            gstNumber: 'GST22446681',
            postalCode: '94103',
            address: '455 Renewable Way, Silicon Valley, CA',
        },
    });
    const adminUser = await prisma.user.create({
        data: {
            email: 'admin@enercore.com',
            password: passwordHash,
            name: 'Rohan Gupta (Admin)',
            role: client_1.Role.ADMIN,
        },
    });
    const vendorUser = await prisma.user.create({
        data: {
            email: 'vendor@enercore.com',
            password: passwordHash,
            name: 'Rajesh Kumar',
            role: client_1.Role.VENDOR,
        },
    });
    console.log('Users created.');
    const vendor = await prisma.vendor.create({
        data: {
            id: vendorUser.id,
            companyName: 'Lumos Energy Solutions',
            rating: 4.8,
            isVerified: true,
        },
    });
    console.log('Vendor profiles created.');
    const plantAlpha = await prisma.plant.create({
        data: {
            name: 'Plant Alpha',
            location: 'Pune, Maharashtra',
            peakCapacity: 250.0,
            status: 'Active',
            ownerId: clientUser.id,
        },
    });
    const plantBeta = await prisma.plant.create({
        data: {
            name: 'Plant Beta',
            location: 'Mumbai, Maharashtra',
            peakCapacity: 120.0,
            status: 'Active',
            ownerId: clientUser.id,
        },
    });
    console.log('Plants created.');
    const panelsAlpha = [];
    for (let r = 1; r <= 2; r++) {
        for (let c = 1; c <= 2; c++) {
            const panel = await prisma.panel.create({
                data: {
                    row: r,
                    column: c,
                    status: r === 2 && c === 2 ? client_1.PanelStatus.WARNING : client_1.PanelStatus.HEALTHY,
                    voltage: r === 2 && c === 2 ? 38.2 : 42.5,
                    current: r === 2 && c === 2 ? 7.8 : 9.2,
                    temperature: r === 2 && c === 2 ? 55.4 : 45.2,
                    generation: r === 2 && c === 2 ? 297.9 : 391.0,
                    plantId: plantAlpha.id,
                },
            });
            panelsAlpha.push(panel);
        }
    }
    const panelsBeta = [];
    for (let c = 1; c <= 2; c++) {
        const panel = await prisma.panel.create({
            data: {
                row: 1,
                column: c,
                status: client_1.PanelStatus.HEALTHY,
                voltage: 41.8,
                current: 8.9,
                temperature: 42.1,
                generation: 372.0,
                plantId: plantBeta.id,
            },
        });
        panelsBeta.push(panel);
    }
    console.log('Panels created.');
    const timeNow = new Date();
    for (const panel of [...panelsAlpha, ...panelsBeta]) {
        for (let i = 4; i >= 0; i--) {
            const timestamp = new Date(timeNow.getTime() - i * 60 * 60 * 1000);
            const factor = 0.9 + Math.random() * 0.2;
            await prisma.telemetry.create({
                data: {
                    voltage: panel.voltage * factor,
                    current: panel.current * factor,
                    temperature: panel.temperature * factor,
                    generation: panel.generation * factor,
                    timestamp,
                    panelId: panel.id,
                    plantId: panel.plantId,
                },
            });
        }
    }
    console.log('Telemetry logs seeded.');
    await prisma.invoice.create({
        data: {
            invoiceNumber: 'INV-2023-1024',
            amount: 12400.0,
            period: 'Oct 2023',
            status: client_1.InvoiceStatus.PENDING,
            dueDate: new Date('2023-10-31T23:59:59Z'),
            userId: clientUser.id,
            plantId: plantAlpha.id,
        },
    });
    await prisma.invoice.create({
        data: {
            invoiceNumber: 'INV-2023-0915',
            amount: 8200.0,
            period: 'Sep 2023',
            status: client_1.InvoiceStatus.PAID,
            dueDate: new Date('2023-09-30T23:59:59Z'),
            paidAt: new Date('2023-09-15T12:00:00Z'),
            userId: clientUser.id,
            plantId: plantAlpha.id,
        },
    });
    console.log('Invoices seeded.');
    const p1 = await prisma.product.create({
        data: {
            title: '550W Monocrystalline PV Module',
            brand: 'LUMOS ENERGY',
            spec: '22.5% Efficiency | Half-cut Cell Tech',
            rating: 4.8,
            reviewsCount: 156,
            price: 18450.0,
            originalPrice: 21000.0,
            isAssured: true,
            category: 'Solar Panels',
            stock: 500,
            vendorId: vendor.id,
        },
    });
    const p2 = await prisma.product.create({
        data: {
            title: '440W Bifacial Dual Glass Panel',
            brand: 'ECOPOWER',
            spec: 'High Output | 30-year Warranty',
            rating: 4.9,
            reviewsCount: 82,
            price: 15200.0,
            isAssured: true,
            category: 'Solar Panels',
            stock: 350,
            vendorId: vendor.id,
        },
    });
    const p3 = await prisma.product.create({
        data: {
            title: '10kW Hybrid Solar Inverter',
            brand: 'LUMOS ENERGY',
            spec: 'Dual MPPT Tracker | IP65 Protection',
            rating: 4.7,
            reviewsCount: 45,
            price: 82000.0,
            originalPrice: 95000.0,
            isAssured: false,
            category: 'Inverters',
            stock: 20,
            vendorId: vendor.id,
        },
    });
    console.log('Products seeded.');
    const order = await prisma.order.create({
        data: {
            orderNumber: 'ORD-2023-1105-01',
            totalAmount: 18450.0 * 2 + 82000.0,
            status: client_1.OrderStatus.PENDING,
            userId: clientUser.id,
            items: {
                create: [
                    {
                        productId: p1.id,
                        quantity: 2,
                        priceAtPurchase: 18450.0,
                    },
                    {
                        productId: p3.id,
                        quantity: 1,
                        priceAtPurchase: 82000.0,
                    },
                ],
            },
        },
    });
    console.log('Orders seeded.');
    const ticket = await prisma.ticket.create({
        data: {
            ticketNumber: 'TKT-1042',
            title: 'Inverter Efficiency Drop',
            description: 'The plant inverter efficiency has fallen below 85% since yesterday afternoon. Please inspect.',
            status: client_1.TicketStatus.IN_PROGRESS,
            priority: client_1.TicketPriority.HIGH,
            lastUpdateMessage: 'Technical team is investigating the voltage surge',
            userId: clientUser.id,
            plantId: plantAlpha.id,
        },
    });
    await prisma.ticketComment.create({
        data: {
            ticketId: ticket.id,
            userId: clientUser.id,
            message: 'Here is a screenshot of the grid monitoring app showing the anomaly.',
        },
    });
    await prisma.ticketComment.create({
        data: {
            ticketId: ticket.id,
            userId: adminUser.id,
            message: 'Technical team is investigating the voltage surge. We will update you in a few hours.',
        },
    });
    console.log('Tickets and comments seeded.');
    await prisma.notification.create({
        data: {
            userId: clientUser.id,
            title: 'Invoice Due Alert',
            message: 'Your invoice INV-2023-1024 of ₹12,400 is due on Oct 31.',
            read: false,
        },
    });
    await prisma.notification.create({
        data: {
            userId: clientUser.id,
            title: 'Support Ticket In Progress',
            message: 'Rohan Gupta (Admin) updated your support ticket TKT-1042: "Technical team is investigating..."',
            read: true,
        },
    });
    console.log('Notifications seeded.');
    console.log('Database seeded successfully!');
}
main()
    .catch((e) => {
    console.error(e);
    process.exit(1);
})
    .finally(async () => {
    await prisma.$disconnect();
});
//# sourceMappingURL=seed.js.map