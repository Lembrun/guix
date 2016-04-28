;;; GNU Guix --- Functional package management for GNU
;;; Copyright © 2014, 2016 Ludovic Courtès <ludo@gnu.org>
;;;
;;; This file is part of GNU Guix.
;;;
;;; GNU Guix is free software; you can redistribute it and/or modify it
;;; under the terms of the GNU General Public License as published by
;;; the Free Software Foundation; either version 3 of the License, or (at
;;; your option) any later version.
;;;
;;; GNU Guix is distributed in the hope that it will be useful, but
;;; WITHOUT ANY WARRANTY; without even the implied warranty of
;;; MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
;;; GNU General Public License for more details.
;;;
;;; You should have received a copy of the GNU General Public License
;;; along with GNU Guix.  If not, see <http://www.gnu.org/licenses/>.

(define-module (gnu build linux-modules)
  #:use-module (guix elf)
  #:use-module (rnrs io ports)
  #:use-module (rnrs bytevectors)
  #:use-module (srfi srfi-1)
  #:use-module (srfi srfi-26)
  #:use-module (ice-9 vlist)
  #:use-module (ice-9 match)
  #:export (dot-ko
            ensure-dot-ko
            module-dependencies
            recursive-module-dependencies
            modules-loaded
            module-loaded?
            load-linux-module*

            current-module-debugging-port))

;;; Commentary:
;;;
;;; Tools to deal with Linux kernel modules.
;;;
;;; Code:

(define current-module-debugging-port
  (make-parameter (%make-void-port "w")))

(define (section-contents elf section)
  "Return the contents of SECTION in ELF as a bytevector."
  (let* ((modinfo  (elf-section-by-name elf ".modinfo"))
         (contents (make-bytevector (elf-section-size modinfo))))
    (bytevector-copy! (elf-bytes elf) (elf-section-offset modinfo)
                      contents 0
                      (elf-section-size modinfo))
    contents))

(define %not-nul
  (char-set-complement (char-set #\nul)))

(define (nul-separated-string->list str)
  "Split STR at occurrences of the NUL character and return the resulting
string list."
  (string-tokenize str %not-nul))

(define (key=value->pair str)
  "Assuming STR has the form \"KEY=VALUE\", return a pair like (KEY
. \"VALUE\")."
  (let ((= (string-index str #\=)))
    (cons (string->symbol (string-take str =))
          (string-drop str (+ 1 =)))))

(define (modinfo-section-contents file)
  "Return the contents of the '.modinfo' section of FILE as a list of
key/value pairs.."
  (let* ((bv      (call-with-input-file file get-bytevector-all))
         (elf     (parse-elf bv))
         (modinfo (section-contents elf ".modinfo")))
    (map key=value->pair
         (nul-separated-string->list (utf8->string modinfo)))))

(define %not-comma
  (char-set-complement (char-set #\,)))

(define (module-dependencies file)
  "Return the list of modules that FILE depends on.  The returned list
contains module names, not actual file names."
  (let ((info (modinfo-section-contents file)))
    (match (assq 'depends info)
      (('depends . what)
       (string-tokenize what %not-comma)))))

(define dot-ko
  (cut string-append <> ".ko"))

(define (ensure-dot-ko name)
  "Return NAME with a '.ko' prefix appended, unless it already has it."
  (if (string-suffix? ".ko" name)
      name
      (dot-ko name)))

(define (normalize-module-name module)
  "Return the \"canonical\" name for MODULE, replacing hyphens with
underscores."
  ;; See 'modname_normalize' in libkmod.
  (string-map (lambda (chr)
                (case chr
                  ((#\-) #\_)
                  (else chr)))
              module))

(define (file-name->module-name file)
  "Return the module name corresponding to FILE, stripping the trailing '.ko'
and normalizing it."
  (normalize-module-name (basename file ".ko")))

(define* (recursive-module-dependencies files
                                        #:key (lookup-module dot-ko))
  "Return the topologically-sorted list of file names of the modules depended
on by FILES, recursively.  File names of modules are determined by applying
LOOKUP-MODULE to the module name."
  (let loop ((files   files)
             (result  '())
             (visited vlist-null))
    (match files
      (()
       (delete-duplicates (reverse result)))
      ((head . tail)
       (let* ((visited? (vhash-assoc head visited))
              (deps     (if visited?
                            '()
                            (map lookup-module (module-dependencies head))))
              (visited  (if visited?
                            visited
                            (vhash-cons head #t visited))))
         (loop (append deps tail)
               (append result deps) visited))))))

(define %not-newline
  (char-set-complement (char-set #\newline)))

(define (modules-loaded)
  "Return the list of names of currently loaded Linux modules."
  (let* ((contents (call-with-input-file "/proc/modules"
                     get-string-all))
         (lines    (string-tokenize contents %not-newline)))
    (match (map string-tokenize lines)
      (((modules . _) ...)
       modules))))

(define (module-black-list)
  "Return the black list of modules that must not be loaded.  This black list
is specified using 'modprobe.blacklist=MODULE1,MODULE2,...' on the kernel
command line; it is honored by libkmod for users that pass
'KMOD_PROBE_APPLY_BLACKLIST', which includes 'modprobe --use-blacklist' and
udev."
  (define parameter
    "modprobe.blacklist=")

  (let ((command (call-with-input-file "/proc/cmdline"
                   get-string-all)))
    (append-map (lambda (arg)
                  (if (string-prefix? parameter arg)
                      (string-tokenize (string-drop arg (string-length parameter))
                                       %not-comma)
                      '()))
                (string-tokenize command))))

(define (module-loaded? module)
  "Return #t if MODULE is already loaded.  MODULE must be a Linux module name,
not a file name."
  (member module (modules-loaded)))

(define* (load-linux-module* file
                             #:key
                             (recursive? #t)
                             (lookup-module dot-ko)
                             (black-list (module-black-list)))
  "Load Linux module from FILE, the name of a '.ko' file; return true on
success, false otherwise.  When RECURSIVE? is true, load its dependencies
first (à la 'modprobe'.)  The actual files containing modules depended on are
obtained by calling LOOKUP-MODULE with the module name.  Modules whose name
appears in BLACK-LIST are not loaded."
  (define (slurp module)
    ;; TODO: Use 'finit_module' to reduce memory usage.
    (call-with-input-file file get-bytevector-all))

  (define (black-listed? module)
    (let ((result (member module black-list)))
      (when result
        (format (current-module-debugging-port)
                "not loading module '~a' because it's black-listed~%"
                module))
      result))

  (define (load-dependencies file)
    (let ((dependencies (module-dependencies file)))
      (every (cut load-linux-module* <> #:lookup-module lookup-module)
             (map lookup-module dependencies))))

  (and (not (black-listed? (file-name->module-name file)))
       (or (not recursive?)
           (load-dependencies file))
       (begin
         (format (current-module-debugging-port)
                 "loading Linux module from '~a'...~%" file)

         (catch 'system-error
           (lambda ()
             (load-linux-module (slurp file)))
           (lambda args
             ;; If this module was already loaded and we're in modprobe style, ignore
             ;; the error.
             (or (and recursive? (= EEXIST (system-error-errno args)))
                 (apply throw args)))))))

;;; linux-modules.scm ends here
