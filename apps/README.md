# 🖱️ Apps do Tool-Box

Documentação dos aplicativos gráficos em `apps/`. Rodam pelo CLI mestre a
partir da raiz do repositório: `./install.sh <nome-do-app> [ação/argumentos]`.

---

## 🖱️ App: `swain-macros`

App GNOME (Ubuntu, Wayland e X11) que troca a função dos botões laterais do
mouse Redragon Swain por macros (teclas, texto, cliques, scroll, comandos).
Usa o `python3` do sistema, não o `.venv`.

```bash
# Configuração inicial (uma vez; pede sudo quando precisa):
./install.sh swain-macros install

# Abrir o app (ou pelo menu de aplicativos):
./install.sh swain-macros
```

Veja [`swain-macros/README.md`](swain-macros/README.md) para a linguagem de macros e como desinstalar.

---

## 🌀 App: `mac-fan`

App GNOME para controlar a ventoinha de um Mac com chip T2 (ex.: Mac mini 2018)
rodando Debian com kernel T2: modo automático (SMC), velocidade fixa ou curva por
temperatura da CPU. Usa o `python3` do sistema, não o `.venv`.

```bash
# Configuração inicial (uma vez; pede sudo quando precisa):
./install.sh mac-fan install

# Abrir o app (ou pelo menu de aplicativos):
./install.sh mac-fan
```

Veja [`mac-fan/README.md`](mac-fan/README.md) para os modos, a proteção térmica e como desinstalar.
