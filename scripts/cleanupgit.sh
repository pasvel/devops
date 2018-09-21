# Remove the history from 
cd $1
rm -rf .git

# recreate the repos from the current content only
git init
git add .
git commit -m "Initial commit"

# push to the github remote repos ensuring you overwrite history
git remote add origin git@github.com:pasvel/devops.git
git push -u --force origin master
