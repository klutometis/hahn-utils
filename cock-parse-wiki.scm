(define (wiki-monospace text)
  #<#EOF
{{#{text}}}
EOF
)

(define (wiki-italics text)
  #<#EOF
'''#{text}'''
EOF
)

(define wiki-link
  (case-lambda
   ((link) (wiki-link link #f))
   ((link text)
  #<#EOF
[[#{link}#(if text (format "|~a" text) "")]]
EOF
)))

(define (wiki-title title)
  #<#EOF
== #{title}

EOF
)

(define (wiki-subtitle title)
  #<#EOF
=== #{title}

EOF
)

(define (wiki-subsubtitle title)
  #<#EOF
==== #{title}

EOF
)

(define (wiki-subsubsubtitle title)
  #<#EOF
===== #{title}

EOF
)

(define (wiki-source source)
  #<#EOF
<enscript highlight="scheme">#{source}</enscript>

EOF
)

(define (wiki-procedure signature to)
  #<#EOF
<procedure>#{signature} → #{to}</procedure>
EOF
)

(define (wiki-syntax signature to)
  #<#EOF
<syntax>#{signature} → #{to}</syntax>
EOF
)

(define (wiki-read signature to)
  #<#EOF
<read>#{signature} → #{to}</read>
EOF
)

(define (wiki-record type)
  #<#EOF
<record>#{type}</record>
EOF
)

(define (wiki-module name)
  #<#EOF
#(wiki-italics "[module]") #(wiki-monospace name)

EOF
)

(define (wiki-export export)
  #<#EOF
* #(wiki-link (format "#~a" export))
EOF
)

;;; What happens with colons in the definition?
(define (wiki-parameter parameter definition)
  #<#EOF
; #(wiki-monospace parameter) : #{definition}
EOF
)

;; Made these into a strings, because the brackets throw off paredit.
(define (wiki-preamble title description)
  #<#EOF
#(wiki-title title)
#{description}
#(wiki-link "toc:")

EOF
)

;;; TODO: This is extremely github-specific.
(define (tag-or-release repository tag)
  (if repository
      (wiki-link
       (format "~a/releases/tag/~a" repository tag)
       tag)
      tag))

(define (wiki-postamble author
                        username
                        license
                        repository
                        dependencies
                        versions)
  #<#EOF
#(wiki-subtitle "About this egg")
#(wiki-subsubtitle "Author")
#(wiki-link (format "/users/~a" username) author)
#(if repository
     (string-append
      (wiki-subsubtitle "Repository")
      (wiki-link repository))
     "")
#(if license
     (string-append
      (wiki-subsubtitle "License")
      license)
     "")
#(if (null? dependencies)
     ""
     (string-append
      (wiki-subsubtitle "Dependencies")
      (string-join
       (map (lambda (dependency)
              (format "~a~%" (wiki-link dependency)))
            dependencies)
       "* "
       'prefix)))
#(if (null? versions)
     ""
     (string-append
      (wiki-subsubtitle "Versions")
      (string-join
       (map (match-lambda ((tag . message)
                      (format "; ~a : ~a"
                              (tag-or-release repository tag)
                              (string-trim-both message))))
            versions)
       "\n")))
#(wiki-subsubtitle "Colophon")
Documented by #(wiki-link "/egg/cock" "cock").
EOF
)

(define (wiki-parameter-object name init)
  #<#EOF
<parameter>#{name} → #{init}</parameter>
EOF
)

(define (wiki-scalar name definition)
  #<#EOF
<constant>#{name} → #{definition}</constant>
EOF
)

;;; Needs to be generalized.
(define (wiki-parse-directive doc expr data document)
  (let ((directive (car doc))
        (arguments (cdr doc))
        (data (document-data document)))
    (case directive
      ((email)
       (hash-table-set! data 'email (car arguments))
       void)
      ((username)
       (hash-table-set! data 'username (car arguments))
       void)
      ((author)
       (hash-table-set! data 'author (car arguments))
       void)
      ((title)
       (hash-table-set! data 'title (car arguments))
       void)
      ((egg)
       (hash-table-set! data 'egg (car arguments))
       void)
      ((description)
       (hash-table-set! data 'description (car arguments))
       void)
      ((example)
       (lambda () (write-example data (car arguments) (cdr arguments))))
      ((example-no-eval)
       (lambda () (write-example-no-eval data (car arguments) (cdr arguments))))
      ((source)
       (lambda () (write-wiki-source (car arguments))))
      ((heading)
       (let ((title (car arguments)))
         (lambda ()
           (hash-table-set! data 'heading-level 1)
           (display (wiki-subtitle title)))))
      ;; Should we pop the expression stack at this point? Maybe,
      ;; maybe not. @noop-and-pop? Jesus.
      ((noop) void)
      ((subheading)
       (let ((title (car arguments)))
         (lambda ()
           (hash-table-set! data 'heading-level 2)
           (display (wiki-subsubtitle title)))))
      ;; Shit: we're supporting a different language than LaTeX; TODO:
      ;; intermediate S-expressions over pre-post-order!
      ((subsubheading)
       (let ((title (car arguments)))
         (lambda ()
           (hash-table-set! data 'heading-level 3)
           (display (wiki-subsubsubtitle title)))))
      ;; This is where me might to some fancy-schmancy
      ;; markdown-to-wiki bullshit; maybe we can support a subset? I
      ;; really just want monospace and links.
      ((text)
       (let ((text (string-join arguments "\n\n" 'suffix)))
         (lambda ()
           (display text)
           (newline))))
      (else
       (lambda () (warning "Unknown directive" directive))))))

(define (wiki-make-heading heading-level)
  (match heading-level
    (0 wiki-subtitle)
    (1 wiki-subsubtitle)
    (_ wiki-subsubsubtitle)))

(define wiki-make-current-heading
  (case-lambda
   ((data)
    (wiki-make-current-heading data 0))
   ((data offset)
    (wiki-make-heading
     (+ (hash-table-ref/default data 'heading-level 0) offset)))))

(define (wiki-make-description descriptions)
  (string-join descriptions "\n\n"))

(define (write-example data description expressions)
  @("Renders an example, evaluating the expressions; attempts
to {{require-extension}} all modules seen so far.")
  (display description)
  (newline)
  (let ((env (interaction-environment))
        (egg (hash-table-ref/default data 'egg #f))
        (modules (hash-table-ref/default data 'modules '())))
    (for-each (lambda (module)
                (eval `(require-extension ,module) env))
      modules)
    (for-each (lambda (expression)
                (fmt #t (columnar " " (with-width 78 (pretty expression))))
                (fmt #t (columnar "  => " (with-width 74 (pretty (eval expression env))))
                     " " nl)
                )
      expressions)))

(define (write-example-no-eval data description expressions)
  (display description)
  (newline)
  (for-each (lambda (expression)
              (fmt #t (columnar " " (with-width 78 (pretty expression)))))
    expressions))

(define (write-wiki-source expression)
  (display (wiki-source (with-output-to-string (lambda () (pp expression))))))

(define (write-wiki-block doc
                          expr
                          data
                          name
                          item
                          . rest-items)
  (receive (normal-parameters special-parameters)
    (doc-normal-and-special-parameters doc)
    (unless (internal? special-parameters)
      (let ((heading (wiki-make-current-heading data))
            (description (wiki-make-description (doc-descriptions doc))))
        (display (heading (wiki-monospace name)))
        (display (string-join (cons item (cons description rest-items)) "\n" 'suffix))
        (when (write-source?)
          (unless (no-source? special-parameters)
            (write-wiki-source expr)))
        (let ((examples (examples special-parameters))
              (examples-no-eval (examples-no-eval special-parameters)))
          (unless (and (null? examples) (null? examples-no-eval))
            (let ((heading (wiki-make-current-heading data 1)))
              (display (heading "Examples"))
              (for-each (lambda (example)
                          (write-example
                           data
                           (example-description example)
                           (example-expressions example)))
                examples)
              (for-each (lambda (example-no-eval)
                          (write-example-no-eval
                           data
                           (example-description example-no-eval)
                           (example-expressions example-no-eval)))
                examples-no-eval))))))))

;;; Generalize this.
(define (make-wiki-procedure template name formals to)
  (template (cons name formals) (string-join to ", ")))

(define (purge-newlines string)
  (irregex-replace/all "\n" string " "))

(define (make-wiki-parameters parameters)
  (let ((parameters
         (map
          (match-lambda ((parameter definition)
                    (wiki-parameter parameter (purge-newlines definition))))
          parameters)))
    (string-join parameters "\n")))

(define (wiki-parse-procedure doc expr data name formals)
  (receive (normal-parameters special-parameters)
    (doc-normal-and-special-parameters doc)
    (let ((to (procedure-to special-parameters)))
      (let ((procedure
             (make-wiki-procedure wiki-procedure name formals to))
            (parameters
             (make-wiki-parameters normal-parameters)))
        (lambda ()
          (write-wiki-block doc
                            expr
                            data
                            name
                            procedure
                            parameters))))))

(define (wiki-parse-case-lambda doc expr data name formals+)
  (receive (normal-parameters special-parameters)
    (doc-normal-and-special-parameters doc)
    (let ((to (procedure-to special-parameters)))
      (let ((procedures
             (string-join
              (map (lambda (formals)
                     (make-wiki-procedure
                      wiki-procedure
                      name
                      formals
                      to))
                   formals+)
              "\n"))
            (parameters
             (make-wiki-parameters normal-parameters)))
        (lambda ()
          (write-wiki-block
           doc
           expr
           data
           name
           procedures
           parameters))))))

(define (wiki-parse-parameter doc expr data name init)
  (let ((parameter (wiki-parameter-object name init)))
    (thunk (write-wiki-block
            doc
            expr
            data
            name
            parameter))))

(define (wiki-parse-scalar doc expr data name)
  (receive (normal-parameters special-parameters)
    (doc-normal-and-special-parameters doc)
    (if (scalar-procedure? normal-parameters special-parameters)
        (wiki-parse-procedure doc
                              expr
                              data
                              name
                              (map car normal-parameters))
        (let* ((definition (last expr))
               (scalar (wiki-scalar name definition)))
          (thunk (write-wiki-block doc
                                   expr
                                   data
                                   name
                                   scalar))))))

(define (wiki-parse-syntax doc expr data name)
  (receive (normal-parameters special-parameters)
    (doc-normal-and-special-parameters doc)
    (let ((to (procedure-to special-parameters)))
      (let ((syntax (make-wiki-procedure wiki-syntax
                                         name
                                         (formals normal-parameters)
                                         to))
            (parameters (make-wiki-parameters normal-parameters)))
        (thunk (write-wiki-block doc
                                 expr
                                 data
                                 name
                                 syntax
                                 parameters))))))

(define (wiki-parse-read doc expr data char)
  (receive (normal-parameters special-parameters)
    (doc-normal-and-special-parameters doc)
    (let* ((to (procedure-to special-parameters))
           (read (wiki-read char (string-join to ", "))))
      (let ((parameters (make-wiki-parameters normal-parameters)))
        (thunk (write-wiki-block doc
                                 expr
                                 data
                                 char
                                 read
                                 parameters))))))

(define (wiki-parse-record doc expr data type)
  (receive (normal-parameters special-parameters)
    (doc-normal-and-special-parameters doc)
    (let ((record (wiki-record type))
          (fields (make-wiki-parameters normal-parameters)))
      (thunk (write-wiki-block doc
                               expr
                               data
                               type
                               record
                               fields)))))

(define (make-wiki-exports exports)
  (string-join (map wiki-export exports) "\n"))

(define (wiki-parse-module doc expr data name exports)
  (let ((module (wiki-module name))
        (exports (make-wiki-exports exports)))
    (thunk (parameterize ((write-source? #f))
             (write-wiki-block doc
                               expr
                               data
                               name
                               module
                               exports)))))

(define (wiki-parse-docexpr document docexpr)
  (parameterize ((parse-directive wiki-parse-directive)
                 (parse-procedure wiki-parse-procedure)
                 (parse-case-lambda wiki-parse-case-lambda)
                 (parse-parameter wiki-parse-parameter)
                 (parse-scalar wiki-parse-scalar)
                 (parse-syntax wiki-parse-syntax)
                 (parse-read wiki-parse-read)
                 (parse-record wiki-parse-record)
                 (parse-module wiki-parse-module))
    (parse-docexpr document docexpr)))

;;; Needs to be generalized.
(define (wiki-parse-docexprs document docexprs)
  (let ((parsed-docexprs (make-stack)))
    (stack-for-each
     docexprs
     (lambda (docexpr)
       (stack-push! parsed-docexprs
                    (wiki-parse-docexpr document docexpr))))
    parsed-docexprs))

;;; Needs to be generalized.
(define wiki-write-docexprs
  @("Write the source-derived docexprs as svnwiki."
    (docexprs "The parsed docexprs"))
  (case-lambda
   ((docexprs) (wiki-write-docexprs docexprs #f))
   ((docexprs metafile) (wiki-write-docexprs docexprs #f #f))
   ((docexprs metafile repo)
    (let* ((document (make-document (make-hash-table) (make-stack)))
           (parsed-docexprs (wiki-parse-docexprs document docexprs)))
      (let ((data (hash-table-merge
                   (hash-table-merge (document-data document)
                                     (parse-metafile metafile))
                   (repo-metadata repo))))
        (let ((author
               (hash-table-ref/default data 'author (default-author)))
              (username
               (or
                (hash-table-ref/default data 'username #f)
                (hash-table-ref/default data 'user #f)
                (default-user)))
              (email
               (hash-table-ref/default data 'email (default-email)))
              (repository
               (or
                (hash-table-ref/default data 'repository #f)
                (hash-table-ref/default data 'repo #f)))
              (title
               (let ((title (hash-table-ref/default data 'title #f))
                     (egg (hash-table-ref/default data 'egg #f)))
                 (or title egg (default-title))))
              (description
               (or (hash-table-ref/default data 'description #f)
                   (hash-table-ref/default data 'synopsis #f)
                   (default-synopsis)))
              (dependencies
               (or (hash-table-ref/default data 'depends #f)
                   (hash-table-ref/default data 'needs #f)
                   '()))
              (license
               (hash-table-ref/default data 'license #f))
              (versions
               (hash-table-ref/default data 'versions '())))
          (display (wiki-preamble title description))
          (stack-for-each parsed-docexprs (lambda (docexpr) (docexpr)))
          (display (wiki-postamble author
                                   username
                                   license
                                   repository
                                   dependencies
                                   versions))))))))
