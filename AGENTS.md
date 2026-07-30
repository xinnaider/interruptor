# AGENTS.md — Interruptor

Instruções para agentes de IA neste repositório.

## Visão geral

| Pasta | O quê | Stack |
|-------|-------|-------|
| `app/` | App menubar macOS (Apple Silicon) | Swift — `build.sh` + `swiftc` |
| `landingpage/` | Site estático | Astro 5 |
| `deploy/` | Docker no Contabo | nginx |

- **Site:** https://interruptor.jfernando.dev
- **Repo:** https://github.com/xinnaider/interruptor
- **Autor git:** `xinnaider <fernandoschnneider@gmail.com>`

## Regras

1. **Distribuição via `install.sh`** — não há release de `.zip`. Usuário instala com `curl -fsSL https://interruptor.jfernando.dev/install.sh | bash`.
2. **Sem runner macOS no CI.** Landing deploy automático no Contabo (`.github/workflows/landing.yml`).
3. **Apple Silicon only** — `arm64-apple-macosx14.0`.
4. **Ícone** gerado em build a partir de `app/Icon.svg`.
5. Copy da landing: direta, sem jargão técnico desnecessário (não mencionar ícone, Gatekeeper, etc. pro usuário final).

## Comandos

```bash
./build.sh                    # raiz → app/build.sh
./install.sh                  # clone + build + open
cd landingpage && npm run dev
```

`install.sh` também em `landingpage/public/install.sh` (servido pelo site). Manter sincronizado com a raiz.

## CI/CD

| Workflow | Runner | Trigger |
|----------|--------|---------|
| `landing.yml` | self-hosted Contabo | push `landingpage/**` |

## O que não fazer

- Não recriar workflow de release macOS
- Não usar Electron
- Não suportar Intel Mac
- Não criar commits sem o usuário pedir
