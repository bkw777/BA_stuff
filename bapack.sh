#!/bin/bash
# Remove all tabs, spaces, and comments from BASIC code
# The first line is preseved for copyright & credits
# usage: ./packer.sh <BIG.DO >SMALL.DO
# Brian K. White 20210703
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
