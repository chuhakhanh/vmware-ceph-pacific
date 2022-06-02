# vmware-ceph-pacific

# 
## Get data
git clone https://github.com/chuhakhanh/vmware-ceph-pacific 
git pull --branch master https://github.com/chuhakhanh/vmware-ceph-pacific
cd vmware-ceph-pacific
cp -u config/hosts /etc/hosts

## Deploy virtual machines 
ansible-playbook -i config/inventory deploy_lab_ceph.yml 
cp config/2022_03.repo /etc/yum.repos.d/
yum install -y sshpass 
ssh-keygen
chmod u+x key_copy.sh; ./key_copy.sh config/host_list.txt

## Deploy app
ansible-playbook -i config/inventory prepare_all_node.yml