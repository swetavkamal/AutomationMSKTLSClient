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

 

 Usage: sh TLS_STEPS_AUTOMATION.sh Example-Alias your-certificate-autority-arn changeit changeit 


------------------------------------------------------------------------------------------------------

Installation steps:-
```
sudo yum install java-1.8.0 -y
wget https://archive.apache.org/dist/kafka/2.2.1/kafka_2.12-2.2.1.tgz
tar -xzf kafka_2.12-2.2.1.tgz
kafka_2.12-2.2.1/bin/kafka-topics.sh --create --zookeeper ZookeeperConnectString --replication-factor 3 --partitions 1 --topic AWSKafkaTutorialTopic-client1
```

```
sudo yum install git -y
git clone https://github.com/swetavkamal/AutomationMSKTLSClient.git
sh AutomationMSKTLSClient/TLS_STEPS_AUTOMATION.sh Example-Alias arn-of-pca changeit changeit 
```

```
mkdir /tmp/kafka_2.12-2.2.1/
mv certificate-file client-cert-sign-request kafka.client.keystore.jks kafka.client.truststore.jks new_certificate_file /tmp/kafka_2.12-2.2.1/
vim ~/kafka_2.12-2.2.1/client.properties
security.protocol=SSL  
ssl.truststore.location=/tmp/kafka_2.12-2.2.1/kafka.client.truststore.jks 
ssl.keystore.location=/tmp/kafka_2.12-2.2.1/kafka.client.keystore.jks  
ssl.keystore.password=changeit
ssl.key.password= changeit
```

```
kafka_2.12-2.2.1/bin/kafka-console-producer.sh --broker-list BootstrapBroker-String --topic ExampleTopic --producer.config kafka_2.12-2.2.1/client.properties
```
