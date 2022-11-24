;; This is an operating system configuration generated
;; by the graphical installer.

(use-modules (gnu)
	     (gnu packages shells)
	     (gnu packages shellutils)
	     (gnu packages vim)
	     (gnu packages ncurses)
	     (gnu packages ssh)
	     (gnu packages version-control)
	     (gnu packages linux)
	     (gnu packages networking)
	     (gnu packages audio)
	     (gnu packages pulseaudio)
	     (gnu packages video)
	     (gnu packages xorg)
	     (gnu packages xdisorg)
	     (gnu packages compton)
	     (gnu packages fonts)
	     (gnu packages gnome)
	     (gnu packages emacs)
	     (gnu packages emacs-xyz)
	     (gnu packages wm)
	     (gnu packages suckless)
	     (gnu packages image-viewers)
	     (gnu packages xfce)
	     (gnu packages lxde)
	     (gnu packages dunst)
	     (gnu packages certs)
	     (gnu services)
	     (nongnu packages linux)
             (nongnu system linux-initrd))

(use-service-modules desktop networking ssh xorg pm base dbus docker virtualization)

(define %backlight-udev-rule
  (udev-rule
   "90-backlight.rules"
   (string-append "ACTION==\"add\", SUBSYSTEM==\"backlight\", "
                  "RUN+=\"/run/current-system/profile/bin/chgrp video /sys/class/backlight/%k/brightness\""
                  "\n"
                  "ACTION==\"add\", SUBSYSTEM==\"backlight\", "
                  "RUN+=\"/run/current-system/profile/bin/chmod g+w /sys/class/backlight/%k/brightness\"")))

(define %my-desktop-services
  (modify-services %desktop-services
		   (udev-service-type config =>
                                      (udev-configuration (inherit config)
                                                          (rules (cons %backlight-udev-rule
                                                                       (udev-configuration-rules config)))))
		   (guix-service-type config => (guix-configuration
						 (inherit config)
						 (substitute-urls
						  (append (list "https://substitutes.nonguix.org")
							  %default-substitute-urls))
						 (authorized-keys
						  (append (list (plain-file "non-guix.pub"
									    "(public-key (ecc (curve Ed25519) (q #C1FD53E5D4CE971933EC50C9F307AE2171A2D3B52C804642A7A35F84F3A4EA98#)))"))
							  %default-authorized-guix-keys))))))

(operating-system
  (kernel linux)
  (initrd microcode-initrd)
  (firmware (list linux-firmware sof-firmware))
  (locale "en_GB.utf8")
  (timezone "Asia/Kolkata")
  (keyboard-layout (keyboard-layout "us"))
  (host-name "ph03n1x")
  (users (cons* (user-account
                  (name "aim")
                  (comment "Ph03n1x AIM")
                  (group "users")
                  (home-directory "/home/aim")
		  (shell (file-append zsh "/bin/zsh"))
                  (supplementary-groups
                    '("wheel" "netdev" "audio" "video" "lp" "docker" "libvirt" "kvm")))
                %base-user-accounts))
  (packages
    (append
     (list
      ;; Basic Packages
      vim
      ncurses
      tlp
      openssh
      git

      ;; Shell utils
      zsh-syntax-highlighting
      zsh-autosuggestions

      ;; Bluetooth
      bluez
      blueman

      ;; Audio
      bluez-alsa
      pulseaudio
      alsa-utils
      pamixer
      pasystray

      ;; Video
      ffmpeg

      ;; Xorg
      xinput
      xsetroot
      xmodmap
      xrandr

      ;; Xdisorg
      xss-lock

      ;; Compton
      picom

      ;;Font
      font-fira-code
      font-awesome
      font-dejavu
      font-google-noto
      font-google-roboto
      font-iosevka
      font-lato
      font-liberation
      font-montserrat

      ;;Gnome Themes
      hicolor-icon-theme
      adwaita-icon-theme
      gnome-icon-theme

      ;; Gnome Virtual File System for USB Mounting
      gvfs

      ;; Emacs and EXWM
      emacs
      emacs-exwm
      emacs-desktop-environment

      ;; WM
      polybar
      dunst
      brightnessctl
      libnotify

      ;; Image Viewers
      feh

      ;; XFCE
      thunar

      ;;LXDE
      lxsession

      ;; Eclipse Java
      eclipse-java

      ;; Certs
      nss-certs)
     %base-packages))
  
  (services
    (append
     (list (service tor-service-type)
	   (screen-locker-service slock)
	   (service tlp-service-type
		    (tlp-configuration
		     (cpu-scaling-governor-on-ac (list "performance"))
		     (sched-powersave-on-bat? #t)))
	   (bluetooth-service #:bluez bluez #:auto-enable? #t)
	   (simple-service 'blueman dbus-root-service-type (list blueman))
            (set-xorg-configuration
              (xorg-configuration
               (keyboard-layout keyboard-layout)))
	    (service docker-service-type)
	    (service libvirt-service-type
		     (libvirt-configuration
		      (unix-sock-group "libvirt")
		      (tls-port "16555")))
	    (service virtlog-service-type
		     (virtlog-configuration
		      (max-clients 1000))))
      %my-desktop-services))
  (bootloader
    (bootloader-configuration
      (bootloader grub-efi-bootloader)
      (targets '("/boot/efi"))
      (keyboard-layout keyboard-layout)))
  (mapped-devices
    (list (mapped-device
            (source
              (uuid "502effea-17b1-4e2f-aff3-4bbdd834c84c"))
            (target "cryptroot")
            (type luks-device-mapping))))
  (file-systems
    (cons* (file-system
             (mount-point "/")
             (device "/dev/mapper/cryptroot")
             (type "btrfs")
             (dependencies mapped-devices))
           (file-system
             (mount-point "/boot/efi")
             (device (uuid "E363-2F75" 'fat32))
             (type "vfat"))
           %base-file-systems)))
