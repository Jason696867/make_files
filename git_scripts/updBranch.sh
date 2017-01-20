#!/bin/bash -eu
#attempt to automate some common git tasks.
# if anything goes wrong, just do a "~$ git stash pop"
# after the script terminates to recover all your work. 
# 
#
# prints to std out highligted in red
function printError(){
      printf '\033[7;1;31m ERROR! %s \033[0;39m\n' "$1"
}
# prints to std out " SUCCESS! yadda yadda" highligted in green
function printSuccess(){
      printf '\033[48;5;118;38;5;0m SUCCESS! %s \033[0;39m\n' "$1"
}
# prints to std out " SUCCESS! yadda yadda" highligted in green
function printInfo(){
      printf '\033[48;5;95;38;5;0m INFO: %s \033[0;39m\n' "$1"
}
printVariable(){
   cat <<EOF
^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^
 $1 = ${!1}
__________________________________________________________________
EOF
}
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

#a function to uniformly check for erros in commands as they are executed
# processes up to three args for each command
function safeExecute(){
   $1 $2 $3 $4 $5 $6
   if [ $? -ne 0 ]
   then
      printError "$1 $2 $3 $4 $5 $6"
      exit 1
   fi
}

function infoExecute(){
   $1 $2 $3 $4 $5 $6
   if [ $? -ne 0 ]
   then
      printInfo "$1 $2 $3 $4 $5 $6"
   fi
}

DEFAULT_COMMIT_COMMENT="review comments addressed"
DEFAULT_DEV_BRANCH="develop"
NOW=$(date +"%d%b%Y-%l-%M-%S-%p")

branchToUpdate=$(git branch | awk '/*/ {print $2}')
branchHeadRef=$(git rev-parse HEAD)
#
if [ $branchToUpdate == $DEFAULT_DEV_BRANCH ]
then
   printError "develop is currently checked out"
   exit 1
else 
   printInfo "Will update develop branch and merge to $branchToUpdate branch"
fi
# if anything goes wrong, just do a "~$ git stash pop"
safeExecute git stash
printInfo "If anything goes wrong, use \'git stash pop\' to get back your un-commited work."
printInfo "Making backup branch. use 'git branch' to see your backup."
safeExecute git branch ${branchToUpdate}-${NOW}
safeExecute git checkout develop
safeExecute git fetch --all
printSuccess "Fetch all to develop."
safeExecute git pull origin develop
printSuccess "pull to develop."
safeExecute git checkout $branchToUpdate
printInfo "If there are merge conflicts, 1)fix each confilcted file, 2)git add each fix, 3)git commit, 4)git subtree pull-all"
printInfo "and then do 'git stash pop' if you are missing uncommited work."
safeExecute git merge develop
printSuccess "merged to $branchToUpdate."
printtInfo "subtree pull-all may fail if one or more subtrees have been removed at origin. This is not fatal."
infoExecute git subtree pull-all
infoExecute git stash pop
printInfo "Merged and subtree pull-all to $branchToUpdate completed."
exit 0

