# 🧰 Ferramentas do Tool-Box

Documentação das ferramentas em `scripts/`. Todas rodam pelo CLI mestre a
partir da raiz do repositório: `./install.sh <nome-da-ferramenta> [ação/argumentos]`.

---

## 🧲 Ferramenta: `torrent-dl`

Baixa um torrent (link magnet, URL de `.torrent` ou arquivo `.torrent`
local) via `aria2c`. Requer `aria2` instalado (`brew install aria2` no
macOS, `apt-get install aria2` no Linux).

```bash
./install.sh torrent-dl 'magnet:?xt=urn:btih:...'
./install.sh torrent-dl 'https://exemplo.com/arquivo.torrent' -o ~/Downloads
```

Veja [`torrent-dl/README.md`](torrent-dl/README.md) para todas as opções.

---

## 🧹 Ferramenta: `disk-cleaner`

Libera espaço em disco em macOS ou Linux, limpando caches, lixeira e
arquivos temporários seguros. Pede confirmação antes de cada etapa.

```bash
# Interativo (pergunta em cada etapa):
./install.sh disk-cleaner

# Assumir "sim" em tudo, exceto nas etapas do Docker (que sempre perguntam):
./install.sh disk-cleaner --yes

# Ver o que seria limpo, sem apagar nada:
./install.sh disk-cleaner --dry-run
```

Veja [`disk-cleaner/README.md`](disk-cleaner/README.md) para a lista completa de etapas.

---

## 🔤 Ferramenta: `aliases`

Instala atalhos de shell (`tb`, `tb-clean`, `tb-mon-status`, etc.) para os
comandos mais usados do Tool-Box.

```bash
./install.sh aliases install   # adiciona ao ~/.zshrc ou ~/.bashrc/.bash_profile
./install.sh aliases list      # lista os atalhos disponíveis
./install.sh aliases uninstall # remove os atalhos
```

Veja [`aliases/README.md`](aliases/README.md) para a lista completa de atalhos.

---
## 🖥️ Ferramenta: `mac-monitor`

Monitora uso de CPU e Memória RAM continuamente via **Glances** e gera relatórios diários agregados via **AWK**.

### Gerar Relatório
```bash
# Relatório de hoje:
./install.sh mac-monitor report

# Relatório de uma data específica (ex: 2026-09-12):
./install.sh mac-monitor report 2026-09-12
```

Você também pode executar diretamente o comando AWK bruto sobre o arquivo
diário (a partir da raiz do repositório):
```bash
awk -F, '           
NR==1 {next}
{
  cpu+=$3; mem+=$5; n++
  if($3>maxcpu) maxcpu=$3
  if($5>maxmem) maxmem=$5
}
END {
  print "=== Relatório do dia ==="
  print "Amostras:", n
  print "CPU média: " cpu/n "%"
  print "CPU máxima: " maxcpu "%"
  print "Memória média: " mem/n "%"
  print "Memória máxima: " maxmem "%"
}' logs/glances-$(date +%Y-%m-%d).csv
```

### Gerenciamento do Serviço
```bash
# Ver status da execução, PID e amostras de hoje
./install.sh mac-monitor status

# Acompanhar gravação do CSV em tempo real
./install.sh mac-monitor logs -f

# Parar / Reiniciar o monitor
./install.sh mac-monitor stop
./install.sh mac-monitor restart

# Instalar / Desinstalar como LaunchAgent no macOS (inicia no boot/login)
./install.sh mac-monitor install-service
./install.sh mac-monitor uninstall-service
```
