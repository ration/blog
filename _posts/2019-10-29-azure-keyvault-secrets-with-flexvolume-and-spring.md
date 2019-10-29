---
layout: post
title:  Using Azure Keyvault Secrets as Spring Properties in Azure Kubernetes Servive
date:   2019-10-29 10:53:10 +0300
tags: [kubernetes, azure, docker, spring-boot]
---

Time for some _probably too good for your own good_ magic. The [Azure
Key Vault](https://azure.microsoft.com/en-us/services/key-vault/) is
Azures solution to deliver cryptographic secrets in a cloud
environment. You can use this to e.g. store passwords and certificates in a centralized
yet secure location in a cloud enviroment. 

So how do you get these secrets available to your containerized Spring
Boot App? Well you can use the [Key Vault
Library](https://docs.microsoft.com/en-us/java/azure/spring-framework/configure-spring-boot-starter-java-app-with-azure-key-vault?view=azure-java-stable)
for example, but if for some reason you don't want or are unable to
modify the implementation you need to come up with a way to pass the
secrets to the application during runtime.

We are going to use
[FlexVolume](https://github.com/Azure/kubernetes-keyvault-flexvol) for
this.  It allows you to access secrets, keys and certificates from
your pod. It will simply mount the desired secrets into a file that is
available inside the container, e.g. `/mnt/secret.property` which then
contains the secret value.

## Setting it up

First you need to go to The [Azure
Key Vault](https://azure.microsoft.com/en-us/services/key-vault/) page
to get all the necessary bootstrapping done. Once you have gone
through those hoop, you should be ready to mount secrets into the pod.

Say for example we have a database password we would like to mount
into the container. To mount _/secrets/database-password_ to contain this
password we first declare the
[VolumeMount](https://kubernetes.io/docs/concepts/storage/volumes/)
for Kubernetes:

{% highlight yaml %}
volumeMounts:
   - name: test
      mountPath: /secrets
      readOnly: true
{% endhighlight %}

Then we could use this in our container, for example nginx:
{% highlight yaml %}
apiVersion: v1
kind: Pod
metadata:
  name: nginx-flex-kv
spec:
  containers:
  - name: nginx-flex-kv
    image: nginx
    volumeMounts:
    - name: test
      mountPath: /secrets
      readOnly: true
  volumes:
  - name: test
    flexVolume:
      driver: "azure/kv"
      secretRef:
        name: kvcreds                             
      options:
        keyvaultname: "my-key-vault"              
        keyvaultobjectnames: "key-vault-database-password-key"  
     	keyvaultobjectaliases: "database-password" 
        keyvaultobjecttypes: secret               
        resourcegroup: "testresourcegroup"       
        subscriptionid: "testsub"                 
        tenantid: "testtenant"  
{% endhighlight %}

This would mount the key vault secret named
"key-vault-database-password-key" into _/secrets/database-password_
and it contains the password as its content.

This is fine and dandy, but how do you make the application know that
there is a file called _/secrets/database-password_ and its contents is 
the password? Or worse, what if you can't even modify this? Say the
application assumes that the database password must be in a Spring
property called _app.database.password_?

## Creating Spring Properties File From The Secrets

Let's create a single file with all the secrets and format it as a
Spring properties file. Let's start with a Kubefile again, say we
have our app image _my-spring-boot-app_:

{% highlight yaml %}
apiVersion: v1
kind: Pod
metadata:
  name: my-spring-boot-app
spec:
  containers:
  - name: my-spring-boot-app
    image: my-app-image
    volumeMounts:
    - name: test
      mountPath: /secrets/
      readOnly: true
  volumes:
  - name: flexvol
    flexVolume:
      driver: "azure/kv"
      secretRef:
        name: kvcreds                             
      options:
        keyvaultname: "my-key-vault"
        keyvaultobjectnames: "db-password;ssl-key"
        keyvaultobjectaliases: "app.db.password;app.ssl.key"
        keyvaultobjecttypes: secret;secret
        resourcegroup: "my-rg"
        subscriptionid: "my-testsub"
        tenantid: "my-tenant"    
{% endhighlight %}

With this, we would have a directory _/secrets/_ with two files,
_app.db.password_ and _app.ssl.key_. So now we have files names with
values, but we need a single file with properties with values. So we want to get this
data into a single file that has a key-value pair of this data, such as _/app/secrets.properties_:

{% highlight properties %}
app.db.password=324r2rfdlskj
app.ssl.key=234riojgfds89glk
{% endhighlight %}

We can modify our Docker container to read all the secrets from
disk and append them into a single file and then start the container:

So this is our Spring boot application container Dockerfile:
{% highlight docker %}
FROM anapsix/alpine-java:8
ARG JAR_FILE
ENV FINAL_JAR=/app/$JAR_FILE
ENV KVMOUNT=/secrets
ENV PROPERTIES_FILE=/config/application.properties
ENV SECRET_FILE=/app/secrets.properties
ENV ENTRYCLASS=fi.lahtela.demo
WORKDIR /app
COPY target/$JAR_FILE .
# Extract the kvmount as key value pairs generate a properties file
ENTRYPOINT echo > $SECRET_FILE && for i in $(ls $KVMOUNT 2>/dev/null); do echo "$i=$(cat $KVMOUNT/$i)" >> $SECRET_FILE; done && java -XX:+UnlockExperimentalVMOptions -XX:+UseCGroupMemoryLimitForHeap -cp $FINAL_JAR -Dloader.path=/app/lib/ -Dspring.config.location=$PROPERTIES_FILE,$SECRET_FILE -Dloader.main=$ENTRYCLASS org.springframework.boot.loader.PropertiesLauncher
{% endhighlight %}

During startup, the docker container appends all the secrets to the _/app/secrets.properties_
file. Here _/config/application.properties would be hour Spring
properties file that contains all the other properties. So we have two
files, one with the secrets, and another with everything else.

This could also be a separate layer in the Docker container for the
same effect.


