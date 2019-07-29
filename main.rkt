;;     LL-Tracket is a low-level application performance tracket
;;     Copyright (C) 2019 Paulo Matos

;;     This program is free software: you can redistribute it and/or modify
;;     it under the terms of the GNU General Public License as published by
;;     the Free Software Foundation, either version 3 of the License, or
;;     (at your option) any later version.

;;     This program is distributed in the hope that it will be useful,
;;     but WITHOUT ANY WARRANTY; without even the implied warranty of
;;     MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
;;     GNU General Public License for more details.

;;     You should have received a copy of the GNU General Public License
;;     along with this program. If not, see <https://www.gnu.org/licenses/>.

#lang racket/base
;; ---------------------------------------------------------------------------------------------------

(require plot/no-gui
         racket/function
         racket/list
         racket/string)

;; ---------------------------------------------------------------------------------------------------

(define data #false)

(define (read-current-memory-use pid)
  (with-input-from-file (format "/proc/~a/statm" pid)
    (thunk
     (second
      (regexp-match #px"^([0-9]+) [0-9]+ [0-9]+ [0-9]+ [0-9]+ [0-9]+ [0-9]+$"
                    (read-line))))))

(define (track-subprocess pid [every 0.001])
  (define start (current-inexact-milliseconds))
  (let loop ([lst (list (cons start (read-current-memory-use pid)))])
    (sync (handle-evt
           (thread-receive-evt)
           (lambda (_) (set! data lst)))
          (handle-evt
           (alarm-evt (+ (current-inexact-milliseconds) (* every 1000)))
           (lambda (_)
             (define mem (read-current-memory-use pid))
             (sleep every)
             (loop (cons (cons (- (current-inexact-milliseconds) start)
                               mem)
                         lst)))))))

(define (plot-to-file path data)
  (plot-file (lines (for/list ([p (in-list data)])
                      (list (car p) (string->number (cdr p)))))
             path))

(define (run-cmd cmd)

  (define exe (first cmd))
  (define args (rest cmd))

  (define exepath
    (if (absolute-path? exe)
        exe
        (path->string (find-executable-path exe))))

  (printf "Running command line ~a ~a~n"
          exepath (string-join args))

  (define-values (sp out in err)
    (apply subprocess
           (current-output-port)
           (current-input-port)
           (current-error-port)
           exepath args))

  (define monitor
    (thread
     (thunk (track-subprocess (subprocess-pid sp)))))
  (subprocess-wait sp)
  (define exitcode (subprocess-status sp))

  (thread-send monitor 'done)
  (thread-wait monitor)

  (unless (zero? exitcode)
    (fprintf (current-error-port) "Process exited with non-zero output: ~a~n" exitcode))

  (when data
    (printf "Process finished, gathered ~a records~n" (length data))
    (printf "Maximum memory requested: ~a~n" (apply max (map (compose string->number cdr) data)))
    (plot-to-file "plot.png" data)))

(module+ main

  (require racket/cmdline)

  (define cmd
    (command-line
     #:program "ll-tracket"
     #:args cmd
     cmd))

  (run-cmd cmd))
