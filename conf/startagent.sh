#!/bin/bash
# startagent.sh <agentfile.txt> <prolog_bin> <dali_src_path>
# $1 = agent filename (e.g. ferrari.txt)
# $2 = path to sicstus binary
# $3 = dali src path
eval "$2 --noinfo -l $3/active_dali_wi.pl --goal \"start0('conf/mas/$1').\""
