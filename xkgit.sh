#/bin/bash

script_name=$0
cmd=$1


function is_repo() {
  if [ -d ".git" ]; then
    return 0;
  else
    echo "No .git folder found. Please cd to a valid git repo and rerun this script."
    return 1
  fi
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

if   [ "$cmd" = "setup"   ]; then
  setup
elif [ "$cmd" = "destroy" ]; then
  destroy
elif [ "$cmd" = ""      ]; then
  echo "Please specify a command for this script to run!"
  echo "Example: "
  echo " $script_name pull"
else
  echo "Unknown command \"$cmd\""
fi