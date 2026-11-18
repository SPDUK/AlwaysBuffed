import { readFileSync } from 'node:fs';
import react from '@vitejs/plugin-react';
import { defineConfig, loadEnv } from 'vite';

const toc = readFileSync(new URL('../AlwaysBuffed/AlwaysBuffed.toc', import.meta.url), 'utf8');
const addonVersion = toc.match(/^## Version:[ \t]+(\S+)/m)?.[1];
if (!addonVersion) throw new Error('AlwaysBuffed.toc is missing its Version field');

export default defineConfig(({ isSsrBuild, mode }) => {
  const siteUrl = loadEnv(mode, process.cwd(), "SITE_").SITE_URL?.trim();
  const base = siteUrl ? new URL(siteUrl).pathname.replace(/\/?$/, "/") : "/";
  return {
    base,
    plugins: [react()],
    define: { __ADDON_VERSION__: JSON.stringify(addonVersion) },
    build: { copyPublicDir: !isSsrBuild },
  };
});
