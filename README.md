# aws-ami-backups

Scripts that help you automate the creation of an Amazon Machine Image (AMI) using the Amazon Command Line Interface for those instances that have a Backup TAG value set to TRUE.


In addition of creating AMIs, the creation script search for expiry date (or a retention period).
Once an AMI has expired, the cleanup script will deregister your AMI and delete associated snapshots. 
