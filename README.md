# VTF

Steps to run a new participant
1. Generate datatables (see, lib/efficiency)
2. move datatables into lib/datatables/ga_dump
3. run lib/datatables/blocking.rmd to transform into files known to expt (with appropriate params)
3. modify run_VTF_contrast.bat and run_VTF_localizer.bat with new participant id

After participant has been run
1. run write_to_bids.Rmd (with appropriate params)
2. transfer to server