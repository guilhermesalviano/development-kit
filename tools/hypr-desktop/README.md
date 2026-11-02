# Hypr Desktop

Desktop Hyprland com visual de Omarchy (tema Tokyo Night, barra no topo,
lançador no Super + Espaço) para **Debian 13 (trixie)**. Não é o Omarchy em si,
só o visual.

O Hyprland vem do `trixie-backports` (repositório oficial do Debian). O GNOME
continua instalado; escolha a sessão na engrenagem da tela de login.

## Uso

```bash
./toolbox hypr-desktop install    # pacotes (pede sudo) + configurações
./toolbox hypr-desktop configs    # só recopia as configurações
./toolbox hypr-desktop check      # valida o hyprland.conf
./toolbox hypr-desktop status
```

Rode o `install` num terminal normal: ele pede a senha do sudo e confirmações.

## O que é instalado

| Papel | Programa | Configuração |
|---|---|---|
| Compositor | Hyprland | `~/.config/hypr/hyprland.conf` |
| Barra superior | Waybar | `~/.config/waybar/` |
| Lançador | fuzzel | `~/.config/fuzzel/fuzzel.ini` |
| Notificações | mako | `~/.config/mako/config` |
| Terminal | Alacritty | `~/.config/alacritty/alacritty.toml` |
| Bloqueio / inatividade | hyprlock / hypridle | `~/.config/hypr/` |
| Volume na tela | swayosd | — |
| Papel de parede | swaybg | `~/.config/hypr/wallpaper.{png,jpg}` (senão, cor sólida) |

Os arquivos ficam em `tools/hypr-desktop/config/`. Edite lá e rode
`configs` de novo; arquivos diferentes em `~/.config` são salvos antes em
`~/.local/state/toolbox-hypr-desktop/<data>/`.

## Atalhos

| Atalho | Ação |
|---|---|
| Super + Enter | Terminal |
| Super + Espaço | Lançador de apps |
| Super + B / E | Navegador padrão / Arquivos |
| Super + W | Fechar janela |
| Super + F / T | Tela cheia / Flutuante |
| Super + setas | Mudar o foco |
| Super + Shift + setas | Mover a janela |
| Super + 1…9 | Área de trabalho |
| Super + Shift + 1…9 | Mover janela para a área |
| Super + Esc | Menu de energia |
| Super + Ctrl + L | Bloquear |
| Print / Shift + Print | Captura de região / tela inteira |

Super é a tecla Command no teclado Apple.
