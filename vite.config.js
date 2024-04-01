import { fileURLToPath, URL } from 'node:url'

import { defineConfig } from 'vite'

import glsl from 'vite-plugin-glsl'

export default defineConfig({
  plugins: [glsl()],
  resolve: {
    alias: {
      '@': fileURLToPath(new URL('./src', import.meta.url))
    }
  },
})
