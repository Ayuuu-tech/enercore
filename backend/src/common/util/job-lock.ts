import { PrismaService } from '../prisma/prisma.service';

/**
 * Stable 32-bit key for a named job, for Postgres advisory locks.
 * (djb2 — any stable hash will do; it just has to agree across instances.)
 */
function jobKey(name: string): number {
  let h = 5381;
  for (let i = 0; i < name.length; i++) h = ((h << 5) + h + name.charCodeAt(i)) | 0;
  return h;
}

/**
 * Runs `fn` only if this instance can take the named lock, so a scheduled job
 * never runs concurrently across replicas (double telemetry rows, double
 * bills). The lock is session-scoped and always released in `finally`.
 *
 * Returns the job's result, or `undefined` when another instance holds the lock.
 */
export async function withJobLock<T>(
  prisma: PrismaService,
  name: string,
  fn: () => Promise<T>,
): Promise<T | undefined> {
  const key = jobKey(name);
  const [{ locked }] = await prisma.$queryRaw<{ locked: boolean }[]>`
    SELECT pg_try_advisory_lock(${key}::bigint) AS locked
  `;
  if (!locked) return undefined;
  try {
    return await fn();
  } finally {
    await prisma.$queryRaw`SELECT pg_advisory_unlock(${key}::bigint)`;
  }
}
