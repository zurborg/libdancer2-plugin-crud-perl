latexmk=latexmk
perl=/usr/bin/perl
doc2md=$(perl) ../bin/d2crud-dumpblueprint

all: talk-gpw2015-de.beamer.pdf talk-gpw2015-de.handout.pdf

%.pdf: %.tex
	$(latexmk) -pdf -bibtex $?

clean:
	git clean -xdf .

%.html: %.md
	aglio -i $? -o $@

%.md: %.pm
	$(doc2md) $? default > $@

%.beamer.tex: %.tex %.bib
	@touch $@

%.handout.tex: %.tex %.bib
	@touch $@

.PHONY: all clean
