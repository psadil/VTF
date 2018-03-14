

library(tidyverse)
library(magrittr)

files <- list.files(pattern = glue::glue( "AC.*[[:digit:]].prt"), recursive = TRUE, full.names = TRUE )


extract_moment <- function(filename, trial_id, type = "onset"){
  prt <- read_lines(filename)
  
  id_place <- which(str_detect(prt, trial_id))
  
  position <- id_place + 1
  n_trial <- as.numeric(prt[position])
  
  out <- vector(mode = "numeric", length = n_trial)
  for(trial in 1:n_trial){
    position <- position + 1
    if (type == "onset"){
      out[trial] <- as.numeric(str_extract(prt[position], "[[:digit:]]+"))
    }else if (type == "offset"){
      out[trial] <- as.numeric(str_extract(prt[position], "[:space:][[:digit:]]+"))
    }
  }
  return(out)
}


con_trial_list <- c("LowContrast-0-Trial1","LowContrast-0-Trial2",
                    "LowContrast-20-Trial1","LowContrast-20-Trial2",
                    "LowContrast-40-Trial1", "LowContrast-40-Trial2",
                    "LowContrast-60-Trial1", "LowContrast-60-Trial2",
                    "LowContrast-80-Trial1", "LowContrast-80-Trial2",
                    "LowContrast-100-Trial1", "LowContrast-100-Trial2",
                    "LowContrast-120-Trial1", "LowContrast-120-Trial2",
                    "LowContrast-140-Trial1", "LowContrast-140-Trial2",
                    "LowContrast-160-Trial1", "LowContrast-160-Trial2",
                    "HighContrast-0-Trial1", "HighContrast-0-Trial2",
                    "HighContrast-20-Trial1", "HighContrast-20-Trial2",
                    "HighContrast-40-Trial1", "HighContrast-40-Trial2",
                    "HighContrast-60-Trial1", "HighContrast-60-Trial2",
                    "HighContrast-80-Trial1", "HighContrast-80-Trial2",
                    "HighContrast-100-Trial1", "HighContrast-100-Trial2",
                    "HighContrast-120-Trial1", "HighContrast-120-Trial2",
                    "HighContrast-140-Trial1", "HighContrast-140-Trial2",
                    "HighContrast-160-Trial1", "HighContrast-160-Trial2"
                    )

loc_trial_list <- c("Stim")

retMaP_trial_list <- c("horizontal", "vertical")


d <- file.info(files, extra_cols = FALSE) %>%
  as_tibble() %>%
  tibble::rownames_to_column(var = "filename") %>%
  select(filename) %>%
  # mutate(events = map(filename, read_lines)) %>%
  mutate(task = case_when(str_detect(filename, "loc") ~ "loc",
                          str_detect(filename, "ret") ~ "ret",
                          str_detect(filename, "[[:punct:]]r[[:digit:]].prt") ~ "con"),
         run = str_extract(filename, "[[:digit:]].prt"),
         run = as.integer(str_extract(run, "[[:digit:]]"))) %>%
  group_by(task, run) %>%
  nest() %>%
  mutate(data = map2(data, task, ~if(.y=="loc"){
    crossing(.x,trial_id = loc_trial_list)
    }else if(.y=="ret"){
      crossing(.x, trial_id = retMaP_trial_list)
      }else if(.y == "con"){
        crossing(.x,trial_id = con_trial_list)
      }  )) %>%
  unnest() %>%
  mutate(onset = map2(filename, trial_id, ~extract_moment(.x, trial_id = .y, type = "onset")),
         offset = map2(filename, trial_id, ~extract_moment(.x, trial_id = .y, type = "offset")))


con <- d %>%
  filter(task == "con") %>%
  unnest(onset, offset) %>%
  mutate(duration = offset - onset) %>%
  separate(trial_id, c("contrast", "orientation", "trial"), "-") %>%
  mutate(orientation = as.numeric(orientation),
         contrast = as.numeric(plyr::mapvalues(contrast, c("LowContrast","HighContrast"), c(.3, .8))),
         repetition = as.integer(str_extract(trial, "[[:digit:]]")),
         subject = 3) %>%
  mutate(con = plyr::mapvalues(contrast, from = unique(contrast), to = str_c("con", unique(contrast), sep = "-")),
         ori = plyr::mapvalues(orientation, from = unique(orientation), to = str_c("ori", unique(orientation), sep = "-"))) %>%
  unite(trial_type, c(con, ori)) %>%
  select(onset, duration, trial_type, contrast, orientation, repetition, run, subject, task, filename) %>%
  arrange(onset)

for(r in unique(con$run)){
  con %>%
    filter(run == r) %>%
    readr::write_tsv(., file.path(glue::glue("sub-03_task-con_run-{sprintf('%02d', r)}_events.tsv")))
}


ret <- d %>%
  filter(task == "ret") %>%
  crossing(repetition = 1:6) %>%
  mutate(onset = map2_dbl(onset, repetition, ~.x[.y]),
         offset = map2_dbl(offset, repetition, ~.x[.y]),
         duration = offset - onset,
         subject = 3) %>%
  rename(trial_type = trial_id) %>%
  select(onset, duration, trial_type, repetition, run, subject, task, filename) %>%
  arrange(onset)

for(r in unique(ret$run)){
  ret %>%
    filter(run == r) %>%
    readr::write_tsv(., file.path(glue::glue("sub-03_task-ret_run-{sprintf('%02d', r)}_events.tsv")))
}


loc <- d %>%
  filter(task == "loc") %>%
  crossing(repetition = 1:15) %>%
  mutate(onset = map2_dbl(onset, repetition, ~.x[.y]),
         offset = map2_dbl(offset, repetition, ~.x[.y]),
         duration = offset - onset,
         subject = 3,
         trial_type = "checkerboard") %>%
  select(onset, duration, trial_type, repetition, run, subject, task, filename) %>%
  arrange(onset)


for(r in unique(loc$run)){
  loc %>%
    filter(run == r) %>%
    readr::write_tsv(., file.path(glue::glue("sub-03_task-loc_run-{sprintf('%02d', r)}_events.tsv")))
}

