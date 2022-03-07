# -*- mode: ruby -*-
# vi: set ft=ruby :

Vagrant.configure("2") do |config|
  config.vm.box = "ubuntu/focal64"
  config.vm.provider "virtualbox" do |vb|
    vb.memory = "2048"
  end

  config.vm.provision "shell", inline: <<-SHELL
    apt-get update
    curl -fsSL get.docker.com | sh
    usermod -aG docker vagrant
    docker pull captainfluffytoes/csme:12.4.1
    docker pull cyberark/conjur-cli:5-6.2.6
  SHELL
end