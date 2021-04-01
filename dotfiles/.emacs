(custom-set-variables
 ;; custom-set-variables was added by Custom.
 ;; If you edit it by hand, you could mess it up, so be careful.
 ;; Your init file should contain only one such instance.
 ;; If there is more than one, they won't work right.
 '(case-fold-search t)
 '(current-language-environment "Latin-1")
 '(default-input-method "latin-1-prefix")
 '(diff-command "diff")
 '(emerge-diff-program "diff")
 '(emerge-diff3-program "diff3")
 '(global-font-lock-mode t nil (font-lock))
 '(inhibit-startup-screen t)
 '(package-selected-packages (quote (groovy-mode)))
 '(printer-name "big-toshiba")
 '(ps-printer-name "\\\\T61-LARRY-B\\HPO7700_PS"))
(custom-set-faces
 ;; custom-set-faces was added by Custom.
 ;; If you edit it by hand, you could mess it up, so be careful.
 ;; Your init file should contain only one such instance.
 ;; If there is more than one, they won't work right.
 )
;; Use just newlines for new files by default.
(setq default-buffer-file-coding-system 'utf-8)
(setq-default indent-tabs-mode nil)
(setq-default tab-width 4)
(setq viper-mode t)
(setq viper-inhibit-startup-message 't)
(setq viper-expert-level '3)
(require 'viper)

(add-hook 'comint-output-filter-functions
    'shell-strip-ctrl-m nil t)
(add-hook 'comint-output-filter-functions
    'comint-watch-for-password-prompt nil t)

;; use groovy-mode when file ends in .groovy or has #!/bin/groovy at start
(autoload 'groovy-mode "groovy-mode" "Groovy editing mode." t)
(add-to-list 'auto-mode-alist '("\.groovy$" . groovy-mode))
(add-to-list 'interpreter-mode-alist '("groovy" . groovy-mode))

;; Add 3rd-party code directories to the load path.
;; (setq load-path (append load-path '("c:/ProgramFiles/GNU/emacs-23.1/site-lisp/nxml/")))
;; (setq load-path (append load-path '("c:/ProgramFiles/GNU/emacs-23.1/site-lisp/nxhtml/")))
;; (setq load-path (append load-path '("c:/ProgramFiles/GNU/emacs-23.1/site-lisp/anything/")))
;; (setq load-path (append load-path '("c:/ProgramFiles/GNU/emacs-23.1/site-lisp/elib/")))
;; (setq load-path (append load-path '("c:/ProgramFiles/GNU/emacs-23.1/site-lisp/ecb-2.40")))
;; (setq load-path (append load-path '("c:/ProgramFiles/GNU/emacs-23.1/site-lisp/cedit-1.0pre7/speedbar")))

;; gtags support.
;; (autoload 'gtags-mode "gtags" "" t)

;; anything stuff.
;; Rexexp search across files and more!
;; (require 'anything-config)
;; (require 'anything-extension)

;; nxml stuff.
;; /usr/share/emacs/site-lisp/tcc-nxml-emacs:  Add these lines
;;      to your .emacs to use nxml-mode.  For documentation of
;;      this mode, see http://www.nmt.edu/tcc/help/pubs/nxml/

;;--
;; Make sure nxml-mode can autoload
;;--
;; (load "c:/ProgramFiles/GNU/emacs-23.1/site-lisp/nxml/rng-auto.el")

;;--
;; Load nxml-mode for files ending in .xml, .xsl, .rng, .xhtml
;;--
;; (setq auto-mode-alist
;;       (cons '("\\.\\(xml\\|xsl\\|rng\\|xhtml\\)\\'" . nxml-mode)
;;             auto-mode-alist))

;;--
;; Run the nxhtml autostart.
;;--
;; (load "c:/ProgramFiles/GNU/emacs-23.1/site-lisp/nxhtml/autostart.el")

;; write emacs backup files in one directory
(defun make-backup-file-name (file)
(concat "~/.emacs_backups/" (file-name-nondirectory file) "~"))


;; Load CEDET.
;; See cedet/common/cedet.info for configuration details.
;;(load-file "c:/ProgramFiles/GNU/emacs-23.1/site-lisp/cedet-1.0pre7/common/cedet.el")


;; ecb stuff (contains cedit).
;;(require 'ecb)


;; Enable EDE (Project Management) features
;; (global-ede-mode 1)

;; Enable EDE for a pre-existing C++ project
;; (ede-cpp-root-project "NAME" :file "~/myproject/Makefile")

;; Enabling Semantic (code-parsing, smart completion) features
;; Select one of the following:

;; * This enables the database and idle reparse engines
;; (semantic-load-enable-minimum-features)

;; * This enables some tools useful for coding, such as summary mode
;;   imenu support, and the semantic navigator
;; (semantic-load-enable-code-helpers)

; Enable template insertion menu
;; (global-srecode-minor-mode 1)

;; (defun my-semantic-hook ()
;; (imenu-add-to-menubar "TAGS"))
;; (add-hook 'semantic-init-hooks 'my-semantic-hook)
;;
(require 'package)
(add-to-list 'package-archives
    '("melpa" . "http://melpa.milkbox.net/packages/") t)
(package-initialize)

(require 'yaml-mode)
(add-to-list 'auto-mode-alist '("\\.yml\\'" . yaml-mode))


(add-hook 'yaml-mode-hook
  '(lambda ()
    (define-key yaml-mode-map "\C-m" 'newline-and-indent)))
