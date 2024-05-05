terraform {
  required_providers {
    openstack = {
        source = "terraform-provider-openstack/openstack"
    }
  }
}
provider "openstack" {
    cloud = "openstack"
}
resource "openstack_compute_instance_v2" "puppet_master" {
  name = "jenkins_Server"
  image_name = "ubuntu-20.04"
  flavor_name = "css.1c4r.20g"
  key_pair = "private-Key"
  network {
    name = "public"
  }

  connection {
    type = "ssh"
    user = "ubuntu"
    private_key = "${file("~/.ssh/id_rsa")}"
    host = openstack_compute_instance_v2.puppet_master.access_ip_v4
  }

  provisioner "file" {
    source = "./manifest.pp"
    destination = "/home/ubuntu/manifest.pp"
  }

  provisioner "remote-exec" {
      inline = [
        "sleep 20",
        "sudo apt update -y",
        "sudo bash -c 'echo \"${openstack_compute_instance_v2.puppet_master.access_ip_v4} puppetmaster.openstacklocal puppetmaster\" >> /etc/hosts'",
        "curl -LO https://apt.puppet.com/puppet7-release-focal.deb",
        "sudo dpkg -i ./puppet7-release-focal.deb",
        "sudo apt update",
        "sudo apt -y install puppetserver",
        "sudo bash -c 'echo -e \"dns_alt_names=puppetmaster.openstacklocal,puppetmaster\n\n[main]\ncertname=puppetmaster.openstacklocal\nserver=puppetmaster.openstacklocal\nenvironment=production\nruninterval=3m\" >> /etc/puppetlabs/puppet/puppet.conf'",
        "sudo /opt/puppetlabs/bin/puppetserver ca setup",
        "sudo mv /home/ubuntu/manifest.pp /etc/puppetlabs/code/environments/production/manifests/manifest.pp",
        "sudo systemctl start puppetserver",
        "sudo apt-get install puppet-agent -y",
        "sudo /opt/puppetlabs/bin/puppet config set server puppetmaster",
        "sudo /opt/puppetlabs/puppet/bin/puppet agent",
      ]
  }
}

resource "openstack_compute_instance_v2" "puppet_agent_dev" {
  count = 2
  name = "puppet_agent_dev-${count.index}"
  image_name = "ubuntu-20.04"
  flavor_name = "l2.c2r4.100"
  key_pair = "VM170-Key"
  
  network {
      name = "public"
  }
  connection {
    type = "ssh"
    user = "ubuntu"
    private_key = "${file("~/.ssh/id_rsa")}"
    host = "${self.access_ip_v4}"
  }
  provisioner "remote-exec" {
      inline = [
        "sleep 20",
        "sudo apt update -y",
        "curl -LO https://apt.puppet.com/puppet7-release-focal.deb",
        "sudo dpkg -i ./puppet7-release-focal.deb",
        "sudo apt update",
        "sudo apt-get install puppet-agent -y",
        "sudo bash -c 'echo -e \"[main]\ncertname=${self.name}.openstacklocal\nserver=puppetmaster.openstacklocal\" >> /etc/puppetlabs/puppet/puppet.conf'",
        "sudo bash -c 'echo -e \"${openstack_compute_instance_v2.puppet_master.access_ip_v4} puppetmaster.openstacklocal puppetmaster\" >> /etc/hosts'",
        "sudo bash -c 'echo -e \"${self.access_ip_v4} ${self.name}.openstacklocal ${self.name}\" >> /etc/hosts'",
        "sudo systemctl start puppet",
        "sudo /opt/puppetlabs/puppet/bin/puppet agent",
      ]
  }

}

resource "openstack_compute_instance_v2" "puppet_agent_storage" {
  count = 2
  name = "puppet_agent_storage-${count.index}"
  image_name = "ubuntu-20.04"
  flavor_name = "l2.c2r4.100"
  key_pair = "VM170-Key"
  
  network {
      name = "public"
  }
  connection {
    type = "ssh"
    user = "ubuntu"
    private_key = "${file("~/.ssh/id_rsa")}"
    host = "${self.access_ip_v4}"
  }
  provisioner "remote-exec" {
      inline = [
        "sleep 20",
        "sudo apt update -y",
        "curl -LO https://apt.puppet.com/puppet7-release-focal.deb",
        "sudo dpkg -i ./puppet7-release-focal.deb",
        "sudo apt update",
        "sudo apt-get install puppet-agent -y",
        "sudo bash -c 'echo -e \"[main]\ncertname=${self.name}.openstacklocal\nserver=puppetmaster.openstacklocal\" >> /etc/puppetlabs/puppet/puppet.conf'",
        "sudo bash -c 'echo -e \"${openstack_compute_instance_v2.puppet_master.access_ip_v4} puppetmaster.openstacklocal puppetmaster\" >> /etc/hosts'",
        "sudo bash -c 'echo -e \"${self.access_ip_v4} ${self.name}.openstacklocal ${self.name}\" >> /etc/hosts'",
        "sudo systemctl start puppet",
        "sudo /opt/puppetlabs/puppet/bin/puppet agent",
      ]
  }

}

resource "openstack_compute_instance_v2" "puppet_agent_compile" {
    count = 2
    name = "compile-${count.index}"
    image_name = "ubuntu-20.04"
    flavor_name = "l2.c2r4.100"
    key_pair = "VM170-Key"
    
    network {
        name = "public"
    }
    connection {
      type = "ssh"
      user = "ubuntu"
      private_key = "${file("~/.ssh/id_rsa")}"
      host = "${self.access_ip_v4}"
    }
    provisioner "remote-exec" {
        inline = [
          "sleep 20",
          "sudo apt update -y",
          "curl -LO https://apt.puppet.com/puppet7-release-focal.deb",
          "sudo dpkg -i ./puppet7-release-focal.deb",
          "sudo apt update",
          "sudo apt-get install puppet-agent -y",
          "sudo bash -c 'echo -e \"[main]\ncertname=${self.name}.openstacklocal\nserver=puppetmaster.openstacklocal\" >> /etc/puppetlabs/puppet/puppet.conf'",
          "sudo bash -c 'echo -e \"${openstack_compute_instance_v2.puppet_master.access_ip_v4} puppetmaster.openstacklocal puppetmaster\" >> /etc/hosts'",
          "sudo bash -c 'echo -e \"${self.access_ip_v4} ${self.name}.openstacklocal ${self.name}\" >> /etc/hosts'",
          "sudo systemctl start puppet",
          "sudo /opt/puppetlabs/puppet/bin/puppet agent",
        ]
  }

}
resource "openstack_compute_instance_v2" "puppet_agent_docker" {
    name = "puppet-agent-docker"
    image_name = "ubuntu-22.04"
    flavor_name = "l2.c2r4.100"
    key_pair = "VM170-Key"
    network {
      name = "default"
    }

    connection {
      type = "ssh"
      user = "ubuntu"
      private_key = "${file("~/.ssh/id_rsa")}"
      host = openstack_compute_instance_v2.puppet_agent_docker.access_ip_v4
    }

    provisioner "remote-exec" {
        inline = [
          "sleep 20",
          "sudo apt update -y",
          "curl -LO https://apt.puppet.com/puppet7-release-focal.deb",
          "sudo dpkg -i ./puppet7-release-focal.deb",
          "sudo apt update",
          "sudo apt-get install puppet-agent -y",
          "sudo bash -c 'echo -e \"[main]\ncertname=${openstack_compute_instance_v2.puppet_agent_docker.name}.openstacklocal\nserver=puppetmaster.openstacklocal\" >> /etc/puppetlabs/puppet/puppet.conf'",
          "sudo bash -c 'echo -e \"${openstack_compute_instance_v2.puppet_master.access_ip_v4} puppetmaster.openstacklocal puppetmaster\" >> /etc/hosts'",
          "sudo bash -c 'echo -e \"${openstack_compute_instance_v2.puppet_agent_docker.access_ip_v4} ${openstack_compute_instance_v2.puppet_agent_docker.name}.openstacklocal ${openstack_compute_instance_v2.puppet_agent_docker.name}\" >> /etc/hosts'",
          "sudo systemctl start puppet",
          "sudo /opt/puppetlabs/puppet/bin/puppet agent",
        ]
    }

}

