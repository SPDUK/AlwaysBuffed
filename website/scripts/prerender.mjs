import { appendFile, readFile, writeFile } from 'node:fs/promises';
import { fileURLToPath } from 'node:url';
import { loadEnv } from 'vite';
import { render } from '../.prerender/entry-server.js';

const output = new URL('../dist/', import.meta.url);
const index = new URL('index.html', output);
const template = await readFile(index, 'utf8');

const project = fileURLToPath(new URL('../', import.meta.url));
const siteUrl = loadEnv('production', project, 'SITE_').SITE_URL?.trim();
let homepage;
if (siteUrl) {
  homepage = URL.canParse(siteUrl) ? new URL(siteUrl) : null;
  if (!homepage || !['http:', 'https:'].includes(homepage.protocol) || homepage.search || homepage.hash || homepage.username || homepage.password) {
    throw new Error('SITE_URL must be an HTTP(S) homepage URL without credentials, a query, or a fragment');
  }
  homepage.pathname = homepage.pathname.replace(/\/?$/, '/');
}

const application = {
  '@context': 'https://schema.org',
  '@type': 'SoftwareApplication',
  name: 'AlwaysBuffed',
  description: 'Consumable recommendations, shopping lists, and buff reminders for World of Warcraft: Forever.',
  applicationCategory: 'GameApplication',
  operatingSystem: 'Windows, macOS',
  softwareRequirements: 'World of Warcraft: Forever',
  downloadUrl: 'https://github.com/SPDUK/AlwaysBuffed/releases/latest',
  author: { '@type': 'Person', name: 'SPDUK', url: 'https://github.com/SPDUK' },
  sameAs: 'https://github.com/SPDUK/AlwaysBuffed',
  license: 'https://www.gnu.org/licenses/gpl-3.0.html',
  offers: { '@type': 'Offer', price: 0, priceCurrency: 'USD' },
};

const metadata = [];
if (homepage) {
  const image = new URL('art/hero.webp', homepage).href;
  Object.assign(application, { url: homepage.href, image });
  metadata.push(
    `<link rel="canonical" href="${escapeMarkup(homepage.href)}" />`,
    `<meta property="og:url" content="${escapeMarkup(homepage.href)}" />`,
    `<meta property="og:image" content="${escapeMarkup(image)}" />`,
    '<meta property="og:image:alt" content="Sunlight through the trees of Ashenvale in World of Warcraft: Forever" />',
    '<meta name="twitter:card" content="summary_large_image" />',
  );
}
metadata.push(`<script type="application/ld+json">${JSON.stringify(application).replaceAll('<', '\\u003c')}</script>`);

const appMarker = '<!--app-html-->';
const metadataMarker = '<!--site-metadata-->';
if (!template.includes(appMarker) || !template.includes(metadataMarker)) {
  throw new Error('Built index.html is missing the AlwaysBuffed render markers');
}

await writeFile(index, template
  .replace(metadataMarker, () => metadata.join('\n    '))
  .replace(appMarker, () => render()));

if (homepage) {
  const sitemapUrl = new URL('sitemap.xml', homepage).href;
  await Promise.all([
    writeFile(new URL('sitemap.xml', output), `<?xml version="1.0" encoding="UTF-8"?>\n<urlset xmlns="http://www.sitemaps.org/schemas/sitemap/0.9">\n  <url><loc>${escapeMarkup(homepage.href)}</loc></url>\n</urlset>\n`),
    appendFile(new URL('robots.txt', output), `\nSitemap: ${sitemapUrl}\n`),
  ]);
}

function escapeMarkup(value) {
  return value.replaceAll('&', '&amp;').replaceAll('"', '&quot;').replaceAll('<', '&lt;').replaceAll('>', '&gt;');
}
