# tar_make() is run with pipeline/ as the working directory, which would skip
# the repo-root .Rprofile and leave the renv project library off .libPaths()
# (models in Suggests, e.g. midasr, then silently drop out of model_adapters()).
# Activate the repo-root renv project explicitly.
Sys.setenv(RENV_PROJECT = normalizePath(".."))
source(file.path("..", "renv", "activate.R"))
