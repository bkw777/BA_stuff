#!/usr/bin/gawk -f
# Renumber the lines of a TRS-80 Model 100 BASIC program
# GPL3 b.kenyon.w@gmail.com 2021
#
# Usage:
# ./renum.awk [-v DEBUG=#] [-v STEP=#] [-v START=#] FILE.DO
#
#   -v DEBUG=#  0 (default) = runnable output, with CRLF
#               1+ = increasingly verbose debugging output, no CRLF
#
#   -v STEP=#   new line numbers increment, default 10
#
#   -v START=#  new line numbers start, default 1*STEP
#
#   FILE.DO     ascii format TRS-80 Model 100 BASIC program
#
# Examples:
# runnable output, default settings
#    ./renum.awk FILE.DO > NEW.DO
#
# max verbose debug, start output line#'s at 5000, increment by 1
#    ./renum.awk -v DEBUG=5 -v START=5000 -v STEP=1 FILE.DO |less

BEGIN {
  RS = "(\r\n|\n)"
  if (DEBUG == "") DEBUG = 0
  if (STEP < 1) STEP = 10
  if (START == "") START = STEP
  KEYWORDS_REGEX = "(GOTO|GOSUB|RESUME|ELSE|THEN)"
  ARGUMENT_REGEX = "[0-9,[:space:]]+"
}

# read all the original lines into arrays
# seperate the line numbers and bodies
# generate new line numbers in an array indexed by old line number
match($0 , /^[0-9]+/) {
  OLD_LNUM[FNR] = substr($0 , 1 , RLENGTH)
  OLD_BODY[FNR] = substr($0 , RLENGTH+1)
  NEW_LNUM[OLD_LNUM[FNR]] = START+(FNR-1)*STEP
}

END {

  HIGHEST_NEW_LNUM = NEW_LNUM[OLD_LNUM[FNR]]

  # loop over array of old line bodies
  for (rn = 1 ; rn <= FNR ; rn++) {
    vprint(1,OLD_LNUM[rn] OLD_BODY[rn])

    NEW_BODY = ""
    STATEMENT_POS = 0
    STATEMENT_LEN = 0
    SCAN_POS = 1
    OLD_BODY_LEN = length(OLD_BODY[rn])
    FLAG = ""
    CURRENT_NEW_LNUM = NEW_LNUM[OLD_LNUM[rn]]

    # scan the the original line body for goto keywords
    do {

      # portion of original body to scan
      REMAINING_OLD_BODY = substr(OLD_BODY[rn] , SCAN_POS)
      vprint(3,"    position: " SCAN_POS)
      vprint(3,"    remaining |" REMAINING_OLD_BODY "|")

      # find GOTO, GOSUB, RESUME, ELSE, or THEN,
      # with 0 or more spaces, numbers, or commas
      #   ELSE10			no space
      #   RESUME 10			space
      #   GOTO 10,20,30,40		list
      #   GOSUB 10,20,30,,,,40		list may include empty fields
      STATEMENT_POS = match(REMAINING_OLD_BODY , KEYWORDS_REGEX ARGUMENT_REGEX)
      STATEMENT_LEN = RLENGTH
      vprint(3,"    match at: " STATEMENT_POS)

      if (STATEMENT_POS < 1) {
        ### found no statement

        NEW_BODY = NEW_BODY REMAINING_OLD_BODY
        vprint(5,">   new body  |" NEW_BODY "|")
        SCAN_POS = OLD_BODY_LEN		# jump the scan position to the end
      }
      else {
        ### found a statement

        # append part before statement to new body
        NEW_BODY = NEW_BODY substr(REMAINING_OLD_BODY , 1 , STATEMENT_POS-1)
        vprint(5,">   new body  |" NEW_BODY "|")

        # isolate the statement
        OLD_STATEMENT = substr(REMAINING_OLD_BODY , STATEMENT_POS , STATEMENT_LEN)
        gsub(/[[:space:]]/ , "" , OLD_STATEMENT)
        vprint(2,"    old statement |" OLD_STATEMENT "|")

        # split the statement into keyword & argument
        KEYWORD = OLD_STATEMENT
        OLD_ARGUMENT = ""
        ka = match(OLD_STATEMENT , ARGUMENT_REGEX)
        if (ka > 0) {
          KEYWORD = substr(OLD_STATEMENT , 1 , ka-1)
          OLD_ARGUMENT = substr(OLD_STATEMENT , ka)
        }
        vprint(3,"        keyword |" KEYWORD "|")
        vprint(3,"        old argument |" OLD_ARGUMENT "|")

        # split the original argument on commas
        Tn = split(OLD_ARGUMENT , T , ",")
        vprint(4,"        fields: " Tn)

        # replace each old target with new target
        NEW_ARGUMENT = ""
        for (t = 1 ; t <= Tn ; t++) {
          OLD_TARGET_LNUM = T[t]
          vprint(4,"          old[" t "] |" OLD_TARGET_LNUM "|")

          # if target line# doesn't exist, create a new line# and flag the event
          if (OLD_TARGET_LNUM != "" && NEW_LNUM[OLD_TARGET_LNUM] == "") {
            HIGHEST_NEW_LNUM = HIGHEST_NEW_LNUM + STEP
            NEW_LNUM[OLD_TARGET_LNUM] = HIGHEST_NEW_LNUM
            if (FLAG) FLAG = FLAG ","
            FLAG = FLAG " " HIGHEST_NEW_LNUM " was " OLD_TARGET_LNUM
            eprint(">>> " OLD_LNUM[rn] "->" CURRENT_NEW_LNUM ": Old line# " OLD_TARGET_LNUM " does not exist -> New line# " HIGHEST_NEW_LNUM " also does not exist.")
          }

          vprint(4,"          new[" t "] |" NEW_LNUM[OLD_TARGET_LNUM] "|")
          NEW_ARGUMENT = NEW_ARGUMENT NEW_LNUM[OLD_TARGET_LNUM]
          if (t < Tn) NEW_ARGUMENT = NEW_ARGUMENT ","
        }
        vprint(3,"        new argument |" NEW_ARGUMENT "|")

        NEW_STATEMENT = KEYWORD NEW_ARGUMENT
        vprint(2,"    new statement |" NEW_STATEMENT "|")

        NEW_BODY = NEW_BODY NEW_STATEMENT
        vprint(5,">   new body  |" NEW_BODY "|")

        # advance the scan position to the end of the current statement
        SCAN_POS = SCAN_POS + STATEMENT_POS + STATEMENT_LEN - 1
      }

    # repeat until end of original body
    } while (SCAN_POS < OLD_BODY_LEN)

  # complete new line
  vprint(0,CURRENT_NEW_LNUM NEW_BODY)

  # if a flag was raised while generating the new line, and if STEP leaves room,
  # then write the message in a comment in the next line
  if (FLAG && STEP > 1) vprint(0,CURRENT_NEW_LNUM+1 "'" CURRENT_NEW_LNUM ":" FLAG)

  vprint(1,"")
  }
}

# print if DEBUG level is above specified level
# if DEBUG is 0, add CR
# vprint( minimum_debug_level , string )
function vprint (d,s) {
  if (DEBUG == 0) s = s "\r"
  if (DEBUG >= d) print s
}

function eprint (s) {
  if (DEBUG == 0) print s > "/dev/stderr"
  else print s
}
