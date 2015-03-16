latexmk=latexmk
perl=/usr/bin/perl
doc2md=$(perl) ../bin/d2crud-dumpblueprint

all: talk-gpw2015-de.pdf

%.pdf: %.tex %.bib
	$(latexmk) -pdf -bibtex $?

clean:
	git clean -xdf .

%.html: %.md
	aglio -i $? -o $@

%.md: %.pm
	$(doc2md) $? default > $@

.PHONY: all clean
