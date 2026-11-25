#!/usr/bin/env bash
# Konfiguracja ERPNext pod integrację Taiga - galwork-pm - ERPNext (Fundacja Galicea).
# Powtarza ustawienia sprawdzone na instancji testowej (etap 0 projektu integracji):
#   1. rola "Galwork Integracja" z uprawnieniami przez Role Permission Manager
#      (nie bezpośrednio przez Custom DocPerm - przy Doctype bez własnych uprawnień
#      pierwszy rekord Custom DocPerm wyłączyłby standardowe, np. Projects User na Activity Cost),
#   2. Projects Settings: ignore_employee_time_overlap = 1,
#   3. Custom Field Timesheet.galwork_ref (Data, read_only, no_copy, search_index, BEZ unique -
#      anulowany dokument zachowuje ref, więc unique blokowałby amend),
#   4. kontrola: Activity Types, konto techniczne (tylko rola integracji, bez profilu ról).
#
# Domyślnie TYLKO SPRAWDZA. Zmiany: --apply.
#
# Dane logowania administratora ERPNext (System Manager) - wyłącznie w zmiennych środowiskowych:
#   export ERP_URL=https://galicea.transmem.pl
#   export ERP_KEY=...  ERP_SECRET=...        # klucz API administratora (nie konta technicznego)
#   export TECH_USER=galwork-hub@galicea.org  # konto techniczne huba (opcjonalnie - kontrola)
#   export ACTIVITY_TYPES="programowanie,dokumentowanie,testowanie,wdrażanie"
#   ./erpnext_setup.sh            # podgląd
#   ./erpnext_setup.sh --apply    # zmiany

set -uo pipefail

ERP_URL=${ERP_URL:-https://galicea.transmem.pl}
: "${ERP_KEY:?ustaw ERP_KEY (klucz API administratora)}"
: "${ERP_SECRET:?ustaw ERP_SECRET}"
ACTIVITY_TYPES=${ACTIVITY_TYPES:-programowanie,dokumentowanie,testowanie,wdrażanie}
TECH_USER=${TECH_USER:-}
ROLE="Galwork Integracja"
APPLY=0
[[ "${1:-}" == "--apply" ]] && APPLY=1

AUTH="Authorization: token ${ERP_KEY}:${ERP_SECRET}"
OK=0; TODO=0; ERR=0

erp() {  # erp METODA ŚCIEŻKA [JSON]
  local method=$1 path=$2 body=${3:-}
  if [[ -n "$body" ]]; then
    curl -gsS -X "$method" -H "$AUTH" -H "Content-Type: application/json" -d "$body" "$ERP_URL$path"
  else
    curl -gsS -X "$method" -H "$AUTH" "$ERP_URL$path"
  fi
}
uri() { jq -rn --arg s "$1" '$s|@uri'; }
ok()   { echo "  [OK]   $*"; OK=$((OK+1)); }
todo() { echo "  [DO ZROBIENIA] $*"; TODO=$((TODO+1)); }
err()  { echo "  [BŁĄD] $*"; ERR=$((ERR+1)); }
exc()  { jq -r '(.exc_type // "") + " " + ((._server_messages // "" | fromjson? // [] | map(fromjson.message|gsub("<[^>]+>";"")) | join("; ")) // "")'; }

echo "ERPNext: $ERP_URL  (tryb: $([[ $APPLY == 1 ]] && echo ZMIANY || echo podgląd))"
WHO=$(erp GET /api/method/frappe.auth.get_logged_user | jq -r '.message // empty')
[[ -z "$WHO" ]] && { echo "Nie można zalogować się kluczem ERP_KEY/ERP_SECRET"; exit 1; }
echo "Zalogowany: $WHO | wersje: $(erp GET /api/method/frappe.utils.change_log.get_versions | jq -c '.message | map_values(.version) | {frappe, erpnext, hrms}')"

echo
echo "1. Rola \"$ROLE\""
if [[ $(erp GET "/api/resource/Role/$(uri "$ROLE")" | jq -r '.data.name // empty') == "$ROLE" ]]; then
  ok "rola istnieje"
elif [[ $APPLY == 1 ]]; then
  r=$(erp POST /api/resource/Role "$(jq -n --arg r "$ROLE" '{role_name:$r, desk_access:1}')")
  [[ $(jq -r '.data.name // empty' <<<"$r") == "$ROLE" ]] && ok "utworzono rolę" || err "rola: $(exc <<<"$r")"
else
  todo "utworzenie roli"
fi

echo
echo "2. Uprawnienia roli (Role Permission Manager, permlevel 0)"
PM=/api/method/frappe.core.page.permission_manager.permission_manager
declare -A PERMS=( [Timesheet]="read write create submit cancel amend" [Employee]="read" [Project]="read"
                   ["Activity Type"]="read" ["Activity Cost"]="read" )
ALL_PTYPES="read write create delete submit cancel amend report export print email share"
for dt in "${!PERMS[@]}"; do
  want=" ${PERMS[$dt]} "
  current=$(erp GET "/api/resource/Custom%20DocPerm?filters=[[\"parent\",\"=\",\"$(uri "$dt")\"],[\"role\",\"=\",\"$(uri "$ROLE")\"],[\"permlevel\",\"=\",0]]&fields=[\"read\",\"write\",\"create\",\"delete\",\"submit\",\"cancel\",\"amend\",\"report\",\"export\",\"print\",\"email\",\"share\"]" \
            | jq -r '.data[0] // {} | to_entries | map(select(.value==1) | .key) | join(" ")')
  diff=""
  for pt in $ALL_PTYPES; do
    has=0; [[ " $current " == *" $pt "* ]] && has=1
    need=0; [[ "$want" == *" $pt "* ]] && need=1
    [[ $has != "$need" ]] && diff="$diff $pt=$need"
  done
  if [[ -z "$diff" && -n "$current" ]]; then
    ok "$dt: ${PERMS[$dt]}"
  elif [[ $APPLY == 1 ]]; then
    [[ -z "$current" ]] && erp POST "$PM.add" "$(jq -n --arg d "$dt" --arg r "$ROLE" '{parent:$d, role:$r, permlevel:0}')" >/dev/null
    for pt in $ALL_PTYPES; do
      need=0; [[ "$want" == *" $pt "* ]] && need=1
      erp POST "$PM.update" "$(jq -n --arg d "$dt" --arg r "$ROLE" --arg p "$pt" --argjson v $need \
        '{doctype:$d, role:$r, permlevel:0, ptype:$p, value:$v}')" >/dev/null
    done
    ok "$dt: ustawiono ${PERMS[$dt]}"
  else
    todo "$dt: zmiany${diff:- (brak uprawnień roli)}"
  fi
done

echo
echo "3. Projects Settings: ignore_employee_time_overlap"
v=$(erp GET "/api/resource/Projects%20Settings/Projects%20Settings" | jq -r '.data.ignore_employee_time_overlap')
if [[ "$v" == "1" ]]; then
  ok "włączone"
elif [[ $APPLY == 1 ]]; then
  r=$(erp PUT "/api/resource/Projects%20Settings/Projects%20Settings" '{"ignore_employee_time_overlap":1}')
  [[ $(jq -r '.data.ignore_employee_time_overlap' <<<"$r") == "1" ]] && ok "włączono" || err "$(exc <<<"$r")"
else
  todo "włączenie (UWAGA: globalne - wyłącza kontrolę nakładania także dla Timesheetów wpisywanych ręcznie)"
fi

echo
echo "4. Custom Field Timesheet.galwork_ref"
cf=$(erp GET "/api/resource/Custom%20Field/Timesheet-galwork_ref" | jq -c '.data // empty | {unique, search_index, read_only, no_copy}')
if [[ -n "$cf" ]]; then
  if [[ $(jq -r '.unique' <<<"$cf") == "1" ]]; then
    if [[ $APPLY == 1 ]]; then
      erp PUT "/api/resource/Custom%20Field/Timesheet-galwork_ref" '{"unique":0}' >/dev/null; ok "zdjęto unique"
    else
      todo "pole ma unique=1 - zdjąć (blokuje amend)"
    fi
  else
    ok "istnieje $cf"
  fi
elif [[ $APPLY == 1 ]]; then
  r=$(erp POST "/api/resource/Custom%20Field" '{"dt":"Timesheet","fieldname":"galwork_ref","label":"Galwork ref","fieldtype":"Data","insert_after":"note","unique":0,"read_only":1,"no_copy":1,"search_index":1}')
  [[ $(jq -r '.data.name // empty' <<<"$r") == "Timesheet-galwork_ref" ]] && ok "utworzono" || err "$(exc <<<"$r")"
else
  todo "utworzenie pola"
fi

echo
echo "5. Activity Types (kontrola - tworzenie i stawki ręcznie, zob. WDROZENIE.md)"
active=$(erp GET '/api/resource/Activity%20Type?filters=[["disabled","=",0]]&fields=["name","billing_rate","costing_rate"]&limit_page_length=500')
IFS=',' read -ra WANT <<<"$ACTIVITY_TYPES"
for at in "${WANT[@]}"; do
  at=$(echo "$at" | xargs)
  row=$(jq -c --arg n "$at" '.data[] | select(.name==$n)' <<<"$active")
  if [[ -z "$row" ]]; then
    todo "brak aktywnego Activity Type \"$at\""
  else
    b=$(jq -r '.billing_rate' <<<"$row"); c=$(jq -r '.costing_rate' <<<"$row")
    if [[ "$c" == "0" || "$c" == "0.0" ]]; then
      todo "\"$at\": stawka kosztu 0 (brak Activity Cost da koszt 0)"
    else
      ok "\"$at\" (sprzedaż $b, koszt $c)$([[ "$b" == "$c" ]] && echo ' - UWAGA: sprzedaż = koszt, zerowa marża')"
    fi
  fi
done
others=$(jq -r --arg w ",$ACTIVITY_TYPES," '[.data[].name | . as $n | select(($w | contains("," + $n + ",")) | not)] | join(", ")' <<<"$active")
[[ -n "$others" ]] && echo "  [INFO] inne aktywne Activity Types (rozważ wyłączenie): $others"

echo
echo "6. Konto techniczne"
if [[ -z "$TECH_USER" ]]; then
  echo "  [INFO] pomijam - ustaw TECH_USER"
else
  u=$(erp GET "/api/resource/User/$(uri "$TECH_USER")")
  if [[ -z $(jq -r '.data.name // empty' <<<"$u") ]]; then
    todo "brak użytkownika $TECH_USER (utwórz ręcznie, zob. WDROZENIE.md)"
  else
    roles=$(jq -r '[.data.roles[]?.role] | sort | join(", ")' <<<"$u")
    profile=$(jq -r '[.data.role_profile_name // empty] + [.data.role_profiles[]?.role_profile] | unique | join(", ")' <<<"$u")
    [[ "$roles" == "$ROLE" ]] && ok "role: $roles" || todo "role: [$roles] - powinna być tylko \"$ROLE\""
    [[ -z "$profile" ]] && ok "bez profilu ról" || todo "profil ról [$profile] - zdjąć (odtwarza role przy zapisie użytkownika)"
    [[ $(jq -r '.data.api_key // empty' <<<"$u") != "" ]] && ok "ma klucz API" || todo "wygeneruj klucz API"
    [[ $(jq -r '.data.enabled' <<<"$u") == "1" ]] || err "konto wyłączone"
  fi
fi

echo
echo "Podsumowanie: OK=$OK, do zrobienia=$TODO, błędy=$ERR"
[[ $ERR == 0 ]]
