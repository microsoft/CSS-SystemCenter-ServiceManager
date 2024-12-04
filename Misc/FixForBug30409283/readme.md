# Symptom
The [Update Rollup 2 for SCSM 2022](https://support.microsoft.com/en-us/topic/update-rollup-2-for-system-center-2022-service-manager-631042ca-f36d-4716-898c-6a4d4856f353) fails on the Data Warehouse (DW) management server. This only happens if the SCSM Data Warehouse was previously upgraded from version 2019.

# Root cause
During the upgrade of the DW management server from version 2019 to 2022, the files below are mistakenly deleted in the folder `C:\Program Files\Microsoft System Center\Service Manager\DW`:
- build_scdm_db.sql
- build_scdw_db.sql

These files are then used by SCSM 2022 UR2, however as they are missing, UR2 fails.

# Solution
- Download the below 2 files: <a href="https://raw.githubusercontent.com/microsoft/CSS-SystemCenter-ServiceManager/main/Misc/FixForBug30409283/build_scdm_db.sql" download="build_scdm_db.sql">build_scdm_db.sql</a>
  -  [build_scdm_db.sql](https://raw.githubusercontent.com/microsoft/CSS-SystemCenter-ServiceManager/main/Misc/FixForBug30409283/build_scdm_db.sql)
  -  [build_scdw_db.sql](https://raw.githubusercontent.com/microsoft/CSS-SystemCenter-ServiceManager/main/Misc/FixForBug30409283/build_scdw_db.sql)
- On the DW management server, copy these 2 files into the folder `C:\Program Files\Microsoft System Center\Service Manager\DW`
- On the DW management server, restart the [Update Rollup 2 for SCSM 2022](https://support.microsoft.com/en-us/topic/update-rollup-2-for-system-center-2022-service-manager-631042ca-f36d-4716-898c-6a4d4856f353)


