(define current-docexpr
  @("Enables communication with the parsing @-reader")
  (make-parameter #f))

(define docexprs (make-parameter (make-stack)))

(define-syntax thunk
  (lambda (expression rename compare)
    (let ((body (cdr expression))
          (%lambda (rename 'lambda)))
      `(,%lambda () ,@body))))

(define-record-and-printer null-expression)
(define null-expression (make-null-expression))

(define (prepend-@ symbol)
  (string->symbol
   (string-append "@" (symbol->string symbol))))

(set-read-syntax! #\@
  (lambda (in)
    (let ((expression (read in)))
      (cond ((symbol? expression)
             (prepend-@ expression))
            ((pair? expression)
             (current-docexpr expression)
             (stack-push! (docexprs)
                          (make-docexpr (current-docexpr)
                                        null-expression))
             (values))
            (else expression)))))

(define-record-and-printer docexpr
  @("Composite documentation and adherent expression"
    (doc "Documentation for the expression")
    (expr "Expression surrounding the documentation"))
  doc
  expr)

(define (parse-noop . args) (lambda () void))

;;; Because it's apparent that latex and wiki share a lot of code,
;;; these should actually do something.
(define parse-directive (make-parameter parse-noop))

(define parse-procedure (make-parameter parse-noop))

(define parse-scalar (make-parameter parse-noop))

(define parse-parameter (make-parameter parse-noop))

(define parse-case-lambda (make-parameter parse-noop))

(define parse-syntax (make-parameter parse-noop))

(define parse-read (make-parameter parse-noop))

(define parse-record (make-parameter parse-noop))

(define parse-module (make-parameter parse-noop))

;;; Somehow, we have to process these preamble-directives before we
;;; spit the document out; could it be that we have to keep the thing
;;; in memory before we spit it out?
;;;
;;; The document has some header fields and a list of docexprs: thus,
;;; we can process the docexprs in order, pushing to the section
;;; stack; &c.
;;;
;;; Should we say, more formally, that directives are things which
;;; work on the document; and have first-class support for things like
;;; sections?
;;;
;;; Sections, &c. could work, I suppose, by pushing something unto the
;;; docexprs stack.
;;;
;;; It's a shame, though, that the document-fields are fixed; and that
;;; directives don't have the ability to put arbitrary data in there.
;;; Why not add a hash-table called data?
;;;
;;; The idea is that the renderers check for some kind of field in the
;;; hash-table, supplying a reasonable default.
;;;
;;; It's a shame, though, that we have to special case so-called
;;; directives; can every parsed docexpr work on the document?
;;;
;;; Non-directive docexprs would have to push themselves on the
;;; docexpr-stack, though.
;;;
;;; Why not push every docexpr on the stack and convert the directives
;;; into no-ops? Bingo.
;;;
;;; docexprs are lambdas: at construction time, they take a document they
;;; can modify. At invocation time, they write something.
;;;
;;; If we were to support more than latex, though, how would they know
;;; to dispatch? Do we need an e.g. write-docexpr-as-{html,latex},
;;; such that we need to maintain the types?
;;;
;;; If I go with the dispatch-on-type, though, I have to come up with
;;; types for e.g. headings and subheading; which is a pain in the
;;; ass. Oh, for pure lambdas!
(define-record-and-printer document
  data
  docexprs)

(define (parse-docexpr document docexpr)
  (let ((doc (docexpr-doc docexpr))
        (expr (docexpr-expr docexpr))
        (data (document-data document)))
    (match expr
      ((? null-expression?)
       ((parse-directive) doc expr data document))
      ((or ('define (procedure . formals) . body)
           ('define procedure ('lambda formals . body)))
       ((parse-procedure) doc expr data procedure formals))
      (('define procedure ((or 'foreign-lambda
                               'foreign-safe-lambda)
                           ret name . formals))
       ((parse-procedure) doc expr data procedure formals ret))
      (('define procedure ((or 'foreign-lambda*
                               'foreign-safe-lambda*
                               'foreign-primitive)
                           ret formals . body))
       ((parse-procedure) doc expr data procedure (map cadr formals) ret))
      (('define procedure ('case-lambda (formals . body) ...))
       ((parse-case-lambda) doc expr data procedure formals))
      (('define parameter ('make-parameter init . converter))
       ((parse-parameter) doc expr data parameter init))
      (('define scalar . body)
       ((parse-scalar) doc expr data scalar))
      (('define-syntax name . _)
       ((parse-syntax) doc expr data name))
      ((or ('set-read-syntax! char-or-symbol proc)
           ('set-sharp-read-syntax! char-or-symbol proc)
           ('set-parameterized-read-syntax! char-or-symbol proc))
       ((parse-read) doc expr data char-or-symbol))
      ((or ('define-record-and-printer type . fields)
           ('define-record-type type . fields)
           ('define-record type . fields)
           ('defstruct type . fields))
       ((parse-record) doc expr data type))
      (('module module exports . body)
       ((parse-module) doc expr data module exports)) 
      ;; Here's where we might make the thing extensible; or maybe
      ;; initially, to give people the opportunity to override the
      ;; above?
      ;;
      ;; Don't know what the fuck this is: let's treat it like a
      ;; directive, for the time being.
      (_ ((parse-directive) doc null-expression data document)))))

(define substitute-template
  (case-lambda
   ((template key substitution)
    (substitute-template template `((,key . ,substitution))))
   ((template substitutions)
    (string-substitute*
     template
     (map
      (match-lambda ((key . value)
                (cons
                 (format "@~a@" (string-upcase (symbol->string key)))
                 (->string value))))
      substitutions)
     #f)))) 

(define (write-template . keys-or-substitutions)
  (display (apply substitute-template keys-or-substitutions)))

(define special-parameters
  (list (string->symbol "@example")
        (string->symbol "@example-no-eval")
        (string->symbol "@internal")
        (string->symbol "@no-source")
        (string->symbol "@to")
        (string->symbol "@args")))

(define (special-parameter? parameter)
  (memq parameter special-parameters))

(define normal-parameter? (complement special-parameter?))

(define (doc-descriptions doc)
  (filter string? doc))

(define (doc-normal-and-special-parameters doc)
  (let ((parameters (filter pair? doc)))
    (let ((normal-parameters
           (filter (compose normal-parameter? car) parameters))
          (special-parameters
           (filter (compose special-parameter? car) parameters)))
      (values normal-parameters special-parameters))))

;;; Generalize this.
(define (procedure-to special-parameters #!optional foreign-ret)
  (alist-ref/default special-parameters
                     (string->symbol "@to")
                     (or (and foreign-ret
                              (list (symbol->string foreign-ret)))
                         '("unspecified"))))

(define (procedure-args special-parameters formals)
  (alist-ref/default special-parameters
                     (string->symbol "@args")
                     formals))

(define example-description car)

(define example-expressions cdr)

(define (examples special-parameters)
  (map cdr
       (filter (lambda (parameter)
                 (eq? (car parameter) (string->symbol "@example")))
               special-parameters)))

(define (examples-no-eval special-parameters)
  (map cdr
       (filter (lambda (parameter)
                 (eq? (car parameter) (string->symbol "@example-no-eval")))
               special-parameters)))

(define (internal? special-parameters)
  (any (lambda (parameter)
         (eq? (car parameter) (string->symbol "@internal")))
       special-parameters))

(define (no-source? special-parameters)
  (any (lambda (parameter)
         (eq? (car parameter) (string->symbol "@no-source")))
       special-parameters))

(define (scalar-procedure? normal-parameters special-parameters)
  (or (not (null? normal-parameters))
      (alist-ref/default special-parameters
                         (string->symbol "@to")
                         #f)))

(define (formals parameters) (map car parameters))

(define write-source? (make-parameter #t))

;;; Shouldn't we let the caller pass in its own docexprs?
(define (parse-files . files)
  @("Parse files into docexprs."
    (files "Hahn-documented files to be parsed")
    (@to "Resultant docexprs"))
  (parameterize ((docexprs (make-stack)))
    (for-each
        (lambda (file)
          (with-input-from-file file
            (lambda ()
              (let read-next ((expression (read)))
                (if (not (eof-object? expression))
                    (begin
                      (if (current-docexpr)
                          (docexpr-expr-set! (stack-peek (docexprs)) expression))
                      (current-docexpr #f)
                      (read-next (read))))))))
      files)
    (docexprs)))

(define default-author (make-parameter '("Anonymous")))
(define default-category (make-parameter '("uncategorized")))
(define default-email (make-parameter '("anonymous@example.com")))
(define default-synopsis (make-parameter '("Egg synopsis")))
(define default-title (make-parameter #f))
(define default-user (make-parameter '("anonymous")))

(define (find-metafile)
  (and-let* ((metafiles (glob "*.meta"))
             ((pair? metafiles))
             (metafile (car metafiles)))
    metafile))

;;; Strong assumptions here about the nature of a version: a.b.....z.
(define (version<=? x y)
  (let iter ((xs (map string->number (string-tokenize x char-set:digit)))
             (ys (map string->number (string-tokenize y char-set:digit))))
    (cond ((null? xs) #t)
          ((null? ys) #f)
          (else
           (let ((x (car xs)) (y (car ys)))
             (cond ((< x y) #t)
                   ((> x y) #f)
                   (else (iter (cdr xs) (cdr ys)))))))))

(define (repo-metadata repo)
  (let ((metadata (make-hash-table))
        (repo (or repo ".git")))
    ;; We have to check for directory-existence here; libgit2 seems to
    ;; segfault when the directory doesn't exist on repository-open.
    (when (directory-exists? repo)
      (let* ((repo (repository-open repo))
             (tags (tags repo)))
        (hash-table-set! metadata
                         'versions
                         (sort
                          (map (lambda (tag) (cons (tag-name tag)
                                              (tag-message tag)))
                               tags)
                          version<=?
                          car))))
    metadata))

(define parse-metafile
  (case-lambda
   (() (parse-metafile (find-metafile)))
   ((metafile)
    (let ((metafile (or metafile (find-metafile)))
          (metadata (make-hash-table)))
      (when metafile
        (and-let* ((egg-match
                    (irregex-match
                     '(: (=> egg-name (* any)) ".meta")
                     metafile))
                   (egg-name
                    (irregex-match-substring
                     egg-match
                     'egg-name)))
          (hash-table-set! metadata 'egg egg-name)
          (let ((egg-data (with-input-from-file metafile read)))
            (for-each (match-lambda ((key . rest)
                                ;; If it's a one-member list that contains a
                                ;; string, let's call it a string.
                                ;; This doesn't work for e.g. category.
                                (if (and (= (length rest) 1)
                                         (or (eq? key 'category)
                                             (string? (car rest))))
                                    (hash-table-set! metadata key (car rest))
                                    (hash-table-set! metadata key rest))))
              egg-data)))) 
      metadata))))

(define (with-working-directory directory thunk)
  @("Change to the {{directory}}, execute {{thunk}}, change back;
returns the value of executing {{thunk}}."
    (directory "The directory to switch to")
    (thunk "The thunk to execute")
    (@to "object"))
  (let ((original-directory (current-directory)))
    (dynamic-wind (lambda () (current-directory directory))
        thunk
        (lambda () (current-directory original-directory)))))
