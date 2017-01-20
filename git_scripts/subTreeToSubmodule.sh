#!/bin/bash -eu
# will remove one subtree and replace it with a submodule. 
# Must be run within a git repo 
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
function printTwoVariables(){
   cat <<EOF
^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^
 $1 = ${!1}
 $2 = ${!2}
__________________________________________________________________
EOF
}
function printVariable(){
   cat <<EOF
^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^
 $1 = ${!1}
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
   $1 ${2:-``} ${3:-``} ${4:-``} ${5:-``} ${6:-``} ${7:-``} ${8:-``} ${9:-``} 
   if [ $? -ne 0 ]
   then
      printError "$1 ${2:-``} ${3:-``} ${4:-``} ${5:-``} ${6:-``} ${7:-``} ${8:-``} ${9:-``}"
      exit 1
   fi
}

function infoExecute(){
   $1 ${2:-``} ${3:-``} ${4:-``} ${5:-``} ${6:-``} ${7:-``} ${8:-``} ${9:-``} 
   if [ $? -ne 0 ]
   then
      printInfo "$1 ${2:-``} ${3:-``} ${4:-``} ${5:-``} ${6:-``} ${7:-``} ${8:-``} ${9:-``}"
   fi
}

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
#print both optargs and positional args
function printUsage()
{
	cat <<EOF

   Usage: ${0##*/} <1-subPath> <2-sourceURL>
      <1-path>     		- relative path in the containing project where the subtree is and the submodule will be
      <2-url>      		- source URL for the subtree - submodule
      <3-updateBranch>  - Optional: branch to commit to, if not the current branch. May be omitted.

      Must be run from the top of the container project dir, within a git repo. 
EOF
}
MIN_EXPECTED_ARGS=2
MAX_EXPECTED_ARGS=3
#this validates all input arguments. as written, assumes three dash options
#followed by several positional parameters.

function processInputArguments()
{	
	# Non-option positional arguments
	ARGS=("$@")	
	NUM_OF_ARGS="$#"

	# This validates number of arguments, if needed. Allows for optional positional args 
	# at the end of the list. Be sure to provide defaults for all optional args! 
	if [[ $NUM_OF_ARGS -lt $MIN_EXPECTED_ARGS || $NUM_OF_ARGS -gt $MAX_EXPECTED_ARGS ]]; then
		printUsage
		errorAndExit "$NUM_OF_ARGS: insufficient or too many arguments"
	fi
	currentBranch=$(git branch | awk '/*/ {print $2}')

	SUBTREE_PATH="${ARGS[0]}"
	SUBTREE_URL="${ARGS[1]}"
	BRANCH_NAME="${ARGS[2]:-currentBranch}"
}

# this is where you put your new script.
function main()
{
	printBanner "Start of ${0##*/}."
	processInputArguments $@

	printConsoleInfo "Deleting subtree $SUBTREE_PATH"
	safeExecute rm -r $SUBTREE_PATH
	safeExecute git add -A 
	safeExecute git commit -m `"Removed subtree $SUBTREE_PATH"`
	printConsoleInfo "Adding submodule $SUBTREE_PATH"
	safeExecute git submodule add "$SUBTREE_URL" "$SUBTREE_PATH" -b "$BRANCH_NAME"
	safeExecute git config -f .gitmodules submodule."$SUBTREE_PATH".branch "$BRANCH_NAME"
	safeExecute git submodule update --remote
	safeExecute git add -A 
	safeExecute git commit -m "Added submodule $SUBTREE_PATH and set it up to track branch $BRANCH_NAME"

}

# call to main, passing in all the optional and positional parameters.
main $@
printSuccess "End of ${0##*/} reached. Exiting."
EXIT_MSG="Great success."
exit 0
