// One-off, non-destructive: fills each plant's panel grid up to a target size
// (16x16 for the largest plant, 8x8 for others) without deleting existing data.
import 'dotenv/config';
import { PrismaClient, PanelStatus } from '@prisma/client';
import { PrismaPg } from '@prisma/adapter-pg';
import { Pool } from 'pg';

const pool = new Pool({ connectionString: process.env.DATABASE_URL });
const adapter = new PrismaPg(pool);
const prisma = new PrismaClient({ adapter });

async function main() {
  const plants = await prisma.plant.findMany({ orderBy: { peakCapacity: 'desc' } });
  if (plants.length === 0) {
    console.log('No plants found. Run the full seed first.');
    return;
  }

  for (let i = 0; i < plants.length; i++) {
    const plant = plants[i];
    const size = i === 0 ? 16 : 8; // largest plant gets 16x16, rest 8x8
    const existing = await prisma.panel.findMany({
      where: { plantId: plant.id },
      select: { row: true, column: true },
    });
    const taken = new Set(existing.map((p) => `${p.row}:${p.column}`));

    let created = 0;
    for (let r = 1; r <= size; r++) {
      for (let c = 1; c <= size; c++) {
        if (taken.has(`${r}:${c}`)) continue;
        const isWarning = (r * size + c) % 37 === 0;
        await prisma.panel.create({
          data: {
            row: r,
            column: c,
            status: isWarning ? PanelStatus.WARNING : PanelStatus.HEALTHY,
            voltage: isWarning ? 38.2 : 42.5,
            current: isWarning ? 7.8 : 9.2,
            temperature: isWarning ? 55.4 : 45.2,
            generation: isWarning ? 297.9 : 391.0,
            plantId: plant.id,
          },
        });
        created++;
      }
    }
    console.log(`${plant.name}: grid ${size}x${size}, ${existing.length} existing, ${created} created.`);
  }
}

main()
  .catch((e) => {
    console.error(e);
    process.exit(1);
  })
  .finally(() => prisma.$disconnect());
