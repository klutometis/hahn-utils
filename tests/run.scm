(cond-expand
  (chicken-4
   (use hahn
      hahn-utils
      files
      ports
      test))
  (chicken-5
   (import hahn hahn-utils chicken.file chicken.port test)))

(define (with-output-to-temporary-file thunk)
  @("Outputs to a temporary file and returns that file."
    (thunk "A thunk that outputs")
    (@to "string"))
  (let ((file (create-temporary-file)))
    (with-output-to-file file thunk)
    file))

;; This is a hack; but because it relies on reader-macros, &c., need
;; to write the string to a file and parse it using parse-files.
(define (parse-and-write-fragment-as-string expression)
  (let ((file (with-output-to-temporary-file
               (lambda ()
                 (write expression))))) 
    (with-output-to-string
      (lambda ()
        (wiki-write-docexprs (parse-files file) #f #f #t)))))

(test-assert (version<=? "0.1" "0.3.4"))
(test-assert (not (version<=? "0.3.4" "0.1")))
(test-assert (version<=? "0.0.2" "0.1.1"))
(test-assert (not (version<=?  "0.1.1" "0.0.2")))
(test-assert (version<=? "1.2.3" "1.2.4"))
(test-assert (not (version<=? "1.2.4" "1.2.3")))
(test-assert (version<=? "1.2" "1.2.4"))
(test-assert (not (version<=? "1.2.4" "1.2")))
(test-assert (version<=? "1.2.3" "1.2.10"))
(test-assert (not (version<=? "1.2.10" "1.2.3")))

(test
 "=== {{k}}
<constant>k → 1.38e-23</constant>
The Boltzmann constant
<enscript highlight=\"scheme\">(define k 1.38e-23)
</enscript>
"
 (parse-and-write-fragment-as-string
  `(define k ,at("The Boltzmann constant") 1.38e-23)))

(test
 "=== {{+}}
<procedure>(+ x y) → return</procedure>
Description

Long description
; {{x}} : x
; {{y}} : y
<enscript highlight=\"scheme\">(define (+ x y) (- x (- y)))
</enscript>
==== Examples
Using +
 (+ 1 2)
  => 3
 
"
 (parse-and-write-fragment-as-string
  `(define (+ x y)
     ,at("Description"
         "Long description"
         (x "x")
         (y "y")
         (@to "return")
         (@example "Using +" (+ 1 2)))
     (- x (- y)))))

(test
 "=== {{module}}
'''[module]''' {{module}}

Description

Long description
* [[#export-a]]
* [[#export-b]]
"
 (parse-and-write-fragment-as-string
  `(module module
     ,at("Description"
         "Long description")
     (export-a export-b)
     (import scheme))))

(test
 "Warning: this should never terminate.
 (find-fermat-counterexample)
"
 (parse-and-write-fragment-as-string
  `(,at(example-no-eval "Warning: this should never terminate."
                        (find-fermat-counterexample)))))

(test
 "Top-level source with multiple expressions"
 "<enscript highlight=\"scheme\">(first-expression)
(second-expression)
</enscript>
"
 (parse-and-write-fragment-as-string
  `(,at(source (first-expression) (second-expression)))))
