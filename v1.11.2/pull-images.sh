#!/bin/sh
# Read the list from ./image.list file, and pull them from the logged in repository. e.g richardx
# as prerequisite, should login repository first

REPONAME="richardx"

tmp=`cat ./image.list`

for i in $tmp
do
    docker image list | grep -v "^REPOSITORY" | awk '{ print $1":"$2 }' | grep "^$i" >/dev/null 2>&1
    if [ $? -eq 0 ]
    then
        echo "Image of $i is already pulled down..."
    else
        newImage=`echo $i | awk -F"/" '{ print $NF }'`
        newImage="${REPONAME}/${newImage}"

        docker pull ${newImage}
        if [ $? -eq 0 ]
        then
            echo "Images of $i is pulled down successfully..."
            
            docker tag docker.io/${newImage} $i
            docker rmi ${newImage} 
        else
            echo "Images of $i is failed to pull down..."
        fi
    fi
done

