#!/bin/bash
#attempt to automate some common git tasks.
# if anything goes wrong, the branch is backed up 
# after the script terminates to recover all your work. 
# first parameter is the subtree as in '--prefix=src/${1}'
# second parameter is a string used as the commit comment.
# if you don't provide a 
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
DEFAULT_COMMIT_COMMENT="review comments addressed"
DEFAULT_DEV_BRANCH="develop"
NOW=$(date +"%d%b%Y-%l;%M;%S-%p")
branchToUpdate=$(git branch | awk '/*/ {print $2}')
backupBranch=${branchToUpdate}-${NOW}
#
#a function to uniformly check for erros in commands as they are executed
# processes up to three args for each command
function safeExecute(){
   ${1} ${2} ${3} ${4} ${5} ${6}
   if [ $? -ne 0 ]
   then
      printError "${1} ${2} ${3} ${4} ${5} ${6}"
      printInfo "your backup branch is ${backupBranch}"
      exit 1
   fi
}
if [ ${branchToUpdate} = ${DEFAULT_DEV_BRANCH} ]
then
   printError "develop is currently checked out"
   exit 1
else 
   printInfo "Will update develop branch and merge to $branchToUpdate branch"
fi
# if anything goes wrong, your branch is backed up. 
safeExecute git add ${PWD}/src/.
safeExecute git commit -m ${2:-DEFAULT_COMMIT_COMMENT}
safeExecute git branch ${backupBranch}
safeExecute git subtree push --prefix=src/${1} --squash ${branchToUpdate}

