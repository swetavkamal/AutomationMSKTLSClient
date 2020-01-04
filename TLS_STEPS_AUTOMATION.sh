
#!/bin/bash
# Script to automate the steps of creating a client machine for TLS based MSK cluster
# This script automates the step of below doc from AWS :
# https://docs.aws.amazon.com/msk/latest/developerguide/msk-authentication.html
#
# Variables to be passed to script :
# 1. ALIAS NAME
# 2. Certificate authority ARN
# 3. Store pass
# 4. Key pass
# 
# 
#
# Usage: sh TLS_STEPS_AUTOMATION.sh Example-Alias <your-certificate-autority-arn> changeit changeit 
# -----------------------------------------------------------------------------------------


alias_name=$1
echo "Alias name given by you " $alias_name


certificate_authority_arn=$2
echo "certificat authority arn provide by you: " $certificate_authority_arn

storepass=$3
echo "Your store pass is " $storepass

keypass=$4
echo "Your key pass is " $keypass


# Getting the certs from jvm path t create the truststore jks file
cacerts_path=$(find /usr/lib/jvm  -name cacerts)
cp $cacerts_path kafka.client.truststore.jks
echo "java certs file copied at" $cacerts_path

#Calling Keytool to generate the keystore
keytool -genkey -keystore kafka.client.keystore.jks -validity 300 -storepass $storepass -keypass $keypass -dname "CN=Distinguished-Name" -alias $alias_name -storetype pkcs12
echo "test"
if [ $? -eq 0 ];then
        echo "keystore generate"
else
        echo "keygen generation error "
fi

#Creating certificate request..
keytool -keystore kafka.client.keystore.jks -certreq -file client-cert-sign-request -alias $alias_name -storepass $storepass -keypass $keypass
if [ $? -eq 0 ];then
        echo "certificate request at file "
else
        echo "certificate request failed "
fi

#Modifying the client-cert-sign request to remove the NEW character
sed -i 's/BEGIN NEW CERTIFICATE/BEGIN CERTIFICATE/g' client-cert-sign-request
sed -i 's/END NEW CERTIFICATE/END CERTIFICATE/g' client-cert-sign-request


echo " Calling issue certificate command "
echo "certificate-authority-arn is  " $certificate_authority_arn

echo "Client cert sign file is generated "
echo "********************************************"

# calling aws command to issue the certificate..
CertificateArn=$(aws acm-pca issue-certificate --certificate-authority-arn $certificate_authority_arn  --csr file://client-cert-sign-request --signing-algorithm "SHA256WITHRSA" --validity Value=300,Type="DAYS")


#Formating  the certificate ARN from the last command
CertificateArntrimmed="arn"$(echo $CertificateArn |sed -e 's/\(^.*arn\)\(.*\)\(".*$\)/\2/')
sleep 3
echo $CertificateArntrimmed

#Calling for get certificate by passing certificate autority and certificate arn from last command
aws acm-pca get-certificate --certificate-authority-arn $certificate_authority_arn --certificate-arn $CertificateArntrimmed > certificate-file

# Formatting the certificate file that we got from last line

# Finding \n in the file and removing replacing it with new line character
sed -i 's/\\n/\'$'\n''/g' certificate-file

#Removing extra terms such as Certificate and certificateChain
sed -i 's/"CertificateChain":/''/g' certificate-file
sed -i 's/"Certificate":/''/g' certificate-file

#Remove characters such as { } " ,
sed -i 's/{/''/g' certificate-file
sed -i 's/}/''/g' certificate-file
sed -i 's/\"/''/g' certificate-file
sed -i 's/,/''/g' certificate-file

# After formating copy the certificate first and certifcate chain first

# Need to identify the certificate and chain.. After first END CERTIFICATE we will have certs while before that there will be chain
certificate_start_line=$(awk  -v n=1 '/-----END CERTIFICATE-----/ {print NR }' certificate-file | head -1)
certificate_end_line=$(awk  -v n=1 '/-----END CERTIFICATE-----/ {print NR }' certificate-file | tail -1)

certificate_chain_start=1
certificate_chain_end=$(awk  -v n=1 '/-----END CERTIFICATE-----/ {print NR }' certificate-file | head -1)

#Copy the certs part first to new file and then append chain part to the new file
awk -v s=$certificate_start_line -v e=$certificate_end_line 'NR>s&&NR<=e' certificate-file >new_certificate_file

awk -v s=$certificate_chain_start -v e=$certificate_chain_end 'NR>=s&&NR<=e' certificate-file >> new_certificate_file

#Final formatting which would include adding new line at the end of file removing trail spaces and removing blanks
echo "">> new_certificate_file
sed "s/^[ \t]*//" -i new_certificate_file
sed 's/[[:blank:]]*$//' new_certificate_file -i
sed 's/\$/''/g' new_certificate_file -i

#Call to import the certificate to the keystore
keytool -keystore kafka.client.keystore.jks -import -file new_certificate_file -alias $alias_name -storepass $storepass -keypass $keypass -noprompt



