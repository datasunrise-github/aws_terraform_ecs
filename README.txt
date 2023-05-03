________          __           _________                  .__
\______ \ _____ _/  |______   /   _____/__ __  ___________|__| ______ ____
 |    |  \\__  \\   __\__  \  \_____  \|  |  \/    \_  __ \  |/  ___// __ \
 |    `   \/ __ \|  |  / __ \_/        \  |  /   |  \  | \/  |\___ \\  ___/
/_______  (____  /__| (____  /_______  /____/|___|  /__|  |__/____  >\___  >
        \/     \/          \/        \/           \/              \/     \/


Pre-deployment instructions
============================================================================
1. Set these three environment variables:
      AWS_ACCESS_KEY_ID="SET-ACCESS-KEY-HERE"
      AWS_SECRET_ACCESS_KEY="SET-SECRET-KEY-HERE"
      AWS_DEFAULT_REGION="SET-REGION-HERE"
2. Edit the file variables.tf and set all the required variables.


Deployment instructions
============================================================================
1. Execute:
      terraform init
   to initialize the working directory.

!3.22.0+ version of the Terraform AWS provider is required!
If current version is lower, execute:
      terraform init -upgrade
      
2. Execute:
      terraform plan
   to create an execution plan.

3. Execute:
      terraform apply
   to start the deployment.
 
To delete all created resources:
1. Execute:
      terraform destroy