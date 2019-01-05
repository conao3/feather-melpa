TOP := $(abspath $(dir $(lastword $(MAKEFILE_LIST))))

-include ./config.mk

SHELL         := bash
EMACS_COMMAND ?= emacs

PKGDIR  := packages
RCPDIR  := recipes
HTMLDIR := html
WORKDIR := working
SLEEP   ?= 0
SANDBOX := sandbox
STABLE  ?= nil
ifneq ($(STABLE), nil)
PKGDIR  := packages-stable
HTMLDIR := html-stable
endif

LISP_CONFIG ?= '(progn\
  (setq package-build-working-dir "$(TOP)/$(WORKDIR)/")\
  (setq package-build-archive-dir "$(TOP)/$(PKGDIR)/")\
  (setq package-build-recipes-dir "$(TOP)/$(RCPDIR)/")\
  (setq package-build-stable $(STABLE))\
  (setq package-build-write-melpa-badge-images t))'

LOAD_PATH ?= $(TOP)/package-build

EVAL := $(EMACS_COMMAND) --no-site-file --batch \
$(addprefix -L ,$(LOAD_PATH)) \
--eval $(LISP_CONFIG) \
--load package-build.el \
--eval

TIMEOUT := $(shell which timeout && echo "-k 60 600")

all: packages packages/archive-contents json index

## Conao Added rules start ################
SSHKEY := ~/.ssh/id_rsa
DATEDETAIL := $(shell date '+%Y/%m/%d %H:%M:%S')

commit: $(SSHKEY)
	echo "Commit by Travis-CI (job $$TRAVIS_JOB_NUMBER at $(DATEDETAIL))" >> commit.log

	git remote -v
	git remote set-url origin git@github.com:conao3/feather-melpa.git
	git remote add upstream https://github.com/melpa/melpa.git

	git checkout master
	git checkout -b travis-$$TRAVIS_JOB_NUMBER
	git add .
	git commit -m "Travis CI (job $$TRAVIS_JOB_NUMBER) [skip ci]"

	git checkout master
	git merge --no-ff travis-$$TRAVIS_JOB_NUMBER -m "Merge travis-$$TRAVIS_JOB_NUMBER [skip ci]"

	git fetch upstream
	git merge --no-ff upstream/master -m "Merge upstream [skip ci]"

	git push origin master

$(SSHKEY):
	openssl aes-256-cbc -K $$encrypted_018677cccdfe_key -iv $$encrypted_018677cccdfe_iv -in .travis_rsa.enc -out ~/.ssh/id_rsa -d
	chmod 600 ~/.ssh/id_rsa
	git config --global user.name "conao3"
	git config --global user.email conao3@gmail.com

## Conao Added rules end ################

## General rules
html: index
index: json
	@echo " • Building html index ..."
	$(MAKE) -C $(HTMLDIR)


## Cleanup rules
clean-working:
	@echo " • Removing package sources ..."
	@git clean -dffX $(WORKDIR)/.

clean-packages:
	@echo " • Removing packages ..."
	@git clean -dffX $(PKGDIR)/.

clean-json:
	@echo " • Removing json files ..."
	@-rm -vf $(HTMLDIR)/archive.json $(HTMLDIR)/recipes.json

clean-sandbox:
	@echo " • Removing sandbox files ..."
	@if [ -d '$(SANDBOX)' ]; then \
		rm -rfv '$(SANDBOX)/elpa'; \
		rmdir '$(SANDBOX)'; \
	fi

pull-package-build:
	git subtree pull --squash -P package-build package-build master

add-package-build-remote:
	git remote add package-build git@github.com:melpa/package-build.git

clean: clean-working clean-packages clean-json clean-sandbox

packages: $(RCPDIR)/*

packages/archive-contents: .FORCE
	@echo " • Updating $@ ..."
	@$(EVAL) '(package-build-dump-archive-contents)'

cleanup:
	@$(EVAL) '(package-build-cleanup)'

## Json rules
html/archive.json: $(PKGDIR)/archive-contents
	@echo " • Building $@ ..."
	@$(EVAL) '(package-build-archive-alist-as-json "html/archive.json")'

html/recipes.json: $(RCPDIR)/.dirstamp
	@echo " • Building $@ ..."
	@$(EVAL) '(package-build-recipe-alist-as-json "html/recipes.json")'

html-stable/archive.json: $(PKGDIR)/archive-contents
	@echo " • Building $@ ..."
	@$(EVAL) '(package-build-archive-alist-as-json "html-stable/archive.json")'

html-stable/recipes.json: $(RCPDIR)/.dirstamp
	@echo " • Building $@ ..."
	@$(EVAL) '(package-build-recipe-alist-as-json "html-stable/recipes.json")'

json: $(HTMLDIR)/archive.json $(HTMLDIR)/recipes.json

$(RCPDIR)/.dirstamp: .FORCE
	@[[ ! -e $@ || "$$(find $(@D) -newer $@ -print -quit)" != "" ]] \
	&& touch $@ || exit 0


## Recipe rules
$(RCPDIR)/%: .FORCE
	@echo " • Building package $(@F) ..."
	@- $(TIMEOUT) $(EVAL) "(package-build-archive \"$(@F)\")" \
	&& echo " ✓ Success:" \
	&& ls -lsh $(PKGDIR)/$(@F)-*
	@test $(SLEEP) -gt 0 && echo " Sleeping $(SLEEP) seconds ..." && sleep $(SLEEP) || true
	@echo


## Sandbox
sandbox: packages/archive-contents
	@echo " • Building sandbox ..."
	@mkdir -p $(SANDBOX)
	@$(EMACS_COMMAND) -Q \
		--eval '(setq user-emacs-directory (file-truename "$(SANDBOX)"))' \
		-l package \
		--eval "(add-to-list 'package-archives '(\"gnu\" . \"http://elpa.gnu.org/packages/\") t)" \
		--eval "(add-to-list 'package-archives '(\"melpa\" . \"https://melpa.org/packages/\") t)" \
		--eval "(add-to-list 'package-archives '(\"sandbox\" . \"$(TOP)/$(PKGDIR)/\") t)" \
		--eval "(package-refresh-contents)" \
		--eval "(package-initialize)" \
		--eval '(setq sandbox-install-package "$(INSTALL)")' \
		--eval "(unless (string= \"\" sandbox-install-package) (package-install (intern sandbox-install-package)))"

.PHONY: clean build index html json sandbox
.FORCE:
