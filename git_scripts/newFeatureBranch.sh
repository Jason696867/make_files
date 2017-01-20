#!/bin/bash
#attempt to automate some common git tasks.
# prints "ERROR! yadda yadda" higlighted in red
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
NOW=$(date +"%d%b%Y-%l:%M:%S-%p")
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
	  printInfo "Use 'git stash pop' to get back your un-commited work."
      exit 1
   fi
}
DEFAULT_FEATURE_BRANCH="XXXX-default-branch-name"
featureBranch="feature/SB-${1:-$DEFAULT_FEATURE_BRANCH}"
safeExecute git stash
safeExecute git checkout develop
safeExecute git fetch --all
safeExecute git pull origin develop
printSuccess "develop branch updated."
safeExecute git checkout -b "${featureBranch}"
printSuccess "New branch ${featureBranch}."
#safeExecute git subtree pull-all
safeExecute git stash pop
printSuccess "On ${featureBranch} completed"