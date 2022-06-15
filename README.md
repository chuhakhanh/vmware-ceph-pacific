# vmware-ceph-pacific

## 
### Get data
git clone https://github.com/chuhakhanh/vmware-ceph-pacific 
git pull --branch master https://github.com/chuhakhanh/vmware-ceph-pacific
cd vmware-ceph-pacific
cp -u config/hosts /etc/hosts

### Deploy virtual machines 
ansible-playbook -i config/inventory deploy_lab_ceph.yml 
cp config/2022_03.repo /etc/yum.repos.d/
yum install -y sshpass 
ssh-keygen
chmod u+x key_copy.sh; ./key_copy.sh config/host_list.txt

### Deploy app
ansible-playbook -i config/inventory prepare_all_node.yml


### cephadm-ansible
dnf install git -y
git clone https://github.com/ceph/cephadm-ansible
sudo yum install -y python3-pip python3-virtualenv
virtualenv --python=python3 /path/to/virtualenv_python3
source /path/to/virtualenv_python3/bin/activate 
(virtualenv_python3) [root@c3-server-c cephadm-ansible]# pip list
Package    Version
---------- -------
pip        21.3.1
setuptools 59.6.0
wheel      0.37.1
(virtualenv_python3) pip3 install -r requirements.txt
(virtualenv_python3) pip3 install ansible
(virtualenv_python3) [root@c3-server-c cephadm-ansible]# pip list
Package            Version
------------------ -------
ansible            2.9.27
atomicwrites       1.4.0
attrs              21.4.0
cffi               1.15.0
cryptography       37.0.2
execnet            1.9.0
importlib-metadata 4.8.3
Jinja2             3.0.3
MarkupSafe         2.0.1
more-itertools     8.13.0
packaging          21.3
pip                21.3.1
pluggy             0.13.1
py                 1.11.0
pycparser          2.21
pyparsing          3.0.9
pytest             4.6.11
pytest-forked      1.4.0
pytest-xdist       1.28.0
PyYAML             6.0
setuptools         59.6.0
six                1.16.0
testinfra          3.4.0
typing_extensions  4.1.1
wcwidth            0.2.5
wheel              0.37.1
zipp               3.6.0

yum remove docker-ce docker-ce-cli containerd.io
hostname > hosts
ssh-keygen
ssh-copy-id root@localhost
ansible-playbook -i hosts cephadm-preflight.yml --extra-vars "ceph_origin="
vi initial-config-primary-cluster.yaml

cephadm bootstrap --mon-ip=10.1.17.73 \
--apply-spec=initial-config-primary-cluster.yaml \
--initial-dashboard-password=redhat \
--dashboard-password-noupdate \
--allow-fqdn-hostname 