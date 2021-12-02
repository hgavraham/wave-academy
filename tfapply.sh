#!/bin/bash
start_time=$(date +%s)


#terraform init
#sleep 3
terraform apply -auto-approve

end_time=$(date +%s)
echo ""
echo "----------------------"
echo "Time elapsed: $(date -d@$(($end_time - $start_time)) -u +%H:%M:%S)"
echo "----------------------"

