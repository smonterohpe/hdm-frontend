#!/bin/bash
# ==============================================================================
# lastdischarges_api-GET.sh — Consulta las últimas altas del backend HDM
#
# Uso:
#   ./lastdischarges_api-GET.sh [LIMIT]     (por defecto: 3)
#
# Equivalente al lastbookings_api-GET.sh del Flight Booking Simulator.
# ==============================================================================

API="${API_BASE:-http://10.10.44.14:8001}"
LIMIT="${1:-3}"
TMPFILE=$(mktemp /tmp/_hdm_last.XXXXXX)
trap 'rm -f "$TMPFILE"' EXIT

if ! [[ "$LIMIT" =~ ^[1-9][0-9]*$ ]]; then
  echo "Uso: $0 [LIMIT]"
  echo "  LIMIT debe ser un entero positivo (por defecto: 3)"
  exit 1
fi

GRN='\033[0;32m'; RED='\033[0;31m'; CYA='\033[0;36m'; YEL='\033[1;33m'
BLD='\033[1m'; DIM='\033[2m'; RST='\033[0m'

echo ""
echo -e "${BLD}GET /api/discharges/recent  —  Últimas ${LIMIT} altas${RST}"
echo -e "${DIM}─────────────────────────────────────────────${RST}"
echo -e "  Endpoint  : ${CYA}${API}/api/discharges/recent?n=${LIMIT}${RST}"
echo ""

echo -e "${BLD}[1/2]${RST} Obteniendo las últimas ${YEL}${LIMIT}${RST} altas..."

HTTP_CODE=$(curl -s -o "$TMPFILE" -w "%{http_code}" \
  "${API}/api/discharges/recent?n=${LIMIT}")

RESPONSE=$(cat "$TMPFILE")

if [ "$HTTP_CODE" = "200" ]; then
  COUNT=$(echo "$RESPONSE" | python3 -c "import sys,json; print(len(json.load(sys.stdin)))" 2>/dev/null)
  echo -e "      ${GRN}✔  ${COUNT} altas recibidas  (HTTP ${HTTP_CODE})${RST}"

  # KPIs totales
  echo -e "${BLD}[2/2]${RST} Obteniendo KPIs totales..."
  KPIS=$(curl -s --max-time 5 "${API}/api/kpis" 2>/dev/null)
  TOTAL=$(echo "$KPIS" | python3 -c "import sys,json; print(json.load(sys.stdin).get('total_discharges','?'))" 2>/dev/null)
  AVG=$(echo "$KPIS"   | python3 -c "import sys,json; print(json.load(sys.stdin).get('avg_processing_time_min','?'))" 2>/dev/null)
  PENDING=$(echo "$KPIS" | python3 -c "import sys,json; print(json.load(sys.stdin).get('patients_pending','?'))" 2>/dev/null)

  echo ""
  echo -e "${DIM}─────────────────────────────────────────────${RST}"
  [ -n "$TOTAL" ]   && echo -e "  Total altas en BD      : ${YEL}${TOTAL}${RST}"
  [ -n "$AVG" ]     && echo -e "  Tiempo medio de alta   : ${YEL}${AVG} min${RST}"
  [ -n "$PENDING" ] && echo -e "  Pacientes en espera    : ${YEL}${PENDING}${RST}"
  echo -e "${DIM}─────────────────────────────────────────────${RST}"
  echo ""

  # Tabla de altas
  echo "$RESPONSE" | python3 -c "
import sys, json
rows = json.load(sys.stdin)
for r in rows:
    print(f\"  [{r.get('id','?')}] {r.get('patient_name','?'):<30} | {r.get('ward','?'):<30} | {r.get('diagnosis_code','?')} | {r.get('discharge_type','?'):<15} | {r.get('processing_time_min','?')} min\")
" 2>/dev/null || echo "$RESPONSE"

else
  echo -e "      ${RED}✗  Error en la petición  (HTTP ${HTTP_CODE})${RST}"
  echo ""
  echo "$RESPONSE" | python3 -c "import sys,json; print(json.dumps(json.load(sys.stdin), ensure_ascii=False, indent=4))" 2>/dev/null || echo "$RESPONSE"
  exit 1
fi
echo ""
