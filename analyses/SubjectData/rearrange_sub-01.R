

library(tidyverse)
library(magrittr)

files <- list.files(pattern = glue::glue( ".*events_pre.tsv"), recursive = FALSE, full.names = TRUE )

tInfo <- file.info(files, extra_cols = FALSE) %>%
  as_tibble() %>%
  tibble::rownames_to_column(var = "filename") %>%
  select(filename) %>%
  mutate(events = map(filename, read_tsv)) %>%
  mutate(run = 1:n()) %>%
  unnest(events) %>%
  select(-filename)

d <- tInfo %>%
  separate(trial_type, into = c("contrast", "orientation"), sep = "_") %>%
  mutate(contrast = plyr::mapvalues(contrast, c("low","high"), c(0.3,0.8)),
         contrast = as.numeric(contrast),
         orientation = as.numeric(orientation)) %>%
  select(onset, duration, contrast, orientation, run)


for(r in 1:n_distinct(d$run)){
  d %>%
    filter(run == r) %>%
    readr::write_tsv(., file.path(getwd(), glue::glue("sub-01_task-con_run-{sprintf('%02d', r)}_events.tsv")))
}

