;;; GNU Guix --- Functional package management for GNU
;;; Copyright © 2012, 2013, 2014, 2015 Andreas Enge <andreas@enge.fr>
;;; Copyright © 2013, 2015 Ludovic Courtès <ludo@gnu.org>
;;; Copyright © 2014 Mark H Weaver <mhw@netris.org>
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

(define-module (gnu packages algebra)
  #:use-module (gnu packages)
  #:use-module (gnu packages compression)
  #:use-module (gnu packages multiprecision)
  #:use-module (gnu packages mpi)
  #:use-module (gnu packages perl)
  #:use-module (gnu packages readline)
  #:use-module (gnu packages flex)
  #:use-module (gnu packages xorg)
  #:use-module ((guix licenses) #:prefix license:)
  #:use-module (guix packages)
  #:use-module (guix download)
  #:use-module (guix build-system gnu)
  #:use-module (guix build-system cmake)
  #:use-module (guix utils))


(define-public mpfrcx
  (package
   (name "mpfrcx")
   (version "0.4.2")
   (source (origin
            (method url-fetch)
            (uri (string-append
                  "http://www.multiprecision.org/mpfrcx/download/mpfrcx-"
                  version ".tar.gz"))
            (sha256
             (base32
              "0grw66b255r574lvll1bqccm5myj2m8ajzsjaygcyq9zjnnbnhhy"))))
   (build-system gnu-build-system)
   (propagated-inputs
     `(("gmp" ,gmp)
       ("mpfr" ,mpfr)
       ("mpc"  ,mpc))) ; Header files are included by mpfrcx.h.
   (synopsis "Arithmetic of polynomials over arbitrary precision numbers")
   (description
    "Mpfrcx is a library for the arithmetic of univariate polynomials over
arbitrary precision real (mpfr) or complex (mpc) numbers, without control
on the rounding.  For the time being, only the few functions needed to
implement the floating point approach to complex multiplication are
implemented.  On the other hand, these comprise asymptotically fast
multiplication routines such as Toom–Cook and the FFT.")
   (license license:lgpl2.1+)
   (home-page "http://mpfrcx.multiprecision.org/")))

(define-public cm
  (package
   (name "cm")
   (version "0.2.1")
   (source (origin
            (method url-fetch)
            (uri (string-append
                  "http://www.multiprecision.org/cm/download/cm-"
                  version ".tar.gz"))
            (sha256
             (base32
              "1r5dx5qy0ka2sq26n9jll9iy4sjqg0jp5r3jnbjhpgxvmj8jbhq8"))))
   (build-system gnu-build-system)
   (propagated-inputs
     `(("mpfrcx" ,mpfrcx)
       ("zlib" ,zlib))) ; Header files included from cm_common.h.
   (inputs
     `(("pari-gp"  ,pari-gp)))
   (synopsis "CM constructions for elliptic curves")
   (description
    "The CM software implements the construction of ring class fields of
imaginary quadratic number fields and of elliptic curves with complex
multiplication via floating point approximations.  It consists of libraries
that can be called from within a C program and of executable command
line applications.")
   (license license:gpl2+)
   (home-page "http://cm.multiprecision.org/")))

(define-public fplll
  (package
   (name "fplll")
   (version "4.0.4")
   (source (origin
            (method url-fetch)
            (uri (string-append
                  "http://perso.ens-lyon.fr/damien.stehle/fplll/libfplll-"
                  version ".tar.gz"))
            (sha256 (base32
                     "1cbiby7ykis4z84swclpysrljmqhfcllpkcbll1m08rzskgb1a6b"))))
   (build-system gnu-build-system)
   (inputs `(("gmp" ,gmp)
             ("mpfr" ,mpfr)))
   (synopsis "Library for LLL-reduction of euclidean lattices")
   (description
    "fplll LLL-reduces euclidean lattices.  Since version 3, it can also
solve the shortest vector problem.")
   (license license:lgpl2.1+)
   (home-page "http://perso.ens-lyon.fr/damien.stehle/fplll/")))

(define-public pari-gp
  (package
   (name "pari-gp")
   (version "2.7.5")
   (source (origin
            (method url-fetch)
            (uri (string-append
                  "http://pari.math.u-bordeaux.fr/pub/pari/unix/pari-"
                  version ".tar.gz"))
            (sha256
              (base32
                "0c8l83a0gjq73r9hndsrzkypwxvnnm4pxkkzbg6jm95m80nzwh11"))))
   (build-system gnu-build-system)
   (inputs `(("gmp" ,gmp)
             ("libx11" ,libx11)
             ("perl" ,perl)
             ("readline" ,readline)))
   (arguments
    '(#:make-flags '("gp")
      ;; FIXME: building the documentation requires tex; once this is
      ;; available, replace "gp" by "all"
      #:test-target "dobench"
      #:phases
      (alist-replace
       'configure
       (lambda* (#:key outputs #:allow-other-keys)
         (let ((out (assoc-ref outputs "out")))
           (zero?
            (system* "./Configure" (string-append "--prefix=" out)))))
       %standard-phases)))
   (synopsis "PARI/GP, a computer algebra system for number theory")
   (description
    "PARI/GP is a widely used computer algebra system designed for fast
computations in number theory (factorisations, algebraic number theory,
elliptic curves...), but it also contains a large number of other useful
functions to compute with mathematical entities such as matrices,
polynomials, power series, algebraic numbers, etc., and a lot of
transcendental functions.
PARI is also available as a C library to allow for faster computations.")
   (license license:gpl2+)
   (home-page "http://pari.math.u-bordeaux.fr/")))

(define-public gp2c
  (package
   (name "gp2c")
   (version "0.0.9pl4")
   (source (origin
            (method url-fetch)
            (uri (string-append
                  "http://pari.math.u-bordeaux.fr/pub/pari/GP2C/gp2c-"
                  version ".tar.gz"))
            (sha256
              (base32
                "079qq4yyxpc53a2kn08gg9pcfgdyffbl14c2hqsic11q8pnsr08z"))))
   (build-system gnu-build-system)
   (native-inputs `(("perl" ,perl)))
   (inputs `(("pari-gp" ,pari-gp)))
   (arguments
    '(#:configure-flags
      (list (string-append "--with-paricfg="
                           (assoc-ref %build-inputs "pari-gp")
                           "/lib/pari/pari.cfg"))))
   (synopsis "PARI/GP, a computer algebra system for number theory")
   (description
    "PARI/GP is a widely used computer algebra system designed for fast
computations in number theory (factorisations, algebraic number theory,
elliptic curves...), but it also contains a large number of other useful
functions to compute with mathematical entities such as matrices,
polynomials, power series, algebraic numbers, etc., and a lot of
transcendental functions.
PARI is also available as a C library to allow for faster computations.

GP2C, the GP to C compiler, translates GP scripts to PARI programs.")
   (license license:gpl2)
   (home-page "http://pari.math.u-bordeaux.fr/")))

(define-public flint
  (package
   (name "flint")
   (version "2.5.2")
   (source (origin
            (method url-fetch)
            (uri (string-append
                  "http://flintlib.org/flint-"
                  version ".tar.gz"))
            (sha256 (base32
                     "11syazv1a8rrnac3wj3hnyhhflpqcmq02q8pqk2m6g2k6h0gxwfb"))
            (patches (map search-patch '("flint-ldconfig.patch")))))
   (build-system gnu-build-system)
   (propagated-inputs
    `(("gmp" ,gmp)
      ("mpfr" ,mpfr))) ; header files from both are included by flint/arith.h
   (arguments
    `(#:parallel-tests? #f ; seems to be necessary on arm
      #:phases
       (modify-phases %standard-phases
         (replace 'configure
           (lambda* (#:key inputs outputs #:allow-other-keys)
             (let ((out (assoc-ref outputs "out"))
                   (gmp (assoc-ref inputs "gmp"))
                   (mpfr (assoc-ref inputs "mpfr")))
               ;; do not pass "--enable-fast-install", which makes the
               ;; homebrew configure process fail
               (zero? (system*
                       "./configure"
                       (string-append "--prefix=" out)
                       (string-append "--with-gmp=" gmp)
                       (string-append "--with-mpfr=" mpfr)))))))))
   (synopsis "Fast library for number theory")
   (description
    "FLINT is a C library for number theory.  It supports arithmetic
with numbers, polynomials, power series and matrices over many base
rings, including multiprecision integers and rationals, integers
modulo n, p-adic numbers, finite fields (prime and non-prime order)
and real and complex numbers (via the Arb extension library).

Operations that can be performed include conversions, arithmetic,
GCDs, factoring, solving linear systems, and evaluating special
functions.  In addition, FLINT provides various low-level routines for
fast arithmetic.")
   (license license:gpl2+)
   (home-page "http://flintlib.org/")))

(define-public arb
  (package
   (name "arb")
   (version "2.7.0")
   (source (origin
            (method url-fetch)
            (uri (string-append
                  "https://github.com/fredrik-johansson/arb/archive/"
                  version ".tar.gz"))
            (file-name (string-append name "-" version ".tar.gz"))
            (sha256
              (base32
                "1rwkffs57v8mry63rq8l2dyw69zfs9rg5fpbfllqp3nkjnkp1fly"))))
   (build-system gnu-build-system)
   (propagated-inputs
    `(("flint" ,flint))) ; flint.h is included by arf.h
   (inputs
    `(("gmp" ,gmp)
      ("mpfr" ,mpfr)))
   (arguments
    `(#:phases
        (alist-replace
         'configure
         (lambda* (#:key inputs outputs #:allow-other-keys)
           (let ((out (assoc-ref outputs "out"))
                 (flint (assoc-ref inputs "flint"))
                 (gmp (assoc-ref inputs "gmp"))
                 (mpfr (assoc-ref inputs "mpfr")))
             ;; do not pass "--enable-fast-install", which makes the
             ;; homebrew configure process fail
             (zero? (system*
                     "./configure"
                     (string-append "--prefix=" out)
                     (string-append "--with-flint=" flint)
                     (string-append "--with-gmp=" gmp)
                     (string-append "--with-mpfr=" mpfr)))))
         %standard-phases)))
   (synopsis "Arbitrary precision floating-point ball arithmetic")
   (description
    "Arb is a C library for arbitrary-precision floating-point ball
arithmetic.  It supports efficient high-precision computation with
polynomials, power series, matrices and special functions over the
real and complex numbers, with automatic, rigorous error control.")
   (license license:gpl2+)
   (home-page "http://fredrikj.net/arb/")))

(define-public bc
  (package
    (name "bc")
    (version "1.06")
    (source (origin
             (method url-fetch)
             (uri (string-append "mirror://gnu/bc/bc-" version ".tar.gz"))
             (sha256
              (base32
               "0cqf5jkwx6awgd2xc2a0mkpxilzcfmhncdcfg7c9439wgkqxkxjf"))))
    (build-system gnu-build-system)
    (inputs `(("readline" ,readline)))
    (native-inputs `(("flex" ,flex)))
    (arguments
     '(#:phases
       (alist-replace 'configure
                      (lambda* (#:key outputs #:allow-other-keys)
                        ;; This old `configure' script doesn't support
                        ;; variables passed as arguments.
                        (let ((out (assoc-ref outputs "out")))
                          (setenv "CONFIG_SHELL" (which "bash"))
                          (zero?
                           (system*
                            "./configure"
                            (string-append "--prefix=" out)
                            ;; By default, man and info pages are put in
                            ;; PREFIX/{man,info}, but we want them in
                            ;; PREFIX/share/{man,info}.
                            (string-append "--mandir=" out "/share/man")
                            (string-append "--infodir=" out "/share/info")))))
                      %standard-phases)))
    (home-page "http://www.gnu.org/software/bc/")
    (synopsis "Arbitrary precision numeric processing language")
    (description
     "bc is an arbitrary precision numeric processing language.  It includes
an interactive environment for evaluating mathematical statements.  Its
syntax is similar to that of C, so basic usage is familiar.  It also includes
\"dc\", a reverse-polish calculator.")
    (license license:gpl2+)))

(define-public fftw
  (package
    (name "fftw")
    (version "3.3.4")
    (source (origin
             (method url-fetch)
             (uri (string-append "ftp://ftp.fftw.org/pub/fftw/fftw-"
                                 version".tar.gz"))
             (sha256
              (base32
               "10h9mzjxnwlsjziah4lri85scc05rlajz39nqf3mbh4vja8dw34g"))))
    (build-system gnu-build-system)
    (arguments
     '(#:configure-flags '("--enable-shared" "--enable-openmp")
       #:phases (alist-cons-before
                 'build 'no-native
                 (lambda _
                   ;; By default '-mtune=native' is used.  However, that may
                   ;; cause the use of ISA extensions (SSE2, etc.) that are
                   ;; not necessarily available on the user's machine when
                   ;; that package is built on a different machine.
                   (substitute* (find-files "." "Makefile$")
                     (("-mtune=native") "")))
                 %standard-phases)))
    (native-inputs `(("perl" ,perl)))
    (home-page "http://fftw.org")
    (synopsis "Computing the discrete Fourier transform")
    (description
     "FFTW is a C subroutine library for computing the discrete Fourier
transform (DFT) in one or more dimensions, of arbitrary input size, and of
both real and complex data (as well as of even/odd data---i.e. the discrete
cosine/ sine transforms or DCT/DST).")
    (license license:gpl2+)))

(define-public fftwf
  (package (inherit fftw)
    (name "fftwf")
    (arguments
     (substitute-keyword-arguments (package-arguments fftw)
       ((#:configure-flags cf)
        `(cons "--enable-float" ,cf))))
    (description
     (string-append (package-description fftw)
                    "  Single-precision version."))))

(define-public fftw-openmpi
  (package (inherit fftw)
    (name "fftw-openmpi")
    (inputs
     `(("openmpi" ,openmpi)
       ,@(package-inputs fftw)))
    (arguments
     (substitute-keyword-arguments (package-arguments fftw)
       ((#:configure-flags cf)
        `(cons "--enable-mpi" ,cf))))
    (description
     (string-append (package-description fftw)
                    "  With OpenMPI parallelism support."))))

(define-public eigen
  (package
    (name "eigen")
    (version "3.2.7")
    (source (origin
              (method url-fetch)
              (uri (string-append "https://bitbucket.org/eigen/eigen/get/"
                                  version ".tar.bz2"))
              (sha256
               (base32
                "0gigbjjdlw2q0gvcnyiwc6in314a647rkidk6977bwiwn88im3p5"))
              (file-name (string-append name "-" version ".tar.bz2"))
              (modules '((guix build utils)))
              (snippet
               ;; There are 3 test failures in the "unsupported" directory,
               ;; but maintainers say it's a known issue and it's unsupported
               ;; anyway, so just skip them.
               '(substitute* "CMakeLists.txt"
                  (("add_subdirectory\\(unsupported\\)")
                   "# Do not build the tests for unsupported features.\n")
                  ;; Work around
                  ;; <http://eigen.tuxfamily.org/bz/show_bug.cgi?id=1114>.
                  (("\"include/eigen3\"")
                   "\"${CMAKE_INSTALL_PREFIX}/include/eigen3\"")))))
    (build-system cmake-build-system)
    (arguments
     '(;; Turn off debugging symbols to save space.
       #:build-type "Release"

       #:phases (modify-phases %standard-phases
                  (replace 'check
                    (lambda _
                      (let* ((cores  (parallel-job-count))
                             (dash-j (format #f "-j~a" cores)))
                        ;; First build the tests, in parallel.  See
                        ;; <http://eigen.tuxfamily.org/index.php?title=Tests>.
                        (and (zero? (system* "make" "buildtests" dash-j))

                             ;; Then run 'CTest' with -V so we get more
                             ;; details upon failure.
                             (zero? (system* "ctest" "-V" dash-j)))))))))
    (home-page "http://eigen.tuxfamily.org")
    (synopsis "C++ template library for linear algebra")
    (description
     "Eigen is a C++ template library for linear algebra: matrices, vectors,
numerical solvers, and related algorithms.  It provides an elegant API based
on \"expression templates\".  It is versatile: it supports all matrix sizes,
all standard numeric types, various matrix decompositions and geometry
features, and more.")

    ;; Most of the code is MPLv2, with a few files under LGPLv2.1+ or BSD-3.
    ;; See 'COPYING.README' for details.
    (license license:mpl2.0)))
