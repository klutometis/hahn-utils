@(title "cock-utils")
@(description "Utilities for translating in-source docs to e.g. wiki, latex")
@(author "Peter Danenberg")
@(username "klutometis")
@(email "pcd@roxygen.org")

(module cock-utils
  @("The cock-parse module is responsible for the heavy lifting:
creating docexprs (see below) from documented sources code; the
drivers then write docexprs as e.g. wiki, LaTeX.")
  (parse-files
   tex-write-docexprs
   wiki-write-docexprs
   with-working-directory)
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
       environments
       fmt
       git
       irregex
       lolevel
       matchable
       posix
       regex
       srfi-13
       srfi-69
       srfi-95
       stack
       utils)

  (import-for-syntax matchable)

  (include "cock-parse-core.scm")
  (include "cock-parse-latex.scm")
  (include "cock-parse-wiki.scm"))
