@echo off
REM startagent.bat <agentfile.txt> <prolog_exe> <dali_src_path>
REM Starts a DALI agent process in a new window
REM %1 = agent filename (e.g. ferrari.txt)
REM %2 = path to spwin.exe or sicstus.exe
REM %3 = dali src path (e.g. ..\..\src)
set "sagent=start0('conf/%1')."
start "DALI Agent: %1" /B "" %2 --noinfo -l %3\active_dali_wi.pl --goal %sagent%
