#!/bin/bash
# makeconf.sh <agentfile.txt> <dali_src_path>
# Creates the agent configuration file in conf/mas/
# $1 = agent filename (e.g. ferrari.txt)
# $2 = dali src path (e.g. ../../src)
agent_name="${1%.[^.]*}"   # strip extension: ferrari.txt -> ferrari
echo "agent('work/$agent_name','$agent_name','no',italian,['conf/communication'],['$2/communication_fipa','$2/learning','$2/planasp'],'no','$2/onto/dali_onto.txt',[])." > "conf/mas/$1"
