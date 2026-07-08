import 'dotenv/config';
import { PrismaClient, Role, PanelStatus, InvoiceStatus, OrderStatus, TicketStatus, TicketPriority } from '@prisma/client';
import { PrismaPg } from '@prisma/adapter-pg';
import { Pool } from 'pg';
import * as bcrypt from 'bcrypt';

const pool = new Pool({ connectionString: process.env.DATABASE_URL });
const adapter = new PrismaPg(pool);
const prisma = new PrismaClient({ adapter });

async function main() {
  console.log('Seeding database...');

  // 1. Clear database
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

  // Hash password
  const passwordHash = await bcrypt.hash('password123', 10);

  // 2. Create Users
  const clientUser = await prisma.user.create({
    data: {
      email: 'client@enercore.com',
      password: passwordHash,
      name: 'Aditya Sharma',
      role: Role.CLIENT,
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
      role: Role.ADMIN,
    },
  });

  const vendorUser = await prisma.user.create({
    data: {
      email: 'vendor@enercore.com',
      password: passwordHash,
      name: 'Rajesh Kumar',
      role: Role.VENDOR,
    },
  });

  console.log('Users created.');

  // 3. Create Vendor Profile
  const vendor = await prisma.vendor.create({
    data: {
      id: vendorUser.id,
      companyName: 'Lumos Energy Solutions',
      rating: 4.8,
      isVerified: true,
    },
  });

  console.log('Vendor profiles created.');

  // 4. Create Plants
  // Real Trackso sites
  const plantAlpha = await prisma.plant.create({
    data: {
      name: 'Hollister',
      location: 'Bawal, Haryana',
      peakCapacity: 497.0,
      status: 'Active',
      ownerId: clientUser.id,
    },
  });

  const plantBeta = await prisma.plant.create({
    data: {
      name: 'Caparo Maruti India Ltd Bawal',
      location: 'Bawal, Haryana',
      peakCapacity: 507.0,
      status: 'Active',
      ownerId: clientUser.id,
    },
  });

  console.log('Plants created.');

  // 5. Create Panels for Plants
  // Plant Alpha Grid (16x16 = 256 units)
  const panelsAlpha = [];
  for (let r = 1; r <= 16; r++) {
    for (let c = 1; c <= 16; c++) {
      const isWarning = (r * 16 + c) % 37 === 0;
      const panel = await prisma.panel.create({
        data: {
          row: r,
          column: c,
          status: isWarning ? PanelStatus.WARNING : PanelStatus.HEALTHY,
          voltage: isWarning ? 38.2 : 42.5,
          current: isWarning ? 7.8 : 9.2,
          temperature: isWarning ? 55.4 : 45.2,
          generation: isWarning ? 297.9 : 391.0,
          plantId: plantAlpha.id,
        },
      });
      panelsAlpha.push(panel);
    }
  }

  // Plant Beta Grid (8x8 = 64 units)
  const panelsBeta = [];
  for (let r = 1; r <= 8; r++) {
    for (let c = 1; c <= 8; c++) {
      const panel = await prisma.panel.create({
        data: {
          row: r,
          column: c,
          status: PanelStatus.HEALTHY,
          voltage: 41.8,
          current: 8.9,
          temperature: 42.1,
          generation: 372.0,
          plantId: plantBeta.id,
        },
      });
      panelsBeta.push(panel);
    }
  }

  console.log('Panels created.');

  // 6. Seed Telemetry (Historical Sensor Logs)
  const timeNow = new Date();
  for (const panel of [...panelsAlpha, ...panelsBeta]) {
    // Generate 5 historical telemetry logs (every 1 hour back)
    for (let i = 4; i >= 0; i--) {
      const timestamp = new Date(timeNow.getTime() - i * 60 * 60 * 1000);
      // Slightly randomize values
      const factor = 0.9 + Math.random() * 0.2; // 0.9 to 1.1
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

  // 7. Seed Invoices
  await prisma.invoice.create({
    data: {
      invoiceNumber: 'INV-2023-1024',
      amount: 12400.0,
      period: 'Oct 2023',
      status: InvoiceStatus.PENDING,
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
      status: InvoiceStatus.PAID,
      dueDate: new Date('2023-09-30T23:59:59Z'),
      paidAt: new Date('2023-09-15T12:00:00Z'),
      userId: clientUser.id,
      plantId: plantAlpha.id,
    },
  });

  console.log('Invoices seeded.');

  // 8. Seed Products
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

  // 9. Seed Orders
  const order = await prisma.order.create({
    data: {
      orderNumber: 'ORD-2023-1105-01',
      totalAmount: 18450.0 * 2 + 82000.0,
      status: OrderStatus.PENDING,
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

  // 10. Seed Support Tickets
  const ticket = await prisma.ticket.create({
    data: {
      ticketNumber: 'TKT-1042',
      title: 'Inverter Efficiency Drop',
      description: 'The plant inverter efficiency has fallen below 85% since yesterday afternoon. Please inspect.',
      status: TicketStatus.IN_PROGRESS,
      priority: TicketPriority.HIGH,
      lastUpdateMessage: 'Technical team is investigating the voltage surge',
      userId: clientUser.id,
      plantId: plantAlpha.id,
    },
  });

  // Ticket comments
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

  // 11. Seed Notifications
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
