# /usr/bin/bash
basepath=$(cd `dirname $0`; pwd)
# cd ../
# basepath=$(pwd)
cd $basepath/../

hugo server -D