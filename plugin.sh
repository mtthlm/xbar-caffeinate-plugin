#!/usr/bin/env -S-P"/usr/local/bin:/opt/homebrew/bin:${PATH}" bash
# shellcheck shell=bash
#
# <xbar.title>Caffeinate</xbar.title>
# <xbar.version>v1.0.0</xbar.version>
# <xbar.author>Matt Helm</xbar.author>
# <xbar.desc>Utility for managing `caffeinate(8)`.</xbar.desc>
# <xbar.dependencies>bash,pmset,caffeinate</xbar.dependencies>
#

[ "${BASH_VERSINFO:=0}" -ge 4 ] || {
  echo -e "Error\n---\nBash version >= 4 required, found ${BASH_VERSINFO}${BASH:+": ${BASH}"}"
  exit
}

set -o errexit -o nounset -o pipefail

declare -r CAFFEINATE_LAUNCHD_LABEL='local.caffeinate'

function :define () {
  IFS=$'\n' read -r -d '' "$@" || true
}

function :readline () {
  IFS= read -r "$@"
}

function :printf () {
  printf -- "$1" "${@:2}"
}

function :print () {
  :printf '%s' "$@"
}

function :println () {
  :printf '%s\n' "$@"
}

function :replace:all () {
  :println "${1//"$2"/"$3"}"
}

function :split () {
  :replace:all "$2" "$1" $'\n'
}

function :join () {
  :replace:all "$(:println "${@:2}")" $'\n' "$1"
}

declare -a caffeinates=() assertions=()

while
  :readline
do
  declare -A assertion
  eval "$REPLY"

  if [[ "${assertion["type"]}" == 'PreventUserIdleDisplaySleep' && "${assertion["command"]}" == 'caffeinate' ]]
  then caffeinates+=("$REPLY")
  else assertions+=("$REPLY")
  fi
done < <(
  {
    pmset -g assertions
  } | {
    declare filter
    :define filter <<'EOP'
BEGIN {
  inSection = 0
}

/^[^[:space:]]/ {
  if ($0 == "Listed by owning process:") {
    inSection = 1
  } else {
    inSection = 0
  }

  next
}

inSection
EOP

    awk "$filter"
  } | {
    while
      declare line
      :readline line
    do
      if
        : 'pid ([1-9][0-9]*)\(([^)]+)\): \[[^]]+\] ([0-5][0-9]:[0-5][0-9]:[0-5][0-9]) ([^ ]+)'
        [[ "$line" =~ $_ ]]
      then
        declare -A assertion=(
              ["pid"]="${BASH_REMATCH[1]}"
          ["command"]="${BASH_REMATCH[2]}"
          ["elapsed"]="${BASH_REMATCH[3]}"
             ["type"]="${BASH_REMATCH[4]}"
        )

        :printf '%s;\n' "$(declare -p assertion)"
      fi
    done
  }
)

if [[ "${#caffeinates[@]}" -gt 0 ]]
then
  :print ':coffee:'

  if [[ "${#caffeinates[@]}" -gt 1 ]]
  then :printf ' (%d)' "${#caffeinates[@]}"
  fi

  :println
  :println '---'

  for element in "${caffeinates[@]}"
  do
    declare -A assertion
    eval "$element"

    :print 'Decaffeinate'

    if [[ "${#caffeinates[@]}" -gt 1 ]]
    then :printf ' (%d)' "${assertion["pid"]}"
    fi

    if
      : "$(ps -o 'ppid=' "${assertion["pid"]}")"
      : "$(:printf '%d' "$_")"
      [[ "$(ps -c -o 'command=' "$_")" == 'launchd' ]]
    then :printf ' | shell="launchctl" param1="remove" param2="%s"' "$CAFFEINATE_LAUNCHD_LABEL"
    else :printf ' | shell="kill" param1="%d"' "${assertion["pid"]}"
    fi

    :println ' | refresh=true'
  done
else
  :println ':zzz:'
  :println '---'
  :printf 'Caffeinate | shell="launchctl" param1="submit" param2="-l" param3="%s" param4="--" param5="caffeinate" param6="-d" | refresh=true\n' "$CAFFEINATE_LAUNCHD_LABEL"
fi

if [[ "${#assertions[@]}" -gt 0 ]]
then
  :println '---'

  # :println 'Other Assertions:'

  for element in "${assertions[@]}"
  do
    declare -A assertion
    eval "$element"

    :printf '%s (%d): %s\n' "${assertion["command"]}" "${assertion["pid"]}" "${assertion["elapsed"]}"
    :printf '%s (%d): %s | alternate=true\n' "${assertion["command"]}" "${assertion["pid"]}" "${assertion["type"]}"
  done
fi
