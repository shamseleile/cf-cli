#!/bin/bash
####################################################################################################
# AUTH: Matthew Baum
# RIVISED BY: Nasreddine Salem  
# DATE: 2018-01-31
# LAST: 2018-05-09
# DESC: This script automates the execution of a jmeter test and the production of test results
# ARGS:
#	$1: jmeter_script: the script to run
#   $2: output_directory: the directory where a date-stamped results directory will be created
#   $others: All other arguments are forwarded directly to jmeter
#
# NOTE: assumes the terminal is GNU BASH
# NOTE: assumes the following programs exist: tee, cat, grep, tail
# NOTE: This script assumes jmeter is included in the command path
# NOTE: This script passes some default sizing args to the jvm. adjust as required
####################################################################################################
if [ $# -lt 2 ]
then
	echo "**** ERROR: Must pass at least 2 args to this script: 1=jmeter_script, 2=output_directory"
	echo "\tFound $# args: #@"
	echo "\texiting..."
	exit 1
fi

# Define JAVA_HOME on PCF (required by jmeter)
# WARNING: This command adds a local jmeter BIN folder to the PATH. This is temporary and must be removed when we build our Docker image!
IS_PCF="$CF_INSTANCE_IP"
IS_CONCOURSE=false

if [ "$USER" = "root" ]
then
	IS_CONCOURSE=true
fi

if [ ! -z $IS_PCF ]
then
	export PATH=$PATH:"$(dirname $1)/bin/jmeter/bin"
	export JAVA_HOME="/home/vcap/app/.java-buildpack/open_jdk_jre"
fi

if [ $IS_CONCOURSE ]
then
	export PATH=$PATH:"$(dirname $1)/bin/jmeter/bin"
fi

# set jvm args for jmeter, if args not already defined, and not running on PCF
if [ -z $JVM_ARGS ] && [ -z $IS_PCF ] && [ ! $IS_CONCOURSE ]
then
	export JVM_ARGS="-Xms512m -Xmx2g"
	echo "**** LOG: Setting JVM heap size to: $JVM_ARGS"
fi

# create output directory
VERSION=$(date +"%Y-%m-%d_%H-%M-%S")
RES_DIR="$2/$VERSION"
echo "**** LOG: Results will appear under: $RES_DIR"
mkdir -p $RES_DIR

# run test and save console log
echo "**** LOG: Starting jmeter test: $1"
echo "**** LOG: Additional arguments: ${@:3}"
jmeter -n -t $1 -l $RES_DIR/res.csv -e -o $RES_DIR/dashboard -j $RES_DIR/jmeter.log -JRES_DIR=$RES_DIR ${@:3} | tee $RES_DIR/console.log

# Compress the results
echo "**** LOG: Writing compressed result files to: ${RES_DIR}.tar.gz"
tar -czvf $RES_DIR.tar.gz -C $RES_DIR .

# extract final summary data and analyze results
avg="$(cat ${RES_DIR}/console.log | grep 'summary =' | tail -n1 | grep -Po 'Avg:\s*\K\d+')"
err="$(cat ${RES_DIR}/console.log | grep 'summary =' | tail -n1 | grep -Po 'Err:\s*\d+\s*\(\K\d+')"

if [ -z "$avg" ]
then
	echo "**** ERROR: could not extract avg resp time. Exiting..."
	exit 1
elif [ -z "$err" ]
then
	echo "**** ERROR: could not extract avg resp time. Exiting..."
	exit 1
fi

declare -i retval
retval=0
	
if [ $avg -lt 5000 ]
then
	echo "**** PASS: avg resp time below 5000 ms ($avg)"
else
	echo "**** FAIL: avg resp time above 5000 ms ($avg)"
	retval=1
fi

if [ $err -lt 5 ]
then
	echo "**** PASS: error rate below 5% ($err)"
else
	echo "**** FAIL: error rate above 5% ($err)"
	retval=1
fi

# Push des résultats sur git, lors d'une execution sur PCF
if [ ! -z $IS_PCF ] || [ $IS_CONCOURSE ]
then
	set -x
	DIR=".."
	git clone performance-rapport-git out-performance-rapport

	pushd out-performance-rapport
		LATEST=performance-rapport-$VERSION
		
		echo $LATEST > ./LATEST
		cp -r ../tests-git/src/test/res/$VERSION.tar.gz ./

		git add .
		git config user.email "paiement@desjardins.com"
		git config user.name "Concourse"
		git commit -m "Rapports pour $LATEST"
	popd
fi

exit $retval
