#!/bin/bash

# Variables
BUCKET_NAME="s3-ec2-project-bucket"
FOLDER_PATH="/home/ec2-user/s3-backup-folder"
CRON_SCHEDULE=$1

# Check if the cron schedule is provided
if [ -z "$CRON_SCHEDULE" ]; then
  echo "Usage: ./setup_s3_backup.sh <cron-schedule>"
  echo "Example cron-schedule: '0 * * * *' for hourly backup"
  exit 1
fi

# Step 1: Create the folder if it doesn't exist
mkdir -p "$FOLDER_PATH"
echo "Created folder $FOLDER_PATH"

# Step 2: Download all contents from the S3 bucket to the folder
aws s3 cp "s3://$BUCKET_NAME/" "$FOLDER_PATH/" --recursive

if [ $? -eq 0 ]; then
  echo "Downloaded contents from $BUCKET_NAME to $FOLDER_PATH"
else
  echo "Failed to download contents from $BUCKET_NAME"
  exit 1
fi

# Step 3: Set up a cron job for backing up the folder to the S3 bucket at the specified schedule
CRON_JOB="$CRON_SCHEDULE /usr/bin/aws s3 cp $FOLDER_PATH/ s3://$BUCKET_NAME/ --recursive"

# Add the cron job
(crontab -l 2>/dev/null; echo "$CRON_JOB") | crontab -

if [ $? -eq 0 ]; then
  echo "Cron job added for backup of $FOLDER_PATH to s3://$BUCKET_NAME"
else
  echo "Failed to add cron job"
  exit 1
fi
