#!/bin/bash

NOW=$(date +"%Y-%m-%dT%H:%M")

### Configuration Options ###

# A name for this experiment to distinguish it in log outputs etc.
EXPERIMENT_NAME="imp_train-$NOW"
# The directory on the euler cluster where to place run-files. Anything inside this directory will be deleted when
# running this script!
REMOTE_DIR="/cluster/project/rsl/rothpa/SemNav"
# The directory on the euler cluster where to place temporary files.
TEMP_DIR="/cluster/project/rsl/rothpa/temp"
# The directory on the euler cluster where to place the files shared amongst processing nodes.
SHARED_DIR="/cluster/project/rsl/rothpa/shared"
# The LOCAL directory where the trainings data is stored --> will be synced to the euler cluster
DATA_DIR="/home/pascal/SemNav/env/data_pc"
# The script in the legged_gym/scripts/ directory to run.
COMMAND="EXPERIMENT_DIRECTORY=/app/shared python /app/shared/imperative_planning_learning/multi_env.py"
# SSH access (user@domain). You should setup SSH access via private/public keys for this user!
SSH="rothpa@euler.ethz.ch"

### Don't modify anything below ###

# sync data
echo "Sync Data ..."
rsync -azPv $DATA_DIR $SSH:$SHARED_DIR

# create run scripts and docker container

DIR=$( cd -- "$( dirname -- "${BASH_SOURCE[0]}" )" &> /dev/null && pwd )

echo "Setting Up Files ..."

cd "$DIR"

cat <<EOT > docker_run.sh
#!/bin/bash
echo "Running $COMMAND"
$COMMAND
EOT
chmod a+x docker_run.sh

mkdir "euler_scripts/"
SINGULARITY_COMMAND="singularity run --writable-tmpfs --nv --bind $SHARED_DIR:/app/shared, $TEMP_DIR/job"
cat <<END_OF_SCRIPT > euler_scripts/run.sh
#!/bin/bash

env2lmod
module load cuda cudnn nccl

cat <<EOT > job.sh
#!/bin/bash

#SBATCH -n 1
#SBATCH --cpus-per-task=16
#SBATCH --gpus=rtx_3090:1
#SBATCH --time=23:00:00
#SBATCH --mem-per-cpu=6144
#SBATCH --mail-type=END
#SBATCH --mail-user=roth.pascal@outlook.de
#SBATCH --job-name=$EXPERIMENT_NAME

echo "Running \"$SINGULARITY_COMMAND\""
eval "$SINGULARITY_COMMAND"
EOT

sbatch < job.sh
rm job.sh
END_OF_SCRIPT
chmod a+x "euler_scripts/run.sh"

cat <<EOT > euler_scripts/wait_and_run.sh
#!/bin/bash

echo -n "Waiting for deployment to finish ..."
while [ ! -f $TEMP_DIR/.euler-deployment-done-$EXPERIMENT_NAME.txt ]
do
    sleep 1
    echo -n "."
done
echo ""

sleep \$((RANDOM % 60))

./run.sh
EOT
chmod a+x "euler_scripts/wait_and_run.sh"

echo "Uploading Scripts ..."

cd "$DIR"
ssh -T "$SSH" << EOL
    mkdir -p $REMOTE_DIR/
    rm -rf $REMOTE_DIR/*
EOL
scp euler_scripts/* "$SSH:$REMOTE_DIR/"

echo "Building Docker Container ..."

cd "$DIR"
docker build ./ -t job

echo "Uploading Docker Tarball ..."

cd "$DIR"
ssh -T "$SSH" << EOL
    mkdir -p $TEMP_DIR/app/
    cd $TEMP_DIR/
    rm -rf job.tar job
EOL
docker save job -o job.tar
scp job.tar "$SSH:$TEMP_DIR/"

echo "Creating Singularity Image on Remote Host ..."

ssh -T "$SSH" << EOL
    cd $TEMP_DIR/
    singularity build job docker-archive://job.tar
    touch .euler-deployment-done-$EXPERIMENT_NAME.txt
EOL

echo "Cleaning Up ..."

rm job.tar
rm -rf euler_scripts/
rm docker_run.sh

ssh -T "$SSH" << EOL
    rm $TEMP_DIR/job.tar
    apptainer cache clean -f
EOL
