#!/bin/sh
# Script to configure BMC/iDRAC's IP
# Author: JP, VxRail DE @ Dell EMC
# Version 1.0
#
# Do not change anything below this line
# --------------------------------------

mkdir -p commands

net-dvs -l > commands/net-dvs_-l.txt
esxcfg-vmknic -l > commands/esxcfg-vmknic_-l.txt
/usr/lib/vmware/bin/vmware-vimdump -U dcui -o commands/vmware-vimdump.txt
echo ""
echo "- vmkernel port on vDS mappings for VLAN, uplink, and portgroup (excluding vmkernel on Standard vSwitch, iDRAC, or NSX vxlan/hyperbus)"
echo ""
for vds_port in `grep -v Port ./commands/esxcfg-vmknic_-l.txt |grep -v iDRAC |grep -v vmservice-vmknic-pg |grep -v vxlan |grep -v hyperbus |grep -v BACKUP |awk '{print $2}' |uniq`
do

        vmk=`cat ./commands/esxcfg-vmknic_-l.txt | awk -v var="$vds_port" '$2 == var' |awk '{print $1}' |uniq`
        pg_id=`grep -A20 "port $vds_port:" ./commands/net-dvs_-l.txt |grep portgroupid |awk '{print $3}' |head -1`
        vlan=`grep -A50 "port $vds_port:" ./commands/net-dvs_-l.txt |grep volatile.vlan |awk -F \= '{print $2}' |head -1`
        pg_name=`grep -A 1 -w $pg_id ./commands/vmware-vimdump*.txt |grep name |awk -F \' '{print $2}' |uniq`

                standby_check=`grep -A50 "port $vds_port:" ./commands/net-dvs_-l.txt |grep standby |grep uplink |tail -1 | wc -l`
                if [ $standby_check -eq 0 ]
                then
                        # Active/Active uplink
                        active_uplink=`grep -A50 "port $vds_port:" ./commands/net-dvs_-l.txt |grep active |grep -v mode |awk 'BEGIN{FS="="}{print $2}' |sed 's/,//' |sed 's/;//'`

                        #
                        # Display the vmkernel port, portgroup id, uplink, vlan, pg name
                        #
                        echo -e "\t$vmk\t$pg_id\tActive:$active_uplink\t\t$vlan\t  $pg_name"
                else
                        # Active/Standby uplink
                        active_uplink=`grep -A50 "port $vds_port:" ./commands/net-dvs_-l.txt |grep active |grep -v mode |awk '{print $3}' |head -1 |sed 's/,//' |sed 's/;//'`
                        standby_uplink=`grep -A50 "port $vds_port:" ./commands/net-dvs_-l.txt |grep standby |grep -v mode |awk '{print $3}' | head -1 |sed 's/,//' |sed 's/;//'`

                        #
                        # Display the vmkernel port, portgroup id, uplink, vlan, pg name
                        #
                        echo -e "\t$vmk\t$pg_id\tActive: $active_uplink\t\tStandby: $standby_uplink\t$vlan\t  $pg_name"
                fi
done      

echo ""

rm -rf ./commands
