# AutomationMSKTLSClient
This script automates the client creation for TLS based MSK

 Script to automate the steps of creating a client machine for TLS based MSK cluster
 This script automates the step of below doc from AWS :
 https://docs.aws.amazon.com/msk/latest/developerguide/msk-authentication.html

 Variables to be passed to script :
 1. ALIAS NAME
 2. Certificate authority ARN
 3. Store pass
 4. Key pass

 

 Usage: sh TLS_STEPS_AUTOMATION.sh Example-Alias <your-certificate-autority-arn> changeit changeit 
