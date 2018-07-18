# -*- mode: ruby -*-
# vi: set ft=ruby :

Vagrant.configure("2") do |config|
  config.vm.box = "hashicorp-vagrant/ubuntu-16.04"
  config.vm.hostname = "udemy-course.local"
  config.ssh.shell = "bash -c 'BASH_ENV=/etc/profile exec bash'"

  system('../shared-modules/vagrant_sudo_setup.sh')


  $install_puppet = "export DEBIAN_FRONTEND=noninteractive && if [ ! -f /opt/puppetlabs/puppet/bin/puppet ]; then cd ~ && wget https://apt.puppetlabs.com/puppetlabs-release-pc1-xenial.deb && dpkg -i puppetlabs-release-pc1-xenial.deb; fi;"
    config.vm.provision "shell", inline: $install_puppet, name: "install puppet"

  $install_other_deps = "export DEBIAN_FRONTEND=noninteractive && apt-get update && apt-get install puppet-agent librarian-puppet bindfs git mercurial bindfs -y && apt-get autoremove -y"
    config.vm.provision "shell", inline: $install_other_deps, name: "apt-get install things"

  # shares
  config.vm.synced_folder "../continuous-deployment-sample-project", "/mnt/web",
    :create => true

$script_bindfs = "export DEBIAN_FRONTEND=noninteractive;
      if ! grep -qs '/home/vagrant/build/mirrors/web' /proc/mounts; then
          mkdir -p /var/www/domains/identity.example.local
          bindfs -u vagrant -g vagrant /mnt/web/ /var/www/domains/identity.example.local/;
      fi;
  "
  config.vm.provision "shell", inline: $script_bindfs, run: "always", name: "bindfs"

  config.vm.provision "shell", inline: "export DEBIAN_FRONTEND=noninteractive; mkdir -p /home/vagrant/build/mirrors", run: "always", name: "make mirrors folder"




$github_add_ssh = "export DEBIAN_FRONTEND=noninteractive; echo 'Add github.com to known_hosts'; mkdir -p /home/vagrant/.ssh && touch /home/vagrant/.ssh/known_hosts && ssh-keyscan github.com > /home/vagrant/.ssh/known_hosts && chmod 600 /home/vagrant/.ssh/known_hosts && chown vagrant:vagrant /home/vagrant/.ssh/known_hosts"
config.vm.provision "shell", inline: $github_add_ssh, name: "add github SSH key to known hosts"

$create_module_path_script = "export DEBIAN_FRONTEND=noninteractive; if [ ! -d /vagrant/puppet/modules ]; then mkdir -p /vagrant/puppet/modules; fi;"
config.vm.provision "shell", inline: $github_add_ssh, name: "create modules folder for librarian-puppet if not present"

$librarian_script = "export DEBIAN_FRONTEND=noninteractive; cd /vagrant/puppet && librarian-puppet update"
  config.vm.provision "shell", inline: $librarian_script, name: "librarian-puppet"


  config.vm.provision :puppet do |puppet|
    puppet.manifests_path = "puppet/manifests"
    puppet.manifest_file = "vagrant.pp"
    puppet.hiera_config_path = "puppet/vagrant.yaml"
    puppet.module_path = "puppet/modules"
    puppet.options = "--verbose"
  end

  config.vm.provider "virtualbox" do |v|
    v.name = "jpeterson_udemy_continuous_deployment_course"
    v.memory = 2048
    v.cpus = 2
    # turn the virtual disk into an SSD- this seems to have a noticeable performance improvement on MBPs with an SSD
    #v.customize ["storageattach", v.name, "--storagectl=IDE Controller", "--port=0", "--device=0", "--nonrotational=on", "--type=hdd", "--medium=iscsi"]
    v.customize ["setextradata", :id, "VBoxInternal2/SharedFoldersEnableSymlinksCreate/v-root", "1"]
    v.customize ["modifyvm", :id, "--natdnshostresolver1", "on"]
  end

  # private network is required for NFS shares
  config.vm.network "private_network",  ip: "172.20.16.100"

  if Vagrant.has_plugin?("hostsupdater")
    config.hostsupdater.aliases = ["identity.example.local"]
  end

  $local_modules = "export DEBIAN_FRONTEND=noninteractive; sudo service supervisor restart"
    config.vm.provision "shell", inline: $local_modules, run: "always"
end