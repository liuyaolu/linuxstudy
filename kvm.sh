#!/bin/bash

template_image_path='/var/lib/libvirt/images/centos7u7-template.img'
template_image_xml='/etc/libvirt/qemu/centos7u7-template.xml'
clone_vm_path='/var/lib/libvirt/images'
clone_vm_xml='/etc/libvirt/qemu'

create_vm(){
	read -p "输入你要创建的虚拟机名称: " vm_name
	read -p "输入你要创建的虚拟机数量：" vm_num
	read -p "输入虚拟机的系统主机名: " hostname
	read -p "输入虚拟机的系统ip地址段[默认100]: " ipaddr
	if [ -z "$ipaddr" ];then
		ipaddr=100
	fi
	for ((i=1;i<=$vm_num;i++));do
		qemu-img create -f qcow2 -b $template_image_path $clone_vm_path/${vm_name}-${i}.img
		cp $template_image_xml $clone_vm_xml/${vm_name}-${i}.xml
		sed -i "s/centos7u7-template/$vm_name-${i}/" $clone_vm_xml/${vm_name}-${i}.xml
		sed -i '/uuid/d' $clone_vm_xml/${vm_name}-${i}.xml
		sed -i '/mac /d' $clone_vm_xml/${vm_name}-${i}.xml
		guestmount -a $clone_vm_path/${vm_name}-${i}.img -i /mnt/
		sed -i "s/template/$hostname${ipaddr}/" /mnt/etc/hostname
		sed -i "s/250/$ipaddr/" /mnt/etc/sysconfig/network-scripts/ifcfg-eth0
		echo "192.168.122.$ipaddr ${hostname}${ipaddr}.com" >> /mnt/etc/hosts 
		umount -l /mnt
		ipaddr=$(($ipaddr+1))
	virsh define $clone_vm_xml/${vm_name}-${i}.xml
	virsh start $vm_name-${i}
	done
}

create_vm
