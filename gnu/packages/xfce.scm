;;; GNU Guix --- Functional package management for GNU
;;; Copyright © 2014, 2015 Sou Bunnbu <iyzsong@gmail.com>
;;; Copyright © 2014, 2015 Mark H Weaver <mhw@netris.org>
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

(define-module (gnu packages xfce)
  #:use-module ((guix licenses) #:hide (freetype))
  #:use-module (guix packages)
  #:use-module (guix download)
  #:use-module (guix utils)
  #:use-module (guix build-system gnu)
  #:use-module (guix build-system glib-or-gtk)
  #:use-module (gnu packages)
  #:use-module (gnu packages pkg-config)
  #:use-module (gnu packages glib)
  #:use-module (gnu packages gtk)
  #:use-module (gnu packages xorg)
  #:use-module (gnu packages xdisorg)
  #:use-module (gnu packages web)
  #:use-module (gnu packages fontutils)
  #:use-module (gnu packages image)
  #:use-module (gnu packages gnome)
  #:use-module (gnu packages pdf)
  #:use-module (gnu packages polkit)
  #:use-module (gnu packages gstreamer)
  #:use-module (gnu packages linux)
  #:use-module (gnu packages photo)
  #:use-module (gnu packages pcre)
  #:use-module (gnu packages pulseaudio))

(define-public gtk-xfce-engine
  (package
    (name "gtk-xfce-engine")
    (version "2.10.1")
    (source (origin
              (method url-fetch)
              (uri (string-append "http://archive.xfce.org/src/xfce/"
                                  name "/" (version-major+minor version) "/"
                                  name "-" version ".tar.bz2"))
              (sha256
               (base32
                "0g86ywkx0ghzhhn96k88p67bbzlm1aqckly85izp07w80l1934ja"))))
    (build-system gnu-build-system)
    (native-inputs
     `(("pkg-config" ,pkg-config)
       ("intltool" ,intltool)))
    (inputs `(("gtk+" ,gtk+-2)))
    (home-page "http://www.xfce.org/")
    (synopsis "GTK+ theme engine for Xfce")
    (description
     "Default GTK+ engine and themes for Xfce Desktop Environment.")
    (license gpl2+)))

(define-public libxfce4util
  (package
    (name "libxfce4util")
    (version "4.12.1")
    (source (origin
              (method url-fetch)
              (uri (string-append "http://archive.xfce.org/xfce/"
                                  (version-major+minor version)
                                  "/src/" name "-" version ".tar.bz2"))
              (sha256
               (base32
                "07c8r3xwx5is298zk77m3r784gmr5y4mh8bbca5zdjqk5vxdwsw7"))))
    (build-system gnu-build-system)
    (native-inputs
     `(("pkg-config" ,pkg-config)
       ("intltool" ,intltool)))
    (propagated-inputs `(("glib" ,glib))) ; required by libxfce4util-1.0.pc
    (home-page "http://www.xfce.org/")
    (synopsis "Basic utility library for Xfce")
    (description
     "A general-purpose utility library with core application support for the
Xfce Desktop Environment.")
    (license lgpl2.0+)))

(define-public xfconf
  (package
    (name "xfconf")
    (version "4.12.0")
    (source (origin
              (method url-fetch)
              (uri (string-append "http://archive.xfce.org/xfce/"
                                  (version-major+minor version)
                                  "/src/" name "-" version ".tar.bz2"))
              (sha256
               (base32
                "0mmi0g30aln3x98y5p507g17pipq0dj0bwypshan8cq5hkmfl44r"))))
    (build-system gnu-build-system)
    (arguments
     '(#:phases
       ;; Run check after install phase to test dbus activation.
       (alist-cons-after
        'install 'check
        (lambda _
          (setenv "HOME" (getenv "TMPDIR")) ; xfconfd requires a writable HOME
          ;; Run test-suite under a dbus session.
          (setenv "XDG_DATA_DIRS" ; for finding org.xfce.Xfconf.service
                  (string-append %output "/share"))
          ;; For the missing '/etc/machine-id'.
          (setenv "DBUS_FATAL_WARNINGS" "0");
          (zero? (system* "dbus-launch" "make" "check")))
        (alist-delete 'check %standard-phases))))
    (native-inputs
     `(("pkg-config" ,pkg-config)
       ("intltool" ,intltool)))
    (propagated-inputs
     ;; libxfconf-0.pc refers to all these.
     `(("glib" ,glib)
       ("dbus" ,dbus)
       ("dbus-glib" ,dbus-glib)))
    (inputs
     `(("libxfce4util" ,libxfce4util)))
    (home-page "http://www.xfce.org/")
    (synopsis "Configuration storage and query system for Xfce")
    (description
     "Settings daemon for Xfce, implemented as a D-Bus-based configuration
storage system.")
    (license lgpl2.0+)))

(define-public libxfce4ui
  (package
    (name "libxfce4ui")
    (version "4.12.0")
    (source (origin
              (method url-fetch)
              (uri (string-append "http://archive.xfce.org/xfce/"
                                  (version-major+minor version)
                                  "/src/" name "-" version ".tar.bz2"))
              (sha256
               (base32
                "11rrhqxnfwx5jls3nlg9s2x8saag9f2zqk9cdm6hr3bs6cr9a781"))))
    (build-system gnu-build-system)
    (native-inputs
     `(("pkg-config" ,pkg-config)
       ("intltool" ,intltool)))
    (propagated-inputs
     `(("gtk+-2" ,gtk+-2)  ; required by libxfce4ui-1.pc
       ("gtk+-3" ,gtk+)    ; required by libxfce4ui-2.pc
       ;; libxfce4kbd-private-2.pc refers to all these.
       ("libxfce4util" ,libxfce4util)
       ("xfconf" ,xfconf)))
    (inputs `(("libsm" ,libsm)
              ("libice" ,libice)
              ("startup-notification" ,startup-notification)))
    (home-page "http://www.xfce.org/")
    (synopsis "Widgets library for Xfce")
    (description
     "Libxfce4ui is the replacement of the old libxfcegui4 library.  It is used
to share commonly used Xfce widgets among the Xfce applications.")
    (license lgpl2.0+)))

(define-public exo
  (package
    (name "exo")
    (version "0.10.3")
    (source (origin
              (method url-fetch)
              (uri (string-append "http://archive.xfce.org/xfce/4.12/src/"
                                  name "-" version ".tar.bz2"))
              (sha256
               (base32
                "1g9651ra395v2fmzb943l68b9pg0rfxc19x97a62crchxwa4nw4m"))))
    (build-system gnu-build-system)
    (native-inputs
     `(("pkg-config" ,pkg-config)
       ("intltool" ,intltool)))
    (propagated-inputs
     ;; exo-1.pc refers to all these.
     `(("gtk+" ,gtk+-2)
       ("libxfce4util" ,libxfce4util)))
    (inputs
     `(("libxfce4ui" ,libxfce4ui)
       ("perl-uri" ,perl-uri)))
    (home-page "http://www.xfce.org/")
    (synopsis "Extension library for Xfce")
    (description
     "An extension library to Xfce.  While Xfce comes with quite a few libraries
that are targeted at desktop development, libexo is targeted at application
development.")
    ;; Libraries are under LGPLv2+, and programs under GPLv2+.
    (license (list gpl2+ lgpl2.1+))))

(define-public garcon
  (package
    (name "garcon")
    (version "0.4.0")
    (source (origin
              (method url-fetch)
              (uri (string-append "http://archive.xfce.org/xfce/4.12/src/"
                                  name "-" version ".tar.bz2"))
              (sha256
               (base32
                "0wm9pjbwq53s3n3nwvsyf0q8lbmhiy2ln3bn5ncihr9vf5cwhzbq"))))
    (build-system gnu-build-system)
    (native-inputs
     `(("pkg-config" ,pkg-config)
       ("intltool" ,intltool)
       ("glib:bin" ,glib "bin")))
    (propagated-inputs
     `(("libxfce4ui" ,libxfce4ui))) ; required by garcon-gtk2-1.pc
    (home-page "http://www.xfce.org/")
    (synopsis "Implementation of the freedesktop.org menu specification")
    (description
     "Garcon is a freedesktop.org compliant menu implementation based on
GLib and GIO.  It was started as a complete rewrite of the former Xfce menu
library called libxfce4menu, which, in contrast to garcon, was lacking menu
merging features essential for loading menus modified with menu editors.")
    (license lgpl2.0+)))

(define-public tumbler
  (package
    (name "tumbler")
    (version "0.1.31")
    (source (origin
              (method url-fetch)
              (uri (string-append "http://archive.xfce.org/src/xfce/tumbler/0.1/"
                                  name "-" version ".tar.bz2"))
              (sha256
               (base32
                "0wvip28gm2w061hn84zp2q4dv947ihylrppahn4cjspzff935zfh"))))
    (build-system gnu-build-system)
    (native-inputs
     `(("pkg-config" ,pkg-config)
       ("intltool" ,intltool)
       ("glib:bin" ,glib "bin") ; need glib-genmarshal
       ("dbus-glib" ,dbus-glib))) ; need dbus-binding-tool
    (propagated-inputs
     `(("glib" ,glib))) ; required by tumbler-1.pc
    (inputs
     `(("dbus" ,dbus)
       ("gdk-pixbuf" ,gdk-pixbuf)
       ("freetype" ,freetype)
       ("libjpeg" ,libjpeg)
       ("libgsf" ,libgsf)
       ("poppler" ,poppler)
       ("gstreamer" ,gstreamer)))
    (home-page "http://www.xfce.org/")
    (synopsis "D-Bus service for applications to request thumbnails")
    (description
     "Tumbler is a D-Bus service for applications to request thumbnails for
various URI schemes and MIME types.  It is an implementation of the thumbnail
management D-Bus specification.")
    (license gpl2+)))

(define-public xfce4-panel
  (package
    (name "xfce4-panel")
    (version "4.12.0")
    (source (origin
              (method url-fetch)
              (uri (string-append "http://archive.xfce.org/xfce/"
                                  (version-major+minor version)
                                  "/src/" name "-" version ".tar.bz2"))
              (sha256
               (base32
                "1c4p3ckghvsad1sj5v8wmar5mh9cbhail9mmhad2f9pwwb10z4ih"))
              (patches (list (search-patch "xfce4-panel-plugins.patch")))))
    (build-system gnu-build-system)
    (arguments
     '(#:configure-flags '("--enable-gtk3")))
    (native-inputs
     `(("pkg-config" ,pkg-config)
       ("intltool" ,intltool)))
    (propagated-inputs
     `(("libxfce4util" ,libxfce4util))) ; required by libxfce4panel-1.0.pc
    (inputs
     `(("exo" ,exo)
       ("garcon", garcon)
       ("libwnck" ,libwnck-1)
       ("libxfce4ui" ,libxfce4ui)))
    (native-search-paths
     (list (search-path-specification
            (variable "X_XFCE4_LIB_DIRS")
            (files '("lib/xfce4")))))
    (home-page "http://www.xfce.org/")
    (synopsis "Xfce desktop panel")
    (description
     "Desktop panel for Xfce, which contains program launchers, window buttons,
applications menu, workspace switcher and more.")
    ;; Libraries are under LGPLv2.1+, and programs under GPLv2+.
    (license (list gpl2+ lgpl2.1+))))

(define-public xfce4-battery-plugin
  (package
    (name "xfce4-battery-plugin")
    (version "1.0.5")
    (source (origin
              (method url-fetch)
              (uri (string-append "http://archive.xfce.org/src/panel-plugins/"
                                  name "/" (version-major+minor version) "/"
                                  name "-" version ".tar.bz2"))
              (sha256
               (base32
                "04gbplcj8z4vg5xbks8cc2jjf62mmf9sdymg90scjwmb82pv2ngn"))))
    (build-system gnu-build-system)
    (native-inputs `(("pkg-config" ,pkg-config)
                     ("intltool" ,intltool)))
    (inputs `(("glib" ,glib)
              ("gtk+" ,gtk+-2)
              ("libxfce4util" ,libxfce4util)
              ("libxfce4ui" ,libxfce4ui)
              ("xfce4-panel" ,xfce4-panel)))
    (home-page
     "http://goodies.xfce.org/projects/panel-plugins/xfce4-battery-plugin")
    (synopsis "Battery monitor panel plugin for Xfce4")
    (description
     "A battery monitor panel plugin for Xfce4, compatible with APM and ACPI.")
    ;; The main plugin code is covered by gpl2+, but the files containing code
    ;; to read the battery state via ACPI or APM are covered by lgpl2.0+.
    (license (list gpl2+ lgpl2.0+))))

(define-public xfce4-clipman-plugin
  (package
    (name "xfce4-clipman-plugin")
    (version "1.2.6")
    (source (origin
              (method url-fetch)
              (uri (string-append "http://archive.xfce.org/src/panel-plugins/"
                                  name "/" (version-major+minor version) "/"
                                  name "-" version ".tar.bz2"))
              (sha256
               (base32
                "19a8gwcqc0r5qqi8w28dc8arqip34m8yxdb87lgps9g5qfcky113"))))
    (build-system gnu-build-system)
    (native-inputs
     `(("intltool" ,intltool)
       ("pkg-config" ,pkg-config)))
    (inputs
     `(("exo" ,exo)
       ("libxfce4ui" ,libxfce4ui)
       ("libxtst" ,libxtst)
       ("xfce4-panel" ,xfce4-panel)))
    (home-page
     "http://goodies.xfce.org/projects/panel-plugins/xfce4-clipman-plugin")
    (synopsis "Clipboard manager for Xfce")
    (description
     "Clipman is a clipboard manager for Xfce.  It keeps the clipboard contents
around while it is usually lost when you close an application.  It is able to
handle text and images, and has a feature to execute actions on specific text by
matching them against regular expressions.")
    (license (list gpl2+))))

(define-public xfce4-pulseaudio-plugin
  (package
    (name "xfce4-pulseaudio-plugin")
    (version "0.2.3")
    (source (origin
              (method url-fetch)
              (uri (string-append "http://archive.xfce.org/src/panel-plugins/"
                                  name "/" (version-major+minor version) "/"
                                  name "-" version ".tar.bz2"))
              (sha256
               (base32
                "0crvb2gyxbnlf46712arg3m2vqx81dixqhqdwss0bngpijy3ca78"))))
    (build-system gnu-build-system)
    (native-inputs
     `(("intltool" ,intltool)
       ("pkg-config" ,pkg-config)))
    (inputs
     `(("exo" ,exo)
       ("libnotify" ,libnotify)
       ("libxfce4ui" ,libxfce4ui)
       ("pulseaudio" ,pulseaudio)
       ("xfce4-panel" ,xfce4-panel)))
    (home-page "http://git.xfce.org/panel-plugins/xfce4-pulseaudio-plugin/")
    (synopsis "PulseAudio panel plugin for Xfce")
    (description
     "Xfce PulseAudio plugin is a plugin for the Xfce panel which provides a
convenient way to adjust the audio volume of the PulseAudio sound system and
to an auto mixer tool like pavucontrol.  It can optionally handle multimedia
keys for controlling the audio volume.")
    (license gpl2+)))

(define-public xfce4-appfinder
  (package
    (name "xfce4-appfinder")
    (version "4.12.0")
    (source (origin
              (method url-fetch)
              (uri (string-append "http://archive.xfce.org/xfce/"
                                  (version-major+minor version)
                                  "/src/" name "-" version ".tar.bz2"))
              (sha256
               (base32
                "0ry5hin8xhgnkmm9vs7jq8blk1cnbyr0s18nm1j6nsm7360abm1a"))))
    (build-system gnu-build-system)
    (native-inputs
     `(("pkg-config" ,pkg-config)
       ("intltool" ,intltool)))
    (inputs
     `(("garcon" ,garcon)
       ("libxfce4ui" ,libxfce4ui)))
    (home-page "http://www.xfce.org/")
    (synopsis "Xfce application finder")
    (description
     "Application finder for Xfce, it will show the applications installed on
your system in categories, so you can quickly find and launch them.")
    (license gpl2+)))

(define-public xfce4-session
  (package
    (name "xfce4-session")
    (version "4.12.0")
    (source (origin
              (method url-fetch)
              (uri (string-append "http://archive.xfce.org/xfce/"
                                  (version-major+minor version)
                                  "/src/" name "-" version ".tar.bz2"))
              (sha256
               (base32
                "01kvbd09c06j20n155hracsgrq06rlmfgdywffjsvlwpn19m9j38"))
              (patches
               ;; See: https://bugzilla.xfce.org/show_bug.cgi?id=12282
               (list (search-patch "xfce4-session-fix-xflock4.patch")))
              (modules '((guix build utils)))
              (snippet
               '(begin
                  (substitute* "xfsm-shutdown-helper/main.c"
                    (("/sbin/shutdown -h now")  "halt")
                    (("/sbin/shutdown -r now")  "restart")
                    (("/usr/sbin/pm-suspend")   "pm-suspend")
                    (("/usr/sbin/pm-hibernate") "pm-hibernate"))
                  #t))))
    (build-system gnu-build-system)
    (arguments
     '(#:configure-flags
       (list (string-append "--with-xsession-prefix=" %output))))
    (native-inputs
     `(("pkg-config" ,pkg-config)
       ("intltool" ,intltool)))
    (inputs
     `(("iceauth" ,iceauth)
       ("upower" ,upower)
       ("polkit" ,polkit)
       ("libsm" ,libsm)
       ("libwnck" ,libwnck-1)
       ("libxfce4ui" ,libxfce4ui)))
    (home-page "http://www.xfce.org/")
    (synopsis "Xfce session manager")
    (description
     "Session manager for Xfce, it will restore your session on startup and
allows you to shutdown the computer from Xfce.")
    (license gpl2+)))

(define-public xfce4-settings
  (package
    (name "xfce4-settings")
    (version "4.12.0")
    (source (origin
              (method url-fetch)
              (uri (string-append "http://archive.xfce.org/xfce/"
                                  (version-major+minor version)
                                  "/src/" name "-" version ".tar.bz2"))
              (sha256
               (base32
                "108za1cmjslwzkdl76x9kwxkq8z734kg9nz8rxk057f10pqwxgh4"))
              (patches
               (list (search-patch "xfce4-settings-defaults.patch")))))
    (build-system gnu-build-system)
    (native-inputs
     `(("pkg-config" ,pkg-config)
       ("intltool" ,intltool)))
    (inputs
     `(("exo" ,exo)
       ("garcon" ,garcon)
       ("libnotify" ,libnotify)
       ("libxcursor", libxcursor)
       ("libxi" ,libxi)
       ("libxklavier" ,libxklavier)
       ("libxrandr" ,libxrandr)
       ("libxfce4ui" ,libxfce4ui)
       ("upower" ,upower)
       ("xf86-input-libinput" ,xf86-input-libinput)))
    (home-page "http://www.xfce.org/")
    (synopsis "Xfce settings manager")
    (description
     "Settings manager for Xfce, it can control various aspects of the desktop
like appearance, display, keyboard and mouse settings.")
    (license gpl2+)))

(define-public thunar
  (package
    (name "thunar")
    (version "1.6.6")
    (source (origin
              (method url-fetch)
              (uri (string-append "http://archive.xfce.org/xfce/4.12/src/"
                                  "Thunar-" version ".tar.bz2"))
              (sha256
               (base32
                "1cl9v3rdzipyyxml3pyrzspxfmmssz5h5snpj18irq4an42539dr"))))
    (build-system gnu-build-system)
    (native-inputs
     `(("pkg-config" ,pkg-config)
       ("intltool" ,intltool)))
    (inputs
     `(("exo" ,exo)
       ("libexif" ,libexif)
       ("libgudev" ,libgudev)
       ("libnotify" ,libnotify)
       ("libxfce4ui" ,libxfce4ui)
       ("pcre" ,pcre)
       ("xfce4-panel" ,xfce4-panel)
       ("startup-notification" ,startup-notification)))
    (home-page "http://www.xfce.org/")
    (synopsis "Xfce file manager")
    (description
     "A modern file manager for graphical desktop, aiming to be easy-to-use and
fast.")
    (license gpl2+)))

(define-public thunar-volman
  (package
    (name "thunar-volman")
    (version "0.8.1")
    (source (origin
              (method url-fetch)
              (uri (string-append "http://archive.xfce.org/xfce/4.12/src/"
                                  name "-" version ".tar.bz2"))
              (sha256
               (base32
                "1gf259n1v3y23n1zlkhyr6r0i8j59rnl1cmxvxj6la9cwdfbn22s"))))
    (build-system gnu-build-system)
    (native-inputs
     `(("pkg-config" ,pkg-config)
       ("intltool" ,intltool)))
    (inputs
     `(("exo" ,exo)
       ("libgudev" ,libgudev)
       ("libnotify" ,libnotify)
       ("libxfce4ui" ,libxfce4ui)))
    (home-page "http://www.xfce.org/")
    (synopsis "Removable media manager for Thunar")
    (description
     "Thunar-volman is an extension for the Thunar File Manager, which enables
automatic management of removable drives and media.  For example, if
thunar-volman is installed and configured properly, and you plug in your
digital camera, it will automatically spawn your preferred photo application
and import the new pictures from your camera.")
    (license gpl2+)))

(define-public xfwm4
  (package
    (name "xfwm4")
    (version "4.12.0")
    (source (origin
              (method url-fetch)
              (uri (string-append "http://archive.xfce.org/xfce/"
                                  (version-major+minor version)
                                  "/src/" name "-" version ".tar.bz2"))
              (sha256
               (base32
                "0fnc2ps4k733n9qfpxrz047h1myyqjzxczl7fmkjmqwshvicpx19"))))
    (build-system gnu-build-system)
    (native-inputs
     `(("pkg-config" ,pkg-config)
       ("intltool" ,intltool)))
    (inputs
     `(("libdrm" ,libdrm)
       ("libwnck" ,libwnck-1)
       ("libxcomposite" ,libxcomposite)
       ("libxdamage" ,libxdamage)
       ("libxfce4ui" ,libxfce4ui)
       ("libxrandr" ,libxrandr)))
    (home-page "http://www.xfce.org/")
    (synopsis "Xfce window manager")
    (description
     "Window manager for Xfce, it handles the placement of windows
on the screen.")
    (license gpl2+)))

(define-public xfdesktop
  (package
    (name "xfdesktop")
    (version "4.12.0")
    (source (origin
              (method url-fetch)
              (uri (string-append "http://archive.xfce.org/xfce/"
                                  (version-major+minor version)
                                  "/src/" name "-" version ".tar.bz2"))
              (sha256
               (base32
                "1ivzgg4792nid6wcgd1nq5vc3z0y5ip6ymq7ci5j2qkp663qnykf"))))
    (build-system gnu-build-system)
    (native-inputs
     `(("pkg-config" ,pkg-config)
       ("intltool" ,intltool)))
    (inputs
     `(("exo" ,exo)
       ("garcon" ,garcon)
       ("libnotify" ,libnotify)
       ("libwnck" ,libwnck-1)
       ("libxfce4ui" ,libxfce4ui)
       ("thunar" ,thunar)))
    (home-page "http://www.xfce.org/")
    (synopsis "Xfce desktop manager")
    (description
     "Desktop manager for Xfce, it sets the background color or image with
optional application menu or icons for minimized applications or launchers,
devices and folders.")
    (license gpl2+)))

(define-public xfce4-terminal
  (package
    (name "xfce4-terminal")
    (version "0.6.3")
    (source (origin
              (method url-fetch)
              (uri (string-append "http://archive.xfce.org/src/apps/" name "/"
                                  (version-major+minor version) "/"
                                  name "-" version ".tar.bz2"))
              (sha256
               (base32
                "023y0lkfijifh05yz8grimxadqpi98mrivr00sl18nirq8b4fbwi"))))
    (build-system gnu-build-system)
    (native-inputs
     `(("pkg-config" ,pkg-config)
       ("intltool" ,intltool)))
    (inputs
     `(("libxfce4ui" ,libxfce4ui)
       ("vte" ,vte/gtk+-2)))
    (home-page "http://www.xfce.org/")
    (synopsis "Xfce terminal emulator")
    (description
     "A lightweight and easy to use terminal emulator for Xfce.  Features
include a simple configuration interface, the ability to use multiple tabs
with terminals within a single window, the possibility to have a
pseudo-transparent terminal background, and a compact mode (where both the
menubar and the window decorations are hidden) that helps you to save space
on your desktop.")
    (license gpl2+)))

(define-public xfce
  (package
    (name "xfce")
    (version (package-version xfce4-session))
    (source #f)
    (build-system glib-or-gtk-build-system)
    (arguments
     '(#:modules ((guix build gnu-build-system)
                  (guix build glib-or-gtk-build-system)
                  (guix build utils)
                  (srfi srfi-26))
       #:phases
       (alist-replace
        'install
        (lambda* (#:key outputs #:allow-other-keys)
          (let* ((out  (assoc-ref outputs "out"))
                 (bin  (string-append out "/bin"))
                 (prog (string-append bin "/startxfce4")))
            (mkdir-p bin)
            (symlink (string-append
                      (assoc-ref %build-inputs "xfce4-session")
                      "/bin/startxfce4")
                     prog)
            (wrap-program prog
              ;; For xfce4-panel plugins.
              `("X_XFCE4_LIB_DIRS" = ,(list (getenv "X_XFCE4_LIB_DIRS"))))))
        (map (cut assq <> %standard-phases)
             '(set-paths install glib-or-gtk-wrap)))))
    (propagated-inputs
     `(("exo"                  ,exo)
       ("garcon"               ,garcon)
       ("gnome-icon-theme"     ,gnome-icon-theme)
       ("gtk-xfce-engine"      ,gtk-xfce-engine)
       ("hicolor-icon-theme"   ,hicolor-icon-theme)
       ("shared-mime-info"     ,shared-mime-info)
       ("thunar"               ,thunar)
       ("thunar-volman"        ,thunar-volman)
       ("tumlber"              ,tumbler)
       ("xfce4-appfinder"      ,xfce4-appfinder)
       ("xfce4-panel"          ,xfce4-panel)
       ("xfce4-session"        ,xfce4-session)
       ("xfce4-settings"       ,xfce4-settings)
       ("xfce4-terminal"       ,xfce4-terminal)
       ("xfconf"               ,xfconf)
       ("xfdesktop"            ,xfdesktop)
       ("xfwm4"                ,xfwm4)
       ;; Panel plugins.
       ("xfce4-battery-plugin"    ,xfce4-battery-plugin)
       ("xfce4-clipman-plugin"    ,xfce4-clipman-plugin)
       ("xfce4-pulseaudio-plugin" ,xfce4-pulseaudio-plugin)))
    (home-page "http://www.xfce.org/")
    (synopsis "Desktop environment (meta-package)")
    (description
     "Xfce is a lightweight desktop environment.  It aims to be fast and low on
system resources, while still being visually appealing and user friendly.")
    (license gpl2+)))
