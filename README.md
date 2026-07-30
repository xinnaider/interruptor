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
- **Idioma do sistema** — PT ou EN conforme o macOS
- **Nativo e leve** — Swift puro para Apple Silicon, sem Electron

## Instalação

```bash
curl -fsSL https://interruptor.jfernando.dev/install.sh | bash
```

Requisitos: macOS 14+, Apple Silicon, monitor externo conectado.

Ou manualmente:

```bash
git clone https://github.com/xinnaider/interruptor.git
cd interruptor
./build.sh
open app/Interruptor.app
```

## Atalho padrão

| Ação | Atalho |
|------|--------|
| Ligar / desligar monitores externos | `⌃⌥⌘I` |

## Site

[interruptor.jfernando.dev](https://interruptor.jfernando.dev) · [English](https://interruptor.jfernando.dev/en/)

## Desenvolvimento

```bash
cd landingpage && npm install && npm run dev
```

Detalhes em [AGENTS.md](AGENTS.md).

## License

MIT © [xinnaider](https://github.com/xinnaider)
