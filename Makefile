SHELL=/usr/bin/zsh
LATEX=latexmk --pdf

VERSION=$(shell git tag | awk -v FIELDWIDTHS="1 2" '/^v[0-9]{2}/{vn=$$2;if(vn>v){v=vn}}END{v++; printf "v%02d",v}')
GITBRANCH=$(shell git branch --show-current)
GITSTATUS=$(shell git status -s)
AUX=log dvi aux toc lof lot out bbl blg xmpi synctexz synctex.gz fdb_latexmk fls bcf run.xml
CLEANAUXDIR=tex bib abstract

# https://blog.jgc.org/2011/07/gnu-make-recursive-wildcard-function.html
rwildcard=$(foreach d,$(wildcard $1*),$(call rwildcard,$d/,$2) $(filter $(subst *,%,$2),$d)) 

.PHONY: help echoes all see thesis abstract version clean mostlyclean cleanaux cleanimg cleanpdf

default: thesis

update:
	awk -i inplace -v p=1 '/#end aux/{p=1} {if (p) print} /#begin aux/{p=0; $$0="$(AUX)"; for(i=1;i<=NF;i++){printf "*.%s\n",$$i}}' .gitignore
	awk -i inplace '/let NERDTreeIgnore=/ {$$0="$(AUX)"; OFS=", "; for(i=1;i<=NF;i++){$$i=sprintf("\047\\.%s$$\047",$$i)}; printf "let NERDTreeIgnore=[%s]",$$0}' .vimlocal

all: thesis abstract ## compile everything

thesis: thesis.pdf ## compile thesis
abstract: abstract.pdf ## compile abstract

see: ## see thesis
	zathura thesis.pdf &

version: thesis ## release major version
ifeq ($(GITSTATUS),)
ifeq ($(GITBRANCH),master)
	cp thesis.pdf version/DP_Wohlrath_$(VERSION).pdf
	git add version/DP_Wohlrath_$(VERSION).pdf
	git commit -m "$(VERSION) release"
	git tag -a $(VERSION) -m "$(VERSION) release"
else
	$(error "aborted: not on master branch!")
endif
else
	$(error "aborted: uncommited changes!")
endif


# cleaning
clean: cleanaux cleanimg cleanpdf ## clean everything
mostlyclean: cleanaux cleanpdf ## clean but not images 
cleanaux: ## clean auxiliary files
	rm -f $(wildcard $(CLEANAUXWC)) $(call rwildcard,$(CLEANAUXDIR),$(CLEANAUXWC))
cleanimg: ## clean compiled images
cleanpdf: ## clean output pdfs
	rm -f thesis.pdf abstract.pdf


# concrete recipes
thesis.pdf: thesis.tex thesis.xmpdata mffthesis.cls tex/*.tex
	$(LATEX) thesis.tex

abstract.pdf: abstract/abstract.tex abstract/abstract.xmpdata
	$(LATEX) abstract/abstract.tex


# help
echoes: ## echo make variables
	$(info version = $(VERSION))
	$(info aux files = $(wildcard $(CLEANAUXWC)) $(call rwildcard,$(CLEANAUXDIR),$(CLEANAUXWC)))

help: # http://marmelab.com/blog/2016/02/29/auto-documented-makefile.html
	@grep -P '^[a-zA-Z_-]+:.*?## .*$$' $(MAKEFILE_LIST) | sort | awk 'BEGIN {FS = ":.*?## "}; {printf "\033[36m%-20s\033[0m %s\n", $$1, $$2}'


