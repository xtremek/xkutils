 
QUIET=@

all:

deploy-user:
	$(QUIET)echo "Deploying to ~/bin..."
	$(QUIET)cp xkgit.sh ~/bin
	$(QUIET)chmod +x ~/bin/xkgit.sh
	$(QUIET)ln -sf ~/bin/xkgit.sh ~/bin/xkgit
	$(QUIET)echo "Be sure to add ~/bin to your PATH!"

deploy-system:
	$(QUIET)echo "Deploying to /usr/bin..."
	$(QUIET)cp xkgit.sh /usr/bin
	$(QUIET)chmod +x ~/usr/xkgit.sh
	$(QUIET)ln -sf /usr/bin/xkgit.sh /usr/bin/xkgit