# vmware-ceph-pacific

## I. Setup
### 1. Get data
    git clone https://github.com/chuhakhanh/vmware-ceph-pacific 
    git pull --branch master https://github.com/chuhakhanh/vmware-ceph-pacific
    cd vmware-ceph-pacific
    cp -u config/hosts /etc/hosts
    cp config/2022_03.repo /etc/yum.repos.d/
    yum install -y sshpass 
    ssh-keygen
### 2. Deploy virtual machines 
    ansible-playbook -i config/inventory deploy_lab_ceph.yml 
    chmod u+x key_copy.sh; ./key_copy.sh config/host_list.txt
    scp config/host_list.txt key_copy.sh c3-server-c:/root

### 3. Deploy app
    ansible-playbook -i config/inventory prepare_all_node.yml

### 4. Destroy virtual machines
    ansible-playbook -i config/inventory destroy_lab_ceph.yml 

### 5. cephadm-ansible on c3-server-c
    yum install ansible -y
    yum install git -y
    git clone https://github.com/ceph/cephadm-ansible

    ssh-keygen
    /root/key_copy.sh /root/host_list.txt

    yum install python3-virtualenv
    virtualenv /env_python3
    source /env_python3/bin/activate
    pip3 install -r requirements.txt

### 6. preflight on c3-server-c
Start by checking on the amount of storage you have available on your node.  This guide assume the loopback file will be created in the root partition.  Become root and then execute the following command:
    
    ansible-playbook -i preflight_host_list.txt cephadm-preflight.yml --extra-vars "ceph_origin="

### 7. bootstrap on c3-server-c

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


## II. Ceph Operation

### 1. Add MON on c3-server-d, c3-server-e
    ssh-copy-id -f -i /etc/ceph/ceph.pub root@c3-server-d
    ssh-copy-id -f -i /etc/ceph/ceph.pub root@c3-server-e
    cephadm shell -- ceph orch host add c3-server-d
    cephadm shell -- ceph orch host add c3-server-e
    ceph telemetry on --license sharing-1-0

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

### 2. Add OSD on c3-server-a

#### a. Adđ OSD by cli
    cephadm shell -- ceph orch device ls
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

#### b. Adđ OSD by apply yaml
    
    ceph orch apply -i /tmp/osd_spec.yml
    ceph osd tree
    ceph status

### 3. Add MON on c3-server-a
    cephadm shell -- ceph config dump
    ssh-copy-id -f -i /etc/ceph/ceph.pub root@c3-server-a
    cephadm shell -- ceph orch host add c3-server-a
    cephadm shell -- ceph orch apply mon 4
    cephadm shell -- ceph orch apply mon c3-server-c,c3-server-d,c3-server-e,c3-server-a
    cephadm shell -- ceph orch host label add c3-server-a mon
    cephadm shell -- ceph orch host label add c3-server-a _admin
    ceph orch host ls
    

### 4. Set MON config

#### a. Network
    [root@c3-server-a ~]# ceph mon dump
    epoch 8
    fsid 4d785516-f211-11ec-b064-005056bafcf9
    last_changed 2022-06-23T09:36:51.882439+0000
    created 2022-06-22T09:55:37.190264+0000
    min_mon_release 16 (pacific)
    election_strategy: 1
    0: [v2:10.1.17.75:3300/0,v1:10.1.17.75:6789/0] mon.c3-server-e
    1: [v2:10.1.17.71:3300/0,v1:10.1.17.71:6789/0] mon.c3-server-a
    2: [v2:10.1.17.73:3300/0,v1:10.1.17.73:6789/0] mon.c3-server-c
    3: [v2:10.1.17.74:3300/0,v1:10.1.17.74:6789/0] mon.c3-server-d
    dumped monmap epoch 8
#### b. Compact MON Database
    ceph config show mon.c3-server-c
    ceph config show mon.c3-server-c mon_host
    ceph config set mon mon_compact_on_start true
    ceph orch restart mon
    ssh c3-server-c sudo du -sch /var/lib/ceph/4d7...cf9/mon.c3-server-c/store.db/

#### c. Network    
    ceph config get mon public_network 
    ceph config get mon cluster_network 
    ceph config set mon public_network 192.168.126.0/24


    [osd]
        cluster network = 192.168.126.0/24
    
    cephadm shell --mount osd-cluster-network.conf 
    [ceph: root@c3-server-a /]# ceph config assimilate-conf -i /mnt/osd-cluster-network.conf
    [ceph: root@c3-server-a /]# ceph config get osd cluster_network                         
    192.168.126.0/24
    [ceph: root@c3-server-a /]# ceph config get mon public_network
    10.1.0.0/16
    [ceph: root@c3-server-a /]# ceph config set mon public_network 10.1.0.0/16

    podman restart $(podman ps -a -q)

#### d. Compact MON Database
    ceph config get mon.c3-server-c mon_data_avail_warn
    ceph config get mon.c3-server-c mon_max_pg_per_osd
    ceph config set mon mon_data_avail_warn 15
    ceph config set mon mon_max_pg_per_osd 400