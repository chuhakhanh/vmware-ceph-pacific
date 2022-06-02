# vmware-ceph-pacific

# 
## Get data
git clone --branch master https://github.com/chuhakhanh/vmware-ceph-pacific 
git pull --branch master https://github.com/chuhakhanh/vmware-ceph-pacific
cd vmware-ceph-pacific
cp -u config/hosts /etc/hosts

## Deploy 
ansible-playbook -i config/inventory deploy_lab_ceph.yml 

./key_copy.sh host_list.txt
chmod u+x key_copy.sh