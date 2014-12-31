@(heading "Introduction")

@(text "{{Cock-utils}} is mainly interesting because it provides the {{cock}}
program that takes code documented with [[cock]] and converts
it into documentation.")

@(text "{{Cock-utils}} is a soft-dependency and shouldn't be included
in {{depends}}.")

@(heading "Invocation")

@(text "{{Cock-utils}} is normally invoked from a {{.setup}} file; 
see [[https://wiki.call-cc.org/eggref/4/cock#the-setupfile|this
example]]:")

@(source
  (use cock setup-helper-mod)

  (setup-shared-extension-module
   'landauer
   (extension-version "0.0.1")
   compile-options: '(-X cock))

  (run-cock -o landauer.wiki landauer.scm landauer-core.scm))

@(text "It can also be run from the command line:
  cock -o landauer.wiki landauer.scm landauer-core.scm")

@(text "See {{cock --help}} for details.")

@(heading "Documentation")
@(noop)

(module cock-utils
  @("The cock-parse module is responsible for the heavy lifting:
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

  (include "cock-parse-core.scm")
  (include "cock-parse-latex.scm")
  (include "cock-parse-wiki.scm"))
