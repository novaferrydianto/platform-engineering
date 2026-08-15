import { defineConfig } from 'vite';

export default defineConfig({
  build: {
    outDir: 'dist',
    sourcemap: true,
    // Long-cache hashed assets; index.html stays short-cached at the CDN.
    assetsDir: 'assets',
  },
  server: {
    port: 5173,
  },
});
