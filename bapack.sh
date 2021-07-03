#!/bin/bash
# Remove whitespace and comments from TRS-80 Model 100 BASIC code
# The first line is preseved for copyright & credits
# usage: bapack <BIG.DO >SMALL.DO
# Brian K. White b.kenyon.w@gmail.com 20210703

function usage() {
  while read -r x t ;do
    case "${x}" in
      '#') printf "%s\n" "${t}" >&2 ;;
      '') exit ;;
    esac
  done < ${0}
}

case "${1}" in
  -?|-h|--help|help) usage ;;
esac

n=0
while IFS=$'\r\n' read -r t ;do
  o='' p=-1
  while (( ${p} < ${#t} )) ;do
    c="${t:$((++p)):1}"
    [[ "${t:${p}:3}" == [Rr][Ee][Mm] ]] && c="'"
    case "${c}" in
      $'\t'|' ') continue ;;
      "'") p=${#t} ; continue ;;
      '"')
        while (( ${p} < ${#t} )) ;do
          o+="${c}" c="${t:$((++p)):1}"
          [[ "${c}" == '"' ]] && break
        done
        ;;
    esac
    o+="${c}"
  done
  (( $((++n)) <= 1 )) && o="${t}"
  [[ "${o}" =~ ^[0-9]+$ ]] || printf "%s\r\n" "${o}"
done
