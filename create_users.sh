#!/bin/bash

# You should first create the students SLURM account:
# sudo sacctmgr create account students

# need to first authenticate for kerberos
sudo kinit admin

csvfile=Class_List_MSDS684_FW1_2019.csv
defaultsalt="deepdream"

# gets the fourth column from the csv, which is the id in this case
ids=$(csvtool namedcol "User ID" $csvfile  | sed '1d')
for id in $ids
do
  # some bug is causing the users to stick around even after sudo ipa user-del,
  # so skip this check to see if they exist
  # if id "$id" > /dev/null 2>&1; then
  #   # if user exists already, do nothing
  #   echo 'user already exists'
  #   :
  # else
  PASSWORD="$id$defaultsalt"
  echo $PASSWORD
  echo /storage/$id/
  # for testing I also had to set the minimum password life to 0 hours:
  # ipa pwpolicy-mod global_policy --minlife 0
  # https://serverfault.com/a/609004/305991
  echo $PASSWORD | sudo ipa user-add $id --first='-' --last='-' --homedir=/storage/$id --shell=/bin/bash --password --setattr krbprincipalexpiration=$(date '+%Y-%m-%d' -d '+1 year +30 days')$'Z' --setattr krbPasswordExpiration=$(date '+%Y-%m-%d' -d '-1 day')$'Z'
  # make their home folder only readable to them and not other students
  sudo mkdir /storage/$id
  sudo cp /etc/skel/.profile /storage/$id
  sudo cp /etc/skel/.bashrc /storage/$id
  sudo chmod -R 700 /storage/$id
  # only allow users to use 4 of 6 GPUs at a time
  sudo sacctmgr -i create user name=$id account=students MaxJobs=4 MaxSubmitJobs=30
  # sudo sacctmgr -i modify user where name=$id set MaxJobs=4
  # fi
done

# for some reason it can't find the newly-created users, so have to put this in another loop
for id in $ids
do
  sudo chown -R $id:$id /storage/$id
  # set quota on storage drive
  sudo setquota -u $id 150G 150G 0 0 /storage
  sudo setquota -u $id 5G 5G 0 0 /
done
