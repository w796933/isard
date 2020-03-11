apk add sshpass ssh-keygen
if [[ -z $HYPERVISOR || -z $PASSWORD ]]
then
    echo "You should add environment variables:"
    echo "  docker exec -e HYPERVISOR=<IP|DNS> -e PASSWORD=<YOUR_ROOT_PASSWD> isard_isard-app_1 bash -c '/add-hypervisor.sh'"
    echo "Optional parameters: USER (default is root), PORT (default is 22)"
    echo ""
    echo "Please run it again setting environment variables"
    exit 1
fi

if [[ -z $ENABLED ]]
then
    ENABLED=false
fi

if [[ -z $PORT ]]
then
    PORT=22
fi

if [[ -z $USER ]]
then
    USER=root
fi

if [[ -z $ID ]]
then
    ID=$(echo "$HYPERVISOR" | tr "." "_")
fi

if [[ -z $POOL ]]
then
    POOL=default
fi

if [[ -z $DISKOP ]]
then
    DISKOP=true
fi

if [[ -z $VIRTUALOP ]]
then
    VIRTUALOP=true
fi

if [[ -z $VIEWERHOST ]]
then
    VIEWERHOST=$HYPERVISOR
fi

if [[ -z $VIEWERNATHOST ]]
then
    VIEWERNATHOST=$HYPERVISOR
fi

if [[ -z $VIEWERNATOFFSET ]]
then
    VIEWERNATOFFSET=0
fi

if [ -f /NEWHYPER ]
then
    rm /NEWHYPER
fi
sed -i '/'"$HYPERVISOR"'/d' /root/.ssh/known_hosts
echo "Trying to ssh into $HYPERVISOR..."
ssh-keyscan -p $PORT $HYPERVISOR > /NEWHYPER
if [ ! -s /NEWHYPER ]
then
    echo "Hypervisor $HYPERVISOR:$PORT could not be reached. Aborting"
    exit 1
else
    cat /NEWHYPER >> /root/.ssh/known_hosts
    sshpass -p "$PASSWORD" ssh-copy-id -p $PORT $USER@"$HYPERVISOR"
    if [ $? -ne 0 ]
    then
       sed -i '/'"$HYPERVISOR"'/d' /root/.ssh/known_hosts
       echo "Can't access $USER@$HYPERVISOR:$PORT. Aborting"
       exit 1
    fi
fi

echo "Hypervisor ssh access granted."
sleep 1
virsh -c qemu+ssh://"$USER"@"$HYPERVISOR":"$PORT"/system quit
if [ $? -ne 0 ]
then
   echo "Can't access libvirtd daemon. Please ensure that libvirt daemon is running in $USER@$HYPERVISOR:$PORT. Aborting"
   sed -i '/'"$HYPERVISOR"'/d' /root/.ssh/known_hosts 
   exit 1
fi

cp /root/.ssh/known_hosts /root/.ssh/known_hosts.bak
echo "Access to $USER@$HYPERVISOR:$PORT granted and found libvirtd service running."
echo "Adding hyper to Isard..."
echo "Options: -e $ENABLED -u $USER -a $HYPERVISOR -p $PORT -i $ID -o $POOL -d $DISKOP -v $VIRTUALOP -m $VIEWERHOST -n $VIEWERNATHOST -f $VIEWERNATOFFSET"
/usr/bin/python3 /add-hyper-rethink.py -e $ENABLED -u $USER -a $HYPERVISOR -p $PORT -i $ID -o $POOL -d $DISKOP -v $VIRTUALOP -m $VIEWERHOST -n $VIEWERNATHOST -f $VIEWERNATOFFSET
