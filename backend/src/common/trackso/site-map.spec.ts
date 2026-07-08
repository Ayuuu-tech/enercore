import { allSiteKeys, siteKeyForPlantName, TRACKSO_SITES } from './site-map';

describe('trackso site-map', () => {
  it('lists every configured site key', () => {
    expect(allSiteKeys()).toEqual(TRACKSO_SITES.map((s) => s.key));
  });

  it('maps Hollister-family names to its site key', () => {
    expect(siteKeyForPlantName('Hollister')).toBe('38124d4420');
    expect(siteKeyForPlantName('Plant Alpha')).toBe('38124d4420');
    expect(siteKeyForPlantName('HOLLISTER MEDICAL')).toBe('38124d4420');
  });

  it('maps Caparo-family names to its site key', () => {
    expect(siteKeyForPlantName('Caparo Maruti India Ltd Bawal')).toBe('d0dd69ac58');
    expect(siteKeyForPlantName('Plant Beta')).toBe('d0dd69ac58');
  });

  it('returns null for an unmapped plant', () => {
    expect(siteKeyForPlantName('Random Solar Farm')).toBeNull();
    expect(siteKeyForPlantName('')).toBeNull();
  });
});
