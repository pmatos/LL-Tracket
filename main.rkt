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

(require racket/function
         racket/string
         )

;; ---------------------------------------------------------------------------------------------------

(define (read-current-memory-use pid)
  (call-with-input-file "/proc/~a/statm"
    (lambda (in)
      (define l (read-line in))


(define (track-subprocess pid [every 0.1])
  (define start (current-inexact-milliseconds))
  (let loop ([lst '()])
    (sync (handle-evt
           (thread-receive-evt)
           (lambda (_) (void)))
          (handle-evt
           (alarm-evt (+ (current-inexact-milliseconds) (* every 1000)))
           (lambda (_)
             (define mem (read-current-memory-use pid))
             (loop (cons (- (current-inexact-milliseconds) start)
                         mem)))))))

(define (run-cmd cmd)
  (printf "Running command line ~a~n"
          (string-join cmd))

  (define-values (sp out in err)
    (apply subprocess
           (current-output-port)
           (current-input-port)
           (current-error-port)
           cmd))

  (define monitor
    (thread
     (thunk (track-subprocess (subprocess-pid sp)))))
  (define exitcode (subprocess-wait sp))

  (thread-send monitor 'done)

  (unless (zero? exit)
    (fprintf (current-error-port) "Process exited with non-zero output: ~a~n" exitcode)))

(module+ main

  (require racket/cmdline)

  (define cmd
    (command-line
     #:program "ll-tracket"
     #:args cmd
     cmd))

  (run-cmd cmd))
