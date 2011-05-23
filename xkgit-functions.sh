#!/bin/bash

current_branch=""

function xkgit_check_param() {
	if [ -z "$1" ]; then
		current_branch=$(xkgit_current_branch)
		#echo "Please specify a branch to use with this function."
		#return 1
	else
		current_branch=$1
	fi

	return 0
}

function xkgit_check_valid() {
	if [ -d ".git" ]; then
		return 0
	fi

	echo "No .git folder found. Please cd to a valid git repo and rerun this command".

	return 1
}

function xkgit_check() {
	xkgit_check_param $1

	if [ $? -eq 1 ]; then
		return	1
	fi

	xkgit_check_valid

	if [ $? -eq 1 ]; then
		return	1
	fi
}

function xkgit_setup_repo() {
	xkgit_check_valid
	if [ $? -eq 1 ]; then
		return	
	fi

	echo "This script will help you setup a backup Git repository in" \
				"your Dropbox folder."
	echo ""

	echo "Looking for user Dropbox path..."
	dropbox_path=$(sqlite3 ~/.dropbox/config.db "select value from config where key = 'dropbox_path'")

	echo "Checking repository name..."
	repo=$(basename $PWD)

	echo ""
	echo "======================== Environment ============================"
	echo " - Dropbox Path: $dropbox_path"
	echo " - Repository Name: $repo"
	echo "================================================================="
	echo ""

	repo_path=$dropbox_path/Git/$repo.git

	echo "Starting setup operation..."

	if [ -d $repo_path ]; then
		echo "Error: The directory $repo_path already exists!"
		echo "You can delete this folder if you want to re-setup your project."
		return
	fi

	git clone --bare . $repo_path

	echo "Adding Git remote origin..."
	git remote add dropbox  $repo_path

	echo ""
	echo "OK, your Git repository is setup and ready to go! You can now use the following commands for pulling and pushing: "
	echo ""
	echo " xkgit_pull master"
	echo " xkgit_push master"
	echo ""
	echo "Have fun!"
	echo ""
	echo " - The XK"
	echo ""
}

xkgit_current_branch() {
	git branch 2> /dev/null | sed -e '/^[^*]/d' -e 's/* \(.*\)/\1/'
}

xkgit_current_repo() {
	basename $(pwd)
}



function xkgit_sync() {
	
}

function xkgit_pull() {
	xkgit_check $1
	if [ $? -eq 1 ]; then
		return	
	fi

	echo -n "Pull from Dropbox remote..."
	# The dropbox repo
	git pull dropbox $current_branch > /dev/null

	git pull origin $current_branch
}

function xkgit_print_rc() {
	if [ $? -ne 0 ]; then
		echo "[ERROR]"
	else
		echo "[OK]"
	fi

}

function xkgit_timestamp() {
	date +%m%d%y%H%M%S
}

function xkgit_log_filename() {
	if [ -z $1 ]; then
		echo ".$(xkgit_current_repo)-$(xkgit_timestamp).log"
	else
		echo ".$(xkgit_current_repo)-$1-$(xkgit_timestamp).log"
	fi
}

function xkgit_push() {
	xkgit_check $1
	if [ $? -eq 1 ]; then
		return	
	fi

	echo -n "Push to Dropbox remote..."
	# The dropbox repo
	git push dropbox $current_branch &> $(xkgit_log_filename dropbox)
	xkgit_print_rc

	echo -n "Push to GitHub origin..."
	git push origin $current_branch &> $(xkgit_log_filename origin)
	xkgit_print_rc
}

function xkgit() {
	param=$1

	if [ $param = "pull" ]; then
		xkgit_pull $2
	elif [ $param = "push" ]; then
		xkgit_push $2
	elif [ $param = "setup" ]; then
		xkgit_setup_repo
	else
		echo "Unknown command $1"
	fi
}
