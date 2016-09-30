#!/bin/bash

AWSCLI="/usr/bin/aws"
SMTPCLI="/home/ec2-user/smtp-cli"
LOGDIR="/home/ec2-user/logs"
LOG="aws-ami-backup.log"
KEYSMTP="_your_keysmtp"
SECRETKEYSMTP="_your_secretkey_smtp"
PROFILE="_your_aws_cli_profile"
ACCOUNTID="_your_account_id"
MAILFROM="AWS AMI Backups <_your_gmail_account@gmail.com>"
MAILTO="_your_team_email_account@gmail.com"


###Create AMIS:

$AWSCLI  ec2 describe-instances --filter Name=tag:Backup,Values=TRUE --query 'Reservations[*].Instances[*].[InstanceId]' --profile $PROFILE  \
| while read i ; do $AWSCLI ec2 create-image --instance-id $i --name $i-$(date +%Y%m%d%H%M) --no-reboot --profile $PROFILE \
| while read a ; do $AWSCLI ec2 create-tags --resources $a --tags Key=Name,Value=$i-$a-$(date +%Y%m%d%H%M) --profile $PROFILE ; \
echo $i-$a-$(date +%Y%m%d%H%M) >> $LOGDIR/$LOG ; done ; done


###Deregister AMIS older than 10 days:

$AWSCLI ec2 describe-images --owner $ACCOUNTID --profile $PROFILE \
| grep `date +%Y-%m-%d --date '10 days ago'` | awk '{ print $5 }' \
| while read i ; do $AWSCLI ec2 deregister-image --image-id $i --profile $PROFILE ; done


###Delete SNAPSHOTS older than 10 days:

$AWSCLI ec2 describe-snapshots --owner $ACCOUNTID --profile $PROFILE \
| grep `date +%Y-%m-%d --date '10 days ago'` | awk '{print $12 }' \
| while read i ; do aws ec2 delete-snapshot --snapshot-id $i --profile $PROFILE ; done


###Send email with reports:

$SMTPCLI --host email-smtp.us-west-2.amazonaws.com:587 \
--user $KEYSMTP \
--auth-plain \
--from="$MAILFROM" \
--to $MAILTO \
--pass $SECRETKEYSMTP \
--body-plain=/home/ec2-user/logs/aws-ami-backup.log \
--subject="AWS _your_account_id AMIs successfully created on $(date)" \
--missing-modules-ok


#Keep a LOG copy for up to ten days:

if test -d $LOGDIR
	then
		cd $LOGDIR
			if test -s $LOG
				then
				test -f $LOG.9 && mv $LOG.9 $LOG.10
				test -f $LOG.8 && mv $LOG.8 $LOG.9
				test -f $LOG.7 && mv $LOG.7 $LOG.8
				test -f $LOG.6 && mv $LOG.6 $LOG.7
				test -f $LOG.5 && mv $LOG.5 $LOG.6
				test -f $LOG.4 && mv $LOG.4 $LOG.5
				test -f $LOG.3 && mv $LOG.3 $LOG.4
				test -f $LOG.2 && mv $LOG.2 $LOG.3
				test -f $LOG.1 && mv $LOG.1 $LOG.2
				test -f $LOG.0 && mv $LOG.0 $LOG.1
				mv $LOG $LOG.0
				cp /dev/null $LOG
				chmod 644 $LOG
				sleep 5
			fi
fi
exit 0
