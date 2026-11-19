#!/usr/bin/env bash

# ============================================================
# T2 - ATPG automatizado para todas as configuracoes
# Executar dentro de:
# ~/T2_scan/stream_merge_scan/synthesis
#
# Antes de executar:
#   module purge
#   module load modus/21.10
# ============================================================

set +e

CONFIGS=(
  "DATA_W16_DEPTH8_WMAX7"
  "DATA_W32_DEPTH4_WMAX7"
  "DATA_W32_DEPTH8_WMAX3"
  "DATA_W32_DEPTH8_WMAX7"
  "DATA_W32_DEPTH8_WMAX15"
  "DATA_W32_DEPTH16_WMAX7"
  "DATA_W64_DEPTH8_WMAX7"
)

TECHLIB="/soft64/design-kits/stm/65nm-cmos065_536/CORE65GPSVT_5.1/behaviour/verilog/CORE65GPSVT.v,/soft64/design-kits/stm/65nm-cmos065_536/CLOCK65GPSVT_3.1/behaviour/verilog/CLOCK65GPSVT.v,/soft64/design-kits/stm/65nm-cmos065_536/IO65LPHVT_SF_1V8_50A_7M4X0Y2Z_7.0/behaviour/verilog/IO65LPHVT_SF_1V8_50A_7M4X0Y2Z.v"

if ! command -v modus >/dev/null 2>&1; then
    echo "ERRO: comando 'modus' nao encontrado."
    echo "Execute antes: module purge && module load modus/21.10"
    exit 1
fi

ROOT="$(pwd)"

echo "============================================================"
echo " T2 - ATPG automatizado"
echo "============================================================"

for TAG in "${CONFIGS[@]}"; do
    TOP="stream_merge_${TAG}"
    RESULTDIR="$ROOT/results/$TAG"
    WORKDIR="$RESULTDIR/modus_atpg"
    LOGFILE="$RESULTDIR/atpg_console.log"
    EXPERIMENT="${TOP}_atpg"

    echo
    echo "------------------------------------------------------------"
    echo " ATPG: $TAG"
    echo "------------------------------------------------------------"

    if [ ! -d "$WORKDIR" ]; then
        echo "ERRO: pasta ausente: $WORKDIR"
        continue
    fi

    if [ ! -f "$WORKDIR/${TOP}.test_netlist.v" ]; then
        echo "ERRO: netlist ausente: $WORKDIR/${TOP}.test_netlist.v"
        continue
    fi

    if [ ! -f "$WORKDIR/${TOP}.FULLSCAN.pinassign" ]; then
        echo "ERRO: pinassign ausente: $WORKDIR/${TOP}.FULLSCAN.pinassign"
        continue
    fi

    # Limpa somente resultados ATPG anteriores desta configuracao.
    rm -rf "$WORKDIR/tbdata" "$WORKDIR/testresults"

    # Alimenta o Modus pela entrada padrao, reproduzindo o fluxo que
    # funcionou manualmente e evitando o problema observado com -file.
    modus > "$LOGFILE" 2>&1 <<EOF
set_db workdir $WORKDIR
set WORKDIR [get_db workdir]
set_option stdout summary

build_model \\
    -cell $TOP \\
    -techlib $TECHLIB \\
    -designsource \$WORKDIR/${TOP}.test_netlist.v \\
    -allowmissingmodules no \\
    -messagecounteach 100

build_testmode \\
    -testmode FULLSCAN \\
    -assignfile \$WORKDIR/${TOP}.FULLSCAN.pinassign \\
    -modedef FULLSCAN

report_test_structures \\
    -testmode FULLSCAN \\
    -reportscanchain all

verify_test_structures \\
    -messagecount TSV-016=10,TSV-024=10,TSV-315=10,TSV-027=10 \\
    -testmode FULLSCAN

build_faultmodel \\
    -includedynamic no

create_logic_tests \\
    -experiment $EXPERIMENT \\
    -testmode FULLSCAN

write_toggle_gram \\
    -experiment $EXPERIMENT \\
    -testmode FULLSCAN

write_vectors \\
    -inexperiment $EXPERIMENT \\
    -testmode FULLSCAN \\
    -language verilog \\
    -scanformat parallel

commit_tests \\
    -inexperiment $EXPERIMENT \\
    -testmode FULLSCAN

exit
EOF

    STATUS=$?

    if [ $STATUS -eq 0 ]; then
        echo "OK: $TAG"
        # Mostra as ultimas linhas de cobertura ATPG encontradas.
        grep "TDA-220" "$LOGFILE" | tail -6
    else
        echo "ERRO: $TAG terminou com codigo $STATUS"
        echo "Veja: $LOGFILE"
    fi
done

echo
echo "============================================================"
echo " ATPG concluido. Logs em results/<config>/atpg_console.log"
echo "============================================================"
