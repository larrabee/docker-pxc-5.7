#!/bin/bash
set -euo pipefail

CMD="$@"

source <(grep = ${MYSQL_CONFIG_FILE} |sed 's/ *= */=/g' |sed 's/;/#/g' |sed 's/-/_/g')

init_db() {
  local password="$(mysqld --defaults-file="${MYSQL_CONFIG_FILE}" --log_error="${MYSQL_STDOUT_FILE}" --log_error_verbosity=3 --initialize |grep 'A temporary password is generated for root@localhost' |sed 's/^.*root@localhost: //')"
  echo "DB initialized successful"
  echo "root@localhost password: ${password}"
}

wsrep_recover_position() {
  local grastate_loc="${datadir}/grastate.dat"
  local uuid=""
  local seqno=0
  
  if ! [[ -e "${grastate_loc}" ]]; then
    echo "File ${grastate_loc} not found, using default position"
    WSREP_POSITION="00000000-0000-0000-0000-000000000000:-1"
    return
  fi
  
  uuid=$(grep 'uuid:' "${grastate_loc}" | cut -d: -f2 | tr -d ' ')
  seqno=$(grep 'seqno:' "${grastate_loc}" | cut -d: -f2 | tr -d ' ')
  
  if [[ ! -z "${seqno}" ]] && [[ "${seqno}" -ne -1 ]]; then
    echo "Skipping wsrep-recover for $uuid:$seqno pair"
    echo "Assigning $uuid:$seqno to wsrep_start_position"
    WSREP_POSITION="$uuid:$seqno"
    return
  fi
  echo "Recovering position with '--wsrep_recover'"
  set +e 
  local WS_RECOVER_OUTPUT="$(mysqld --defaults-file="${MYSQL_CONFIG_FILE}" --wsrep_recover --log_error="${MYSQL_STDOUT_FILE}" --log_error_verbosity=3 |grep 'WSREP: Recovered position:' |sed 's/.*WSREP\:\ Recovered\ position://' |sed 's/^[ \t]*//')"
  set -e
  if [[ -z "${WS_RECOVER_OUTPUT}" ]]; then
    echo "Recovery failed, starting without recovery"
    WSREP_POSITION=""
  else
    echo "Recovered position ${WS_RECOVER_OUTPUT}"
    WSREP_POSITION="${WS_RECOVER_OUTPUT}"
  fi
  
}

if [[ -z "${datadir:-}" ]]; then
  echo "ERROR: datadir directive not found in '${MYSQL_CONFIG_FILE}', please check configs"
  exit 1
fi

if [[ ! -d "${datadir}/mysql" ]]; then
  echo "Directory \"${datadir}/mysql\" not found, starting initialization"
  init_db
fi

if [[ -z "${MYSQL_SKIP_POSITION_RECOVERY:-}" ]]; then
  WSREP_POSITION=""
  wsrep_recover_position
  if [[ ! -z "${WSREP_POSITION}" ]]; then
    echo "Position recovered successful"
    CMD="${CMD} --wsrep_start_position=${WSREP_POSITION}"
  fi
fi

echo "Running mysqld with options: --defaults-file=\"${MYSQL_CONFIG_FILE}\" ${CMD}"
exec mysqld --defaults-file="${MYSQL_CONFIG_FILE}" ${CMD}
