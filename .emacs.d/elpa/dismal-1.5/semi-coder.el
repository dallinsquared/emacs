;;; semi-coder.el --- Let users insert codes from model into Soar/PA sheets.

;; Copyright (C) 1992, 2013 Free Software Foundation, Inc.

;; Author: Frank Ritter
;; Created-On: Sun Jul 19 02:04:03 1992

;; This is free software: you can redistribute it and/or modify
;; it under the terms of the GNU General Public License as published by
;; the Free Software Foundation, either version 3 of the License, or
;; (at your option) any later version.

;; This software is distributed in the hope that it will be useful,
;; but WITHOUT ANY WARRANTY; without even the implied warranty of
;; MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
;; GNU General Public License for more details.

;; You should have received a copy of the GNU General Public License
;; along with this software.  If not, see <http://www.gnu.org/licenses/>.

;;; Commentary:

;; Note: users must have new pscm-stats loaded.

;;; Code:

(require 'dismal-data-structures)
(require 'rmatrix)


;;;; i.	Variables & constants

(defvar dis-operator-codes nil
  "Operator names taken from Soar that can be used to code segments.")

(defconst dis-op-code-insert-query
  "Operator code to insert (? for complete list): ")


;;;; I.	dis-op-code-segment

;; would be useful to allow new codes to be added.

(defun dis-op-code-segment ()
  "Code a segment with an operator name."
  (interactive)

  ;; if not initialized, init
  (if (not dis-operator-codes)
      (dis-initialize-operator-codes))
  (let ((code nil))  
  (setq code
        (completing-read dis-op-code-insert-query
           dis-operator-codes
	   nil 'require-match))
  ;; insert into cell
  (dismal-set-exp dismal-current-row dismal-current-col
  (dismal-set-val dismal-current-row dismal-current-col
                  code))
  (dismal-save-excursion
    (dismal-redraw-cell dismal-current-row dismal-current-col t)) ))


;;;; II.	dis-save-op-codes

(defun dis-save-op-codes (file)
  "Write dismal operator codes out to a FILE."
 (interactive (list (dismal-read-minibuffer "Dump op codes in: "
                        'editable (expand-file-name dis-codes-file))))
  ;; (interactive "FFile to dump operator codes into: ")
  (save-excursion
  (let ((codes dis-operator-codes))
    (if (file-exists-p file)
        (if (y-or-n-p (format "Delete %s? " 'file))
            (delete-file file)
          (error "Can't overwrite file %s" file)))
    (find-file file)
    (mapc (function (lambda (x) (insert (car x) "\n")))
          codes)
    (save-buffer)
    (kill-buffer (current-buffer)))))


;;;; III.	dis-load-op-codes

(defun dis-load-op-codes (file &optional union-or-replace)
 "Load operator codes into dismal.  UNION-OR-REPLACE can be either."
 (interactive (list (dismal-read-minibuffer "Load codes from: "
                        'editable (expand-file-name dis-codes-file))))
 (let ((code-buffer (find-file-noselect file))
       (done nil) (completion-ignore-case t)
       (code-word nil))
 ;; union or replace these codes?
 (if (not (or (eq union-or-replace 'union) (eq union-or-replace 'replace)))
     (setq union-or-replace
           (completing-read "Use Union or Replace to incorporate these codes: "
                            '(("Union") ("Replace")) nil 'require-match)))
 (if (string= "replace" union-or-replace)
     (setq dis-operator-codes nil))
 (save-excursion (set-buffer code-buffer) (goto-char (point-min)))
 (while (not done)
   (save-excursion
     (set-buffer code-buffer)
     (setq code-word
          (buffer-substring (point) (save-excursion (end-of-line) (point))))
     (forward-line)
     (if (eobp) (setq done t)))
   (if (not (assoc code-word dis-operator-codes))
       (setq dis-operator-codes (cons (list code-word) dis-operator-codes))))
 (kill-buffer code-buffer)))


;;;; IV.	Utilities

;; (defconst dis-init-op-codes-prompt "Attempt to load codes from DSI or TAQL: ")

(defun dis-initialize-operator-codes ()
  "Initialize the dismal operator codes."
  ;; used to require either SX+ latest pscm-stats, or taql and taql-stats
  ;; both in the sx directory.
  (interactive)
  (let ((completion-ignore-case t))
  ;; look in process, or query user for a file
  (cond ((comint-check-proc "*soar*")
         (if (string= "DSI"
                     (completing-read dis-init-op-codes-prompt
                        '(("DSI") ("TAQL")) nil 'require-match))
             (setq dis-operator-codes
                  (car
                    (read-from-string
                    (downcase
                    (ilisp-send "(or #+sx(sx::list-pscm-operators)
                                     #-sx(and nil))")))))
               (setq dis-operator-codes
                    (car
                    (read-from-string
                    (downcase
                    (ilisp-send "(or #+taql(user::list-taql-operators)
                                     #-taql(and nil))"))))))
          ;; if you got 'em, fix em up
          (if (and dis-operator-codes (listp dis-operator-codes))
              (setq dis-operator-codes
                    (mapcar (function (lambda (x) (list (format "%s" x)) ))
                            dis-operator-codes))
            (call-interactively 'dis-load-op-codes)) )
        (t (call-interactively 'dis-load-op-codes))) ))

(provide 'semi-coder)
;;; semi-coder.el ends here
