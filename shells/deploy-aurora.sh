# /usr/bin/bash
basepath=$(cd `dirname $0`; pwd)
# cd ../
# basepath=$(pwd)
cd $basepath/../

#build 
hugo  --buildDrafts --baseUrl="https://1huizui.cn/"
# hugo --theme=blackburn --buildDrafts --baseUrl="https://1huizui.cn/"

cd public

git add ./ -A

now=date

git commit -m "deploy at $now"

git push -u  aurora-origin master