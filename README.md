# vmware-ceph-pacific

## 
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
    chmod u+x key_copy.sh; ./key_copy.sh config/host_list.txt
    scp config/host_list.txt key_copy.sh c3-server-c:/root

### Deploy app
    ansible-playbook -i config/inventory prepare_all_node.yml

### Destroy virtual machines
    ansible-playbook -i config/inventory destroy_lab_ceph.yml 

### cephadm-ansible on c3-server-c
    yum install ansible -y
    yum install git -y
    git clone https://github.com/ceph/cephadm-ansible

    ssh-keygen
    /root/key_copy.sh /root/host_list.txt

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

    ssh-copy-id -f -i /etc/ceph/ceph.pub root@c3-server-d
    ssh-copy-id -f -i /etc/ceph/ceph.pub root@c3-server-e
    cephadm shell -- ceph orch host add c3-server-d
    cephadm shell -- ceph orch host add c3-server-e

    for i in c3-server-c c3-server-d c3-server-e; do sudo ceph orch host label add $i osd; done
    for i in c3-server-c c3-server-d c3-server-e; do sudo ceph orch host label add $i mon; done

    cephadm shell -- ceph orch apply mon 3
    cephadm shell -- ceph orch apply mon c3-server-c,c3-server-d,c3-server-e
    cephadm shell -- ceph log last cephadm

    [root@c3-server-c cephadm-ansible]# ceph orch host ls
    HOST         ADDR        LABELS          STATUS  
    c3-server-c  10.1.17.73  _admin osd mon          
    c3-server-d  10.1.17.74  osd mon                 
    c3-server-e  10.1.17.75  osd mon                 
    3 hosts in cluster


    [root@c3-server-c cephadm-ansible]# cephadm shell -- ceph orch device ls
    Inferring fsid 4d785516-f211-11ec-b064-005056bafcf9
    Using recent ceph image quay.io/ceph/ceph@sha256:5d3c9f239598e20a4ed9e08b8232ef653f5c3f32710007b4cabe4bd416bebe54
    HOST         PATH      TYPE  DEVICE ID   SIZE  AVAILABLE  REFRESHED  REJECT REASONS  
    c3-server-c  /dev/sdb  hdd              21.4G  Yes        4m ago                     
    c3-server-c  /dev/sdc  hdd              21.4G  Yes        4m ago                     
    c3-server-c  /dev/sdd  hdd              10.7G  Yes        4m ago                     
    c3-server-c  /dev/sde  hdd              10.7G  Yes        4m ago                     
    c3-server-d  /dev/sdb  hdd              21.4G  Yes        99s ago                    
    c3-server-d  /dev/sdc  hdd              21.4G  Yes        99s ago                    
    c3-server-d  /dev/sdd  hdd              10.7G  Yes        99s ago                    
    c3-server-d  /dev/sde  hdd              10.7G  Yes        99s ago                    
    c3-server-e  /dev/sdb  hdd              21.4G  Yes        109s ago                   
    c3-server-e  /dev/sdc  hdd              21.4G  Yes        109s ago                   
    c3-server-e  /dev/sdd  hdd              10.7G  Yes        109s ago                   
    c3-server-e  /dev/sde  hdd              10.7G  Yes        109s ago   


    cephadm shell -- ceph orch daemon add osd c3-server-c:/dev/sdb
    cephadm shell -- ceph orch daemon add osd c3-server-c:/dev/sdc
    cephadm shell -- ceph orch daemon add osd c3-server-d:/dev/sdb
    cephadm shell -- ceph orch daemon add osd c3-server-d:/dev/sdc
    cephadm shell -- ceph orch daemon add osd c3-server-e:/dev/sdb
    cephadm shell -- ceph orch daemon add osd c3-server-e:/dev/sdc

    for i in c3-server-c c3-server-d c3-server-e; do 
        ephadm shell -- ceph orch daemon add osd $i:/dev/sdb
        cephadm shell -- ceph orch daemon add osd $i:/dev/sdc 
    done

    ceph telemetry on --license sharing-1-0