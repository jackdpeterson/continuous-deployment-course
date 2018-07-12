** notes: Uses puppet version 4.10

```

    curl -O https://apt.puppetlabs.com/puppetlabs-release-pc1-xenial.deb
    sudo dpkg -i puppetlabs-release-pc1-xenial.deb
    sudo apt-get update

sudo apt-get install puppet-agent

```
***  provisioning:

Add dependencies
```
$ librarian-puppet install
```


execution (Configuration Management)
```
$ sudo /opt/puppetlabs/bin/puppet apply /home/ubuntu/continuous-deployment-course/puppet/manifests/awscdimage72.pp --modulepath=/home/ubuntu/continuous-deployment-course/puppet/modules/ --hiera_config=/home/ubuntu/continuous-deployment-course/puppet/hiera.yaml
```

