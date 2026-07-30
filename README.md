<div align="center">

<img src="landingpage/public/favicon.svg" width="96" height="96" alt="Interruptor logo"/>

# Interruptor

**Desligue o monitor externo do Mac sem puxar o cabo.**
**Um clique na barra de menus e as janelas voltam pro notebook.**

[![Landing](https://img.shields.io/github/actions/workflow/status/xinnaider/interruptor/landing.yml?branch=main)](https://github.com/xinnaider/interruptor/actions)
[![License: MIT](https://img.shields.io/badge/license-MIT-yellow.svg)](LICENSE)
[![Platform: macOS](https://img.shields.io/badge/platform-macOS-lightgrey.svg)](#macos-14-apple-silicon)

[interruptor.jfernando.dev](https://interruptor.jfernando.dev)

</div>

## Features

- **Soft disconnect** — corta o sinal do monitor por software, sem desligar o cabo
- **Barra de menus** — interruptor discreto, sempre a um clique
- **Atalho gravável** — padrão `⌃⌥⌘I`, ou grave o seu
- **Multi monitor** — um interruptor por tela externa
- **Janelas automáticas** — o macOS devolve tudo pro notebook enquanto a tela estiver apagada
- **Atualização automática** — o app avisa quando sair versão nova no GitHub
- **Idioma do sistema** — PT ou EN conforme o macOS, sem configuração manual
- **Nativo e leve** — Swift puro para Apple Silicon, sem Electron

## Installation

### Requirements

- **macOS 14** ou superior
- **Apple Silicon** (M1, M2, M3, M4…)
- Pelo menos **um monitor externo** conectado

---

### macOS (14+ · Apple Silicon)

**Download** — pegue o `.zip` da [última release](https://github.com/xinnaider/interruptor/releases/latest), extraia e arraste `Interruptor.app` para Aplicativos.

O app verifica atualizações ao abrir e pelo botão ↓ no painel.

---

### Build from source

```bash
git clone https://github.com/xinnaider/interruptor.git
cd interruptor/app
./build.sh
open Interruptor.app
```

## Atalho padrão

| Ação | Atalho |
|------|--------|
| Ligar / desligar monitores externos | `⌃⌥⌘I` |

Grave outro atalho clicando no chip de teclado no rodapé do painel.

## Site

A landing page tem o interruptor interativo: apague a luz do site e o cursor vira uma lanterna.

[interruptor.jfernando.dev](https://interruptor.jfernando.dev) · [versão em inglês](https://interruptor.jfernando.dev/en/)

## Contributing

Contribuições são bem-vindas.

### Development setup

**App (Swift):**

```bash
cd app
./build.sh
open Interruptor.app
```

**Landing (Astro):**

```bash
cd landingpage
npm install
npm run dev    # http://localhost:4321
```

### Publicar release

Tag `v*` dispara o workflow no runner macOS self-hosted:

```bash
echo "1.0.1" > VERSION
git add VERSION && git commit -m "chore: bump version"
git tag v1.0.1 && git push origin main --tags
```

## License

MIT © [xinnaider](https://github.com/xinnaider)
