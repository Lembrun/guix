;;; guix-emacs.el --- Emacs packages installed with Guix

;; Copyright © 2014 Alex Kost <alezost@gmail.com>

;; This file is part of GNU Guix.

;; GNU Guix is free software; you can redistribute it and/or modify
;; it under the terms of the GNU General Public License as published by
;; the Free Software Foundation, either version 3 of the License, or
;; (at your option) any later version.

;; GNU Guix is distributed in the hope that it will be useful,
;; but WITHOUT ANY WARRANTY; without even the implied warranty of
;; MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
;; GNU General Public License for more details.

;; You should have received a copy of the GNU General Public License
;; along with this program.  If not, see <http://www.gnu.org/licenses/>.

;;; Commentary:

;; This file provides auxiliary code for working with Emacs packages
;; installed with Guix.

;;; Code:

(require 'guix-profiles)

(defcustom guix-emacs-activate-after-operation t
  "Activate Emacs packages after installing.
If nil, do not load autoloads of the Emacs packages after
they are successfully installed."
  :type 'boolean
  :group 'guix)

(defvar guix-emacs-autoloads nil
  "List of the last loaded Emacs autoloads.")

(defun guix-emacs-directory (&optional profile)
  "Return directory with Emacs packages installed in PROFILE.
If PROFILE is nil, use `guix-user-profile'."
  (expand-file-name "share/emacs/site-lisp"
                    (or profile guix-user-profile)))

(defun guix-emacs-find-autoloads-in-directory (directory)
  "Return list of Emacs 'autoloads' files in DIRECTORY."
  (directory-files directory 'full-name "-autoloads\\.el\\'" 'no-sort))

(defun guix-emacs-subdirs (directory)
  "Return list of DIRECTORY subdirectories."
  (cl-remove-if (lambda (file)
                  (or (string-match-p (rx "/." string-end) file)
                      (string-match-p (rx "/.." string-end) file)
                      (not (file-directory-p file))))
                (directory-files directory 'full-name nil 'no-sort)))

(defun guix-emacs-find-autoloads (&optional profile)
  "Return list of autoloads of Emacs packages installed in PROFILE.
If PROFILE is nil, use `guix-user-profile'.
Return nil if there are no emacs packages installed in PROFILE."
  (let ((elisp-root-dir (guix-emacs-directory profile)))
    (if (file-directory-p elisp-root-dir)
        (let ((elisp-pkgs-dir (expand-file-name "guix.d" elisp-root-dir))
              (root-autoloads (guix-emacs-find-autoloads-in-directory
                               elisp-root-dir)))
          (if (file-directory-p elisp-pkgs-dir)
              (let ((pkgs-autoloads
                     (cl-mapcan #'guix-emacs-find-autoloads-in-directory
                                (guix-emacs-subdirs elisp-pkgs-dir))))
                (append root-autoloads pkgs-autoloads))
            root-autoloads))
      (message "Directory '%s' does not exist." dir)
      nil)))

;;;###autoload
(defun guix-emacs-load-autoloads (&optional all)
  "Load autoloads for Emacs packages installed in a user profile.
Add autoloads directories to `load-path'.
If ALL is nil, activate only those packages that were installed
after the last activation, otherwise activate all Emacs packages
installed in `guix-user-profile'."
  (interactive "P")
  (let* ((autoloads (guix-emacs-find-autoloads))
         (files (if all
                    autoloads
                  (cl-nset-difference autoloads guix-emacs-autoloads
                                      :test #'string=))))
    (dolist (file files)
      (cl-pushnew (file-name-directory file) load-path
                  :test #'string=)
      (load file 'noerror))
    (setq guix-emacs-autoloads autoloads)))

(defun guix-emacs-load-autoloads-maybe ()
  "Load autoloads for Emacs packages if needed.
See `guix-emacs-activate-after-operation' for details."
  (and guix-emacs-activate-after-operation
       (guix-emacs-load-autoloads)))

(provide 'guix-emacs)

;;; guix-emacs.el ends here
