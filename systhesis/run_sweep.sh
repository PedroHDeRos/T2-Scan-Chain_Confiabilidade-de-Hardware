#!/usr/bin/env bash

# ============================================================
# T2 - Sweep de parametros do stream_merge
# Requer:
#   - executar dentro de ~/T2_scan/stream_merge_scan/synthesis
#   - modulo Genus ja carregado
#   - run_config.tcl presente na pasta atual
# ============================================================

CONFIGS=(
  "64 8 7"
  "32 4 7"
  "32 16 7"
  "32 8 3"
  "32 8 15"
)

echo "============================================================"
echo " T2 - Iniciando sweep de parametros"
echo "============================================================"

for CFG in "${CONFIGS[@]}"; do
    read -r DATA_W DEPTH WMAX <<< "$CFG"

    TAG="DATA_W${DATA_W}_DEPTH${DEPTH}_WMAX${WMAX}"

    echo
    echo "------------------------------------------------------------"
    echo " Executando: ${TAG}"
    echo "------------------------------------------------------------"

    genus -batch \
        -files run_config.tcl \
        -execute "set DATA_W ${DATA_W}; set DEPTH ${DEPTH}; set WMAX ${WMAX}" \
        -log "genus_${TAG}"

    STATUS=$?

    if [ $STATUS -eq 0 ]; then
        echo " OK: ${TAG}"
    else
        echo " ERRO: ${TAG} terminou com codigo ${STATUS}"
    fi
done

echo
echo "============================================================"
echo " Sweep concluido."
echo " Resultados em ./results/"
echo "============================================================"
