;; Autogenerate a list of Scheme keywords (i.e., macros) and built-in
;; functions. This is written for the Guile implementation. The
;; principle of autogenerating this has the advantage of catching many
;; builtins that would be tedious to maintain by hand, and the
;; disadvantage that some builtins very specific to Guile and not
;; relevant to other implementations are caught as well. However,
;; since Scheme builtin function names tend to be rather specific,
;; this should not be a significant problem.

(define port (open-output-file "../pygments/lexers/_scheme_builtins.py"))

(display
   "\"\"\"
    pygments.lexers._scheme_builtins
    ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~

    Scheme builtins.

    :copyright: Copyright 2006-2022 by the Pygments team, see AUTHORS.
    :license: BSD, see LICENSE for details.
\"\"\"
"
   port)

(format port
"\n# Autogenerated by external/scheme-builtins-generator.scm\n\
# using Guile ~a.\n\n"
        (version))

(use-modules (srfi srfi-1)
             (ice-9 match))

(define relevant-modules
  ;; This is a nightmare. Scheme builtins are split in
  ;; gazillions of standards, SRFIs and implementation
  ;; extensions. With so many sources, it's hard to define
  ;; what is really a Scheme builtin. This is a rather
  ;; conservative list of Guile modules that might be used
  ;; the most frequently (somewhat subjective, admittedly).
  '(
    ;; The real builtins.
    (guile)
    ;; Let's include the fundamental list library.
    (srfi srfi-1)
    ;; define-record-type
    (srfi srfi-9)
    ;; let-values, let*-values
    (srfi srfi-11)
    ;; case-lambda
    (srfi srfi-16)
    ;; Pattern matching
    (ice-9 match)
    ;; Included for compatibility with files written for R5RS
    (rnrs r5rs)))

(define (get-all-bindings module)
  ;; Need to recurse to find all public bindings. module-map
  ;; only considers the module's own bindings.
  (let* ((own (module-map cons module))
        (uses (module-uses module)))
    (append own (append-map get-all-bindings uses))))

(define all-bindings
  (append-map
   ;; Need to use module-public-interface to restrict to
   ;; public bindings.  Note that module-uses already
   ;; returns public interfaces.
   (lambda (mod-path)
     (let* ((mod-object (resolve-module mod-path))
            (iface (module-public-interface mod-object)))
       (get-all-bindings iface)))
   relevant-modules))

(define (filter-for pred)
  (filter-map
   (match-lambda
    ((key . variable)
      (and (variable-bound? variable)
           (let ((value (variable-ref variable)))
             (and (pred value)
                  key)))))
   all-bindings))

(define (sort-and-uniq lst pred)
  (let loop ((lst (sort lst pred))
             (acc '()))
    (match lst
     (() (reverse! acc))
     ((one . rest)
      (loop (drop-while (lambda (elt)
                          (equal? elt one))
                        rest)
            (cons one acc))))))

(define (dump-py-list lst)
  (string-join
   (map
    (lambda (name)
      (format #f "    \"~a\"," name))
    (sort-and-uniq
     (map symbol->string lst)
     string<?))
   "\n"))

(define (dump-builtins name pred extra)
  (format port
          "~a = {\n~a\n}\n\n"
          name
          (dump-py-list (append extra (filter-for pred)))))

(define extra-procedures
  ;; These are found in RnRS but not implemented by Guile.
 '(load transcript-off transcript-on))

(dump-builtins 'scheme_keywords macro? '())
(dump-builtins 'scheme_builtins procedure? extra-procedures)