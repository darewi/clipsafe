# Copyright (c) 2008 Ross Palmer Mohn <rpmohn at waxandwane dot org>
# This file is part of cliPSafe.
# See gpl.txt file for license details.

VERSION = 1.1

SRC = clipsafe.hdr Pwsafe.pl Complete.pl clipsafe.pl

clipsafe: ${SRC}
	@echo "cat ${SRC} >$@"
	@cat ${SRC} >$@
	@chmod 755 $@

clean:
	@echo cleaning
	@rm -f clipsafe clipsafe-${VERSION}.tar.gz clipsafe-${VERSION}.tar.gz.sha1

dist: clipsafe
	@echo creating dist tarball
	@tar czf clipsafe-${VERSION}.tar.gz clipsafe
	@sha1sum -b clipsafe-${VERSION}.tar.gz > clipsafe-${VERSION}.tar.gz.sha1

.PHONY: clean dist
