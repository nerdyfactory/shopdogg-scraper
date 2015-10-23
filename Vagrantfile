# -*- mode: ruby -*-
# vi: set ft=ruby :

VAGRANTFILE_API_VERSION = "2"

Vagrant.configure(VAGRANTFILE_API_VERSION) do |config|
  config.vm.box = "trusty64"
  config.vm.box_url = "https://cloud-images.ubuntu.com/vagrant/trusty/current/trusty-server-cloudimg-amd64-vagrant-disk1.box"
  config.vm.network :private_network, ip: "192.168.50.20"
  config.vm.synced_folder "./", "/vagrant", type: "nfs"
  config.vm.hostname = "shopdogg"
  config.vm.provider "virtualbox" do |vb|
    vb.memory = "4096"
    vb.cpus = 4
  end
  config.vm.provision :ansible do |ansible|
    ansible.playbook = "provisioning/vagrant.yml"
    ansible.inventory_path = "provisioning/vagrant"
    ansible.limit = "vagrant"
  end
end
