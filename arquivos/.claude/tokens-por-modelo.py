#!/usr/bin/env python3
"""Soma os tokens por modelo nas transcrições locais do projeto, dentro de um intervalo.

Uso: .claude/tokens-por-modelo.py "AAAA-MM-DD HH:MM:SS" "AAAA-MM-DD HH:MM:SS"
Os horários usam o fuso local, como o comando `date`. As transcrições dos subagentes entram na
soma. Cada mensagem conta uma vez, porque uma resposta pode ocupar várias linhas da transcrição.
"""
import json
import re
import sys
from collections import defaultdict
from datetime import datetime
from pathlib import Path

CAMPOS = {
    "entrada": "input_tokens",
    "saída": "output_tokens",
    "cache escrito": "cache_creation_input_tokens",
    "cache lido": "cache_read_input_tokens",
}


def main():
    if len(sys.argv) != 3:
        sys.exit(__doc__)
    inicio, fim = (datetime.fromisoformat(a).astimezone() for a in sys.argv[1:])

    raiz = str(Path(__file__).resolve().parent.parent)
    pasta = Path.home() / ".claude" / "projects" / re.sub(r"[^A-Za-z0-9]", "-", raiz)

    mensagens = {}
    for arquivo in pasta.rglob("*.jsonl"):
        for linha in arquivo.open(encoding="utf-8"):
            try:
                registro = json.loads(linha)
            except json.JSONDecodeError:
                continue
            if not isinstance(registro, dict) or not registro.get("timestamp"):
                continue
            mensagem = registro.get("message")
            if not isinstance(mensagem, dict) or not mensagem.get("usage"):
                continue
            modelo = mensagem.get("model")
            if not modelo or modelo == "<synthetic>":
                continue
            quando = datetime.fromisoformat(registro["timestamp"].replace("Z", "+00:00"))
            if inicio <= quando <= fim:
                mensagens[mensagem.get("id") or registro.get("uuid")] = (modelo, mensagem["usage"])

    if not mensagens:
        print("não medido")
        return

    totais = defaultdict(lambda: defaultdict(int))
    for modelo, uso in mensagens.values():
        for rotulo, campo in CAMPOS.items():
            totais[modelo][rotulo] += uso.get(campo) or 0

    print("; ".join(
        f"{modelo}: " + ", ".join(f"{rotulo} {valores[rotulo]}" for rotulo in CAMPOS)
        for modelo, valores in sorted(totais.items())
    ))


if __name__ == "__main__":
    main()
