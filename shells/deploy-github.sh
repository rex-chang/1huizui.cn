# /usr/bin/bash
basepath=$(cd `dirname $0`; pwd)
# cd ../
# basepath=$(pwd)
cd $basepath/../

#build 
hugo --theme=blackburn --buildDrafts --baseUrl="https://rex-chang.github.io/"

cd public
git pull origin
git add ./ -A

now=date

git commit -m "deploy at $now"

git push -u origin master
