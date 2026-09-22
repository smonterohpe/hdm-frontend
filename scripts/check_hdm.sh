#!/bin/bash
# =============================================================================
# check_hdm.sh — Verifica que el frontend HDM está operativo
#
# Uso:
#   ./check_hdm.sh                    → comprueba http://10.10.44.13:8081
#   ./check_hdm.sh http://host:8081   → URL personalizada
#
# Returns exit 0 si todo OK, exit 1 si algún check falla.
# =============================================================================

BASE="${1:-http://10.10.44.13:8081}"
PASS=0; FAIL=0

GREEN='\033[0;32m'; RED='\033[0;31m'; YELLOW='\033[1;33m'; NC='\033[0m'
ok()      { echo -e "  ${GREEN}✓${NC} $1"; PASS=$((PASS+1)); }
fail()    { echo -e "  ${RED}✗${NC} $1"; FAIL=$((FAIL+1)); }
section() { echo -e "\n${YELLOW}── $1${NC}"; }
status()  { curl -s -o /dev/null -w "%{http_code}" --max-time 5 "$1"; }

echo -e "\n🏥 HDM Frontend smoke test: ${BASE}"

# ── Página principal ──────────────────────────────────────────────────────────
section "Página principal y assets estáticos"

code=$(status "$BASE/")
[ "$code" = "200" ] && ok "GET /  →  $code" || fail "GET /  →  $code (esperado 200)"

body=$(curl -s --max-time 5 "$BASE/")
echo "$body" | grep -q "Hospital Discharge Manager" \
  && ok "/ contiene 'Hospital Discharge Manager'" \
  || fail "/ no contiene el título esperado"

# ── API proxy → Backend ────────────────────────────────────────────────────────
section "API proxy → Backend (puerto 8001)"

health_body=$(curl -s --max-time 5 "$BASE/api/health")
echo "$health_body" | grep -q '"status":"ok"' \
  && ok "GET /api/health  →  ok" \
  || fail "GET /api/health  →  respuesta inesperada: ${health_body:0:80}"

kpis_body=$(curl -s --max-time 5 "$BASE/api/kpis")
echo "$kpis_body" | grep -q '"total_discharges"' \
  && ok "GET /api/kpis  →  total_discharges presente" \
  || fail "GET /api/kpis  →  respuesta inesperada: ${kpis_body:0:80}"

discharges_body=$(curl -s --max-time 5 "$BASE/api/discharges/recent?n=3")
echo "$discharges_body" | grep -q '^\[' \
  && ok "GET /api/discharges/recent  →  lista recibida" \
  || fail "GET /api/discharges/recent  →  respuesta inesperada: ${discharges_body:0:80}"

rbg_body=$(curl -s --max-time 5 "$BASE/api/rbg/status")
echo "$rbg_body" | grep -q '"running"' \
  && ok "GET /api/rbg/status  →  campo 'running' presente" \
  || fail "GET /api/rbg/status  →  respuesta inesperada: ${rbg_body:0:80}"

# ── SPA fallback ──────────────────────────────────────────────────────────────
section "SPA routing"

code=$(status "$BASE/ruta-desconocida")
[ "$code" = "200" ] \
  && ok "GET /ruta-desconocida  →  200 (SPA fallback OK)" \
  || fail "GET /ruta-desconocida  →  $code (esperado 200)"

code=$(status "$BASE/api/endpoint-inexistente-xyz")
[ "$code" != "200" ] \
  && ok "GET /api/inexistente  →  $code (proxy activo, no 200)" \
  || fail "GET /api/inexistente  →  $code (no debería ser 200)"

# ── Resumen ───────────────────────────────────────────────────────────────────
echo ""
echo "─────────────────────────────────────────"
TOTAL=$((PASS + FAIL))
if [ "$FAIL" -eq 0 ]; then
  echo -e "${GREEN}✅ Todos los checks OK ($PASS/$TOTAL)${NC}"
  exit 0
else
  echo -e "${RED}❌ $FAIL/$TOTAL checks fallaron${NC}"
  exit 1
fi
