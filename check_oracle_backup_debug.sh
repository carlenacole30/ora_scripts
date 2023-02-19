#!/bin/env bash
#
# 18.10.2016
#
# Check oracle backup script
#
#############################################################################

# Locale

LANG='en_US.UTF-8'
export LANG


# Functions

Usage(){
 echo "Usage: ./check_oracle.sh [ -f ] [ -i ] [ -a ] [ -l ] [ -c ] [ -h ]"
 echo "-f - проверка полного бэкапа"
 echo "-i - проверка инкрементального бэкапа"
 echo "-a - проверка бэкапа архивлогов"
 echo "-l - проверка алерт лога"
 echo "-c - проверка crontab"
 echo "-h - вывод подсказки"
 echo "Выводы скрипта:"
 echo "0 - Бэкап прошел/нет ошибок/схема используется"
 echo "1 - Ошибки при бэкапе/ошибки в алерт логе"
 echo "2 - Бэкап отсутствует"
 echo "3 - ORA-19591 (Схема INCREMENTAL_UPDATE)"
 echo "4 - Нет Oracle (при проверке алерт лога)"
 echo "5 - Схема бэкапа не задана"
 echo "6 - Нет директории или директория пустая"
 echo "7 - Бэкап в процессе"
 echo "8 - Схема бэкапа закомментирована в crontab"
 exit 3
}

Empty_log(){
 if ! [ -s $seek ];
  then
   echo "CRITICAL - Backup log is empty."
   exit 2
 fi
}

Bkp_in_progress(){
 if ! [[ -n `cat $seek | grep "Finished backup at" | sort -nr | grep -m 1 "Finished backup at"` ]];
  then
   error=`cat $seek | grep -m 1 ORA-`
   if ! [[ -n $error ]];
    then
     echo "Current Backup in progress."
     exit 0
   fi
 fi
}

Bkp_in_progress_num(){
 if ! [[ -n `cat $seek | grep "Finished backup at" | sort -nr | grep -m 1 "Finished backup at"` ]];
  then
   error=`cat $seek | grep -m 1 ORA-`
   if ! [[ -n $error ]];
    then
     echo "7"
     exit 0
   fi
 fi
}

Check_day_incr1(){
 day_one=Sat
 day=`date | awk '{print $1}'`
 if [ "$day" != "$day_one" ];
  then
   echo "CRITICAL - Backup is missing."
   exit 2
  else
   seek=`find $path -mmin -2880 -name 'db_bkp_diff1*' | grep -m 1 diff1`
 fi
}

Check_day_arc(){
 hour=`date | awk '{print $4}' | cut -c 1-2`
 if [ $hour -ne 00 -a $hour -ne 01 -a $hour -ne 02 -a $hour -ne 03 -a $hour -ne 04 -a $hour -ne 05 -a $hour -ne 22 -a $hour -ne 23 ];
  then
   echo "CRITICAL - Backup is missing."
   exit 2
  else
   seek2=`ls -t $path | grep arc_bkp | head -1`
   if [ -d $seek2 ];
    then
     echo "CRITICAL - Backup is missing."
     exit 2
    else
     Empty_log
     var=ERROR
     varc=`ls $seek2 | cut -d "." -f 2`
     vard=`cat $seek2 | grep '\(ORA-\|RMAN-\)'`
     critical=`cd $path; cat $seek2 | grep -om 1 $var`
   fi
 fi
}

Check_day_incr1_num(){
 day_one=Sat
 day=`date | awk '{print $1}'`
 if [ "$day" != "$day_one" ];
  then
   echo "2"
   exit 2
  else
   seek=`find $path -mmin -2880 -name 'db_bkp_diff1*' | grep -m 1 diff1`
 fi
}

Check_day_arc_num(){
 hour=`date | awk '{print $4}' | cut -c 1-2`
 if [ $hour -ne 00 -a $hour -ne 01 -a $hour -ne 02 -a $hour -ne 03 -a $hour -ne 04 -a $hour -ne 05 -a $hour -ne 22 -a $hour -ne 23 ];
  then
   echo "2"
   exit 2
  else
   seek2=`ls -t $path | grep arc_bkp | head -1`
   if [ -d $seek2 ];
    then
     echo "2"
     exit 2
    else
     Empty_log
     var=ERROR
     varc=`ls $seek2 | cut -d "." -f 2`
     vard=`cat $seek2 | grep '\(ORA-\|RMAN-\)'`
     critical=`cd $path; cat $seek2 | grep -om 1 $var`
   fi
 fi
}

directory(){
 if ! [ -d "/u01/app/oradata/backup/logs" ];
  then
   echo "CRITICAL - Directory doesn't exist."
   exit 2
 fi

 path=/u01/app/oradata/backup/logs

 cd $path

 if [ `ls | wc -l` -eq 0 ];
  then
   echo "CRITICAL - Directory is empty."
   exit 2
 fi
}

directory_num(){
 if ! [ -d "/u01/app/oradata/backup/logs" ];
  then
   echo "6"
   exit 2
 fi

 path=/u01/app/oradata/backup/logs

 cd $path

 if [ `ls | wc -l` -eq 0 ];
  then
   echo "6"
   exit 2
 fi
}


# Check keys

if [ $# -lt 1 ];
 then
  echo "No options found!"
  Usage
  exit 1
fi


# Keys

while getopts ":fialch" opt
 do
  case $opt in

	f)	full=$2

		case $full in

		d)		directory
				seek=`find $path -mmin -1440 -name 'DB_I0_BACK*' | grep -m 1 BACK`
				if [ -d $seek ];
				 then
				  seek=`find $path -mmin -10080 -name 'db_bkp_diff0*' | grep -m 1 diff0`
				  if [ -d $seek ];
				   then
				    logs=`ls $path | grep 'db_bkp_diff0*' | wc -l`
				    if [ $logs -eq 0 ];
				     then
				      echo "Схема бэкапа не задана."
				      exit 2
				    fi
				    echo "CRITICAL - Backup is missing."
				    exit 2
				   else
			            Empty_log
		          	    var=ERROR
			            varc=`ls $seek | cut -d "." -f 2`
			            Bkp_in_progress
			            vard=`cat $seek | grep '\(ORA-\|RMAN-\)'`
			            critical=`cd $path; cat $seek | grep -om 1 $var`
			       	    if [ "$var" = "$critical" ];
			             then
			              echo "CRITICAL - Backup Failed: $vard."
			              exit 2
			             else
			              echo "OK - Backup Complete at $varc."
			              exit 0
				    fi
				  fi
				 else
                                  logs=`ls $path | grep 'DB_I0_BACK*' | wc -l`
                                   if [ $logs -eq 0 ];
                                    then
                                     echo "Схема бэкапа не задана."
                                     exit 2
                                   fi
		                  Empty_log
		                  var=ERROR
		                  varc=`ls $seek | cut -d "." -f 2`
		                  Bkp_in_progress
		                  vard=`cat $seek | grep '\(ORA-\|RMAN-\)'`
		                  critical=`cd $path; cat $seek | grep -om 1 $var`
			          if [ "$var" = "$critical" ];
			           then
			            echo "CRITICAL - Backup Failed: $vard."
			            exit 2
			           else
			            echo "OK - Backup Complete at $varc."
			            exit 0
			          fi
				fi

			;;

			*)	directory_num
                                seek=`find $path -mmin -1440 -name 'DB_I0_BACK*' | grep -m 1 BACK`
                                if [ -d $seek ];
                                 then
                                  seek=`find $path -mmin -10080 -name 'db_bkp_diff0*' | grep -m 1 diff0`
                                  if [ -d $seek ];
                                   then
                                    logs=`ls $path | grep 'db_bkp_diff0*' | wc -l`
                                    if [ $logs -eq 0 ];
                                     then
                                      echo "5"
                                      exit 2
                                    fi
                                    echo "2"
                                    exit 2
                                   else
                                    Empty_log
                                    var=ERROR
                                    varc=`ls $seek | cut -d "." -f 2`
                                    Bkp_in_progress_num
                                    vard=`cat $seek | grep '\(ORA-\|RMAN-\)'`
                                    critical=`cd $path; cat $seek | grep -om 1 $var`
                                    if [ "$var" = "$critical" ];
                                     then
                                      echo "1"
                                      exit 2
                                     else
                                      echo "0"
                                      exit 0
                                    fi
                                  fi
                                 else
                                  logs=`ls $path | grep 'DB_I0_BACK*' | wc -l`
                                   if [ $logs -eq 0 ];
                                    then
                                     echo "5"
                                     exit 2
                                   fi
                                  Empty_log
                                  var=ERROR
                                  varc=`ls $seek | cut -d "." -f 2`
                                  Bkp_in_progress_num
                                  vard=`cat $seek | grep '\(ORA-\|RMAN-\)'`
                                  critical=`cd $path; cat $seek | grep -om 1 $var`
                                  if [ "$var" = "$critical" ];
                                   then
                                    echo "1"
                                    exit 2
                                   else
                                    echo "0"
                                    exit 0
                                  fi
                                fi

			;;
			esac

	;;

	i)	incr1=$2

		case $incr1 in

			d)
				directory
				seek=`find $path -mmin -1440 -name 'DB_INCREMENTAL_UPDATE*' | grep -m 1 UPDATE`
				if [ -d $seek ];
				 then
				  seek=`find $path -mmin -1440 -name 'db_bkp_diff1*' | grep -m 1 diff1`
				  if [ -d $seek ];
				   then
                                    logs=`ls $path | grep 'db_bkp_diff1*' | wc -l`
                                    if [ $logs -eq 0 ];
                                     then
                                      echo "Схема бэкапа не задана."
                                      exit 2
                                    fi
				    Check_day_incr1
		                    Empty_log
		                    var=ERROR
		                    varc=`ls $seek | cut -d "." -f 2`
		                    Bkp_in_progress
		                    vard=`cat $seek | grep '\(ORA-\|RMAN-\)'`
		                    critical=`cd $path; cat $seek | grep -om 1 $var`
		                    if [ "$var" = "$critical" ];
		                     then
		                      echo "CRITICAL - Backup Failed: $vard."
		                      exit 2
		                     else
		                      echo "OK - Backup Complete at $varc."
		                      exit 0
		                    fi
				   else
		                    Empty_log
		                    var=ERROR
		                    varc=`ls $seek | cut -d "." -f 2`
		                    Bkp_in_progress
		                    vard=`cat $seek | grep '\(ORA-\|RMAN-\)'`
		                    critical=`cd $path; cat $seek | grep -om 1 $var`
		                    if [ "$var" = "$critical" ];
		                     then
		                      echo "CRITICAL - Backup Failed: $vard."
		                      exit 2
		                     else
		                      echo "OK - Backup Complete at $varc."
		                      exit 0
		                    fi
				  fi
				 else
                                  logs=`ls $path | grep 'DB_INCREMENTAL_UPDATE*' | wc -l`
                                  if [ $logs -eq 0 ];
                                   then
                                    echo "Схема бэкапа не задана."
                                    exit 2
                                  fi
		                  Empty_log
		                  Bkp_in_progress
		                  var=ERROR
		                  varb=ORA-19591
		                  varc=`cat $seek | grep 'Finished backup at' | awk '{print $4" "$5}'`
		                  vard=`cat $seek | grep '\(ORA-\|RMAN-\)'`
		                  critical=`cd $path; cat $seek | grep -om 1 $var`
		                  timeout=`cd $path; cat $seek | grep -om 1 $varb`
		                  if [ "$varb" = "$timeout" ];
		                   then
		                    echo "CRITICAL - ORA-19591: backup aborted because job time exceeded duration time."
		                    exit 2
		                   elif [ "$var" = "$critical" ];
		                    then
		                     echo "CRITICAL - Backup Failed: $vard."
		                     exit 2
		                    else
		                     echo "OK - Backup Complete at $varc."
		                     exit 0
				  fi
				fi

			;;

			*)

                               directory_num
                                seek=`find $path -mmin -1440 -name 'DB_INCREMENTAL_UPDATE*' | grep -m 1 UPDATE`
                                if [ -d $seek ];
                                 then
                                  seek=`find $path -mmin -1440 -name 'db_bkp_diff1*' | grep -m 1 diff1`
                                  if [ -d $seek ];
                                   then
                                    logs=`ls $path | grep 'db_bkp_diff1*' | wc -l`
                                    if [ $logs -eq 0 ];
                                     then
                                      echo "5"
                                      exit 2
                                    fi
                                    Check_day_incr1_num
                                    Empty_log
                                    var=ERROR
                                    varc=`ls $seek | cut -d "." -f 2`
                                    Bkp_in_progress_num
                                    vard=`cat $seek | grep '\(ORA-\|RMAN-\)'`
                                    critical=`cd $path; cat $seek | grep -om 1 $var`
                                    if [ "$var" = "$critical" ];
                                     then
                                      echo "1"
                                      exit 2
                                     else
                                      echo "0"
                                      exit 0
                                    fi
                                   else
                                    Empty_log
                                    var=ERROR
                                    varc=`ls $seek | cut -d "." -f 2`
                                    Bkp_in_progress_num
                                    vard=`cat $seek | grep '\(ORA-\|RMAN-\)'`
                                    critical=`cd $path; cat $seek | grep -om 1 $var`
                                    if [ "$var" = "$critical" ];
                                     then
                                      echo "1"
                                      exit 2
                                     else
                                      echo "0"
                                      exit 0
                                    fi
                                  fi
                                 else
                                  logs=`ls $path | grep 'DB_INCREMENTAL_UPDATE*' | wc -l`
                                  if [ $logs -eq 0 ];
                                   then
                                    echo "5"
                                    exit 2
                                  fi
                                  Empty_log
                                  Bkp_in_progress_num
                                  var=ERROR
                                  varb=ORA-19591
                                  varc=`cat $seek | grep 'Finished backup at' | awk '{print $4" "$5}'`
                                  vard=`cat $seek | grep '\(ORA-\|RMAN-\)'`
                                  critical=`cd $path; cat $seek | grep -om 1 $var`
                                  timeout=`cd $path; cat $seek | grep -om 1 $varb`
                                  if [ "$varb" = "$timeout" ];
                                   then
                                    echo "3"
                                    exit 2
                                   elif [ "$var" = "$critical" ];
                                    then
                                     echo "1"
                                     exit 2
                                    else
                                     echo "0"
                                     exit 0
                                  fi
                                fi

                        ;;
			esac

	;;

	a)	arch=$2

		case $arch in

			d)
				directory
				seek=`find $path -mmin -60 -name 'DB_AL_BACK*' | grep -m 1 BACK`
				if [ -d $seek ];
				 then
				  hour=`date | awk '{print $4}' | cut -c 1-2`
				  if [ $hour -ne 00 -a $hour -ne 01 -a $hour -ne 02 -a $hour -ne 03 -a $hour -ne 04 -a $hour -ne 23 ];
				   then
				    seek=`find $path -mmin -60 -name 'arc_bkp*' | grep -m 1 arc`
			            if [ -d $seek ];
			             then
                                      logs=`ls $path | grep 'arc_bkp*' | wc -l`
                                      if [ $logs -eq 0 ];
                                       then
                                        echo "Схема бэкапа не задана."
                                        exit 2
                                      fi
				      Check_day_arc
			      	      if [ "$var" = "$critical" ];
			               then
			                echo "CRITICAL - Backup Archivelogs Failed: $vard."
			                exit 2
			               else
			                echo "OK - Backup Archivelogs Complete at $varc."
			                exit 0
			              fi
				     else
			              Empty_log
			              Bkp_in_progress
			              var=ERROR
			              varc=`ls $seek | cut -d "." -f 2`
			              vard=`cat $seek | grep '\(ORA-\|RMAN-\)'`
			              critical=`cd $path; cat $seek | grep -om 1 $var`
		                      if [ "$var" = "$critical" ];
		                       then
		                        echo "CRITICAL - Backup Archivelogs Failed: $vard."
		                        exit 2
		                       else
		                        echo "OK - Backup Archivelogs Complete at $varc."
		                        exit 0
		                      fi
				    fi
				   else
				    seek=`find $path -mmin -120 -name 'DB_AL_BACK*' | grep -m 1 BACK`
				     if [ -d $seek ];
				      then
                                       logs=`ls $path | grep 'DB_AL_BACK*' | wc -l`
                                       if [ $logs -eq 0 ];
                                        then
                                         echo "Схема бэкапа не задана."
                                         exit 2
                                       fi
				       echo "CRITICAL - Backup is missing."
				       exit 2
				      else
				       Empty_log
				       var=ERROR
				       varc=`ls $seek | cut -d "." -f 2`
				       vard=`cat $seek | grep '\(ORA-\|RMAN-\)'`
				       critical=`cd $path; cat $seek | grep -om 1 $var`
		                       if [ "$var" = "$critical" ];
		                        then
		                         echo "CRITICAL - Backup Archivelogs Failed: $vard."
		                         exit 2
		                        else
		                         echo "OK - Backup Archivelogs Complete at $varc."
		                         exit 0
				       fi
				     fi
				  fi
				 else
			          Empty_log
			          Bkp_in_progress
			          var=ERROR
			          varc=`ls $seek | cut -d "." -f 2`
			          vard=`cat $seek | grep '\(ORA-\|RMAN-\)'`
			          critical=`cd $path; cat $seek | grep -om 1 $var`
			          if [ "$var" = "$critical" ];
			           then
			            echo "CRITICAL - Backup Archivelogs Failed: $vard."
			            exit 2
			           else
			            echo "OK - Backup Archivelogs Complete at $varc."
			            exit 0
			          fi
			        fi

			;;

			*)
                               directory_num
                                seek=`find $path -mmin -60 -name 'DB_AL_BACK*' | grep -m 1 BACK`
                                if [ -d $seek ];
                                 then
                                  hour=`date | awk '{print $4}' | cut -c 1-2`
                                  if [ $hour -ne 00 -a $hour -ne 01 -a $hour -ne 02 -a $hour -ne 03 -a $hour -ne 04 -a $hour -ne 23 ];
                                   then
                                    seek=`find $path -mmin -60 -name 'arc_bkp*' | grep -m 1 arc`
                                    if [ -d $seek ];
                                     then
                                      logs=`ls $path | grep 'arc_bkp*' | wc -l`
                                      if [ $logs -eq 0 ];
                                       then
                                        echo "5"
                                        exit 2
                                      fi
                                      Check_day_arc_num
                                      if [ "$var" = "$critical" ];
                                       then
                                        echo "1"
                                        exit 2
                                       else
                                        echo "0"
                                        exit 0
                                      fi
                                     else
                                      Empty_log
                                      Bkp_in_progress_num
                                      var=ERROR
                                      varc=`ls $seek | cut -d "." -f 2`
                                      vard=`cat $seek | grep '\(ORA-\|RMAN-\)'`
                                      critical=`cd $path; cat $seek | grep -om 1 $var`
                                      if [ "$var" = "$critical" ];
                                       then
                                        echo "1"
                                        exit 2
                                       else
                                        echo "0"
                                        exit 0
                                      fi
                                    fi
                                   else
                                    seek=`find $path -mmin -120 -name 'DB_AL_BACK*' | grep -m 1 BACK`
                                     if [ -d $seek ];
                                      then
                                       logs=`ls $path | grep 'DB_AL_BACK*' | wc -l`
                                       if [ $logs -eq 0 ];
                                        then
                                         echo "5"
                                         exit 2
                                       fi
                                       echo "2"
                                       exit 2
                                      else
                                       Empty_log
                                       var=ERROR
                                       varc=`ls $seek | cut -d "." -f 2`
                                       vard=`cat $seek | grep '\(ORA-\|RMAN-\)'`
                                       critical=`cd $path; cat $seek | grep -om 1 $var`
                                       if [ "$var" = "$critical" ];
                                        then
                                         echo "1"
                                         exit 2
                                        else
                                         echo "0"
                                         exit 0
                                       fi
                                     fi
                                  fi
                                 else
                                  Empty_log
                                  Bkp_in_progress_num
                                  var=ERROR
                                  varc=`ls $seek | cut -d "." -f 2`
                                  vard=`cat $seek | grep '\(ORA-\|RMAN-\)'`
                                  critical=`cd $path; cat $seek | grep -om 1 $var`
                                 if [ "$var" = "$critical" ];
                                   then
                                    echo "1"
                                    exit 2
                                   else
                                    echo "0"
                                    exit 0
                                  fi
                                fi

			;;
			esac

	;;

	l)	log=$2

		case $log in

			d)
				SID=`cat /etc/oratab | grep CDB | cut -c 1-6`
			        if [[ -z $SID ]];
			         then
			          echo "CRITICAL - NO ORACLE SID!"
			          exit 2
			        fi

			        sid=`echo $SID | tr '[A-Z]' '[a-z]'`
			        alert_dir=/u01/app/oradata/diag/rdbms/$sid/$SID/trace
			        alert_log=$alert_dir/alert_$SID.log
			        day=`date +%a" "%b" "%d`


                                ORAERR=`cat $alert_log | grep -A20000 "$day" | grep ORA-01555`
                                if [[ -n $ORAERR ]];
                                 then
                                  ORA=`cat $alert_log | grep -A20000 "$day" | grep ORA-01555 | grep Duration | awk '{print $11}' | sed 's/Duration=//' | sort -r | head -1`
                                  if [[ $ORA -le 36000 ]];
                                   then
                                    echo "Ошибки в БД: $ORAERR. Смотри в alert.log за $day."
                                    exit 2
                                   else
				    ERROR=`cat $alert_log | grep -A20000 "$day" | grep -v '\(ORA-00600: internal error code, arguments: \[\]\|17302\|16365\|ktrget3:clschk_kcbgtcr_12\|kglUnPin-bad-pin\|kgantc_1\|4450\|17090\|k2spsp\|OCIKSEC\)' | grep '\(ORA-00600\|ORA-07445\|ORA-01578\|ORA-04030\|ORA-04031\|ORA-00255\|ORA-01116\|ORA-01110\|ORA-27041\)'`
                                    if [[ -n $ERROR ]];
                                     then
                                      echo "Ошибки в БД: $ERROR. Смотри в alert.log за $day."
                                      exit 2
                                     else
                                      echo "OK - Нет ошибок."
                                      exit 0
                                    fi
				  fi
				 else
                                  ERROR=`cat $alert_log | grep -A20000 "$day" | grep -v '\(ORA-00600: internal error code, arguments: \[\]\|17302\|16365\|ktrget3:clschk_kcbgtcr_12\|kglUnPin-bad-pin\|kgantc_1\|4450\|17090\|k2spsp\|OCIKSEC\)' | grep '\(ORA-00600\|ORA-07445\|ORA-01578\|ORA-04030\|ORA-04031\|ORA-00255\|ORA-01116\|ORA-01110\|ORA-27041\)'`
                                  if [[ -n $ERROR ]];
                                   then
                                    echo "Ошибки в БД: $ERROR. Смотри в alert.log за $day."
                                    exit 2
                                   else
                                    echo "OK - Нет ошибок."
                                    exit 0
                                  fi
                                fi

			;;

			*)
				SID=`cat /etc/oratab | grep CDB | cut -c 1-6`
                                if [[ -z $SID ]];
                                 then
                                  echo "4"
                                  exit 2
                                fi

                                sid=`echo $SID | tr '[A-Z]' '[a-z]'`
                                alert_dir=/u01/app/oradata/diag/rdbms/$sid/$SID/trace
                                alert_log=$alert_dir/alert_$SID.log
                                day=`date +%a" "%b" "%d`

			        ORAERR=`cat $alert_log | grep -A20000 "$day"| grep ORA-01555`
				if [[ -n $ORAERR ]];
				 then
				  ORA=`cat $alert_log | grep -A20000 "$day" | grep ORA-01555 | grep Duration | awk '{print $11}' | sed 's/Duration=//' | sort -r | head -1`
				  if [[ $ORA -le 36000 ]];
				   then
				    echo "1"
				    exit 2
				   else
                                    ERROR=`cat $alert_log | grep -A20000 "$day" | grep -v '\(ORA-00600: internal error code, arguments: \[\]\|17302\|16365\|ktrget3:clschk_kcbgtcr_12\|kglUnPin-bad-pin\|kgantc_1\|4450\|17090\|k2spsp\|OCIKSEC\)' | grep '\(ORA-00600\|ORA-07445\|ORA-01578\|ORA-04030\|ORA-04031\|ORA-00255\|ORA-01116\|ORA-01110\|ORA-27041\)'`
                                    if [[ -n $ERROR ]];
                                     then
                                      echo "1"
                                      exit 2
                                     else
                                      echo "0"
                                      exit 0
                                    fi
				  fi
				 else
                                  ERROR=`cat $alert_log | grep -A20000 "$day" | grep -v '\(ORA-00600: internal error code, arguments: \[\]\|17302\|16365\|ktrget3:clschk_kcbgtcr_12\|kglUnPin-bad-pin\|kgantc_1\|4450\|17090\|k2spsp\|OCIKSEC\)' | grep '\(ORA-00600\|ORA-07445\|ORA-01578\|ORA-04030\|ORA-04031\|ORA-00255\|ORA-01116\|ORA-01110\|ORA-27041\)'`
                                  if [[ -n $ERROR ]];
                                   then
                                    echo "1"
                                    exit 2
                                   else
                                    echo "0"
                                    exit 0
                                  fi
			        fi

			;;

			esac

	;;

	c)	cron=$2

		case $cron in

			d)
				tab=`crontab -lu oracle | grep DB_INCREMENTAL_UPDATE | cut -c 1-1`
				if [ "$tab" = "#" ];
				 then
				  echo "CRITICAL - Схема закомментирована!"
				  exit 1
				 else
				  echo "OK - Схема используется"
				  exit 0
				fi

			;;

			*)
                                tab=`crontab -lu oracle | grep DB_INCREMENTAL_UPDATE | cut -c 1-1`
                                if [ "$tab" = "#" ];
                                 then
                                  echo "8"
                                  exit 1
                                 else
                                  echo "0"
                                  exit 0
                                fi

			;;

			esac

	;;

	h) Usage

	;;

	*)	echo "Wrong option."
        	Usage
        	exit 1

	;;

  esac
 done
