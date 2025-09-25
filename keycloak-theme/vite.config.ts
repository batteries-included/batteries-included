import { defineConfig } from 'vite';
import react from '@vitejs/plugin-react';
import { keycloakify } from 'keycloakify/vite-plugin';
import tailwindcss from '@tailwindcss/vite';

// https://vitejs.dev/config/
export default defineConfig({
  plugins: [
    tailwindcss(),
    react(),
    keycloakify({
      accountThemeImplementation: 'none',
      // This line needs to always be here
      // It is set by the bi-source script
      // to the current version of the batteries-included platform
      themeVersion: '1.6.0',
    }),
  ],
});
