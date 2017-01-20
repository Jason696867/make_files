#!/bin/bash -eu
#attempt to automate some common git tasks.
# if anything goes wrong, just do a "~$ git stash pop"
# after the script terminates to recover all your work. 
# 
#
# prints to std out highligted in red
function printConsoleError(){
      printf '\033[7;1;31m ERROR! %s \033[0;39m\n' "$1"
}
# prints to std out " SUCCESS! yadda yadda" highligted in green
function printConsoleSuccess(){
      printf '\033[48;5;118;38;5;0m SUCCESS! %s \033[0;39m\n' "$1"
}
# prints to std out " SUCCESS! yadda yadda" highligted in green
function printConsoleInfo(){
      printf '\033[48;5;95;38;5;0m INFO: %s \033[0;39m\n' "$1"
}
function printVariables(){
   cat <<EOF
^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^
 $1 = ${!1}
 $2 = ${!2}
__________________________________________________________________
EOF
}

function printBanner{
   cat <<EOF
~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~

 $1

~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
EOF
}
#a function to uniformly check for erros in commands as they are executed
# processes up to five args for each command
function safeExecute(){
   $1 ${2:-``} ${3:-``} ${4:-``} ${5:-``} ${6:-``} 
   if [ $? -ne 0 ]
   then
      printError "$1 ${2:-``} ${3:-``} ${4:-``} ${5:-``} ${6:-``} "
      exit 1
   fi
}

function infoExecute(){
   $1 ${2:-``} ${3:-``} ${4:-``} ${5:-``} ${6:-``} 
   if [ $? -ne 0 ]
   then
      printInfo "$1 ${2:-``} ${3:-``} ${4:-``} ${5:-``} ${6:-``} "
   fi
}

actualGoVersion=$(go version | awk '{print $3}' | sed s/go//)

#this is how to return a value from a function. Note that __r3sulTvar
# will be "eval " as a global variable so it cannot match any other 
# likely variableName. Hence the offucation. 
function myfunc()
{
    local  __r3sulTvar=$1
    local  myresult='some value'
    eval $__r3sulTvar="'$myresult'"
}

myfunc result
echo $result

#traps on the EXIT sudo signal and calls safeExit for cleanup
trap safeExit EXIT 
#before running commands that may throw, change the EXIT_MSG to somehing
#helpful 
EXIT_MSG="Great success."
#this will always run when the scrip terminates for any reason. 
#put code to clean up any dirs or files created or close ports, start or stop
#services or whatever you want to make sure happens before this process
#unloads.
function safeExit() {
   echo "${EXIT_MSG}"
}

# declare an array called array and define 3 vales
#iterate over the array. 
array=( one two three )
for i in "${array[@]}"
do
	echo $i
done

#print both optargs and positional args
function printUsage()
{
	cat <<EOF

   multiserver : Usage: ${0##*/} [OPTIONS...] <1-workspaceDir> <2-multiserverBranchName>
   	  -a                          - optional parameter a explained
   	  -b                          - optional parameter b explained
   	                                   option -a must be set before -b for -b to take effect.
   	  -w                          - optional parameter w explained
      <1-variableName>            - provide the usage explination of the frist postional paramter
      <2-secondVariableName>      - provide the usage explination of the second postional paramter
      <3-thirdVariableName>      - provide the usage explination of the third postional paramter
EOF
}
#example of how to extract the exact word and portion of that word
#from some command ( 'go version' in this case ) and save it to a variable
actualGoVersion=$(go version | awk '{print $3}' | sed s/go//)

#this validates all input arguments. as written, assumes three dash options
#followed by several positional parameters.
DEFAULT_WORKSPACE=/var/whatever/default_workspace
DEFAULT_MULTI_SERVER_BRANCH_NAME=develop

function processInputArguments()
{	
	EXIT_MSG="Error processing input arguments."
	OPTIND=1
	while getopts "awb" opt; do
		case $opt in
			a)
				VARIABLE_A="yes"
				;;
			w)
				VARIABLE_W="yes"
				;;
			b)
				if [ "$VARIABLE_A" == "yes" ]; then
					VARIABLE_B="yes"
				else
					EXIT_MSG="Flag -a must be set before -b because we are difficult to work with."
					printUsage
				fi
				;;
			\?)
				EXIT_MSG="Unknown option: \"-$OPTARG\""
				printUsage
				;;
			:)
				EXIT_MSG="Option \"-$OPTARG\" requires an argument"
				printUsage
				;;
		esac
	done
	# Shift optional arguments out of argument list
	shift $(($OPTIND-1))

	# Non-option positional arguments
	ARGS=("$@")	
	NUM_OF_ARGS="$#"

	# This validates number of arguments, if needed. 
	# It's better to just provide defaults for all positional args
	# and let the user decide which ones to override
	if [ $NUM_OF_ARGS -ne $NUM_EXPECTED_INPUT_ARGS ]; then
		printUsage
		errorAndExit "$NUM_OF_ARGS Insufficient or too many arguments"
	fi

	WORKSPACE="${ARGS[0]:-DEFAULT_WORKSPACE}"
	MULTI_SERVER_BRANCH_NAME="${ARGS[1]:-DEFAULT_MULTI_SERVER_BRANCH_NAME}"
	THRID_VARIABLE="${ARGS[2]}"
	FOURTH_VARIABLE="${ARGS[3]}"

# this is where you put your new script.
function main()
{
	printBanner "Start of ${0##*/}."
	processInputArguments $@

}

# call to main, passing in all the optional and positional parameters.
main $@
printSuccess "End of ${0##*/} reached. Exiting."
ERROR_MESSAGE="Great success."
exit 0
