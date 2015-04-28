# -*- mode: ruby -*-
# vi: set ft=ruby :

# Vagrantfile API/syntax version. Don't touch unless you know what you're doing!
VAGRANTFILE_API_VERSION = "2"

Vagrant.configure(VAGRANTFILE_API_VERSION) do |config|

  config.vm.box = "ubuntu/trusty64"

  config.vm.provision :shell, :path => "Vagrant/provision.sh"
  config.vm.network "private_network", ip: "192.168.50.4"
  config.ssh.forward_agent = true
  
  config.vm.synced_folder ".", "/home/vagrant/project", create: false,  :mount_options => ["dmode=777","fmode=777"]
  
  config.vm.provider :virtualbox do |vb|
    vb.customize ["setextradata", :id, "VBoxInternal2/SharedFoldersEnableSymlinksCreate/v-root", "1"]
    vb.customize ["modifyvm", :id, "--memory", "512"]
  end
end
