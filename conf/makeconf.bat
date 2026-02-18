@echo off
REM makeconf.bat <agentname> <agentfile.txt>
REM Creates the agent configuration file in conf\
REM %1 = agent name (e.g. ferrari)
REM %2 = agent filename (e.g. ferrari.txt)
echo agent('work/%1',%1,'no',italian,['conf/communication'],['../../src/communication_fipa','../../src/learning','../../src/planasp'],'no','../../src/onto/dali_onto.txt',[]). > conf\%2
