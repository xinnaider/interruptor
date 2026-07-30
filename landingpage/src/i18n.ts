export type Lang = "pt" | "en";

export const copy = {
  pt: {
    htmlLang: "pt-BR",
    metaTitle: "Interruptor — desligue o monitor externo do Mac sem puxar o cabo",
    metaDescription:
      "App de barra de menus para macOS que desliga o monitor externo com um clique ou atalho, sem tirar o cabo. Grátis e open source.",
    skipLink: "Pular para o conteúdo",
    hero: {
      badge: "Exclusivo para Mac",
      line1: "Desligue o seu monitor externo.",
      line2: "Sem puxar cabo nenhum.",
      sub: "Interruptor vive na barra de menus do macOS. Um clique ou atalho apaga a tela externa e as janelas voltam para o Mac. Só Apple Silicon.",
      github: "Ver no GitHub",
      badges: [
        "Grátis e open source",
        "Apple Silicon",
        "macOS 14+",
        "MIT",
      ],
    },
    install: {
      copy: "Copiar",
      copied: "Copiado!",
    },
    features: {
      eyebrow: "Detalhes",
      title: "Feito para uma coisa só.",
      items: [
        {
          icon: "ph-plugs-connected",
          title: "Sem puxar cabo",
          body: "O corte é por software. O monitor nem percebe, só deixa de receber imagem do Mac.",
        },
        {
          icon: "ph-monitor",
          title: "Um interruptor por tela",
          body: "Vários monitores externos? Cada um ganha o próprio interruptor dentro do painel.",
        },
        {
          icon: "ph-keyboard",
          title: "Atalho do seu jeito",
          body: "Grave qualquer combinação de teclas para apagar tudo sem tirar a mão do teclado.",
        },
        {
          icon: "ph-feather",
          title: "Nativo e leve",
          body: "Feito em Swift para Apple Silicon. Sem Electron, sem peso sobrando na memória.",
        },
      ],
    },
    faq: {
      eyebrow: "FAQ",
      title: "Tudo que você ia perguntar",
      items: [
        {
          q: "O que acontece com as minhas janelas?",
          a: "Elas voltam automaticamente para a tela principal do Mac enquanto o monitor externo estiver apagado. Ao religar, o macOS as devolve para onde estavam.",
        },
        {
          q: "Funciona com mais de um monitor externo?",
          a: "Sim. Cada tela aparece no painel com o próprio interruptor, e o atalho liga ou desliga todas de uma vez.",
        },
        {
          q: "O monitor desliga de verdade?",
          a: "Não. O Interruptor corta o envio de imagem do Mac para aquela tela, um soft disconnect. O monitor continua ligado, pronto para ser reconectado quando você quiser.",
        },
        {
          q: "É seguro?",
          a: "O app usa uma API privada do macOS, a SkyLight, para controlar os displays. O código é aberto e pode ser auditado, mas essa API pode mudar em atualizações do sistema.",
        },
        {
          q: "Quais são os requisitos?",
          a: "Um Mac com Apple Silicon rodando macOS 14 ou superior, e ao menos um monitor externo conectado.",
        },
        {
          q: "Como instalo?",
          a: "Cole o comando acima no Terminal e aperte Enter.",
        },
        {
          q: "É grátis?",
          a: "Sim, para sempre. Licença MIT.",
        },
      ],
    },
    final: {
      title: "Apague a luz. Leve o interruptor",
      sub: "Cole o comando no Terminal e pronto.",
    },
    footer: {
      note: "Interruptor · licença MIT · feito em Swift",
      top: "Voltar ao topo",
    },
    switch: {
      on: "Interruptor da página, luz acesa",
      off: "Interruptor da página, luz apagada",
    },
    langLabel: "Mudar idioma",
  },

  en: {
    htmlLang: "en",
    metaTitle: "Interruptor — turn off your Mac's external display without unplugging the cable",
    metaDescription:
      "A menu bar app for macOS that turns off your external display with one click or shortcut, no cable pulling. Free and open source.",
    skipLink: "Skip to content",
    hero: {
      badge: "Mac only",
      line1: "Turn off your external display.",
      line2: "Without unplugging a single cable.",
      sub: "Interruptor lives in your Mac menu bar. One click or shortcut turns off the external display and windows return to your Mac. Apple Silicon only.",
      github: "View on GitHub",
      badges: [
        "Free and open source",
        "Apple Silicon",
        "macOS 14+",
        "MIT",
      ],
    },
    install: {
      copy: "Copy",
      copied: "Copied!",
    },
    features: {
      eyebrow: "Details",
      title: "Made for one thing.",
      items: [
        {
          icon: "ph-plugs-connected",
          title: "No cable pulling",
          body: "The cut happens in software. The display doesn't even notice, it just stops receiving image from the Mac.",
        },
        {
          icon: "ph-monitor",
          title: "One switch per screen",
          body: "Multiple external displays? Each one gets its own switch inside the panel.",
        },
        {
          icon: "ph-keyboard",
          title: "Your own shortcut",
          body: "Record any key combination to turn everything off without leaving the keyboard.",
        },
        {
          icon: "ph-feather",
          title: "Native and light",
          body: "Built in Swift for Apple Silicon. No Electron, no wasted memory.",
        },
      ],
    },
    faq: {
      eyebrow: "FAQ",
      title: "Everything you were going to ask",
      items: [
        {
          q: "What happens to my windows?",
          a: "They automatically move back to the Mac's main display while the external monitor is off. Turn it back on and macOS sends them back to where they were.",
        },
        {
          q: "Does it work with more than one external display?",
          a: "Yes. Each screen shows up in the panel with its own switch, and the shortcut toggles all of them at once.",
        },
        {
          q: "Does the monitor actually turn off?",
          a: "No. Interruptor stops the Mac from sending image to that screen, a soft disconnect. The monitor stays on, ready to be reconnected whenever you want.",
        },
        {
          q: "Is it safe?",
          a: "The app uses a private macOS API, SkyLight, to control displays. The code is open and can be audited, but that API may change in system updates.",
        },
        {
          q: "What are the requirements?",
          a: "A Mac with Apple Silicon running macOS 14 or later, and at least one external display connected.",
        },
        {
          q: "How do I install?",
          a: "Paste the command above in Terminal and press Enter.",
        },
        {
          q: "Is it free?",
          a: "Yes, forever. MIT license.",
        },
      ],
    },
    final: {
      title: "Lights out. Take the switch",
      sub: "Paste the command in Terminal and you're set.",
    },
    footer: {
      note: "Interruptor · MIT license · built in Swift",
      top: "Back to top",
    },
    switch: {
      on: "Page switch, light on",
      off: "Page switch, light off",
    },
    langLabel: "Change language",
  },
} as const;
