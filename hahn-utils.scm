@(heading "Introduction")

@(text "{{Hahn-utils}} is mainly interesting because it provides the {{hahn}}
program that takes code documented with [[hahn]] and converts
it into documentation.")

@(text "{{Hahn-utils}} is a soft-dependency and shouldn't be included
in {{depends}}.")

@(heading "Invocation")

@(text "{{Hahn-utils}} is normally invoked from a {{.setup}} file; 
see [[https://wiki.call-cc.org/eggref/4/hahn#the-setupfile|this
example]]:")

@(source
  (use hahn setup-helper-mod)

  (setup-shared-extension-module
   'landauer
   (extension-version "0.0.1")
   compile-options: '(-X hahn))

  (run-hahn -o landauer.wiki landauer.scm landauer-core.scm))

@(text "It can also be run from the command line:
  hahn -o landauer.wiki landauer.scm landauer-core.scm")

@(text "See {{hahn --help}} for details.")

@(heading "Documentation")
@(noop)

(module hahn-utils
  @("The hahn-parse module is responsible for the heavy lifting:
creating docexprs (see below) from documented sources code; the
drivers then write docexprs as e.g. wiki, LaTeX.")
  (parse-files
   tex-write-docexprs
   wiki-write-docexprs
   with-working-directory
   version<=?) 
  (import chicken
          data-structures
          extras
          ports
          scheme
          srfi-1
          stack)
  (use alist-lib
       debug
       define-record-and-printer
       fmt
       git
       irregex
       lolevel
       matchable
       posix
       regex
       srfi-13
       srfi-14
       srfi-69
       srfi-95
       stack
       utils)

  (import-for-syntax matchable)

  (include "hahn-parse-core.scm")
  (include "hahn-parse-latex.scm")
  (include "hahn-parse-wiki.scm"))
