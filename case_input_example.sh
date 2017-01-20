#!/bin/sh
# chkconfig: 2345 74 26
### BEGIN INIT INFO
# Provides:          leap-server
# Required-Start:    $local_fs
# Required-Stop:     
# Default-Start:     2 3 4 5
# Default-Stop:      0 1 6
# Short-Description: Start the Lutron LEAP server on boot
# Description:       Enable the LEAP server.
# X-Start-Before:    
# X-Stop-After:      
# X-Timesys-Start-Number:  74
# X-Timesys-Stop-Number:  26
### END INIT INFO

PATH=/usr/bin:/bin:/usr/sbin:/sbin

case "${1}" in
   start)
      echo -n "Starting leap server..."
      start-stop-daemon --start --oknodo --quiet --background --exec /usr/sbin/leap-server.gobin -- -config=/etc/lutron.d/lutron.conf && echo "[ OK ]" || echo "[ FAIL ]"
      ;;

   stop)
    
      echo -n "Stopping leap server..."   
      if ! killall leap-server.gobin > /dev/null 2>&1; then
            # leap server wasn't running.
            echo "[ OK ]"
            exit 0         
      fi
      # give the binary two seconds to close
      sleep 2

      # We expect multi-server to need just over 2s to stop completely. 
      # So give it up to 1 more second before drastic measures are taken. 
      for i in 1 2 3 4
      do
            if ! killall -0 leap-server.gobin > /dev/null 2>&1; then
                  # The process has stopped in the expected time.             
                  echo "[ OK ]"
                  exit 0
            else
                  # sleep for a quarter second               
                  usleep 250000
            fi
      done

      # Succeeding to kill -9 here means the binary was still running.
      if killall -9 leap-server.gobin > /dev/null 2>&1; then
            # Log to syslog an error. The tag is the name of this script.         
            logger -p 3 -t $0 "Had to force kill leap server."
            echo "GREAT BEN BARDS HAMMER!"
      fi
      ;;

   restart)
      ${0} stop
      sleep 1
      ${0} start
      ;;

   *)
      echo "Usage: $0 [start|stop|restart]"
      ;;
esac