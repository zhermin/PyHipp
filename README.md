# AWS Data Engineering

## Initial Setup

*Python code for analyzing hippocampus data*

To install, launch Anaconda Navigator. On the left sidebar, select Environments. Select “base (root)” or another environment that you are using. Click on the triangle icon, and select “Open Terminal”. In the Terminal window, change to the PyHipp directory and do:

```bash
cd ~/Documents/Python/PyHipp

pip install -r requirements.txt

pip install -e .
```

Clone pyedfread for reading Eyelink files from GitHub to your computer by selecting Clone->Open in Desktop:

```bash
git clone https://github.com/nwilming/pyedfread
```

While still in the Terminal window, change directory to where the pyedfread code is saved, and do:

```bash
cd ~/Documents/Python/pyedfread
pip install .
```

You should also clone the following two repositories:

```bash
git clone https://github.com/grero/DataProcessingTools
git clone https://github.com/grero/PanGUI
```

Change to the directory where the code is saved, and install them using:

```bash
pip install -e .
```

Close the Terminal window, select Home in the sidebar of the Anaconda Navigator window, and launch Spyder. Type the following from the python prompt:

```python
import PyHipp as pyh

# You should be able to use the functions by doing: 

pyh.pyhcheck('hello')

cd ~/Documents/Python/PyHipp

# Count number of items in the directory

df1 = pyh.DirFiles()

cd PyHipp

# Count number of items in the directory

df2 = pyh.DirFiles()

# Add both objects together

df1.append(df2)

# Plot the number of items in the first directory

df1.plot(i=0)

# Plot the number of items in the second directory

df1.plot(i=1)

# Test to make sure you are able to read EDF files: 
# Change to a directory that contains EDF files, e.g.:

cd /Volumes/Hippocampus/Data/picasso-misc/20181105

# Enter the following command: 

samples, events, messages = edf.pread('181105.edf', filter='all')

# You can create objects by doing:

rl = pyh.RPLParallel()

uy = pyh.Unity()

el = pyh.Eyelink()

# You can create plots by doing:

rp = PanGUI.create_window(rl)

up = PanGUI.create_window(uy)

ep = PanGUI.create_window(el)
```

## Credentials (Stored in `.env`)

[AWS Console](https://298402190365.signin.aws.amazon.com/console)

```bash
arn:aws:iam::298402190365:user/zm-user

# Topic ARN
298402190365

# GitHub Key
...

# AWS SNS Subscribe
aws sns subscribe --topic-arn arn:aws:sns:ap-southeast-1:298402190365:awsnotify --protocol email --notification-endpoint e0426185@u.nus.edu

aws sns publish --topic-arn arn:aws:sns:ap-southeast-1:298402190365:awsnotify --message "ClusterTest"

# AWS Credentials
username: zm-user (non-root)
key_id: ...
access_key: ...
default region name: ap-southeast-1
default output format: json
```

## Create snapshot

```bash
update_snapshot.sh data 2 MyCluster01
```

The first argument is the name of the snapshot, the second number specifies how many similarly named snapshots to keep, while the last argument specifies the name of the cluster you want to base the snapshot on. Keep in mind that each snapshot you keep will use up some of your AWS credits. This command might take a while, so you can return once you receive the email notification.

## Check snapshot created

```bash
aws ec2 describe-snapshots --owner-ids self --query 'Snapshots[]' --region=ap-southeast-1
```

### Any errors in cluster env, check AWS credentials

```bash
cat ~/.aws/config
Local: region = ap-southeast-1

cat ~/.aws/credentials

# If doesn’t match
aws configure
```

### Bash Notes

* Replace file `$ output > out.txt`
* Append to file `$ output >> out.txt`

## EC2 Creation (Mainly only for Head Node at most)

Can help create another small t2-micro instance for misc tasks

```bash
aws ec2 create-key-pair --key-name MyKeyPair --query 'KeyMaterial' --output text > ~/MyKeyPair.pem
aws ec2 run-instances --image-id resolve:ssm:/aws/service/ami-amazon-linux-latest/amzn2-ami-hvm-x86_64-gp2 --instance-type t2.micro --key-name MyKeyPair
aws ec2 describe-instances --filter "Name=instancetype,Values=t2.micro" --query "Reservations[].Instances[].PublicIpAddress"
aws ec2 describe-instances --filter "Name=instancetype,Values=t2.micro" --query "Reservations[].Instances[].InstanceId"
aws ec2 terminate-instances --instance-ids
```

## Cluster Config Notes

```bash
cat ~/cluster-config.yaml

...

SharedStorage
  MountDir: data
^ mounts the EBS storage at /data
```

## Cluster Setup

1. ALWAYS START WITH EDITING ~/cluster_config.yaml
    1. Includes COPYING snapshot to my own snapshots and get a NEW snapshotId
    2. Make sure the data folder is correctly named (not always /data)
    3. Then do `pcluster create-cluster` (create the head node and wait for email notif) and ssh into it
    4. Once ssh, try to `cd /data`. If cannot find dir, wait a while more for AWS to mount the volume and try again
2. Don’t try to scp things from my laptop to the head node because of the stupid inbound traffic config that always fail. Especially if it says "create a slurm script", means just create a new file in the head node with touch and nano… NOT SUPPOSED TO SCP ANYWAY
3. `cp -r /aws ~/.aws` (otherwise just do `aws configure`)
4. `/data/miniconda3/bin/conda init`
5. `source ~/.bashrc`
6. `conda activate env1`
7. `nano slurm-script.sh`
8. `sbatch slurp-script.sh` (if command not found, log out and log back in, same with any `s***` command)
9. `squeue`
    1. `scancel {id_start..id_end}` to cancel jobs
10. `exit`
11. `(aws) update_snapshot.sh data 2` TO SAVE SNAPSHOT!!!
12. `(aws) pcluster delete-cluster …`

`srun --pty /bin/bash` to change to the compute node instance

## Billing

1. Instances (filter=running)
2. Billing page (expand all, mainly on EC2)
3. Credits page
4. Cost explorer page

## Change compute node instance types

If you do not have any jobs running, you can use the following command on your computer to change the instance type of your compute nodes after editing the config file without having to delete and re-create the cluster:

```bash
(aws) $ pcluster update-compute-fleet --status STOP_REQUESTED --region ap-southeast-1 --cluster-name MyCluster01
(aws) $ pcluster update-cluster --cluster-configuration ~/cluster-config.yaml --cluster-name MyCluster01
```

## Multiple Clusters Config with t2.micro

```bash
ssh -i ~/MyKeyPair.pem ec2-user@<T2.MICRO IP>

# !!! Edit cluster_config.yaml and pcluster create head node and other clusters

pcluster create-cluster --cluster-configuration ~/cluster-config.yaml --cluster-name MyCluster01

# WAIT FOR EMAIL and use AWS instances for 2/2 checks

pcluster list-clusters --region ap-southeast-1
pcluster ssh -i ~/MyKeyPair.pem --region ap-southeast-1 --cluster-name MyCluster01

# WAIT FOR /DIR TO MOUNT, WAIT FOR SQUEUE, ACTIVATE CONDA ENV1
```

1. From AWS instances, get the InstanceId and public IP
2. Go to AWS Lambda and update the termination InstanceId
3. `cd /data/src/PyHipp` and `git pull`
4. COPY AWS TO .AWS `cp -r aws ~/.aws` and `cp bashrc ~/.bashrc`
5. Edit PyHipp `ec2snapshot.sh` file to use t2.micro IP and correct cluster names in 2 places (and also the mounted dir if need)
6. `(aws) $ scp -i ~/MyKeyPair.pem ~/MyKeyPair.pem ec2-user@<CLUSTER IP>:/data` to transfer the key to cluster
7. CONDA ACTIVATE FIRST!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!
8. `cd` to `20181105` and `sbatch` from `/data/src/PyHipp/pipe2.sh`; from PyHipp folder (git pull if need)
9. `sbatch consol_job.sh`; also from PyHipp
10. EMAILS & TRACK SQUEUE
    1. `pcluster ssh -i ~/MyKeyPair.pem --region ap-southeast-1 --cluster-name MyCluster01 squeue`
    2. JobDone for the jobs stuffs
    3. state:terminated for cluster node termination
    4. ClusterTerminated for AWS EventBridge notif
    5. AWS snapshot updated and instance removed
11. `pcluster delete-cluster --region ap—southeast-1 --cluster-name …` (otherwise won’t be able to create cluster with same name next time, not able to SSH into it as well because it’s technically terminated)
12. `pcluster list-clusters --region ap-southeast-1`

## Correct Number of Output Files

### `.hkl` Files

1. `/session01`: `rplparallel`, `unity`, `eyelink` = 3
2. n channel directories: `rplraw`, `rpllfp`, `rplhighpass` = 3n
3. `/sessioneye`: `rplparallel`, `eyelink` = 2
4. n channel directories: `rplraw`, `rpllfp`, `rplhighpass` = 3n

* Total = 3 + 2 + 3n + 3n = 5 + 6n
* If n = 8, total = 5 + 6 * 8 = 53
* If n = 110, total = 5 + 6 * 110 = 665

* `rpllfp*.hkl` = 3n = 3 * 110 = 330
* `rplhighpass*.hkl` = 3n = 3 * 110 = 330
* "Don't need to regenerate spike sorting files" means use `sort-slurm.sh` instead of `rplhighpass-sort-slurm.sh`

### `firings.mda` Files (If neural data present)

Total = n channels

### If No Neural Data

* If no neural data for particular day, only `rplparallel` will run
* Generates the 5 `/session*` data
* So total number of `.hkl` files should be 5 x d

## Maximizing vCPUs

### `m5a.large` Head Node and `m5a.4xlarge` Compute Nodes

* `m5a.4xlarge`: 16 vCPUs
* `m5a.2xlarge`:  8 vCPUs
* `m5a.xlarge` :  4 vCPUs

64 vCPUs = Head Node x2 + t2.micro x2 + 60 free vCPUs

* `+ 4xlarge x3 = 16x3 = 48 vCPUs`
* `+ 2xlarge x1 =  8x1 = 48 + 8 = 56 vCPUs`
* `+ xlarge  x1 =  4x1 = 56 + 4 = 60 vCPUs`

Total 5 email notifications of compute node started up for the 60 vCPUs

### `t3.large` Head Node and `z1d.2xlarge` Compute Nodes

* `z1d.2xlarge`: 8 vCPUs
* `z1d.xlarge`:  4 vCPUs

64 vCPUs = Head Node x2 + t2.micro x2 + 60 free vCPUs

* `+ 2xlarge x3 = 8x7 = 56 vCPUs`
* `+ xlarge  x1 = 4x1 = 56 + 4 = 60 vCPUs`

Total 4 email notifications of compute node started up for the 60 vCPUs

## Update cluster_config.yaml while cluster is running

```bash
pcluster update-compute-fleet --status STOP_REQUESTED --region ap-southeast-1 --cluster-name MyCluster01

pcluster describe-cluster --region ap-southeast-1 --cluster-name MyCluster01
>> "computeFleetStatus": "STOPPED",

pcluster update-cluster --cluster-configuration ~/cluster-config.yaml --cluster-name MyCluster01

pcluster update-compute-fleet --status START_REQUESTED --region ap-southeast-1 --cluster-name MyCluster01

pcluster describe-cluster --region ap-southeast-1 --cluster-name MyCluster01
>> "computeFleetStatus": "RUNNING",
```

---

# SUMMARY

```bash
ssh -i ~/MyKeyPair.pem ec2-user@<T2.MICRO IP>

nano ~/cluster_config.yaml
cat ~/cluster_config.yaml

pcluster create-cluster --cluster-configuration ~/cluster-config.yaml --cluster-name MyCluster01

# Access one of the compute nodes with 64GB memory if need to run intensive stuffs in single thread
srun --pty /bin/bash

# Get InstanceId and public IP either from AWS Console or `describe-cluster` and update AWS Lambda

pcluster list-clusters --region ap-southeast-1
pcluster ssh -i ~/MyKeyPair.pem --region ap-southeast-1 --cluster-name MyCluster01

squeue
cd /data

# If new snapshot (eg. from quizzes)
aws configure
scp -i ~/MyKeyPair.pem ~/MyKeyPair.pem ec2-user@<PUBLIC IP>:/data

cp -r aws ~/.aws
cp bashrc ~/.bashrc
source ~/.bashrc
source miniconda/bin/activate
conda activate env1

git clone https://github.com/zhermin/PyHipp  # clone into /data/src
cd pyh  # cd /data/src/PyHipp
git pull

# Edit ec2snapshot.sh if cluster name or data dir changed

cd day  # cd /data/picasso/20181105
envlist.py cenv 64
sbatch /data/src/PyHipp/_.sh  # or pipe*.sh
sbatch --dependency=afterok:1:2:3:4:5:6 /data/src/PyHipp/consol_jobs.sh  # manually type in afteroks
squeue
scancel {jobId...jobId}
source /data/src/PyHipp/checkfiles2.sh

# Exit back to t2.micro
exit
./update_snapshot.sh data 2 MyCluster01
pcluster delete-cluster --region ap-southeast-1 --cluster-name MyCluster01
pcluster list-clusters --region ap-southeast-1

# Copy files from cluster to local
(aws) $ scp -i ~/MyKeyPair.pem -p "ec2-user@<PUBLIC IP>:/data/picasso/**/freq*.hkl" .
```

# MISCELLANEOUS

* `update_snapshot.sh`, ie. updating snapshots don't require clusters to be running
* Hence why `ec2snapshot.sh` requests cluster stop then update snapshots together
* Can take hours (>2h) to finish updating don't panic if AWS status is pending at 0%
* SnapshotComplete AWS EventBridge Event will terminate cluster using Lambda function set to the correct instanceId and then send SNS notification upon successful update of snapshot (hence closing the cluster connection)
* For new IAM users, they need Admin (EC2, S3, EBS) and ECS access to create and delete clusters and access EBS and S3 storages
  * NOPE. Admin already has all access, adding more makes no difference; the bug is somewhere else
* For cluster deletion failure, check CloudFormation for error messages; likely is auto-generated cluster nodes not deleted cleanly in Route 53 (so delete all but the NS and SOA ones)
* `consol_jobs.sh` is to get the SUBSEQUENT queued jobs, not the original sbatch ones
* **!!! MAKE SURE THERE IS !!!** `envlist.hkl` in `/data/picasso` if not no mountain sort, no mda files!
* Remember to start slurm scripts with `python -u -c "import PyHipp as pyh; \` and end with `"` to close the script properly

## `DPT.objects.processDirs()`

Either `processDirs(level="...", cmd="...")` to actually process some directories using the command

Or `processDirs(dirs=None, objtype=pyh.<some object>)` to process pre-processed pyh objects such as:

```python
pyh.RPLParallel  #  
pyh.RPLSplit     # 
pyh.RPLLFP       # lowpass objects
pyh.RPLHighPass  # highpass objects
pyh.Unity        # 
pyh.FreqSpectrum # freqspectrum viz objects (lab 7)
pyh.Waveform     # waveform viz objects (lab 7 step 6)
pyh.VMPlaceCell  # 
```

# BASH

```bash
# Days selected
grep "2018101[67]" oct_channels.txt | grep array01 > c1617.txt
grep 20181016 c1617.txt | cut -d "/" -f 4 > channels.txt

# Days without Neural Data (Aug to Oct 2018)
ls -d 20180??? 201810??

# Channels | Lowpass | Highpass | Firings.mda
find . -name "channel*" | grep -v -e eye -e mountain | sort | cut -d "/" -f 1-4 > chs.txt
find . -name "rpllfp*hkl" | grep -v -e eye -e mountain | sort | cut -d "/" -f 1-4 > lfp.txt
find . -name "rplhighpass*hkl" | grep -v -e eye -e mountain | sort | cut -d "/" -f 1-4 > hps.txt
find . -name "firings.mda" | grep -v -e eye -e mountain | sort | cut -d "/" -f 3 > mda.txt

# Find uncommon lines between two files, remove empty lines (and add prefix if needed)
comm -23 chs.txt mda.txt | sed -r '/^\s*$/d'  # | ts 'mountains/' | tr -d ' '
grep -v -F -f mda.txt chs.txt > missing.txt  # find missing firings.mda files

# Run script on missing files and dirs, run from each day's dir

# Missing Lowpass
cwd=`pwd`; for i in `comm -23 raw.txt lfp.txt`; do echo $i; cd $i; sbatch /data/src/PyHipp/rpllfpfs-slurm.sh; cd $cwd; done

# Missing Highpass
cwd=`pwd`; for i in `comm -23 raw.txt hps.txt`; do echo $i; cd $i; sbatch /data/src/PyHipp/rplhpsfs-slurm.sh; cd $cwd; done

# Missing Firings.mda
cwd=`pwd`; for i in `cat missing.txt`; do echo $i; cd $i; sbatch /data/src/PyHipp/rplhighpass-sort-slurm.sh; cd $cwd; done

# Generate cumulative FreqSpectrum objects
cwd=`pwd`; for i in `find 2018110? -name "channel*" | grep -v -e eye -e mountains | sort`; do echo $i; cd $i; sbatch /data/src/PyHipp/freq-slurm.sh; cd $cwd; done

# Generate only for channels in array01 for 20181016 and 20181017
cwd=`pwd`; for i in `find 2018101[67] -name "channel*" | grep array01 | sort`; do echo $i; cd $i; sbatch /data/src/PyHipp/fsa1-slurm.sh; cd $cwd; done
```
