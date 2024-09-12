#!/bin/bash

json_file="C:\Users\h8men\OneDrive\Documentos\Cefet\TCC\result.json"
log_file="C:\Users\h8men\OneDrive\Documentos\Cefet\TCC\shellErrors.log"
metrics_repo="C:\Users\h8men\OneDrive\Documentos\Cefet\TCC\metrics\"

# Verifica se o arquivo JSON existe
if [ ! -f "$json_file" ]; then
    echo "Arquivo JSON não encontrado!" >> "$log_file"
    exit 1
fi

# Verifica se o diretório de métricas existe, caso contrário cria
if [ ! -d "$metrics_repo" ]; then
    echo "Diretório de métricas não encontrado, criando..." >> "$log_file"
    mkdir -p "$metrics_repo"
fi

# Itera sobre as URLs do arquivo JSON
for row in $(jq -r '.[] | .[2]' "${json_file}"); do
    echo "URL encontrada: ${row}"

    github_url=$row
    repo_name=$(echo "$github_url" | awk -F'/' '{print $(NF-0)}' | cut -d'.' -f1)

    echo "Clonando o repositório do GitHub $repo_name"
    git clone "$github_url" "$repo_name"

    # Verifica se o clone foi bem-sucedido
    if [ "$?" -ne 0 ]; then
        echo "Erro ao clonar o repositório do GitHub. ${row}" >> "$log_file"
        continue
    fi

    echo "Executando análise de métricas no repositório $repo_name"
    java -jar ck-0.7.1-SNAPSHOT-jar-with-dependencies.jar "$repo_name" true 0 false "${metrics_repo}${repo_name}"

    if [ "$?" -ne 0 ]; then
        echo "Erro ao executar o CK no repositório ${repo_name}" >> "$log_file"
        rm -rf "$repo_name"
        continue
    fi

    echo "Análise concluída. Deletando o diretório $repo_name"
    rm -rf "$repo_name"
done

# Limpeza dos logs mais antigos
find "$log_file" -type f -mtime +30 -exec rm -f {} \;

echo "Processo finalizado com sucesso."
