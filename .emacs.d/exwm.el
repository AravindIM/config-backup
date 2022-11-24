;; Phoenix's Desktop Environment Config for EXWM

;; Variables
(defvar emacs/frame-transparency '(90 . 90))
(defvar emacs/frame-transparency '(90 . 90))

;; Environment Variables
;;(setenv "DBUS_SESSION_BUS_ADDRESS" "unix:path=/run/user/1000/bus")

;; Transparency
(set-frame-parameter (selected-frame) 'alpha emacs/frame-transparency)
(add-to-list 'default-frame-alist `(alpha . ,emacs/frame-transparency))
(set-frame-parameter (selected-frame) 'fullscreen 'maximized)
(add-to-list 'default-frame-alist '(fullscreen .maximized))

;; Remove the initial emacs scratch buffer message
(setq initial-scratch-message "")


;; Function Definitions
(defun exwm/run-in-background (command)
  (let ((command-parts (split-string command "[ ]+")))
    (apply #'call-process `(,(car command-parts) nil 0 nil ,@(cdr command-parts)))))


(defun exwm/set-wallpaper ()
  (interactive)
  (start-process-shell-command
   "feh" nil "feh --randomize --bg-fill ~/Pictures/Wallpapers/"))


(defvar exwm/panel-process nil
  "Holds the process of the running panel instance, if any")


(defun exwm/start-panel ()
  (interactive)
  (setq exwm/panel-process (start-process-shell-command "polybar" nil "polybar main"))
  (set-process-query-on-exit-flag (get-process "polybar") nil))


(defun exwm/kill-panel ()
  (interactive)
  (when exwm/panel-process
    (ignore-errors
      (kill-process exwm/panel-process)))
  (setq exwm/panel-process nil))

(defun exwm/restart-panel ()
  (interactive)
  (exwm/kill-panel)
  (exwm/start-panel))


(defun exwm/send-polybar-hook (module-name hook-index)
  (start-process-shell-command "polybar-msg" nil (format "polybar-msg hook %s %s" module-name hook-index)))


(defun exwm/send-polybar-exwm-workspace ()
  (exwm/send-polybar-hook "exwm-workspace" 1))


(defun exwm/init-hook ()
  (setq confirm-kill-emacs nil)
  (exwm/run-in-background "lxsession")
  (start-process-shell-command "picom" nil "picom -b")
  (exwm-workspace-switch-create 1)
  (exwm/start-panel)
  (start-process-shell-command "xinput" nil "xinput set-prop 'SYNA8006:00 06CB:CD8B Touchpad' 'libinput Natural Scrolling Enabled' 1")
  (start-process-shell-command "xsetroot" nil "xsetroot -cursor_name left_ptr")
  (exwm/run-in-background "xss-lock -- slock")
  (exwm/run-in-background "nm-applet")
  (exwm/run-in-background "pasystray")
  (exwm/run-in-background "blueman-applet")
  (exec-path-from-shell-initialize)
  (dmenu-initialize)
  (dmenu--cache-executable-files))


(defun exwm/update-class ()
  (exwm-workspace-rename-buffer exwm-class-name))


(defun exwm/update-title ()
  (pcase exwm-class-name
    ("Brave-browser" (exwm-workspace-rename-buffer (format "Brave: %s" exwm-title)))
    ("firefox-default" (exwm-workspace-rename-buffer (format "Firefox: %s" exwm-title)))))


;; Exwm Package configs

(use-package exec-path-from-shell)

(use-package dmenu)


(use-package exwm
  :config
  (setq exwm-workspace-number 10)

  (add-hook 'exwm-update-class-hook #'exwm/update-class)
  (add-hook 'exwm-update-title-hook #'exwm/update-title)

  (add-hook 'exwm-workspace-switch-hook #'exwm/send-polybar-exwm-workspace)
  
  (add-hook 'exwm-init-hook #'exwm/init-hook)

  (exwm/set-wallpaper)

  (setq exwm-workspace-warp-cursor t)

  (setq mouse-autoselect-window t
	focus-follows-mouse t)

  (start-process-shell-command "xmodmap" nil "xmodmap ~/.emacs.d/exwm/Xmodmap")

  
  (setq exwm-input-prefix-keys
	'(?\C-x
	  ?\C-u
	  ?\C-h
	  ?\M-x
	  ?\M-`
	  ?\M-&
	  ?\M-:
	  ?\C-\M-j
	  ?\C-\ ))

  (define-key exwm-mode-map [?\C-q] 'exwm-input-send-next-key)

  
  ;; EXWM Keybindings
  (setq exwm-input-global-keys
	`(
	  ;; Reset to line mode. C-c C-k switches to char mode
	  ([?\s-r] . exwm-reset)

	  ;; Move between windows
	  ([s-left .windmove-left])
	  ([s-right] windmove-up)
	  ([s-up] . windmove-up)
	  ([s-down] . windmove-down)

	  ([?\s-&] . (lambda (command)
		       (interactive (list (read-shell-command "$ ")))
		       (start-process-shell-command command nil command)))

	  ;; Switch workspace
	  ([?\s-w] . exwm-workspace-switch)

	  ;; Dmenu
	  ([?\s-p] . dmenu)

	  ;; vterm
	  ([s-S-return] . vterm)

	  ;; M-x and s-x now does the same
	  ([?\s-x] . execute-extended-command)

	  ;; Kill currently open buffer/window
	  ([?\s-C] . kill-this-buffer)

	  ,@(mapcar (lambda (i)
		       `(,(kbd (format "s-%d" i)) .
			 (lambda ()
			   (interactive)
			   (exwm-workspace-switch-create ,i))))
		    (number-sequence 0 9))

	  ,@(mapcar (lambda (i)
		       `(,(kbd (format "s-%s" (nth i '(\) \! \@ \# \$ \% \^ \& \* \()))) .
			 (lambda ()
			   (interactive)
			   (exwm-workspace-move-window ,i))))
		     (number-sequence 0 9))))
  (exwm-enable))


(use-package desktop-environment
  :after exwm
  :config (desktop-environment-mode)
  :custom
  (desktop-environment-brightness-small-increment "2%+")
  (desktop-environment-brightness-small-decrement "2%-")
  (desktop-environment-brightness-normal-increment "5%+")
  (desktop-environment-brightness-normal-decrement "5%-"))


(server-start)
