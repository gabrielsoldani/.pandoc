.SUFFIXES: .md .pdf .html

.md.html:
	pandoc $(PANDOCFLAGS) -o $@ $<

.md.pdf:
	pandoc $(PANDOCFLAGS) -o $@ $<
