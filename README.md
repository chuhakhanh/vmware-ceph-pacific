# vmware-ceph-pacific

## Setup
### Get data
    git clone https://github.com/chuhakhanh/vmware-ceph-pacific 
    git pull --branch master https://github.com/chuhakhanh/vmware-ceph-pacific
    cd vmware-ceph-pacific
    cp -u config/hosts /etc/hosts
    cp config/2022_03.repo /etc/yum.repos.d/
    yum install -y sshpass 
    ssh-keygen
### Deploy virtual machines 
    ansible-playbook -i config/inventory deploy_lab_ceph.yml 
    chmod u+x ./script/key_copy.sh; ./script/key_copy.sh config/inventory
   
### Deploy app
    ansible-playbook -i config/inventory prepare_all_node.yml

### Destroy virtual machines
    ansible-playbook -i config/inventory destroy_lab_ceph.yml 

### cephadm-ansible on c3-server-c
    yum install ansible -y
    yum install git -y
    git clone https://github.com/ceph/cephadm-ansible

    ssh-keygen
    chmod u+x ./script/key_copy.sh; ./script/key_copy.sh config/inventory

    yum install python3-virtualenv
    virtualenv /env_python3
    source /env_python3/bin/activate
    pip3 install -r requirements.txt

### preflight on c3-server-c
Start by checking on the amount of storage you have available on your node.  This guide assume the loopback file will be created in the root partition.  Become root and then execute the following command:
    
    ansible-playbook -i preflight_host_list.txt cephadm-preflight.yml --extra-vars "ceph_origin="

### bootstrap on c3-server-c

    ansible-playbook -i hosts cephadm-distribute-ssh-key.yml -e admin_node=c3-server-c -e cephadm_pubkey_path=/root/.ssh/id_rsa.pub 
    cephadm bootstrap --mon-ip=10.1.17.73 \
    --apply-spec=initial-config-primary-cluster.yaml \
    --initial-dashboard-password=redhat \
    --dashboard-password-noupdate \
    --allow-fqdn-hostname 

    cephadm bootstrap --mon-ip=10.1.17.73 \
    --initial-dashboard-password=redhat \
    --dashboard-password-noupdate \
    --allow-fqdn-hostname 

