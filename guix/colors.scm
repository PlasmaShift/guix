;;; GNU Guix --- Functional package management for GNU
;;; Copyright © 2013, 2014 Free Software Foundation, Inc.
;;; Copyright © 2018 Sahithi Yarlagadda <sahi@swecha.net>
;;; Copyright © 2018 Ricardo Wurmus <rekado@elephly.net>
;;; Copyright © 2017, 2018, 2019 Ludovic Courtès <ludo@gnu.org>
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

(define-module (guix colors)
  #:use-module (guix memoization)
  #:use-module (srfi srfi-1)
  #:use-module (ice-9 match)
  #:use-module (ice-9 regex)
  #:export (colorize-string
            color-rules
            color-output?
            isatty?*))

;;; Commentary:
;;;
;;; This module provides tools to produce colored output using ANSI escapes.
;;;
;;; Code:

(define color-table
  `((CLEAR       .   "0")
    (RESET       .   "0")
    (BOLD        .   "1")
    (DARK        .   "2")
    (UNDERLINE   .   "4")
    (UNDERSCORE  .   "4")
    (BLINK       .   "5")
    (REVERSE     .   "6")
    (CONCEALED   .   "8")
    (BLACK       .  "30")
    (RED         .  "31")
    (GREEN       .  "32")
    (YELLOW      .  "33")
    (BLUE        .  "34")
    (MAGENTA     .  "35")
    (CYAN        .  "36")
    (WHITE       .  "37")
    (ON-BLACK    .  "40")
    (ON-RED      .  "41")
    (ON-GREEN    .  "42")
    (ON-YELLOW   .  "43")
    (ON-BLUE     .  "44")
    (ON-MAGENTA  .  "45")
    (ON-CYAN     .  "46")
    (ON-WHITE    .  "47")))

(define (color . lst)
  "Return a string containing the ANSI escape sequence for producing the
requested set of attributes in LST.  Unknown attributes are ignored."
  (let ((color-list
         (remove not
                 (map (lambda (color) (assq-ref color-table color))
                      lst))))
    (if (null? color-list)
        ""
        (string-append
         (string #\esc #\[)
         (string-join color-list ";" 'infix)
         "m"))))

(define (colorize-string str . color-list)
  "Return a copy of STR colorized using ANSI escape sequences according to the
attributes STR.  At the end of the returned string, the color attributes will
be reset such that subsequent output will not have any colors in effect."
  (string-append
   (apply color color-list)
   str
   (color 'RESET)))

(define isatty?*
  (mlambdaq (port)
    "Return true if PORT is a tty.  Memoize the result."
    (isatty? port)))

(define (color-output? port)
  "Return true if we should write colored output to PORT."
  (and (not (getenv "INSIDE_EMACS"))
       (not (getenv "NO_COLOR"))
       (isatty?* port)))

(define-syntax color-rules
  (syntax-rules ()
    "Return a procedure that colorizes the string it is passed according to
the given rules.  Each rule has the form:

  (REGEXP COLOR1 COLOR2 ...)

where COLOR1 specifies how to colorize the first submatch of REGEXP, and so
on."
    ((_ (regexp colors ...) rest ...)
     (let ((next (color-rules rest ...))
           (rx   (make-regexp regexp)))
       (lambda (str)
         (if (string-index str #\nul)
             str
             (match (regexp-exec rx str)
               (#f (next str))
               (m  (let loop ((n 1)
                              (c '(colors ...))
                              (result '()))
                     (match c
                       (()
                        (string-concatenate-reverse result))
                       ((first . tail)
                        (loop (+ n 1) tail
                              (cons (colorize-string (match:substring m n)
                                                     first)
                                    result)))))))))))
    ((_)
     (lambda (str)
       str))))