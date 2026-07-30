# Interruptor

Menubar app para macOS: **soft disconnect** do monitor externo sem puxar o cabo.

```
Interruptor/
├── app/           → app Swift (menubar)
├── landingpage/   → site Astro (interruptor.jfernando.dev)
├── deploy/        → compose + nginx para produção
└── .github/       → CI/CD
```

## App

```bash
cd app
./build.sh
open Interruptor.app
```

- Apple Silicon, macOS 14+
- Atalho gravável (padrão `⌃⌥⌘I`)
- Multi monitor: um interruptor por tela
- Idioma segue o sistema (sem seletor manual)
- Atualização automática via GitHub Releases / appcast

## Landing page

```bash
cd landingpage
npm install
npm run dev      # http://localhost:4321
```

Produção: https://interruptor.jfernando.dev

## CI/CD

### Landing (push em `main`)

Workflow `.github/workflows/landing.yml` no runner **self-hosted** da Contabo:

1. `git pull` em `/home/gha-runner/interruptor`
2. `docker build` da landing
3. `docker compose up` em `/home/gha-runner/interruptor-landing`

Sem secrets SSH. Runner registrado como `contabo-interruptor`.

### Release macOS (tag `v*`)

Workflow `.github/workflows/release.yml`:

1. Roda no runner **self-hosted macOS** (label `macOS`)
2. Compila `Interruptor.app`, gera `.zip` + `appcast.json`
3. Publica GitHub Release

```bash
# Registrar runner no Mac (uma vez):
# Settings → Actions → Runners → New self-hosted → macOS → label: macOS

# Publicar versão:
echo "1.0.1" > VERSION
git add VERSION && git commit -m "chore: bump version"
git tag v1.0.1 && git push origin main --tags
```

## Licença

MIT
