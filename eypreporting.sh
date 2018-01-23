#!/bin/bash

GITHUB_USERNAME=${GITHUB_USERNAME:-NTTCom-MS}
REPOBASEDIR=${REPOBASEDIR:-/var/eyprepos}
REPO_PATTERN=${REPO_PATTERN:-eyp-}
PAGES_REPO=${PAGES_REPO:-git@github.com:NTTCom-MS/NTTCom-MS.github.io.git}

API_URL_REPOLIST="https://api.github.com/users/${GITHUB_USERNAME}/repos?per_page=100"
API_URL_REPOINFO_BASE="https://api.github.com/repos/${GITHUB_USERNAME}"

function table_header()
{
  echo -n "<tr>"
  for header in "$@"
  do
      echo -n "<th>${header}</th>"
  done
  echo -n "</tr>"
}

function table_data()
{
  echo -n "<tr>"
  for field in "$@"
  do
      echo -n "<td>${field}</td>"
  done
  echo -n "</tr>"
}

function update_doc()
{
  CURRENT_DOC_VERSION="$(curl -u "${DOC_USER}:${DOC_PASSWORD}" "${DOC_URL_REST}/content/${DOC_ID}" 2>/dev/null | python -c 'import sys, json; print json.load(sys.stdin)["version"]' | grep -Eo "'number': [0-9]+" | awk '{ print $NF }')"

  let NEXT_DOC_VERSION=CURRENT_DOC_VERSION+1

  curl -u "${DOC_USER}:${DOC_PASSWORD}" -X PUT -H 'Content-Type: application/json' \
  -d"{\"id\":\"${DOC_ID}\",\"type\":\"page\",\"title\":\"Module TOC\",\"space\":{\"key\":\"${DOC_SPACE}\"},\"body\":{\"storage\":{\"value\":\"${REPORT_REPOS}\",\"representation\":\"storage\"}},\"version\":{\"number\":\"${NEXT_DOC_VERSION}\"}}" "${DOC_URL_REST}/content/${DOC_ID}"
}

function paginar()
{
  REPO_LIST_HEADERS=$(curl -I "${API_URL_REPOLIST}&page=${PAGENUM}" 2>/dev/null)

  echo "${REPO_LIST_HEADERS}" | grep "HTTP/1.1 403 Forbidden"
  if [ $? -eq 0 ];
  then
    RESET_RATE_LIMIT=$(echo "${REPO_LIST_HEADERS}" | grep "^X-RateLimit-Reset" | awk '{ print $NF }' | grep -Eo "[0-9]*")
    CURRENT_TS=$(date +%s)

    if [ "${RESET_RATE_LIMIT}" -ge "${CURRENT_TS}" ];
    then
      let SLEEP_RATE_LIMIT=RESET_RATE_LIMIT-CURRENT_TS
    else
      SLEEP_RATE_LIMIT=10
    fi

    RANDOM_EXTRA_SLEEP=$(echo $RANDOM | grep -Eo "^[0-9]{2}")
    let SLEEP_RATE_LIMIT=SLEEP_RATE_LIMIT+RANDOM_EXTRA_SLEEP

    echo "rate limited, sleep: ${SLEEP_RATE_LIMIT}"
    if [ "${DEBUG}" -eq 0 ];
    then
      sleep "${SLEEP_RATE_LIMIT}"
    fi
  fi

  REPOLIST_LINKS=$(echo "${REPO_LIST_HEADERS}" | grep "^Link" | head -n1)
  REPOLIST_NEXT=$(echo "${REPOLIST_LINKS}" | awk '{ print $2 }')
  REPOLIST_LAST=$(echo "${REPOLIST_LINKS}" | awk '{ print $4 }')
}

function report()
{
  REPO_URL=$1

  REPO_NAME=${REPO_URL##*/}
  REPO_NAME=${REPO_NAME%.*}

  cd ${REPOBASEDIR}

  if [ -d "${REPO_NAME}" ];
  then
    rm -fr "${REPOBASEDIR}/${REPO_NAME}"
  fi

  git clone ${REPO_URL} > /dev/null 2>&1
  cd ${REPO_NAME}

  MODULE_VERSION=$(cat metadata.json  | grep '"version"' | awk '{ print $NF }' | cut -f2 -d\")

  #
  table_data "${REPO_NAME}" \
             "${MODULE_VERSION}" \
             "<a href=\"/${GITHUB_USERNAME}/${REPO_NAME}\"><ac:image><ri:url ri:value=\"https://api.travis-ci.org/${GITHUB_USERNAME}/${REPO_NAME}.png?branch=master\"/></ac:image></a>" \
             "<a href=\"https://github.com/${GITHUB_USERNAME}/${REPO_NAME}/blob/master/README.md\">Documentation</a><br/><a href=\"https://github.com/${GITHUB_USERNAME}/${REPO_NAME}/blob/master/CHANGELOG.md\">CHANGELOG</a>"
}

function getpagesrepo()
{
  PAGES_REPO_NAME=${PAGES_REPO##*/}
  PAGES_REPO_NAME=${PAGES_REPO_NAME%.*}

  cd ${REPOBASEDIR}

  if [ -d "${REPOBASEDIR}/${PAGES_REPO_NAME}" ];
  then
    rm -fr "${REPOBASEDIR}/${PAGES_REPO_NAME}"
  fi

  git clone ${PAGES_REPO}
  cd ${PAGES_REPO_NAME}
}

function getrepolist()
{
  # curl -I https://api.github.com/users/NTTCom-MS/repos?per_page=100 2>/dev/null| grep ^Link:

  PAGENUM=1

  REPOLIST=$(curl "${API_URL_REPOLIST}&page=${PAGENUM}" 2>/dev/null | grep "ssh_url" | cut -f4 -d\" | grep -E "/${REPO_PATTERN}")

  paginar

  while [ "${REPOLIST_NEXT}" != "${REPOLIST_LAST}" ];
  do
    let PAGENUM=PAGENUM+1
    REPOLIST=$(echo -e "${REPOLIST}\n$(curl "${API_URL_REPOLIST}&page=${PAGENUM}" 2>/dev/null | grep "ssh_url" | cut -f4 -d\" | grep -E "/${REPO_PATTERN}")")

    paginar
  done

  let PAGENUM=PAGENUM+1
  REPOLIST=$(echo -e "${REPOLIST}\n$(curl "${API_URL_REPOLIST}&page=${PAGENUM}" 2>/dev/null | grep "ssh_url" | cut -f4 -d\" | grep -E "/${REPO_PATTERN}")")
}

PATH="/usr/local/sbin:/usr/local/bin:/sbin:/bin:/usr/sbin:/usr/bin"

BASEDIR=$(dirname $0)
BASENAME=$(basename $0)

if [ ! -z "$1" ] && [ -f "$1" ];
then
  . $1 2>/dev/null
else
  if [[ -s "$BASEDIR/${BASENAME%%.*}.config" ]];
  then
    . $BASEDIR/${BASENAME%%.*}.config 2>/dev/null
  else
    echo "config file missing"
    exit 1
  fi
fi

mkdir -p ${REPOBASEDIR}

getpagesrepo
if [ "${DEBUG}" -eq 0 ];
then
  sleep "$(echo $RANDOM | grep -Eo "^[0-9]{2}")"
fi

getrepolist

REPORT_REPOS="<table><tbody>$(table_header 'Module name' 'Version' 'Travis status' 'Links')"

for REPO_URL in $(echo "${REPOLIST}");
do
  REPORT_REPOS="${REPORT_REPOS}$(report "${REPO_URL}")"
  if [ "${DEBUG}" -eq 0 ];
  then
    sleep "$(echo $RANDOM | grep -Eo "^[0-9]{2}")"
  fi
done

# postejar
# echo -e ${REPORT_REPOS}

REPORT_REPOS="$(echo "${REPORT_REPOS}" | sed 's/"/\\"/g')</tbody></table>"

update_doc

exit 0
