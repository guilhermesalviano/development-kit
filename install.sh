#!/usr/bin/env bash
#
# install.sh - Instalação interativa e CLI do Tool-Box.
#
# Percorre cada ferramenta, mostra o que falta e pergunta antes de instalar
# qualquer coisa (pacotes do sistema, aliases no shell, serviços). Não
# assume "sim" para nada: rodar de novo é seguro, cada passo é independente.
#

set -uo pipefail

ROOT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
OS="$(uname -s)"

# --- Helpers ---------------------------------------------------------------

have() { command -v "$1" >/dev/null 2>&1; }

# Shell de login da conta (o que o chsh muda). O $SHELL só reflete a sessão
# atual: depois de um chsh ele continua apontando para o shell antigo até o
# próximo login, então não serve para decidir nada aqui.
login_shell() {
  local sh=""
  if [[ "${OS}" == "Darwin" ]]; then
    sh=$(dscl . -read "/Users/${USER:-$(id -un)}" UserShell 2>/dev/null | awk '{print $2}')
  elif have getent; then
    sh=$(getent passwd "${USER:-$(id -un)}" | cut -d: -f7)
  fi
  echo "${sh:-${SHELL:-}}"
}

confirm() {
  local reply
  read -r -p "$1 [y/N] " reply </dev/tty
  [[ "${reply}" =~ ^[Yy]$ ]]
}

section() {
  echo ""
  echo "=== $1 ==="
}

# Melhor esforço: tenta achar um gerenciador de pacotes e instalar "$1".
# Sempre confirma antes, já que isso mexe no sistema (e pode pedir sudo).
pkg_install() {
  local pkg="$1"
  local cmd=""
  if have brew; then
    cmd="brew install ${pkg}"
  elif have pacman; then
    cmd="sudo pacman -S --needed ${pkg}"
  elif have apt-get; then
    cmd="sudo apt-get update && sudo apt-get install -y ${pkg}"
  elif have dnf; then
    cmd="sudo dnf install -y ${pkg}"
  else
    echo "Nenhum gerenciador de pacotes suportado encontrado (brew/pacman/apt/dnf)." >&2
    echo "Instale '${pkg}' manualmente e rode este script de novo." >&2
    return 1
  fi

  if confirm "Instalar '${pkg}' agora? (${cmd})"; then
    eval "${cmd}"
  else
    echo "Pulado — a ferramenta que precisa de '${pkg}' vai avisar de novo quando você usar."
    return 1
  fi
}

# --- CLI (list / new / <ferramenta>) -------------------------------------------
#
# Com argumentos, este script é o CLI do Tool-Box: lista, cria e executa as
# ferramentas de scripts/ e apps/. Sem argumentos (ou com "setup"), roda a
# instalação interativa logo abaixo.

SCRIPTS_DIR="${ROOT_DIR}/scripts"
APPS_DIR="${ROOT_DIR}/apps"

# Diretórios varridos para achar uma ferramenta, em ordem de prioridade.
# "apps/" guarda aplicativos com interface gráfica.
TOOL_DIRS=("${SCRIPTS_DIR}" "${APPS_DIR}")

usage() {
  cat <<EOF
Uso: ./install.sh [comando|ferramenta] [argumentos...]

Sem argumentos, roda a instalação interativa (o mesmo que 'setup').

Comandos disponíveis:
  setup                 Instalação interativa (padrão quando não há argumentos)
  list                  Lista todas as ferramentas disponíveis
  new <nome>            Cria uma nova ferramenta a partir do template
  help                  Exibe esta mensagem de ajuda

Executar uma ferramenta:
  ./install.sh <ferramenta> [ação/argumentos]

Exemplos:
  ./install.sh list
  ./install.sh mac-monitor status
  ./install.sh mac-monitor report 2026-09-12
  ./install.sh new backup-system

As ferramentas ficam em 'scripts/' e os apps gráficos em 'apps/'.
EOF
}

# Lista as ferramentas de um diretório ("scripts/" ou "apps/").
list_dir() {
  local dir="$1" tool_path tool_name desc

  if [[ ! -d "${dir}" ]]; then
    echo "  (nenhuma ferramenta em ${dir})"
    return 0
  fi

  for tool_path in "${dir}"/*; do
    [[ -d "${tool_path}" ]] || continue
    tool_name=$(basename "${tool_path}")
    [[ "${tool_name}" == _* ]] && continue

    desc="Sem descrição"
    if [[ -f "${tool_path}/README.md" ]]; then
      desc=$(grep -m 1 -E '^# ' "${tool_path}/README.md" | sed 's/^# //')
      [[ -n "${desc}" ]] || desc="Sem descrição"
    fi
    printf "  %-20s - %s\n" "${tool_name}" "${desc}"
  done
}

cmd_list() {
  echo "=========================================="
  echo "Ferramentas instaladas no Tool-Box"
  echo "=========================================="
  list_dir "${SCRIPTS_DIR}"
  echo ""
  echo "-- Apps (interface gráfica) --"
  list_dir "${APPS_DIR}"
  echo "=========================================="
}

# Ecoa o caminho da ferramenta "$1", procurando em TOOL_DIRS.
find_tool() {
  local name="$1" dir
  for dir in "${TOOL_DIRS[@]}"; do
    if [[ -d "${dir}/${name}" ]]; then
      echo "${dir}/${name}"
      return 0
    fi
  done
  return 1
}

cmd_new() {
  local tool_name="${1:-}"
  if [[ -z "${tool_name}" ]]; then
    echo "Erro: Informe o nome da nova ferramenta." >&2
    echo "Exemplo: ./install.sh new backup-system" >&2
    exit 1
  fi

  local target_dir="${SCRIPTS_DIR}/${tool_name}"
  if [[ -e "${target_dir}" ]]; then
    echo "Erro: A ferramenta '${tool_name}' já existe em ${target_dir}." >&2
    exit 1
  fi

  echo "Criando nova ferramenta '${tool_name}' a partir do template..."
  cp -r "${SCRIPTS_DIR}/_template" "${target_dir}" || exit 1
  echo "Ferramenta criada com sucesso em ${target_dir}!"
  echo "Edite ${target_dir}/run.sh e ${target_dir}/README.md para começar."
}

cmd_run_tool() {
  local name="$1" tool_path
  shift
  if ! tool_path="$(find_tool "${name}")"; then
    echo "Erro: Ferramenta '${name}' não encontrada." >&2
    echo "Execute './install.sh list' para ver as ferramentas disponíveis." >&2
    exit 1
  fi

  if [[ -x "${tool_path}/manage.sh" ]]; then
    exec "${tool_path}/manage.sh" "$@"
  elif [[ -x "${tool_path}/run.sh" ]]; then
    exec "${tool_path}/run.sh" "$@"
  elif [[ -x "${tool_path}/${name}.sh" ]]; then
    exec "${tool_path}/${name}.sh" "$@"
  elif [[ -x "${tool_path}/${name}.py" ]]; then
    exec "${ROOT_DIR}/.venv/bin/python3" "${tool_path}/${name}.py" "$@"
  else
    echo "Erro: Nenhum script executável (manage.sh, run.sh) encontrado em ${tool_path}" >&2
    exit 1
  fi
}

if [[ $# -gt 0 ]]; then
  ACTION="$1"
  shift
  case "${ACTION}" in
    setup)            ;;  # segue para a instalação interativa abaixo
    list|--list|-l)   cmd_list; exit 0 ;;
    new|create)       cmd_new "$@"; exit 0 ;;
    help|--help|-h)   usage; exit 0 ;;
    *)                cmd_run_tool "${ACTION}" "$@" ;;
  esac
fi

# --- Instalação interativa -----------------------------------------------------

echo "Tool-Box - instalação interativa"
echo "================================="
echo "Repositório: ${ROOT_DIR}"
echo "Sistema:     ${OS}"

# --- Zsh + Oh My Zsh ---------------------------------------------------------
#
# Vem antes dos aliases: o instalador do Oh My Zsh troca o ~/.zshrc (o antigo
# vira ~/.zshrc.pre-oh-my-zsh), então os aliases precisam entrar depois.

section "Zsh + Oh My Zsh (autosuggestions, syntax highlighting)"
if ! have zsh; then
  echo "zsh não encontrado."
  pkg_install zsh || true
else
  echo "zsh já está instalado."
fi

OMZ_DIR="${HOME}/.oh-my-zsh"
if have zsh; then
  if [[ -d "${OMZ_DIR}" ]]; then
    echo "Oh My Zsh já está instalado em ${OMZ_DIR}."
  elif ! have git || ! have curl; then
    echo "Oh My Zsh precisa de git e curl — instale-os e rode este script de novo." >&2
  elif confirm "Instalar o Oh My Zsh? (o ~/.zshrc atual vira ~/.zshrc.pre-oh-my-zsh)"; then
    RUNZSH=no CHSH=no sh -c "$(curl -fsSL https://raw.githubusercontent.com/ohmyzsh/ohmyzsh/master/tools/install.sh)" "" --unattended \
      || echo "Falhou — veja a mensagem acima." >&2
  else
    echo "Pulado."
  fi
fi

if [[ -d "${OMZ_DIR}" ]]; then
  ZSH_PLUGINS_DIR="${ZSH_CUSTOM:-${OMZ_DIR}/custom}/plugins"
  zsh_plugins=(
    "zsh-autosuggestions https://github.com/zsh-users/zsh-autosuggestions"
    "zsh-syntax-highlighting https://github.com/zsh-users/zsh-syntax-highlighting"
    "fast-syntax-highlighting https://github.com/zdharma-continuum/fast-syntax-highlighting"
  )
  missing=()
  for entry in "${zsh_plugins[@]}"; do
    [[ -d "${ZSH_PLUGINS_DIR}/${entry%% *}" ]] || missing+=("${entry}")
  done

  if [[ ${#missing[@]} -eq 0 ]]; then
    echo "Plugins do zsh já estão instalados em ${ZSH_PLUGINS_DIR}."
  elif confirm "Instalar os plugins do zsh (${#missing[@]} faltando: $(printf '%s ' "${missing[@]%% *}"))?"; then
    mkdir -p "${ZSH_PLUGINS_DIR}"
    for entry in "${missing[@]}"; do
      git clone --depth 1 "${entry#* }" "${ZSH_PLUGINS_DIR}/${entry%% *}" \
        || echo "Falhou ao clonar ${entry%% *}." >&2
    done
  else
    echo "Pulado."
  fi

  # zsh-syntax-highlighting e fast-syntax-highlighting fazem a mesma coisa e
  # conflitam se carregados juntos: carrega o fast e usa o outro só de reserva.
  ZSH_START_MARKER="# >>> tool-box zsh plugins >>>"
  ZSH_END_MARKER="# <<< tool-box zsh plugins <<<"
  if grep -qF "${ZSH_START_MARKER}" "${HOME}/.zshrc" 2>/dev/null; then
    echo "Plugins já ativados no ~/.zshrc."
  elif confirm "Ativar os plugins no ~/.zshrc?"; then
    cat >> "${HOME}/.zshrc" <<EOF

${ZSH_START_MARKER}
_tb_zsh_plugins="\${ZSH_CUSTOM:-\${ZSH:-\$HOME/.oh-my-zsh}/custom}/plugins"
[[ -r "\${_tb_zsh_plugins}/zsh-autosuggestions/zsh-autosuggestions.zsh" ]] \\
  && source "\${_tb_zsh_plugins}/zsh-autosuggestions/zsh-autosuggestions.zsh"
if [[ -r "\${_tb_zsh_plugins}/fast-syntax-highlighting/fast-syntax-highlighting.plugin.zsh" ]]; then
  source "\${_tb_zsh_plugins}/fast-syntax-highlighting/fast-syntax-highlighting.plugin.zsh"
elif [[ -r "\${_tb_zsh_plugins}/zsh-syntax-highlighting/zsh-syntax-highlighting.zsh" ]]; then
  source "\${_tb_zsh_plugins}/zsh-syntax-highlighting/zsh-syntax-highlighting.zsh"
fi
unset _tb_zsh_plugins
${ZSH_END_MARKER}
EOF
    echo "Ativado em: ${HOME}/.zshrc"
  else
    echo "Pulado."
  fi
fi

RELOGIN_NEEDED=false
if have zsh; then
  if [[ "$(basename "$(login_shell)")" == zsh ]]; then
    echo "zsh já é o shell padrão da conta."
  elif confirm "Tornar o zsh o shell padrão? (chsh -s $(command -v zsh))"; then
    chsh -s "$(command -v zsh)" || echo "Falhou — rode 'chsh -s $(command -v zsh)' manualmente." >&2
  else
    echo "Pulado. Rode 'chsh -s $(command -v zsh)' quando quiser."
  fi
fi

# Os aliases (logo abaixo) escolhem o rc file pelo $SHELL: alinha com o shell
# de login para eles irem para o ~/.zshrc mesmo rodando o script a partir do bash.
LOGIN_SHELL="$(login_shell)"
[[ -n "${LOGIN_SHELL}" ]] && export SHELL="${LOGIN_SHELL}"
# O pai deste script é o shell interativo que o rodou.
if [[ "$(basename "${LOGIN_SHELL}")" == zsh ]] \
   && [[ "$(basename "$(ps -o comm= -p "${PPID}" 2>/dev/null)")" != zsh ]]; then
  RELOGIN_NEEDED=true
  echo "Este terminal ainda está em outro shell: os plugins do zsh só aparecem num shell zsh."
  echo "Saia e entre de novo na sessão (ou rode 'exec zsh' agora) para usar o zsh."
fi

# --- Aliases -----------------------------------------------------------

section "Atalhos de shell (tb, tb-clean, tb-mon-*, ...)"
if confirm "Instalar os atalhos do Tool-Box no seu shell?"; then
  "${ROOT_DIR}/install.sh" aliases install
else
  echo "Pulado. Rode '${ROOT_DIR}/install.sh aliases install' quando quiser."
fi

# --- RTK (Rust Token Killer) -------------------------------------------------
#
# Proxy de CLI que comprime a saída de comandos (git, ls, testes...) antes de
# chegar no contexto dos agentes de código. O `rtk init` instala um hook que
# reescreve `git status` em `rtk git status` sozinho, então cada agente precisa
# ser ativado uma vez.

section "RTK (economia de tokens nos agentes de código)"
if have rtk; then
  echo "rtk já está instalado ($(rtk --version 2>/dev/null))."
else
  echo "rtk não encontrado."
  # Não existe no pacman/apt: brew, AUR ou o script oficial (~/.local/bin).
  # Evite 'cargo install rtk' — no crates.io esse nome é outro projeto.
  if have brew; then
    rtk_cmd="brew install rtk"
  elif have yay; then
    rtk_cmd="yay -S --needed rtk"
  elif have paru; then
    rtk_cmd="paru -S --needed rtk"
  else
    rtk_cmd="curl -fsSL https://raw.githubusercontent.com/rtk-ai/rtk/refs/heads/master/install.sh | sh"
  fi
  if confirm "Instalar o rtk agora? (${rtk_cmd})"; then
    eval "${rtk_cmd}" || echo "Falhou — veja a mensagem acima." >&2
    # O script oficial instala em ~/.local/bin, que pode não estar no PATH ainda.
    [[ -x "${HOME}/.local/bin/rtk" ]] && export PATH="${HOME}/.local/bin:${PATH}"
  else
    echo "Pulado."
  fi
fi

if have rtk; then
  # "nome|detectado?|flags do rtk init"
  rtk_agents=(
    "Claude Code|$(have claude || [[ -d ${HOME}/.claude ]] && echo y)|-g"
    "Codex|$(have codex || [[ -d ${HOME}/.codex ]] && echo y)|-g --codex"
    "Gemini CLI|$(have gemini || [[ -d ${HOME}/.gemini ]] && echo y)|-g --gemini"
    "OpenCode|$(have opencode || [[ -d ${HOME}/.config/opencode ]] && echo y)|-g --opencode"
    "Cursor|$(have cursor-agent || have cursor || [[ -d ${HOME}/.cursor ]] && echo y)|-g --agent cursor"
    "Windsurf|$(have windsurf || [[ -d ${HOME}/.codeium/windsurf ]] && echo y)|-g --agent windsurf"
    "GitHub Copilot|$(have copilot && echo y)|-g --copilot"
  )
  found=0
  for entry in "${rtk_agents[@]}"; do
    IFS='|' read -r name detected flags <<<"${entry}"
    [[ ${detected} == y ]] || continue
    found=1
    # --codex não aceita --auto-patch (não há settings.json para alterar).
    [[ ${flags} == *--codex* ]] || flags+=" --auto-patch"
    if confirm "Ativar o rtk no ${name}? (rtk init ${flags})"; then
      # shellcheck disable=SC2086
      rtk init ${flags} </dev/tty || echo "Falhou — veja a mensagem acima." >&2
    else
      echo "Pulado. Rode 'rtk init ${flags}' quando quiser."
    fi
  done
  if [[ ${found} -eq 0 ]]; then
    echo "Nenhum agente de código detectado. Depois de instalar um, rode 'rtk init -g' (veja o README)."
  else
    echo "Reinicie os agentes abertos para o hook valer. Confira com 'rtk init --show' e 'rtk gain'."
  fi
fi

# --- Delta (diff do git) ----------------------------------------------------
#
# Pager para git diff/log/show com destaque de sintaxe e realce por palavra.
# O pacote se chama git-delta em todos os gerenciadores; o binário é `delta`.
# A configuração do git só é oferecida depois que o binário existe — um
# core.pager apontando para um comando ausente quebra o `git diff`.

section "Delta (diff do git com destaque de sintaxe)"
if have delta; then
  echo "delta já está instalado ($(delta --version 2>/dev/null))."
else
  echo "delta não encontrado."
  pkg_install git-delta || true
fi

if have delta; then
  current_pager=$(git config --global --get core.pager 2>/dev/null || true)
  if [[ ${current_pager} == delta* ]]; then
    echo "O git já usa o delta como pager."
  else
    [[ -n ${current_pager} ]] && echo "Pager atual do git: ${current_pager} (será substituído)."
    if confirm "Configurar o git (global) para usar o delta?"; then
      git config --global core.pager delta
      git config --global interactive.diffFilter "delta --color-only"
      git config --global delta.navigate true
      git config --global delta.side-by-side true
      git config --global diff.algorithm histogram
      echo "Pronto. Diff lado a lado; 'n'/'N' pulam entre arquivos."
    else
      echo "Pulado. Veja os comandos no README (seção Delta)."
    fi
  fi
fi

# --- Torrent DL ----------------------------------------------------------

section "Torrent DL (aria2)"
if have aria2c; then
  echo "aria2c já está instalado."
else
  echo "aria2c não encontrado (necessário para './install.sh torrent-dl')."
  pkg_install aria2 || true
fi

# --- Disk Cleaner ----------------------------------------------------------

section "Disk Cleaner"
echo "Sem pré-requisitos — usa apenas utilitários já presentes no macOS/Linux."
echo "Pronto para usar: ./install.sh disk-cleaner --dry-run"

# --- Mac/System Monitor ----------------------------------------------------

section "Mac/System Monitor (Glances)"
if have python3; then
  if confirm "Criar o virtualenv e instalar o Glances agora?"; then
    "${ROOT_DIR}/install.sh" mac-monitor setup
    if [[ "${OS}" == "Darwin" ]]; then
      if confirm "Instalar como LaunchAgent (inicia sozinho no login)?"; then
        "${ROOT_DIR}/install.sh" mac-monitor install-service
      else
        echo "Pulado. Rode './install.sh mac-monitor install-service' quando quiser."
      fi
    else
      echo "LaunchAgent é exclusivo de macOS — use './install.sh mac-monitor start' para rodar em primeiro plano."
    fi
  else
    echo "Pulado. Rode './install.sh mac-monitor start' quando quiser."
  fi
else
  echo "python3 não encontrado — necessário para o mac-monitor." >&2
  pkg_install python3 || true
fi

section "Pronto"
cmd_list
echo ""
if [[ "${RELOGIN_NEEDED}" == true ]]; then
  echo "Saia e entre de novo na sessão (ou rode 'exec zsh') para usar o zsh, os plugins e os atalhos."
else
  echo "Abra um novo shell (ou 'source' o seu rc file) para os atalhos entrarem em vigor."
fi
