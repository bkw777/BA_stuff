#!/usr/bin/env bash
# Renumber TRS-80 Model 100 BASIC code
# Brian K. White b.kenyon.w@gmail.com 20210703
#
# Usage:
# [DEBUG=#] [STEP=#] [START=#] [SPACE=true|false] barenum <FILE.DO >NEW.DO
#
#   DEBUG=#  0 (default) = runnable output, with CRLF
#            1+ = increasingly verbose debugging output, no CRLF
#
#   STEP=#   new line numbers increment, default 10
#
#   START=#  new line numbers start, default 1*STEP
#
#   SPACE=true|false  insert space between keyword & argument
#
#   FILE.DO  ascii format TRS-80 Model 100 BASIC program
#
# Examples:
# runnable output, default settings
#    barenum <OLD.DO >NEW.DO
#
# debug output, start output line#'s at 5000, increment by 1
#    DEBUG=5 START=5000 STEP=1 barenum <FILE.DO |less

LANG=C
: ${DEBUG:=0}
: ${STEP:=10}
: ${START:=${STEP}}
sp= ;${SPACE:=false} && sp=' '
KEYWORDS_REGEX="(GO\s*TO|GOSUB|RESUME|ELSE|THEN|RESTORE|RETURN|RUN)"
ARGUMENT_REGEX="[0-9,[:space:]]+"
ifs=${IFS}

function vprint () {
  ((DEBUG>=$1)) && shift || return
  printf '%s' "${@}"
  ((DEBUG)) && printf '\n' || printf '\r\n'
}

function eprint () {
  ((DEBUG)) && printf '%s\n' "${@}" || printf '%s\n' "${@}" >&2
}

function usage() {
  while read -r x t ;do
    case "${x}" in
      '#') printf '%s\n' "${t}" >&2 ;;
      '') exit ;;
    esac
  done < ${0}
}

case "${1}" in
  -?|-h|--help|help) usage ;;
esac

# read all input lines into memory
rn=0
while IFS=$'\r\n' read -r t ;do
  [[ "${t}" =~ ^[[:space:]]*[0-9]+ ]] || continue
  OLD_LNUM[++rn]=${BASH_REMATCH[0]//[[:space:]]/}
  OLD_BODY[rn]=${t:${#OLD_LNUM[rn]}}
  NEW_LNUM[${OLD_LNUM[rn]}]=$((START+(rn-1)*STEP))
done

NR=${rn}
HIGHEST_NEW_LNUM=${NEW_LNUM[${OLD_LNUM[NR]}]}

# loop over every record in OLD_BODY[]
for ((rn=1;rn<=NR;rn++)) ;do
  vprint 1 "${OLD_LNUM[rn]}${OLD_BODY[rn]}"

  NEW_BODY=
  STATEMENT_POS=0
  SCAN_POS=1
  OLD_BODY_LEN=${#OLD_BODY[rn]}
  FLAG=

  # process a line
  while ((SCAN_POS<OLD_BODY_LEN)) ;do

    REMAINING_OLD_BODY=${OLD_BODY[rn]:$((SCAN_POS-1))}
    vprint 3 "    position: ${SCAN_POS}"
    vprint 3 "    remaining |${REMAINING_OLD_BODY}|"

    # look for a keyword+argument statement
    [[ "${REMAINING_OLD_BODY}" =~ ${KEYWORDS_REGEX}${ARGUMENT_REGEX} ]] || {

      # did not find a statement
      NEW_BODY+=${REMAINING_OLD_BODY}
      vprint 5 ">   new body  |${NEW_BODY}|"
      SCAN_POS=${OLD_BODY_LEN}
      continue
    }

    # found a statement

    OLD_STATEMENT=${BASH_REMATCH[0]}
    BEFORE_STATEMENT="${REMAINING_OLD_BODY%%${OLD_STATEMENT}*}"
    STATEMENT_POS=${#BEFORE_STATEMENT}
    STATEMENT_LEN=${#OLD_STATEMENT}

    # append part before statement to new body
    NEW_BODY+=${BEFORE_STATEMENT}
    vprint 5 ">   new body  |${NEW_BODY}|"

    OLD_STATEMENT=${OLD_STATEMENT// /}
    vprint 2 "    old statement |${OLD_STATEMENT}|"

    # split the statement into keyword & argument
    [[ "${OLD_STATEMENT}" =~ ${ARGUMENT_REGEX} ]]
    OLD_ARGUMENT=${BASH_REMATCH[0]}
    KEYWORD="${OLD_STATEMENT%%${OLD_ARGUMENT}}"
    vprint 3 "        keyword |${KEYWORD}|"
    vprint 3 "        old argument |${OLD_ARGUMENT}|"

    # split the original argument on commas
    IFS=, ;T=(${OLD_ARGUMENT}) ;IFS=${ifs}
    vprint 4 "        fields: ${#T[@]}"

    # replace each old target with new target
    NEW_ARGUMENT=
    for ((t=0;t<${#T[@]};t++)) ;do
      OLD_TARGET_LNUM=${T[t]}
      vprint 4 "          old[${t}] |${OLD_TARGET_LNUM}|"

      # if target line# doesn't exist, create a new line# and flag the event
      [[ "${OLD_TARGET_LNUM}" && ! "${NEW_LNUM[OLD_TARGET_LNUM]}" ]] && {
        HIGHEST_NEW_LNUM=$((HIGHEST_NEW_LNUM+STEP))
        NEW_LNUM[OLD_TARGET_LNUM]=${HIGHEST_NEW_LNUM}
        [[ "${FLAG}" ]] && FLAG+=,
        FLAG+=" ${HIGHEST_NEW_LNUM} was ${OLD_TARGET_LNUM}"
        eprint ">>> ${OLD_LNUM[rn]}->${NEW_LNUM[${OLD_LNUM[rn]}]}: Old line# ${OLD_TARGET_LNUM} does not exist -> New line# ${HIGHEST_NEW_LNUM} also does not exist."
      }

      vprint 4 "          new[${t}] |${OLD_TARGET_LNUM:+${NEW_LNUM[OLD_TARGET_LNUM]}}|"
      NEW_ARGUMENT+="${OLD_TARGET_LNUM:+${NEW_LNUM[OLD_TARGET_LNUM]}}"
      ((t<${#T[@]}-1)) && NEW_ARGUMENT+=,

    done

    vprint 3 "        new argument |${NEW_ARGUMENT}|"

    NEW_STATEMENT="${KEYWORD}${sp}${NEW_ARGUMENT}${sp}"
    vprint 2 "    new statement |${NEW_STATEMENT}|"

    NEW_BODY+=${NEW_STATEMENT}
    vprint 5 ">   new body  |${NEW_BODY}|"

    # advance the scan position to the end of the current statement
    SCAN_POS=$((SCAN_POS+STATEMENT_POS+STATEMENT_LEN))

  done

  # complete new line
  vprint 0 "${NEW_LNUM[${OLD_LNUM[rn]}]}${NEW_BODY}"

  # if a flag was raised while generating the new line, and if STEP leaves room,
  # then write the message in a comment in the next line
  [[ "${FLAG}" && ${STEP} -gt 1 ]] && vprint 0 "$((NEW_LNUM[${OLD_LNUM[rn]}]+1))'${NEW_LNUM[${OLD_LNUM[rn]}]}:${FLAG}"

  vprint 1 ''

done
