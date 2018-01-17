Vagrant.configure("2") do |config|
  config.vm.box = "mvbcoding/awslinux"
  config.vm.provision :shell, 
  path: "vagrant.userdata.sh",
  keep_color: true
  config.vm.synced_folder ".", "/vagrant", :mount_options => ["dmode=777","fmode=666"]
  config.vm.network :forwarded_port, host: 9999, guest: 80
  config.vm.define 'islandora7x_aws_testvm' do |t|
  end
end
