#!/usr/bin/env bash

# Uso:
#   ./retry_atpg_one.sh DATA_W32_DEPTH8_WMAX3
#   ./retry_atpg_one.sh DATA_W32_DEPTH8_WMAX15
#
# Requer:
#   module purge
#   module load modus/21.10
#
# Executar em:
#   ~/T2_scan/stream_merge_scan/synthesis

TAG="$1"

if [ -z "$TAG" ]; then
    echo "Uso: $0 DATA_Wxx_DEPTHxx_WMAXxx"
    exit 1
fi

TOP="stream_merge_${TAG}"
ROOT="$(pwd)"
RESULTDIR="$ROOT/results/$TAG"
WORKDIR="$RESULTDIR/modus_atpg"
EXPERIMENT="${TOP}_atpg"

TECHLIB="/soft64/design-kits/stm/65nm-cmos065_536/CORE65GPSVT_5.1/behaviour/verilog/CORE65GPSVT.v,/soft64/design-kits/stm/65nm-cmos065_536/CLOCK65GPSVT_3.1/behaviour/verilog/CLOCK65GPSVT.v,/soft64/design-kits/stm/65nm-cmos065_536/IO65LPHVT_SF_1V8_50A_7M4X0Y2Z_7.0/behaviour/verilog/IO65LPHVT_SF_1V8_50A_7M4X0Y2Z.v"

if ! command -v modus >/dev/null 2>&1; then
    echo "ERRO: Modus nao carregado."
    echo "Execute: module purge && module load modus/21.10"
    exit 1
fi

if [ ! -d "$WORKDIR" ]; then
    echo "ERRO: pasta nao encontrada: $WORKDIR"
    exit 1
fi

for ATTEMPT in 1 2 3; do
    LOGFILE="$RESULTDIR/atpg_console_attempt${ATTEMPT}.log"

    echo "============================================================"
    echo " $TAG - tentativa $ATTEMPT"
    echo "============================================================"

    rm -rf "$WORKDIR/tbdata" "$WORKDIR/testresults"

    modus > "$LOGFILE" 2>&1 <<EOF
set_db workdir $WORKDIR
set WORKDIR [get_db workdir]
set_option stdout summary

build_model \
    -cell $TOP \
    -techlib $TECHLIB \
    -designsource \$WORKDIR/${TOP}.test_netlist.v \
    -allowmissingmodules no \
    -messagecounteach 100

build_testmode \
    -testmode FULLSCAN \
    -assignfile \$WORKDIR/${TOP}.FULLSCAN.pinassign \
    -modedef FULLSCAN

report_test_structures \
    -testmode FULLSCAN \
    -reportscanchain all

verify_test_structures \
    -messagecount TSV-016=10,TSV-024=10,TSV-315=10,TSV-027=10 \
    -testmode FULLSCAN

build_faultmodel \
    -includedynamic no

create_logic_tests \
    -experiment $EXPERIMENT \
    -testmode FULLSCAN

write_toggle_gram \
    -experiment $EXPERIMENT \
    -testmode FULLSCAN

write_vectors \
    -inexperiment $EXPERIMENT \
    -testmode FULLSCAN \
    -language verilog \
    -scanformat parallel

commit_tests \
    -inexperiment $EXPERIMENT \
    -testmode FULLSCAN

exit
EOF

    STATUS=$?

    if grep -q "commit_tests completed successfully" "$LOGFILE"; then
        echo "SUCESSO: ATPG concluido na tentativa $ATTEMPT"
        cp "$LOGFILE" "$RESULTDIR/atpg_console.log"
        grep "TDA-220" "$LOGFILE" | tail -6
        exit 0
    fi

    echo "Tentativa $ATTEMPT falhou (status $STATUS)."
    tail -8 "$LOGFILE"
    sleep 2
done

echo "ERRO: falhou nas 3 tentativas."
exit 1
