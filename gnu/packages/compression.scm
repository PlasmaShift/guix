;;; GNU Guix --- Functional package management for GNU
;;; Copyright © 2012, 2013, 2014, 2015 Ludovic Courtès <ludo@gnu.org>
;;; Copyright © 2013 Andreas Enge <andreas@enge.fr>
;;; Copyright © 2014, 2015 Mark H Weaver <mhw@netris.org>
;;; Copyright © 2015 Taylan Ulrich Bayırlı/Kammer <taylanbayirli@gmail.com>
;;; Copyright © 2015 Eric Bavier <bavier@member.fsf.org>
;;; Copyright © 2015 Ricardo Wurmus <rekado@elephly.net>
;;; Copyright © 2015 Leo Famulari <leo@famulari.name>
;;; Copyright © 2015 Jeff Mickey <j@codemac.net>
;;; Copyright © 2015, 2016 Efraim Flashner <efraim@flashner.co.il>
;;; Copyright © 2016 Ben Woodcroft <donttrustben@gmail.com>
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

(define-module (gnu packages compression)
  #:use-module ((guix licenses) #:prefix license:)
  #:use-module (guix utils)
  #:use-module (guix packages)
  #:use-module (guix download)
  #:use-module (guix git-download)
  #:use-module (guix build-system gnu)
  #:use-module (guix build-system perl)
  #:use-module (gnu packages backup)
  #:use-module (gnu packages base)
  #:use-module (gnu packages perl)
  #:use-module (gnu packages pkg-config)
  #:use-module (gnu packages valgrind)
  #:use-module ((srfi srfi-1) #:select (last)))

(define-public zlib
  (package
    (name "zlib")
    (version "1.2.8")
    (source
     (origin
      (method url-fetch)
      (uri (list (string-append "http://zlib.net/zlib-"
                                 version ".tar.gz")
                 (string-append "mirror://sourceforge/libpng/zlib-"
                                 version ".tar.gz")))
      (sha256
       (base32
        "039agw5rqvqny92cpkrfn243x2gd4xn13hs3xi6isk55d2vqqr9n"))))
    (build-system gnu-build-system)
    (arguments
     `(#:phases (alist-replace
                 'configure
                 (lambda* (#:key outputs #:allow-other-keys)
                   ;; Zlib's home-made `configure' fails when passed
                   ;; extra flags like `--enable-fast-install', so we need to
                   ;; invoke it with just what it understand.
                   (let ((out (assoc-ref outputs "out")))
                     ;; 'configure' doesn't understand '--host'.
                     ,@(if (%current-target-system)
                           `((setenv "CHOST" ,(%current-target-system)))
                           '())
                     (zero?
                      (system* "./configure"
                               (string-append "--prefix=" out)))))
                 %standard-phases)))
    (home-page "http://zlib.net/")
    (synopsis "Compression library")
    (description
     "zlib is designed to be a free, general-purpose, legally unencumbered --
that is, not covered by any patents -- lossless data-compression library for
use on virtually any computer hardware and operating system.  The zlib data
format is itself portable across platforms.  Unlike the LZW compression method
used in Unix compress(1) and in the GIF image format, the compression method
currently used in zlib essentially never expands the data. (LZW can double or
triple the file size in extreme cases.)  zlib's memory footprint is also
independent of the input data and can be reduced, if necessary, at some cost
in compression.")
    (license license:zlib)))

(define-public fastjar
  (package
   (name "fastjar")
   (version "0.98")
   (source (origin
             (method url-fetch)
             (uri (string-append "mirror://savannah/fastjar/fastjar-"
                                 version ".tar.gz"))
             (sha256
              (base32
               "0iginbz2m15hcsa3x4y7v3mhk54gr1r7m3ghx0pg4n46vv2snmpi"))))
   (build-system gnu-build-system)
   (inputs `(("zlib" ,zlib)))
   (home-page "http://savannah.nongnu.org/projects/fastjar")
   (synopsis "Replacement for Sun's 'jar' utility")
   (description
    "FastJar is an attempt to create a much faster replacement for Sun's 'jar'
utility.  Instead of being written in Java, FastJar is written in C.")
   (license license:gpl2+)))

(define-public libtar
  (package
   (name "libtar")
   (version "1.2.11")
   (source (origin
            (method url-fetch)
            (uri (string-append
                  "ftp://ftp.feep.net/pub/software/libtar/libtar-"
                  version ".tar.gz"))
            (sha256
             (base32
              "1f3vx1wa69a6c5y0z0aakd81gygirdcm0vimazg433q8nyvfybja"))))
   (build-system gnu-build-system)
   (arguments `(#:tests? #f)) ;no "check" target
   (synopsis "C library for manipulating POSIX tar files")
   (description
    "libtar is a C library for manipulating POSIX tar files.  It handles
adding and extracting files to/from a tar archive.")
   (home-page "http://www.feep.net/libtar/")
   (license license:bsd-3)))

(define-public gzip
  (package
   (name "gzip")
   (version "1.7")
   (source (origin
            (method url-fetch)
            (uri (string-append "mirror://gnu/gzip/gzip-"
                                version ".tar.gz"))
            (sha256
             (base32
              "1as1ddq58spflzz5kxm0ni0xfpswrkkrncjpxyb3aw77gizcacgv"))))
   (build-system gnu-build-system)
   (synopsis "General file (de)compression (using lzw)")
   (arguments
    ;; FIXME: The test suite wants `less', and optionally Perl.
    '(#:tests? #f))
   (description
    "GNU Gzip provides data compression and decompression utilities; the
typical extension is \".gz\".  Unlike the \"zip\" format, it compresses a single
file; as a result, it is often used in conjunction with \"tar\", resulting in
\".tar.gz\" or \".tgz\", etc.")
   (license license:gpl3+)
   (home-page "http://www.gnu.org/software/gzip/")))

(define-public bzip2
  (let ((build-shared-lib
         ;; Build a shared library.
         '(lambda* (#:key inputs #:allow-other-keys)
            (patch-makefile-SHELL "Makefile-libbz2_so")
            (zero? (system* "make" "-f" "Makefile-libbz2_so"))))
        (install-shared-lib
         '(lambda* (#:key outputs #:allow-other-keys)
            (let* ((out    (assoc-ref outputs "out"))
                   (libdir (string-append out "/lib")))
              (for-each (lambda (file)
                          (let ((base (basename file)))
                            (format #t "installing `~a' to `~a'~%"
                                    base libdir)
                            (copy-file file
                                       (string-append libdir "/" base))))
                        (find-files "." "^libbz2\\.so")))))
        (set-cross-environment
         '(lambda* (#:key target #:allow-other-keys)
            (substitute* (find-files "." "Makefile")
              (("CC=.*$")
               (string-append "CC = " target "-gcc\n"))
              (("AR=.*$")
               (string-append "AR = " target "-ar\n"))
              (("RANLIB=.*$")
               (string-append "RANLIB = " target "-ranlib\n"))
              (("^all:(.*)test" _ prerequisites)
               ;; Remove 'all' -> 'test' dependency.
               (string-append "all:" prerequisites "\n"))))))
    (package
      (name "bzip2")
      (version "1.0.6")
      (source (origin
               (method url-fetch)
               (uri (string-append "http://www.bzip.org/" version "/bzip2-"
                                   version ".tar.gz"))
               (sha256
                (base32
                 "1kfrc7f0ja9fdn6j1y6yir6li818npy6217hvr3wzmnmzhs8z152"))))
      (build-system gnu-build-system)
      (arguments
       `(#:modules ((guix build gnu-build-system)
                    (guix build utils)
                    (srfi srfi-1))
         #:phases
         ,(if (%current-target-system)

              ;; Cross-compilation: use the cross tools.
              `(alist-cons-before
                'build 'build-shared-lib ,build-shared-lib
                (alist-cons-after
                 'install 'install-shared-lib ,install-shared-lib
                 (alist-replace 'configure ,set-cross-environment
                                %standard-phases)))

              ;; Native compilation: build the shared library.
              `(alist-cons-before
                'build 'build-shared-lib ,build-shared-lib
                (alist-cons-after
                 'install 'install-shared-lib ,install-shared-lib
                 (alist-delete 'configure %standard-phases))))

         #:make-flags (list (string-append "PREFIX="
                                           (assoc-ref %outputs "out")))

         ;; Don't attempt to run the tests when cross-compiling.
         ,@(if (%current-target-system)
               '(#:tests? #f)
               '())))
      (synopsis "High-quality data compression program")
      (description
       "bzip2 is a freely available, patent free (see below), high-quality data
compressor.  It typically compresses files to within 10% to 15% of the best
available techniques (the PPM family of statistical compressors), whilst
being around twice as fast at compression and six times faster at
decompression.")
      (license (license:non-copyleft "file://LICENSE"
                                  "See LICENSE in the distribution."))
      (home-page "http://www.bzip.org/"))))

(define-public pbzip2
  (package
    (name "pbzip2")
    (version "1.1.12")
    (source (origin
             (method url-fetch)
             (uri (string-append "https://launchpad.net/pbzip2/"
                                 (version-major+minor version) "/" version
                                 "/+download/" name "-" version ".tar.gz"))
             (sha256
              (base32
               "1vk6065dv3a47p86vmp8hv3n1ygd9hraz0gq89gvzlx7lmcb6fsp"))))
    (build-system gnu-build-system)
    (inputs
     `(("bzip2" ,bzip2)))
    (arguments
     `(#:tests? #f ; no tests
       #:phases (modify-phases %standard-phases
                  (delete 'configure))
       #:make-flags (list (string-append "PREFIX=" %output))))
    (home-page "http://compression.ca/pbzip2/")
    (synopsis "Parallel bzip2 implementation")
    (description
     "Pbzip2 is a parallel implementation of the bzip2 block-sorting file
compressor that uses pthreads and achieves near-linear speedup on SMP machines.
The output of this version is fully compatible with bzip2 v1.0.2 (i.e. anything
compressed with pbzip2 can be decompressed with bzip2).")
    (license (license:non-copyleft "file://COPYING"
                                   "See COPYING in the distribution."))))

(define-public xz
  (package
   (name "xz")
   (version "5.2.2")
   (source (origin
            (method url-fetch)
            (uri (list (string-append "http://tukaani.org/xz/xz-" version
                                      ".tar.gz")
                       (string-append "http://multiprecision.org/guix/xz-"
                                      version ".tar.gz")))
            (sha256
             (base32
              "18h2k4jndhzjs8ln3a54qdnfv59y6spxiwh9gpaqniph6iflvpvk"))))
   (build-system gnu-build-system)
   (synopsis "General-purpose data compression")
   (description
    "XZ Utils is free general-purpose data compression software with high
compression ratio.  XZ Utils were written for POSIX-like systems, but also
work on some not-so-POSIX systems.  XZ Utils are the successor to LZMA Utils.

The core of the XZ Utils compression code is based on LZMA SDK, but it has
been modified quite a lot to be suitable for XZ Utils.  The primary
compression algorithm is currently LZMA2, which is used inside the .xz
container format.  With typical files, XZ Utils create 30 % smaller output
than gzip and 15 % smaller output than bzip2.")
   (license (list license:gpl2+ license:lgpl2.1+)) ; bits of both
   (home-page "http://tukaani.org/xz/")))

(define-public lzo
  (package
    (name "lzo")
    (version "2.09")
    (source
     (origin
      (method url-fetch)
      (uri (string-append "http://www.oberhumer.com/opensource/lzo/download/lzo-"
                          version ".tar.gz"))
      (sha256
       (base32
        "0k5kpj3jnsjfxqqkblpfpx0mqcy86zs5fhjhgh2kq1hksg7ag57j"))))
    (build-system gnu-build-system)
    (arguments '(#:configure-flags '("--enable-shared")))
    (home-page "http://www.oberhumer.com/opensource/lzo")
    (synopsis
     "Data compression library suitable for real-time data de-/compression")
    (description
     "LZO is a data compression library which is suitable for data
de-/compression in real-time.  This means it favours speed over
compression ratio.

LZO is written in ANSI C.  Both the source code and the compressed data
format are designed to be portable across platforms.")
    (license license:gpl2+)))

(define-public lzop
  (package
    (name "lzop")
    (version "1.03")
    (source
     (origin
       (method url-fetch)
       (uri (string-append "http://www.lzop.org/download/lzop-"
                           version ".tar.gz"))
       (sha256
        (base32
         "1jdjvc4yjndf7ihmlcsyln2rbnbaxa86q4jskmkmm7ylfy65nhn1"))))
    (build-system gnu-build-system)
    (inputs `(("lzo" ,lzo)))
    (home-page "http://www.lzop.org/")
    (synopsis "Compress or expand files")
    (description
     "Lzop is a file compressor which is very similar to gzip.  Lzop uses the
LZO data compression library for compression services, and its main advantages
over gzip are much higher compression and decompression speed (at the cost of
some compression ratio).")
    (license license:gpl2+)))

(define-public lzip
  (package
    (name "lzip")
    (version "1.16")
    (source (origin
             (method url-fetch)
             (uri (string-append "mirror://savannah/lzip/lzip-"
                                 version ".tar.gz"))
             (sha256
              (base32
               "0l9724rw1l3hg2ldr3n7ihqich4m9nc6y7l302bvdj4jmxdw530j"))))
    (build-system gnu-build-system)
    (home-page "http://www.nongnu.org/lzip/lzip.html")
    (synopsis "Lossless data compressor based on the LZMA algorithm")
    (description
     "Lzip is a lossless data compressor with a user interface similar to the
one of gzip or bzip2.  Lzip decompresses almost as fast as gzip and compresses
more than bzip2, which makes it well suited for software distribution and data
archiving.  Lzip is a clean implementation of the LZMA algorithm.")
    (license license:gpl3+)))

(define-public sharutils
  (package
    (name "sharutils")
    (version "4.15.2")
    (source
     (origin
      (method url-fetch)
      (uri (string-append "mirror://gnu/sharutils/sharutils-"
                          version ".tar.xz"))
      (sha256
       (base32
        "16isapn8f39lnffc3dp4dan05b7x6mnc76v6q5nn8ysxvvvwy19b"))))
    (build-system gnu-build-system)
    (inputs
     `(("which" ,which)))
    (arguments
     `(#:phases
        (alist-cons-after
         'patch-source-shebangs 'unpatch-source-shebang
         ;; revert the patch-shebang phase on a script which is
         ;; in fact test data
         (lambda _
           (substitute* "tests/shar-1.ok"
             (((which "sh")) "/bin/sh")))
         %standard-phases)))
    (home-page "http://www.gnu.org/software/sharutils/")
    (synopsis "Archives in shell scripts, uuencode/uudecode")
    (description
     "GNU sharutils is a package for creating and manipulating shell
archives that can be readily emailed.  A shell archive is a file that can be
processed by a Bourne-type shell to unpack the original collection of files.
This package is mostly for compatibility and historical interest.")
    (license license:gpl3+)))

(define-public sfarklib
  (package
    (name "sfarklib")
    (version "2.24")
    (source (origin
              (method url-fetch)
              (uri (string-append "https://github.com/raboof/sfArkLib/archive/"
                                  version ".tar.gz"))
              (file-name (string-append name "-" version ".tar.gz"))
              (sha256
               (base32
                "0bzs2d98rk1xw9qwpnc7gmlbxwmwc3dg1rpn310afy9pq1k9clzi"))))
    (build-system gnu-build-system)
    (arguments
     `(#:tests? #f ;no "check" target
       #:phases
       (modify-phases %standard-phases
         (replace 'configure
                  (lambda* (#:key outputs #:allow-other-keys)
                    (substitute* "Makefile"
                      (("/usr/local") (assoc-ref outputs "out")))
                    #t)))))
    (inputs
     `(("zlib" ,zlib)))
    (home-page "https://github.com/raboof/sfArkLib")
    (synopsis "Library for SoundFont decompression")
    (description
     "SfArkLib is a C++ library for decompressing SoundFont files compressed
with the sfArk algorithm.")
    (license license:gpl3+)))

(define-public sfarkxtc
  (package
    (name "sfarkxtc")
    (version "b5e0a2ba39")
    (source (origin
              ;; There are no release tarballs, so we just fetch the latest
              ;; commit at this time.
              (method git-fetch)
              (uri (git-reference
                    (url "https://github.com/raboof/sfarkxtc.git")
                    (commit version)))
              (sha256
               (base32
                "0f5x6i46qfl6ry21s7g2p4sd4b2r1g4fb03yqi2vv4kq3saryhvj"))))
    (build-system gnu-build-system)
    (arguments
     `(#:tests? #f ;no "check" target
       #:phases
       (modify-phases %standard-phases
         (replace 'configure
                  (lambda* (#:key outputs #:allow-other-keys)
                    (substitute* "Makefile"
                      (("/usr/local") (assoc-ref outputs "out")))
                    #t)))))
    (inputs
     `(("zlib" ,zlib)
       ("sfarklib" ,sfarklib)))
    (home-page "https://github.com/raboof/sfarkxtc")
    (synopsis "Basic sfArk decompressor")
    (description "SfArk extractor converts SoundFonts in the compressed legacy
sfArk file format to the uncompressed sf2 format.")
    (license license:gpl3+)))

(define-public libmspack
  (package
    (name "libmspack")
    (version "0.5")
    (source
     (origin
      (method url-fetch)
      (uri (string-append "http://www.cabextract.org.uk/libmspack/libmspack-"
                          version "alpha.tar.gz"))
      (sha256
       (base32 "04413hynb7zizxnkgy9riik3612dwirkpr6fcjrnfl2za9sz4rw9"))))
    (build-system gnu-build-system)
    (home-page "http://www.cabextract.org.uk/libmspack/")
    (synopsis "Compression tools for some formats used by Microsoft")
    (description
     "The purpose of libmspack is to provide both compression and
decompression of some loosely related file formats used by Microsoft.")
    (license license:lgpl2.1+)))

(define-public perl-compress-raw-bzip2
  (package
    (name "perl-compress-raw-bzip2")
    (version "2.068")
    (source
     (origin
       (method url-fetch)
       (uri (string-append "mirror://cpan/authors/id/P/PM/PMQS/"
                           "Compress-Raw-Bzip2-" version ".tar.gz"))
       (sha256
        (base32
         "16hl58xppckldz05zdyid1l5gpaykzwvkq682h3rc3nilbhgjqqg"))))
    (build-system perl-build-system)
    ;; TODO: Use our bzip2 package.
    (home-page "http://search.cpan.org/dist/Compress-Raw-Bzip2")
    (synopsis "Low-level interface to bzip2 compression library")
    (description "This module provides a Perl interface to the bzip2
compression library.")
    (license (package-license perl))))

(define-public perl-compress-raw-zlib
  (package
    (name "perl-compress-raw-zlib")
    (version "2.068")
    (source
     (origin
       (method url-fetch)
       (uri (string-append "mirror://cpan/authors/id/P/PM/PMQS/"
                           "Compress-Raw-Zlib-" version ".tar.gz"))
       (sha256
        (base32
         "06q7n87g26nn5gv4z2p31ca32f6zk124hqxc25rfgkjd3qi5798i"))))
    (build-system perl-build-system)
    (inputs
     `(("zlib" ,zlib)))
    (arguments
     `(#:phases (modify-phases %standard-phases
                  (add-before
                   'configure 'configure-zlib
                   (lambda* (#:key inputs #:allow-other-keys)
                     (call-with-output-file "config.in"
                       (lambda (port)
                         (format port "
BUILD_ZLIB = False
INCLUDE = ~a/include
LIB = ~:*~a/lib
OLD_ZLIB = False
GZIP_OS_CODE = AUTO_DETECT"
                                 (assoc-ref inputs "zlib")))))))))
    (home-page "http://search.cpan.org/dist/Compress-Raw-Zlib")
    (synopsis "Low-level interface to zlib compression library")
    (description "This module provides a Perl interface to the zlib
compression library.")
    (license (package-license perl))))

(define-public perl-io-compress
  (package
    (name "perl-io-compress")
    (version "2.068")
    (source
     (origin
       (method url-fetch)
       (uri (string-append "mirror://cpan/authors/id/P/PM/PMQS/"
                           "IO-Compress-" version ".tar.gz"))
       (sha256
        (base32
         "0dy0apjp7j9dfkzfjspjd3z9gh26srx5vac72g59bkkz1jf8s1gs"))))
    (build-system perl-build-system)
    (propagated-inputs
     `(("perl-compress-raw-zlib" ,perl-compress-raw-zlib)     ; >=2.068
       ("perl-compress-raw-bzip2" ,perl-compress-raw-bzip2))) ; >=2.068
    (home-page "http://search.cpan.org/dist/IO-Compress")
    (synopsis "IO Interface to compressed files/buffers")
    (description "IO-Compress provides a Perl interface to allow reading and
writing of compressed data created with the zlib and bzip2 libraries.")
    (license (package-license perl))))

(define-public lz4
  (package
    (name "lz4")
    (version "131")
    (source
     (origin
       (method url-fetch)
       (uri (string-append "https://github.com/Cyan4973/lz4/archive/"
                           "r" version ".tar.gz"))
       (sha256
        (base32 "1vfg305zvj50hwscad24wan9jar6nqj14gdk2hqyr7bb9mhh0kcx"))
       (file-name (string-append name "-" version ".tar.gz"))))
    (build-system gnu-build-system)
    (native-inputs `(("valgrind" ,valgrind)))
    (arguments
     `(#:test-target "test"
       #:parallel-tests? #f ; tests fail if run in parallel
       #:make-flags (list "CC=gcc"
                          (string-append "PREFIX=" (assoc-ref %outputs "out")))
       #:phases (modify-phases %standard-phases
                  (delete 'configure))))
    (home-page "https://github.com/Cyan4973/lz4")
    (synopsis "Compression algorithm focused on speed")
    (description "LZ4 is a lossless compression algorithm, providing
compression speed at 400 MB/s per core (0.16 Bytes/cycle).  It also features an
extremely fast decoder, with speed in multiple GB/s per core (0.71 Bytes/cycle).
A high compression derivative, called LZ4_HC, is also provided.  It trades CPU
time for compression ratio.")
    ;; The libraries (lz4, lz4hc, and xxhash are BSD licenced. The command
    ;; line interface programs (lz4, fullbench, fuzzer, datagen) are GPL2+.
    (license (list license:bsd-2 license:gpl2+))))

(define-public squashfs-tools
  (package
    (name "squashfs-tools")
    (version "4.3")
    (source (origin
              (method url-fetch)
              (uri (string-append "mirror://sourceforge/squashfs/"
                                  "squashfs" version ".tar.gz"))
              (sha256
               (base32
                "1xpklm0y43nd9i6jw43y2xh5zvlmj9ar2rvknh0bh7kv8c95aq0d"))))
    (build-system gnu-build-system)
    (arguments
     '(#:tests? #f ; no check target
       #:make-flags
       (list "CC=gcc"
             "XZ_SUPPORT=1"
             "LZO_SUPPORT=1"
             "LZ4_SUPPORT=1"
             (string-append "INSTALL_DIR=" %output "/bin"))
       #:phases
       (modify-phases %standard-phases
         (replace 'configure
                  (lambda _
                    (chdir "squashfs-tools"))))))
    (inputs
     `(("lz4" ,lz4)
       ("lzo" ,lzo)
       ("xz" ,xz)
       ("zlib" ,zlib)))
    (home-page "http://squashfs.sourceforge.net/")
    (synopsis "Tools to create and extract squashfs filesystems")
    (description
     "Squashfs is a highly compressed read-only filesystem for Linux.  It uses
zlib to compress files, inodes, and directories.  All blocks are packed to
minimize the data overhead, and block sizes of between 4K and 1M are supported.
It is intended to be used for archival use, for live CDs, and for embedded
systems where low overhead is needed.  This package allows you to create and
extract such filesystems.")
    (license license:gpl2+)))

(define-public pigz
  (package
    (name "pigz")
    (version "2.3.3")
    (source (origin
              (method url-fetch)
              (uri (string-append "http://zlib.net/pigz/"
                                  name "-" version ".tar.gz"))
              (sha256
               (base32
                "172hdf26k4zmm7z8md7nl0dph2a7mhf3x7slb9bhfyff6as6g2sf"))))
    (build-system gnu-build-system)
    (arguments
     `(#:phases
       (modify-phases %standard-phases
         (delete 'configure)
         (replace 'install
                  (lambda* (#:key outputs #:allow-other-keys)
                    (let* ((out (assoc-ref outputs "out"))
                           (bin (string-append out "/bin"))
                           (man (string-append out "/share/man/man1")))
                      (install-file "pigz" bin)
                      (symlink "pigz" (string-append bin  "/unpigz"))
                      (install-file "pigz.1" man)
                      #t))))
       #:make-flags (list "CC=gcc")
       #:test-target "tests"))
    (inputs `(("zlib" ,zlib)))
    (home-page "http://zlib.net/pigz/")
    (synopsis "Parallel implementation of gzip")
    (description
     "This package provides a parallel implementation of gzip that exploits
multiple processors and multiple cores when compressing data.")

    ;; Things under zopfli/ are under ASL2.0, but 4 files at the top-level,
    ;; written by Mark Adler, are under another non-copyleft license.
    (license license:asl2.0)))

(define-public pixz
  (package
    (name "pixz")
    (version "1.0.6")
    (source (origin
              (method url-fetch)
              (uri (string-append
                    "https://github.com/vasi/pixz/releases/download/v" version
                    "/pixz-" version ".tar.xz"))
              (sha256
               (base32
                "1s3j7zw6j5zi3fhdxg287ndr3wf6swac7z21mqd1pyiln530gi82"))))
    (build-system gnu-build-system)
    (native-inputs
     `(("pkg-config" ,pkg-config)
       ("libarchive" ,libarchive)))
    (home-page "https://github.com/vasi/pixz")
    (synopsis "Parallel indexing implementation of LZMA")
    (description
     "The existing XZ Utils provide great compression in the .xz file format,
but they produce just one big block of compressed data.  Pixz instead produces
a collection of smaller blocks which makes random access to the original data
possible and can compress in parallel.  This is especially useful for large
tarballs.")
    (license license:bsd-2)))
