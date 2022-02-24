;;; satchel.el --- A bag for your files, separated by git branches -*- lexical-binding: t; -*-

;; Copyright (C) 2022  Free Software Foundation, Inc.

;; Author: Theodor Thornhill <theo@thornhill.no>
;; Keywords: tools git
;; Version: 0.2
;; Package-Requires: ((emacs "27.2") (project "0.8.1"))

;; This program is free software; you can redistribute it and/or modify
;; it under the terms of the GNU General Public License as published by
;; the Free Software Foundation, either version 3 of the License, or
;; (at your option) any later version.

;; This program is distributed in the hope that it will be useful,
;; but WITHOUT ANY WARRANTY; without even the implied warranty of
;; MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
;; GNU General Public License for more details.

;; You should have received a copy of the GNU General Public License
;; along with this program.  If not, see <https://www.gnu.org/licenses/>.

;;; Commentary:

;; A satchel is a persisted list of paths that are considered important for
;; the ongoing work.  Thus, we rely on git branch names to distinguish between
;; satchels.  The use case is as follows:
;;
;; * Create a branch and start the ongoing work.
;; * Discover what files are important, place them in a satchel.
;; * When exploring the code base in the current project, you can more easily now
;;   jump to the important files, thus saving time.
;; * Realize you need to work on a different branch - switch to it.
;;   Now the satchel is automatically scoped to the new branch.
;;   If there are files there, jump to them.
;;
;;  So to clarify, satchel persists a set of files residing under a project as
;;  defined by `project'.  In addition, we use git branches to delimit between
;;  different sets of files.

;;; Code:

(require 'vc-git)
(require 'project)

(defgroup satchel nil
  "Store files related to a branch in for easy retrieval."
  :group 'tools)

(defcustom satchel-directory
  (locate-user-emacs-file ".local/satchel/")
  "Where the satchels will be saved."
  :type 'string)

(defvar satchel--default-directory nil
  "Default directory override.")

(defun satchel--ensure-directory ()
  "Create `satchel-directory' if it doesn't exist, else noop."
  (unless (file-exists-p (expand-file-name satchel-directory))
    (make-directory (file-truename satchel-directory) t)))

(defun satchel--name ()
  (cl-flet ((normalize (file-name)
              (string-replace "/" "---" file-name)))
    (let ((default-directory (or satchel--default-directory
                                 (project-root (project-current t)))))
      (file-truename
       (concat satchel-directory
               (concat
                (normalize default-directory)
                "#"
                (normalize (car (vc-git-branches)))))))))

(defun satchel--read ()
  "Read files from the current `satchel-default-directory'.
This is a file named after the path of the directory it refers
to.  There can be several of those files, appended with the
current branch name.  If the file can be found, we read that file
into Lisp data."
  (let ((filename (satchel--name)))
    (when (file-exists-p filename)
      (with-temp-buffer
        (insert-file-contents filename)
        (read (current-buffer))))))

(defun satchel--persist (satchel)
  "Persist the current satchel into storage.
When updating the satchel, we try to persist it to disk, so
that it can easily be retrieved at a later time."
  (let ((filename (satchel--name)))
    (with-temp-buffer
      (insert ";;; -*- lisp-data -*-\n")
      (let ((print-length nil)
            (print-level nil))
        (pp satchel (current-buffer)))
      (write-region nil nil filename nil 'silent))))

(defun satchel--keep-sort-order (completions)
  ;; Small hack to avoid the default sorting order to apply, which is
  ;; alphabetically.
  (lambda (string pred action)
    (if (eq action 'metadata)
        `(metadata (display-sort-function . ,#'identity))
      (complete-with-action action completions string pred))))

(defun satchel--completing-read (prompt satchel)
  "Read the current satchel, and show a completion selection.
We do make sure we keep the order the files are stored in, so
that `satchel-promote' and `satchel-demote' can do its
thing."
  (let ((default (caar satchel)))
    (if satchel
        (completing-read
         (format prompt (file-name-nondirectory default))
         (satchel--keep-sort-order satchel) nil t nil nil default)
      (user-error "Satchel is empty!"))))

;;;###autoload
(defun satchel-place ()
  "Place the current file into the satchel.
It is placed into a satchel controlled by the git branch."
  (interactive)
  (satchel--ensure-directory)
  (let ((satchel (satchel--read))
        (entry (list buffer-file-name)))
    (unless (member entry satchel)
      (setq satchel (append satchel (list entry)))
      (satchel--persist satchel)
      (message "Placed in satchel!"))))

;;;###autoload
(defun satchel-pick ()
  "Choose a file from the current satchel.
After selection, we jump to the chosen file."
  (interactive)
  (find-file
   (satchel--completing-read
    "Satchel pick [%s]: "
    (remove (list buffer-file-name)
            (satchel--read)))))

;;;###autoload
(defun satchel-feeling-lucky (satchel)
  "Jump to the file currently at the top of the satchel."
  (interactive
   (list (caar (remove (list buffer-file-name) (satchel--read)))))
  (if satchel
      (find-file satchel)
    (user-error "Satchel is empty!")))

;;;###autoload
(defun satchel-burn ()
  "Delete one satchel.
This is limited to the one on the current branch."
  (interactive)
  (when (y-or-n-p "Burn this satchel?")
    (satchel--persist nil)))

;;;###autoload
(defun satchel-drop (satchel)
  "Remove one file from the satchel."
  (interactive (list (satchel--read)))
  (when-let ((entry
              (list
               (satchel--completing-read
                "Satchel drop [%s]: "
                satchel))))
    (setq satchel (remove entry satchel))
    (satchel--persist satchel)
    (message "Dropped %s from satchel"
             (file-name-nondirectory (car entry)))))

;;;###autoload
(defun satchel-promote (satchel)
  "Lift a file to the top of the current satchel."
  (interactive (list (satchel--read)))
  (let ((entry
         (list
          (satchel--completing-read
           "Satchel promote [%s]: "
           satchel))))
    (setq satchel (remove entry satchel))
    (push entry satchel)
    (satchel--persist satchel)
    (message "Promoted %s to top in satchel"
             (file-name-nondirectory (car entry)))))

;;;###autoload
(defun satchel-demote (satchel)
  "Push a file to the bottom of the current satchel."
  (interactive (list (satchel--read)))
  (let ((entry
         (list
          (satchel--completing-read
           "Satchel demote [%s]: "
           satchel))))
    (setq satchel (remove entry satchel))
    (setq satchel (append satchel (list entry)))
    (satchel--persist satchel)
    (message "Demoted %s to bottom in satchel"
             (file-name-nondirectory (car entry)))))

;;;###autoload
(defun satchel-default-directory (dir)
  "Set the directory DIR as the default `satchel-default-directory'."
  (interactive "P")
  (setq satchel--default-directory
        (cond
         ((equal dir '(4))
          (project-root (project-current t)))
         ((equal dir '(16))
          (read-file-name "Default satchel: " nil default-directory 'mustmatch)))))

(provide 'satchel)
;;; satchel.el ends here
