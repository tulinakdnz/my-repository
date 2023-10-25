# Hands-on Ansible-02 : Using Playbook with Tasks

Purpose of the this hands-on training is to give students the knowledge of basic Ansible skills.

## Learning Outcomes

At the end of the this hands-on training, students will be able to;

- Learn ansible playbooks.

## Outline

- Part 1 - Install ansible

- Part 2 - Ansible Playbooks

## Part 1 - Install Ansible

- Create 3 Amazon Linux 2 and 1 Ubuntu EC2 instances. Then name the instances as below. For Security Group, allow ssh and http when creating EC2.
1-control-node
2-node1
3-node2
4-node3 (ubuntu)

- Connect to the control node with SSH and run the following commands.

```bash
sudo dnf update -y
sudo dnf install ansible -y
```
### Confirm Installation

- To confirm the successful installation of Ansible. You can run the following command.

```bash
ansible --version
```
### Configure Ansible on AWS EC2

- Connect to the control node and create an inventory.

```bash
vim inventory.txt
```
```bash
[webservers]
node1 ansible_host=<node1_ip> ansible_user=ec2-user
node2 ansible_host=<node2_ip> ansible_user=ec2-user

[ubuntuservers]
node3 ansible_host=<node3_ip> ansible_user=ubuntu

[all:vars]
ansible_ssh_private_key_file=/home/ec2-user/<pem file>
```

- Create an  `ansible.cfg` file under `/home/ec2-user` folder as below. 

```bash
vim ansible.cfg
[defaults]
host_key_checking = False
inventory = inventory.txt
deprecation_warnings=False
interpreter_python=auto_silent
```

- Copy your pem file to the `/home/ec2-user` directory. First go to your pem file directory on your local computer and run the following command.

```bash
scp -i <pem file> <pem file> ec2-user@<public DNS name of the control node>:/home/ec2-user
```

- or you can create a file name <pem file> into the directory `/home/ec2-user` on the control node and copy your pem file into it.

## Part 2 - Ansible Playbooks

- Create a yaml file named "playbook1.yml" and make sure all our hosts are up and running.

```yml
---
- name: Test Connectivity
  hosts: all
  tasks:
   - name: Ping test
     ansible.builtin.ping:
```

- Run the yaml file.

```bash
ansible-playbook playbook1.yml
```

- Create a text file named "testfile1" and write "Hello Clarusway" with using vim. Then create a yaml file name "playbook2.yml" and send the "testfile1" to the hosts. 

```yml
---
- name: Copy for linux
  hosts: webservers
  tasks:
   - name: Copy your file to the webservers
     ansible.builtin.copy:
       src: /home/ec2-user/testfile1
       dest: /home/ec2-user/testfile1

- name: Copy for ubuntu
  hosts: ubuntuservers
  tasks:
   - name: Copy your file to the ubuntuservers
     ansible.builtin.copy:
       src: /home/ec2-user/testfile1
       dest: /home/ubuntu/testfile1
```

- Run the yaml file.

```bash
ansible-playbook playbook2.yml
```

- Connect the nodes with SSH and check if the text files are copied or not. 

- Create a yaml file named playbook3.yml as below.

```bash
vim playbook3.yml
```
```yml
- name: Copy for linux
  hosts: webservers
  tasks:
   - name: Copy your file to the webservers
     ansible.builtin.copy:
       src: /home/ec2-user/testfile1
       dest: /home/ec2-user/testfile1
       mode: u+rw,g-wx,o-rwx

- name: Copy for ubuntu
  hosts: ubuntuservers
  tasks:
   - name: Copy your file to the ubuntuservers
     ansible.builtin.copy:
       src: /home/ec2-user/testfile1
       dest: /home/ubuntu/testfile1
       mode: u+rw,g-wx,o-rwx

- name: Copy for node1
  hosts: node1
  tasks:
   - name: Copy using inline content
     ansible.builtin.copy:
       content: 'This is content of file2'
       dest: /home/ec2-user/testfile2

   - name: Create a new text file
     ansible.builtin.shell: "echo Hello World > /home/ec2-user/testfile3"
```

- Run the yaml file.

```bash
ansible-playbook playbook3.yml
```
- Connect the node1 with SSH and check if the text files are there.

- Install Apache server with "playbook4.yml". After the installation, check if the Apache server is reachable from the browser.

```bash
ansible-doc yum
ansible-doc apt

vim playbook4.yml
```
```yml
---
- name: Apache installation for webservers
  hosts: webservers
  tasks:
   - name: install the latest version of Apache
     ansible.builtin.yum:
       name: httpd
       state: latest

   - name: start Apache
     ansible.builtin.shell: "service httpd start"

- name: Apache installation for ubuntuservers
  hosts: ubuntuservers
  tasks:
   - name: update
     ansible.builtin.shell: "apt update -y"
     
   - name: install the latest version of Apache
     ansible.builtin.apt:
       name: apache2
       state: latest
```
- Run the yaml file.

```bash
ansible-playbook -b playbook4.yml
ansible-playbook -b playbook4.yml   # Run the command again and show the changing parts of the output.
```

- Create playbook5.yml and remove the Apache server from the hosts.

```bash
vim playbook5.yml
```
```yml
---
- name: Remove Apache from webservers
  hosts: webservers
  tasks:
   - name: Remove Apache
     ansible.builtin.yum:
       name: httpd
       state: absent
       autoremove: yes

- name: Remove Apache from ubuntuservers
  hosts: ubuntuservers
  tasks:
   - name: Remove Apache
     ansible.builtin.apt:
       name: apache2
       state: absent
       autoremove: yes
       purge: yes
```

- Run the yaml file.

```bash
ansible-playbook -b playbook5.yml
```

- This time, install Apache and wget together with playbook6.yml. After the installation, enter the IP-address of node2 to the browser and show the Apache server. Then, connect node1 with SSH and check if "wget and apache server" are running. 

```bash
vim playbook6.yml
```
```yml
---
- name: Apache installation and configuration for ubuntuservers
  hosts: ubuntuservers
  tasks:
   - name: installing apache
     ansible.builtin.apt:
       name: apache2
       state: latest

   - name: index.html
     ansible.builtin.copy:
       content: "<h1>Hello Clarusway</h1>"
       dest: /var/www/html/index.html

   - name: restart apache2
     ansible.builtin.service:
       name: apache2
       state: restarted
       enabled: yes

- name: Apache and wget installation for webservers
  hosts: webservers
  tasks:
    - name: installing httpd and wget
      ansible.builtin.yum:
        pkg: "{{ item }}"
        state: present
      loop:
        - httpd
        - wget
```

- Run the yaml file.

```bash
ansible-playbook -b playbook6.yml
```

- Remove Apache and wget from the hosts with playbook7.yml.

```bash
vim playbook7.yml
```
```yml
---
- name: Remove Apache from ubuntuservers
  hosts: ubuntuservers
  tasks:
   - name: Uninstalling Apache
     ansible.builtin.apt:
       name: apache2
       state: absent
       update_cache: yes
       autoremove: yes
       purge: yes

- name: Remove Apache and wget from webservers
  hosts: webservers
  tasks:
   - name: removing apache and wget
     ansible.builtin.yum:
       pkg: "{{ item }}"
       state: absent
     loop:
       - httpd
       - wget
```

- Run the yaml file.

```bash
ansible-playbook -b playbook7.yml
```

- Using ansible loop and conditional, create users with playbook8.yml. 

```bash
vi playbook8.yml
```

```yml
---
- name: Create users
  hosts: "*"
  tasks:
    - name: Create user for REDHAT OS FAMILY
      ansible.builtin.user:
        name: "{{ item }}"
        state: present
      loop:
        - joe
        - matt
        - james
        - oliver
      when: ansible_os_family == "RedHat"

    - name: Create user for SUSE OS FAMILY
      ansible.builtin.user:
        name: "{{ item }}"
        state: present
      loop:
        - david
        - tyler
      when: ansible_os_family == "SUSE"

    - name: Create user for DEBIAN OS FAMILY
      ansible.builtin.user:
        name: "{{ item }}"
        state: present
      loop:
        - john
        - aaron
      when: ansible_os_family == "Debian" or ansible_distribution_version == "20.04"
```

- Run the playbook8.yml

```bash
ansible-playbook -b playbook8.yml
```