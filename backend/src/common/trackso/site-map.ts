/**
 * Single source of truth for Trackso site identity. Previously the site keys
 * and the plant-name → key mapping were duplicated across the sync, report and
 * access services (magic strings). Everything now funnels through here.
 */
export interface TracksoSite {
  key: string;
  /** Lowercase substrings of a plant's name that map to this site. */
  aliases: string[];
}

export const TRACKSO_SITES: TracksoSite[] = [
  { key: '38124d4420', aliases: ['hollister', 'alpha'] },
  { key: 'd0dd69ac58', aliases: ['caparo', 'beta'] },
];

/** All configured site keys. */
export function allSiteKeys(): string[] {
  return TRACKSO_SITES.map((s) => s.key);
}

/** Resolve a plant's name to its Trackso site key, or null if unmapped. */
export function siteKeyForPlantName(name: string): string | null {
  const n = name.toLowerCase();
  for (const site of TRACKSO_SITES) {
    if (site.aliases.some((a) => n.includes(a))) return site.key;
  }
  return null;
}
