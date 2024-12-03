# Symptom
The [Update Rollup 2 for SCSM 2022](https://support.microsoft.com/en-us/topic/update-rollup-2-for-system-center-2022-service-manager-631042ca-f36d-4716-898c-6a4d4856f353) fails on the Data Warehouse (DW) management server. This only happens if the SCSM Data Warehouse was previously upgraded from version 2019.

# Root cause
During the upgrade of the DW management server from version 2019 to 2022, the files below are mistakenly deleted in the folder `C:\Program Files\Microsoft System Center\Service Manager\DW`:
- build_scdm_db.sql
- build_scdw_db.sql

This files are then used by SCSM 2022 UR2.

# Resolution
- Download the files from ...
- Copy these 2 files into the folder `C:\Program Files\Microsoft System Center\Service Manager\DW` on the DW management server
- Restart SCSM 2022 UR2


