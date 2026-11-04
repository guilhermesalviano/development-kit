# Aliases

Instala atalhos de shell (bash/zsh) para os comandos mais usados do Tool-Box,
para não precisar digitar `./install.sh <ferramenta> <ação>` toda vez.

---

## 📁 Estrutura da Ferramenta

```
scripts/aliases/
├── aliases.sh     # Definição dos atalhos (é "sourced", não executado)
├── manage.sh      # install/uninstall/status/list
└── README.md      # Documentação desta ferramenta
```

`aliases.sh` se autolocaliza (funciona em qualquer caminho onde o
repositório esteja clonado) e é seguro executar `install` mais de uma vez —
ele não duplica a entrada no seu arquivo de shell.

---

## 🔤 Atalhos instalados

| Atalho             | Equivale a                          |
|---------------------|--------------------------------------|
| `tb`                | `./install.sh`                          |
| `tbl`               | `./install.sh list`                     |
| `tbn`               | `./install.sh new`                      |
| `tb-clean`          | `./install.sh disk-cleaner`             |
| `tb-clean-all`      | `./install.sh disk-cleaner --yes`       |
| `tb-clean-dry`      | `./install.sh disk-cleaner --dry-run`   |
| `tb-torrent`        | `./install.sh torrent-dl`               |
| `tb-dl`             | `./install.sh torrent-dl`               |
| `tb-mon`            | `./install.sh mac-monitor`              |
| `tb-mon-status`     | `./install.sh mac-monitor status`       |
| `tb-mon-report`     | `./install.sh mac-monitor report`       |
| `tb-mon-logs`       | `./install.sh mac-monitor logs -f`      |
| `tb-mon-start`      | `./install.sh mac-monitor start`        |
| `tb-mon-stop`       | `./install.sh mac-monitor stop`         |
| `tb-mon-restart`    | `./install.sh mac-monitor restart`      |

Veja a lista atualizada a qualquer momento com `./install.sh aliases list`.

---

## 🚀 Como Usar

```bash
# Instalar (adiciona um bloco marcado ao ~/.zshrc ou ~/.bashrc/.bash_profile,
# detectado pelo shell de login da sua conta, mesmo logo depois de um chsh):
./install.sh aliases install

# Recarregar o shell atual para começar a usar:
source ~/.zshrc   # ou ~/.bashrc / ~/.bash_profile

# Ver quais arquivos já têm os atalhos instalados:
./install.sh aliases status

# Listar todos os atalhos disponíveis:
./install.sh aliases list

# Remover os atalhos:
./install.sh aliases uninstall
```

O `install` só adiciona um bloco entre marcadores (`# >>> tool-box aliases >>>`
/ `# <<< tool-box aliases <<<`) que aponta para `scripts/aliases/aliases.sh` —
nada é copiado para dentro do seu `.zshrc`, então atualizar o Tool-Box já
atualiza os atalhos automaticamente. O `uninstall` remove exatamente esse
bloco, sem tocar no resto do arquivo.
