#!/bin/bash
# ==============================================================================
# insert_discharge_api-POST.sh — Crea una alta médica via la API del backend HDM
#
# Uso:
#   ./insert_discharge_api-POST.sh
#
# Genera un paciente ficticio aleatorio y lo da de alta en el sistema.
# Equivalente al insert_booking_api-POST.sh del Flight Booking Simulator.
# ==============================================================================

API="${API_BASE:-http://10.10.44.14:8001}"
TMPFILE=$(mktemp /tmp/_hdm_insert.XXXXXX)
trap 'rm -f "$TMPFILE"' EXIT

GRN='\033[0;32m'; RED='\033[0;31m'; CYA='\033[0;36m'; YEL='\033[1;33m'
BLD='\033[1m'; DIM='\033[2m'; RST='\033[0m'

# ── Datos ficticios aleatorios ────────────────────────────────────────────────
FIRST_NAMES=("Manuel" "María" "José" "Carmen" "Antonio" "Ana" "Francisco" "Isabel" "Juan" "Pilar" "Luis" "Rosa" "David" "Elena" "Pedro")
LAST_NAMES=("García" "González" "Rodríguez" "Fernández" "López" "Martínez" "Sánchez" "Pérez" "Gómez" "Díaz" "Moreno" "Romero" "Torres" "Navarro")
WARDS=("Cardiología · 3ª planta" "Neurología · 4ª planta" "Traumatología · 2ª planta" "Cirugía General · 5ª planta" "Medicina Interna · 1ª planta" "Oncología · 6ª planta" "Geriatría · Planta baja")
DISCHARGE_TYPES=("DOMICILIO" "DOMICILIO" "DOMICILIO" "RESIDENCIA" "TRASLADO" "HOSPITALIZACION_DIA")
DIAG_CODES=("I21" "I50" "G45" "S72" "J18" "K40" "E11" "N39" "M17" "I48" "C34" "F00")
DIAG_DESCS=("Infarto agudo de miocardio" "Insuficiencia cardíaca" "Accidente isquémico transitorio" "Fractura de cadera" "Neumonía" "Hernia inguinal" "Diabetes tipo 2" "Infección urinaria" "Artrosis de rodilla" "Fibrilación auricular" "Neoplasia de pulmón" "Demencia")
DOCTORS=("Dr. García Martínez" "Dra. López Sánchez" "Dr. Fernández Ruiz" "Dra. Martínez Gómez" "Dr. Sánchez Torres" "Dra. Romero Díaz")
DESTINATIONS=("Domicilio familiar" "Domicilio propio" "Residencia El Pinar" "Residencia Los Olivos" "Centro de Salud Alta Gracia" "Hospital Regional de Referencia")

rand_elem() { local arr=("$@"); echo "${arr[$((RANDOM % ${#arr[@]}))]}"; }

FIRST=$(rand_elem "${FIRST_NAMES[@]}")
LAST1=$(rand_elem "${LAST_NAMES[@]}")
LAST2=$(rand_elem "${LAST_NAMES[@]}")
PATIENT_NAME="$FIRST $LAST1 $LAST2"
PATIENT_ID="P-$((1000000 + RANDOM % 9000000))"
WARD=$(rand_elem "${WARDS[@]}")
DISCHARGE_TYPE=$(rand_elem "${DISCHARGE_TYPES[@]}")
IDX=$((RANDOM % ${#DIAG_CODES[@]}))
DIAG_CODE="${DIAG_CODES[$IDX]}"
DIAG_DESC="${DIAG_DESCS[$IDX]}"
DOCTOR=$(rand_elem "${DOCTORS[@]}")
DESTINATION=$(rand_elem "${DESTINATIONS[@]}")
PROC_TIME=$((5 + RANDOM % 56))
FLOOR=$((RANDOM % 4 + 1))
ROOM=$((RANDOM % 30 + 100))
SLOT=$(echo "ABCD" | fold -w1 | shuf | head -1 2>/dev/null || echo "A")
BED="${FLOOR}${ROOM}-${SLOT}"
ADMISSION=$(date -d "-$((RANDOM % 14 + 1)) days" '+%Y-%m-%d' 2>/dev/null \
         || date -v-$((RANDOM % 14 + 1))d '+%Y-%m-%d' 2>/dev/null \
         || date '+%Y-%m-%d')

echo ""
echo -e "${BLD}POST /api/discharges  —  Crear alta médica manual${RST}"
echo -e "${DIM}─────────────────────────────────────────────${RST}"
echo -e "  Endpoint    : ${CYA}${API}/api/discharges${RST}"
echo -e "  Paciente    : ${YEL}${PATIENT_NAME}${RST}  (${PATIENT_ID})"
echo -e "  Planta      : ${YEL}${WARD}${RST}"
echo -e "  Diagnóstico : ${YEL}${DIAG_CODE} — ${DIAG_DESC}${RST}"
echo ""

# ── Llamada a la API ──────────────────────────────────────────────────────────
echo -e "${BLD}[1/1]${RST} Insertando alta..."

PAYLOAD=$(cat <<JSONEOF
{
  "patient_id":            "${PATIENT_ID}",
  "patient_name":          "${PATIENT_NAME}",
  "ward":                  "${WARD}",
  "bed_number":            "${BED}",
  "admission_date":        "${ADMISSION}",
  "discharge_type":        "${DISCHARGE_TYPE}",
  "diagnosis_code":        "${DIAG_CODE}",
  "diagnosis_description": "${DIAG_DESC}",
  "attending_unit":        "${DOCTOR}",
  "destination":           "${DESTINATION}",
  "processing_time_min":   ${PROC_TIME}
}
JSONEOF
)

HTTP_CODE=$(curl -s -o "$TMPFILE" -w "%{http_code}" \
  -X POST "${API}/api/discharges" \
  -H "Content-Type: application/json" \
  -d "$PAYLOAD")

RESPONSE=$(cat "$TMPFILE")

if [ "$HTTP_CODE" = "200" ] || [ "$HTTP_CODE" = "201" ]; then
  NEW_ID=$(echo "$RESPONSE" | python3 -c "import sys,json; print(json.load(sys.stdin).get('id','?'))" 2>/dev/null)
  echo -e "      ${GRN}✔  Alta creada  (HTTP ${HTTP_CODE})${RST}"
  echo ""
  echo -e "${DIM}─────────────────────────────────────────────${RST}"
  echo -e "  ID alta     : ${YEL}${NEW_ID}${RST}"
  echo -e "  Paciente    : ${YEL}${PATIENT_NAME}${RST}"
  echo -e "  ID paciente : ${YEL}${PATIENT_ID}${RST}"
  echo -e "  Planta/cama : ${YEL}${WARD} — ${BED}${RST}"
  echo -e "  Diagnóstico : ${YEL}${DIAG_CODE} — ${DIAG_DESC}${RST}"
  echo -e "  Tipo alta   : ${YEL}${DISCHARGE_TYPE}${RST}"
  echo -e "  Médico      : ${YEL}${DOCTOR}${RST}"
  echo -e "  Destino     : ${YEL}${DESTINATION}${RST}"
  echo -e "  Proc. (min) : ${YEL}${PROC_TIME}${RST}"
  echo -e "${DIM}─────────────────────────────────────────────${RST}"
else
  echo -e "      ${RED}✗  Error al insertar el alta  (HTTP ${HTTP_CODE})${RST}"
  echo ""
  echo "$RESPONSE"
  exit 1
fi
echo ""
