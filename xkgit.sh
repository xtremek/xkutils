#!/bin/bash

script_name=$0
cmd=$1
current_branch=""

function is_repo() {
  if [ -d ".git" ]; then
    return 0
  else
    echo "No .git folder found. Please cd to a valid git repo and rerun this script."
    return 1
  fi
}

function current_repo() {
  basename $PWD
}

function get_current_branch() {
  git branch 2> /dev/null | sed -e '/^[^*]/d' -e 's/* \(.*\)/\1/'
}


function find_dropbox_path() {
  sqlite3 ~/.dropbox/config.db "select value from config where key = 'dropbox_path'"
}

function destroy() {
  is_repo
  if [ $? -eq 1 ]; then
    return 1
  fi
  project=$1
  origin=dropbox

  echo "This will delete the backup Git repository in your Dropbox" \
       "folder and remove the remote origin '$origin' from your repo"

  echo "Looking for user Dropbox path..."
  dropbox_path=$(find_dropbox_path)

  echo "Checking repository name..."
  repo=$(basename $PWD)

  echo ""
  echo "======================== Environment ============================"
  echo " - Dropbox Path: $dropbox_path"
  echo " - Repository Name: $repo"
  echo "================================================================="
  echo ""

  if [ "$project" == "" ]; then
    repo_path=$dropbox_path/git-backup/$repo.git
  else
    repo_path=$dropbox_path/git-backup/$project/$repo.git
  fi

  echo "Removing Dropbox remote origin..."
  git remote rm $origin

  echo "Removing backup Git repo folder..."
  rm -rf $repo_path

  echo "The Dropbox backup repo has been successfully removed."
}

function setup() {
  is_repo
  if [ $? -eq 1 ]; then
    return 1
  fi

  project=$1
  origin=dropbox

  echo "This script will help you setup a backup Git repository in" \
       "your Dropbox folder." \
       ""

  echo "Looking for user Dropbox path..."
  dropbox_path=$(find_dropbox_path)

  echo "Checking repository name..."
  repo=$(current_repo)

  echo ""
  echo "======================== Environment ============================"
  echo " - Dropbox Path: $dropbox_path"
  echo " - Repository Name: $repo"
  echo "================================================================="
  echo ""

  if [ "$project" == "" ]; then
    repo_path=$dropbox_path/git-backup/$repo.git
  else
    repo_path=$dropbox_path/git-backup/$project/$repo.git
  fi

  echo "Starting setup operation..."

  if [ -d $repo_path ]; then
    echo "Error: The directory '$repo_path' already exists!"
    echo "You can delete this folder if you want to re-setup your project."
    echo "Example: "
    echo ""
    echo "  rm -rf $repo_path"
    echo "  $script_name $cmd"
    echo ""
    return 1
  fi

  git clone --bare . $repo_path

  tmp=$(git remote)
  if [[ $tmp == *$origin* ]]; then
    echo "Your repository already contains the remote origin '$origin'!"
    return 1
  fi

  echo "Adding Dropbox remote..."
  git remote add $origin $repo_path
  if [ $? -ne 0 ]; then
    echo "An error occured while adding Dropbox remote!"
    return 1
  fi

  echo ""
  echo "OK, your Dropbox backup repository is ready to go!" \
       "You can now use the following commands instead of git pull/push:"
  echo ""
  echo "  $script_name pull"
  echo "  $script_name push"
  echo ""
  echo "And optionally, you can specify a branch:"
  echo ""
  echo "  $script_name pull master"
  echo ""
  echo "Have fun!"
  echo ""
  echo " - The XK"
  echo ""
}

function timestamp() {
  date +%m%d%y%H%M%S
}

function log_filename() {
  if [ -z $1 ]; then
    echo "$(current_repo)-$(timestamp).log"
  else
    echo "$(current_repo)-$1-$(timestamp).log"
  fi
}

function print_rc() {
  if [ $1 -eq 0 ]; then
    echo "[OK]"
    return 0
  else
    echo "[ERROR]"
    return 1
  fi
}

function handle_error() {
  echo "An error occured while running the command. Below is the error output:"
  cat $1
  rm $log_file
}

function pull() {
  is_repo
  if [ $? -eq 1 ]; then
    return  
  fi

  if [ ! -z "$2" ]; then
    current_branch=$2
  fi

  echo "Using branch: $current_branch"

  echo -n "Pull from Dropbox remote..."
  log_file=$(log_filename dropbox)
  git pull dropbox $current_branch &> $log_file
  print_rc $?
  if [ $? -eq 1 ]; then
    handle_error $log_file
    return 1
  fi
  rm $log_file

  echo -n "Pull from GitHub origin..."
  log_file=$(log_filename origin)
  git pull origin $current_branch &> $log_file
  print_rc $?
  if [ $? -eq 1 ]; then
    handle_error $log_file
    return 1
  fi
  rm $log_file
}

function push() {
  is_repo
  if [ $? -eq 1 ]; then
    return  
  fi

  if [ ! -z "$2" ]; then
    current_branch=$2
  fi
  echo "Using branch: $current_branch"

  echo -n "Push to Dropbox remote..."
  log_file=$(log_filename dropbox)
  git push dropbox $current_branch &> $log_file
  print_rc $?
  if [ $? -eq 1 ]; then
    handle_error $log_file
    return 1
  fi
  rm $log_file

  echo -n "Push to GitHub origin..."
  log_file=$(log_filename origin)
  git push origin $current_branch &> $log_file
  print_rc $?
  if [ $? -eq 1 ]; then
    handle_error $log_file
    return 1
  fi
  rm $log_file
}

current_branch=$(get_current_branch)

if   [ "$cmd" = "setup"   ]; then
  setup
elif [ "$cmd" = "destroy" ]; then
  destroy
elif [ "$cmd" = "pull" ]; then

  pull $2
elif [ "$cmd" = "push" ]; then
  if [ ! -z "$2" ]; then
    current_branch=$2
  fi

  push $2
elif [ "$cmd" = ""      ]; then
  echo "Please specify a command for this script to run!"
  echo "Example: "
  echo " $script_name pull"
else
  echo "Unknown command \"$cmd\""
fi
