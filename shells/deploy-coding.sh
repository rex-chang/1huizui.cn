# /usr/bin/bash
basepath=$(cd `dirname $0`; pwd)
# cd ../
# basepath=$(pwd)
cd $basepath/../

#build 
hugo --theme=blackburn --buildDrafts --baseUrl="https://1huizui.cn/"

cd public

git add ./ -A

now=date

git commit -m "deploy at $now"

git push -u coding_origin master