gcloud compute resource-policies create instance-schedule gitlab-instance-schedule \
    --description='Auto start & stop schedule for gitlab instance' \
    --region='us-west1' \
    --vm-start-schedule='45 7 * * 1-5' \
    --vm-stop-schedule='30 18 * * 0-6' \
    --timezone='CET'
