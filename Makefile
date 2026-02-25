PREFIX  ?= /usr/local
BINDIR  ?= $(PREFIX)/bin
MANDIR  ?= $(PREFIX)/share/man

.PHONY: install install-bin install-man uninstall uninstall-bin uninstall-man

install: install-bin install-man

install-bin:
	install -d $(DESTDIR)$(BINDIR)
	install -m 755 git-wt $(DESTDIR)$(BINDIR)/git-wt

install-man:
	install -d $(DESTDIR)$(MANDIR)/man1
	install -m 644 doc/git-wt.1 $(DESTDIR)$(MANDIR)/man1/git-wt.1

uninstall: uninstall-bin uninstall-man

uninstall-bin:
	rm -f $(DESTDIR)$(BINDIR)/git-wt

uninstall-man:
	rm -f $(DESTDIR)$(MANDIR)/man1/git-wt.1
