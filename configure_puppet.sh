#!/usr/bin/env bash
## Puppet installation
curl -O https://apt.puppetlabs.com/puppetlabs-release-pc1-xenial.deb
sudo dpkg -i puppetlabs-release-pc1-xenial.deb
sudo apt-get update
sudo apt-get install puppet-agent librarian-puppet
sudo ln -s /opt/puppetlabs/puppet/bin/puppet /usr/local/bin/puppet


## update puppet modules
cd puppet && librarian-puppet install

## add local modules
cp -r local_modules/site_reliability_engineering modules/

## apply the puppet plan
sudo puppet apply /home/ubuntu/continuous-deployment-course/puppet/manifests/awscdimage72.pp --modulepath=/home/ubuntu/continuous-deployment-course/puppet/modules/ --hiera_config=/home/ubuntu/continuous-deployment-course/puppet/aws.yaml
