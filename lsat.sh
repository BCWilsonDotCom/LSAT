#!/bin/bash
# Subnet audit script.
# Brandon Wilson
# version: 3/20/13
# Usage: ./subnetaudit.sh 172.27.2
#
#Debug?
#set -x
#Some vars
SUBNET=$1
OUTPUTFILE="/tmp/audit.$1"
UNSETVARS=$(unset HOSTNAME; unset MODEL; unset OSVER; unset KERNELREV; unset MEMKB; unset MEMMB; unset MEMGB; unset UPTIME)
SSHFLAGS="-o StrictHostKeyChecking=no -o ConnectTimeout=10 -o BatchMode=yes"
for n in {1..254}; do
  ADDR=${SUBNET}.${n}
  DIGCOMMAND="`dig -x ${ADDR} +short`"

  echo ""

  if [ -z "$DIGCOMMAND" ]; then
        echo "$ADDR HAS NO DNS ENTRY"
	echo -n "Does it ping though? .."
	PINGTEST=`ping $ADDR -c 5`
	PINGTESTRESULT=$?
	if [ $PINGTESTRESULT -eq 0 ]; then
		echo "YES! WTF!?"
		echo -n "Can we SSH to it? .."
		SSHTEST=`ssh $SSHFLAGS $ADDR 'hostname'`
		SSHTESTRESULT=$?
		if [ $SSHTESTRESULT -eq 0 ]; then
			echo "Yes!"
			echo "It's $SSHTEST"
			HOSTNAME=$SSHTEST
			echo -n "Gathering information on $HOSTNAME... "
                        OS=`ssh $SSHFLAGS $HOSTNAME 'uname' 2>/dev/null`
                        if [ "$OS" == "Linux" ]; then
                              MODEL=`ssh $SSHFLAGS $HOSTNAME 'dmidecode -s system-product-name' |sed 's/^[ \t]*//;s/[ \t]*$//'`
                              SERIAL=`ssh $SSHFLAGS $HOSTNAME 'dmidecode -s system-serial-number' |sed 's/^[ \t]*//;s/[ \t]*$//'`
                              OSVER=`ssh $SSHFLAGS $HOSTNAME 'cat /etc/redhat-release' |sed 's/^[ \t]*//;s/[ \t]*$//'`
                              KERNELREV=`ssh $SSHFLAGS $HOSTNAME 'uname -r' |sed 's/^[ \t]*//;s/[ \t]*$//'`
                              MEMKB=`ssh $SSHFLAGS $HOSTNAME 'cat /proc/meminfo |grep MemTotal' |awk '{print $2}' |sed 's/^[ \t]*//;s/[ \t]*$//'`
                              MEMMB="$(( $MEMKB / 1024 ))"
                              UPTIME="ssh $SSHFLAGS $HOSTNAME 'uptime |awk '{print $3$4}'"
                              #MEMGB="$(( $MEMMB / 1024 ))"
			      echo "Successful."
                              echo "$ADDR, $HOSTNAME, $MODEL, $SERIAL, $OSVER, $KERNELREV, $MEMMB Mb" >> $OUTPUTFILE
			      echo "$UNSETVARS"
                        elif [ "$OS" == "SunOS" ]; then
                              MODEL=`ssh $SSHFLAGS $HOSTNAME 'prtdiag |grep "System Configuration"'| sed 's/,//g'| sed 's/System Configuration://g' |sed 's/^[ \t]*//;s/[ \t]*$//'`
                              #SERIAL=`ssh $SSHFLAGS $HOSTNAME ''
                              OSVER=`ssh $SSHFLAGS $HOSTNAME 'cat /etc/release |grep Solaris' |sed 's/^[ \t]*//;s/[ \t]*$//'`
                              KERNELREV=`ssh $SSHFLAGS $HOSTNAME 'uname -v' |sed 's/^[ \t]*//;s/[ \t]*$//'`
                              MEMMB=`ssh $SSHFLAGS $HOSTNAME 'prtconf |grep size' |awk '{print $3}' |sed 's/^[ \t]*//;s/[ \t]*$//'`
                              UPTIME="ssh $SSHFLAGS $HOSTNAME 'uptime |awk '{print $3$4}'"
                              #MEMGB="$(( $MEMMB / 1024 ))"
			      echo "Successful."
                              echo "$ADDR, $HOSTNAME, $MODEL, SERIAL-PLACEHOLDER, $OSVER, $KERNELREV, $MEMMB Mb, $UPTIME" >> $OUTPUTFILE
			      echo "$UNSETVARS"
                        else
			      echo "Failed! Unknown OS?"
                              echo "$ADDR, $HOSTNAME, UNKNOWN OS!!!" >> $OUTPUTFILE
                              echo "$UNSETVARS"
                        fi

		else
			echo "Nope!"
			echo "This is odd, check it out!!!"
			echo "$ADDR, UNKNOWN DEVICE!!!"
                        echo "$UNSETVARS"
		fi

	else
		echo "Nope!"
		echo "$ADDR," >> $OUTPUTFILE
                echo "$UNSETVARS"
	fi
  else
	echo "$ADDR HAS DNS ENTRY(S)"
        for host in `echo "$DIGCOMMAND"`; do
                HOSTNAME=`echo "$host" |sed '$s/.$//'`
                NETDEVICECHK=`echo $HOSTNAME |egrep '(-fw)|(-sw)|(-dsw)|(-crtr)|(-wrtr)|(-emtfw)|(wad)|(wmontea)|(ks01)|(ks02)|(ks03)|(-lurhq)|(-acs)|(.eas)'`

		echo "$ADDR $HOSTNAME"
                if [ -n "$NETDEVICECHK" ]; then
			echo "Network Device."
                        echo "$ADDR, $HOSTNAME, NETWORK DEVICE" >> $OUTPUTFILE
                        echo "$UNSETVARS"
                else
			echo -n "Checking Connection and OS Type... "
                        OS=`ssh $SSHFLAGS $HOSTNAME 'uname' 2>/dev/null`
                        OSRESULT=$?
                        if [ $OSRESULT -eq 0 ]; then
				echo "Sucessful."

                                if [ "$OS" == "Linux" ]; then
					echo "OS is $OS"
					echo -n "Gathering Information..."
                                        MODEL=`ssh $SSHFLAGS $HOSTNAME 'dmidecode -s system-product-name' |sed 's/^[ \t]*//;s/[ \t]*$//'`
                                        SERIAL=`ssh $SSHFLAGS $HOSTNAME 'dmidecode -s system-serial-number' |sed 's/^[ \t]*//;s/[ \t]*$//'`
                                        OSVER=`ssh $SSHFLAGS $HOSTNAME 'cat /etc/redhat-release' |sed 's/^[ \t]*//;s/[ \t]*$//'`
                                        KERNELREV=`ssh $SSHFLAGS $HOSTNAME 'uname -r' |sed 's/^[ \t]*//;s/[ \t]*$//'`
                                        MEMKB=`ssh $SSHFLAGS $HOSTNAME 'cat /proc/meminfo |grep MemTotal' |awk '{print $2}' |sed 's/^[ \t]*//;s/[ \t]*$//'`
                                        MEMMB="$(( $MEMKB / 1024 ))"
                                        UPTIME="ssh $SSHFLAGS $HOSTNAME 'uptime |awk '{print $3$4}'"
                                        #MEMGB="$(( $MEMMB / 1024 ))"
					echo "Complete."
                                        echo "$ADDR, $HOSTNAME, $MODEL, $SERIAL, $OSVER, $KERNELREV, $MEMMB Mb" >> $OUTPUTFILE
					echo "$UNSETVARS"
                                elif [ "$OS" == "SunOS" ]; then
					echo "OS is $OS"
					echo -n "Gathering Information..."
                                        MODEL=`ssh $SSHFLAGS $HOSTNAME 'prtdiag |grep "System Configuration"'| sed 's/,//g'| sed 's/System Configuration://g' |sed 's/^[ \t]*//;s/[ \t]*$//'`
                                        #SERIAL=`ssh $SSHFLAGS $HOSTNAME ''
                                        OSVER=`ssh $SSHFLAGS $HOSTNAME 'cat /etc/release |grep Solaris' |sed 's/^[ \t]*//;s/[ \t]*$//'`
                                        KERNELREV=`ssh $SSHFLAGS $HOSTNAME 'uname -v' |sed 's/^[ \t]*//;s/[ \t]*$//'`
                                        MEMMB=`ssh $SSHFLAGS $HOSTNAME 'prtconf |grep size' |awk '{print $3}' |sed 's/^[ \t]*//;s/[ \t]*$//'`
                                        UPTIME="ssh $SSHFLAGS $HOSTNAME 'uptime |awk '{print $3$4}'"
                                        #MEMGB="$(( $MEMMB / 1024 ))"
					echo "Complete."
                                        echo "$ADDR, $HOSTNAME, $MODEL, SERIAL-PLACEHOLDER, $OSVER, $KERNELREV, $MEMMB Mb" >> $OUTPUTFILE
					echo "$UNSETVARS"
                                else
                                        echo "$ADDR, $HOSTNAME, UNKNOWN OS!!!" >> $OUTPUTFILE
					echo "$UNSETVARS"
                                fi

                        else
                                echo "Failed with $OSRESULT."
				echo "$ADDR, $HOSTNAME, CONNECTION FAILED WITH $OSRESULT" >> $OUTPUTFILE
				echo "$UNSETVARS"

                        fi
                fi
        done
  fi

done
