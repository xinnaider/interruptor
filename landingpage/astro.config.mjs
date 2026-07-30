import sitemap from "@astrojs/sitemap";
import { defineConfig } from "astro/config";

export default defineConfig({
  site: "https://interruptor.jfernando.dev",
  integrations: [
    sitemap({
      i18n: {
        defaultLocale: "pt",
        locales: {
          pt: "pt-BR",
          en: "en",
        },
      },
    }),
  ],
});
