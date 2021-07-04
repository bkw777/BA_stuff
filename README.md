# BA stuff

"Model T" BASIC program code manipulators

Process ascii format BASIC code for TRS-80 Model 100 and similar machines.

Written in pure bash, using only built-in features, no external tools like grep, cut, sed, bc, etc... not even backticks or $(...) child bash processes.

See [TPDD_stuff](https://github.com/bkw777/TPDD_stuff) (Makefile) for example use-case.

The "source" version of that program is sector.bas, and has far too many comments and spaces to waste that much space on a Model T.  
But the Makefile generates SECTOR.DO which is packed as small as possible, and that is what you actually run on the Model T.

As you work, moving lines around and using up the available line numbers between existing lines, you periodically run "make renum", and that renumbers the file in-place any time you want.

## barenum

Renumber a BASIC program.

For the time being, options (other than -?|-h|--help|help) are specified by environment variables, and input & output are only via stdin & stdout.

```
[DEBUG=#] [STEP=#] [START=#] [SPACE=true|false] barenum <FILE.DO >NEW.DO

DEBUG=#  0 = runnable output, with CRLF
         1+ = increasingly verbose debugging output, no CRLF

STEP=#   new line numbers increment, default 10

START=#  new line numbers start, default 1*STEP

SPACE=true|false  insert space between keyword & argument

FILE.DO  ascii format TRS-80 Model 100 BASIC program
```

Examples:  
runnable output, default settings  
```barenum <OLD.DO >NEW.DO```

debug output, start output line#'s at 5000, increment by 1  
```DEBUG=5 START=5000 STEP=1 barenum <FILE.DO |less```

Also serves as a line-ending cleaner. Input file may have dos/unix/mixed line-endings,  
output will be all CRLF for the default output, all LF for the debug output.

So you can just edit .DO files conveniently in any editor and ignore the mixed line-endings, and the barenum output will be clean.

## bapack

Pack a BASIC program.

Remove all tabs, spaces, and comments to produce a runnable version that consumes less ram.

The first line is preserved without stripping so that the packed output can still include copyright & credits.

This way you can have a "source" version of a program that has many comments and spaced out structure and is easier to work on and understand,  
and have a Makefile generate a "packed" version that you actually use to run on the "Model T" where 11k of comments and whitespace is out of the question.

Takes no options. Input & output are via stdin & stdout.

```bapack <BIG.DO >SMALL.DO```
