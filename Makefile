# Time-stamp: <2017-05-20 19:29:05 (steve)>
.PHONY: all

all: data/afl-2000.rds

################################################################################
# Make data for feeding into models and manuscript
data/afl-2000.rds: R/data-cleaning.R
	cd $(<D); \
	Rscript --no-save --no-restore $(<F)

################################################################################
# Rules for making stan models
stan/censored-mle-m0.rds: scripts/compile-model.R stan/censored-mle-m0.stan
	cd $(<D); \
	Rscript --no-save --no-restore $(<F) mname=$(basename $(@F) .rds)

stan/censored-mle-m0-robust.rds: scripts/compile-model.R \
	stan/censored-mle-m0-robust.stan
	cd $(<D); \
	Rscript --no-save --no-restore $(<F) mname=$(basename $(@F) .rds)

stan/censored-mle-m1.rds: scripts/compile-model.R stan/censored-mle-m1.stan
	cd $(<D); \
	Rscript --no-save --no-restore $(<F) mname=$(basename $(@F) .rds)

stan/censored-mle-m1-robust.rds: scripts/compile-model.R \
	stan/censored-mle-m1-robust.stan
	cd $(<D); \
	Rscript --no-save --no-restore $(<F) mname=$(basename $(@F) .rds)

stan/censored-mle-m2.rds: scripts/compile-model.R stan/censored-mle-m2.stan
	cd $(<D); \
	Rscript --no-save --no-restore $(<F) mname=$(basename $(@F) .rds)

stan/censored-mle-m2-robust.rds: scripts/compile-model.R \
	stan/censored-mle-m2-robust.stan
	cd $(<D); \
	Rscript --no-save --no-restore $(<F) mname=$(basename $(@F) .rds)

stan/censored-mle-m3.rds: scripts/compile-model.R stan/censored-mle-m3.stan
	cd $(<D); \
	Rscript --no-save --no-restore $(<F) mname=$(basename $(@F) .rds)

stan/censored-mle-m3-robust.rds: scripts/compile-model.R \
	stan/censored-mle-m3-robust.stan
	cd $(<D); \
	Rscript --no-save --no-restore $(<F) mname=$(basename $(@F) .rds)

stan/censored-mle-m4.rds: scripts/compile-model.R stan/censored-mle-m4.stan
	cd $(<D); \
	Rscript --no-save --no-restore $(<F) mname=$(basename $(@F) .rds)

stan/censored-mle-m4-robust.rds: scripts/compile-model.R \
	stan/censored-mle-m4-robust.stan
	cd $(<D); \
	Rscript --no-save --no-restore $(<F) mname=$(basename $(@F) .rds)

################################################################################
# Rules to fit models with data
data/censored-mle-m0.rds: scripts/fit-model.R \
	stan/censored-mle-m0.rds data/imputations.rds
	cd $(<D); \
	Rscript --no-save --no-restore $(<F) mname=$(basename $(@F) .rds) \
		myseed=737 iter=$(MCITER)

data/censored-mle-m0-robust.rds: scripts/fit-model.R \
	stan/censored-mle-m0-robust.rds data/imputations.rds
	cd $(<D); \
	Rscript --no-save --no-restore $(<F) mname=$(basename $(@F) .rds) \
		myseed=737 iter=$(MCITER)

data/censored-mle-m1.rds: scripts/fit-model.R \
	stan/censored-mle-m1.rds data/imputations.rds
	cd $(<D); \
	Rscript --no-save --no-restore $(<F) mname=$(basename $(@F) .rds) \
		myseed=666 iter=$(MCITER)

data/censored-mle-m1-robust.rds: scripts/fit-model.R \
	stan/censored-mle-m1-robust.rds data/imputations.rds
	cd $(<D); \
	Rscript --no-save --no-restore $(<F) mname=$(basename $(@F) .rds) \
		myseed=666 iter=$(MCITER)

data/censored-mle-m2.rds: scripts/fit-model.R \
	stan/censored-mle-m2.rds data/imputations.rds
	cd $(<D); \
	Rscript --no-save --no-restore $(<F) mname=$(basename $(@F) .rds) \
		myseed=42 iter=$(MCITER)

data/censored-mle-m2-robust.rds: scripts/fit-model.R \
	stan/censored-mle-m2-robust.rds data/imputations.rds
	cd $(<D); \
	Rscript --no-save --no-restore $(<F) mname=$(basename $(@F) .rds) \
		myseed=42 iter=$(MCITER)

data/censored-mle-m3.rds: scripts/fit-model.R \
	stan/censored-mle-m3.rds data/imputations.rds
	cd $(<D); \
	Rscript --no-save --no-restore $(<F) mname=$(basename $(@F) .rds) \
		myseed=13 iter=$(MCITER)

data/censored-mle-m3-robust.rds: scripts/fit-model.R \
	stan/censored-mle-m3-robust.rds data/imputations.rds
	cd $(<D); \
	Rscript --no-save --no-restore $(<F) mname=$(basename $(@F) .rds) \
		myseed=13 iter=$(MCITER)

data/censored-mle-m4.rds: scripts/fit-model.R \
	stan/censored-mle-m4.rds data/imputations.rds
	cd $(<D); \
	Rscript --no-save --no-restore $(<F) mname=$(basename $(@F) .rds) \
		myseed=987 iter=$(MCITER)

data/censored-mle-m4-robust.rds: scripts/fit-model.R \
	stan/censored-mle-m4-robust.rds data/imputations.rds
	cd $(<D); \
	Rscript --no-save --no-restore $(<F) mname=$(basename $(@F) .rds) \
		myseed=987 iter=$(MCITER)

################################################################################
# Rules to process data (add dependencies later).
$(ROBUST-PROC-DATA): scripts/post-process-robust.R robust-output-data input-data
	cd $(<D); \
	Rscript --no-save --no-restore $(<F)

$(PROC-DATA): scripts/post-process.R output-data
	cd $(<D); \
	Rscript --no-save --no-restore $(<F)

################################################################################
# Rules to make manuscripts
manuscripts/censored-mle.html: manuscripts/censored-mle.Rmd \
	data-raw/samples.csv
	cd $(<D); \
	Rscript --no-save --no-restore -e "rmarkdown::render('$(<F)')"

manuscripts/model-interrogation.html: manuscripts/model-interrogation.Rmd \
	robust-output-data
	cd $(<D); \
	Rscript --no-save --no-restore -e "rmarkdown::render('$(<F)')"

manuscripts/censored-mle.tex: manuscripts/censored-mle.Rnw \
	data/biofouling.rds data/imputations.rds $(ROBUST-PROC-DATA)
	cd $(<D); \
	Rscript --no-save --no-restore -e "knitr::knit('$(<F)')"

manuscripts/censored-mle-supplement.tex: manuscripts/censored-mle-supplement.Rnw \
	data/biofouling.rds data/imputations.rds $(PROC-DATA)
	cd $(<D); \
	Rscript --no-save --no-restore -e "knitr::knit('$(<F)')"

%.pdf: %.tex
	cd $(<D); \
	latexmk -pdf $(<F)

# phony rule to make paper from included figures
paper: manuscripts/censored-mle.Rnw data/biofouling.rds
	cd $(<D); \
	Rscript --no-save --no-restore -e "knitr::knit('$(<F)')"; \
	latexmk -pdf $(<F:Rnw=tex)

supplement: manuscripts/censored-mle-supplement.Rnw data/biofouling.rds
	cd $(<D); \
	Rscript --no-save --no-restore -e "knitr::knit('$(<F)')"; \
	latexmk -pdf $(<F:Rnw=tex)

################################################################################
# Cleaning targets
clean-models:
	cd stan/; \
	rm -f *.rds

clean-manuscripts:
	cd manuscripts/; \
	rm -rf *.aux *.bbl *.bcf *.blg *.fdb_latexmk *.fls *.lof *.log *.lot \
		*.code *.loe *.toc *.rec *.out *.run.xml *~ *.prv \
		censored-mle.tex _region_*

clobber: clean-data clean-manuscripts
	cd manuscripts/; \
	rm -rf auto/ cache/ figure/
