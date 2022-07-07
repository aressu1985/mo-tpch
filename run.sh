#!/usr/bin/env bash

if [[ $# -eq 0 ]];then
    echo "No parameters provided,please use -H to get help. "

fi

WORKSPACE=$(cd `dirname $0`; pwd)
SERVER="127.0.0.1"
PORT=6001
USER=dump
PASS=111
SCALE=1
QUERY="ALL"
while getopts ":h:P:u:p:s:q:glcH" opt
do
    case $opt in
        h)
        SERVER="${OPTARG}"
        ;;
        P)
        PORT=${OPTARG}
        ;;
        u)
        USER="${OPTARG}"
        ;;
        p)
        PASS="${OPTARG}"
        ;;
        s)
        SCALE=${OPTARG}
        ;;
        g)
        METHOD="GEN"
        ;;
        l)
        METHOD="LOAD"
        #echo -e "Start to load the tpch data to the mo server,scale=${SCALE} G"
        ;;
        c)
        METHOD="CTAB"
        ;;
        q)
        METHOD="QUERY"
        QUERY="${OPTARG}"
        ;;
        H)
        echo -e "Usage:　bash run.sh [option] [param] ...\nExcute mo tpch task"
        echo -e "   -h  mo server address"
        echo -e "   -P  mo server port"
        echo -e "   -u  mo server username"
        echo -e "   -p  mo server password of the user[-u]"
        echo -e "   -s  the scale of the tpch data ,unit G,default is 1G"
        echo -e "   -q  run the tpch query sql,and can specify the certain query by q[1-22],or all"
        echo -e "   -g  generate the tpch data,must specify scale through -s"
        echo -e "   -l  load the tpch data to mo server,must specify scale by -s,and the mo server info by -h,-P,-u,-p"
        echo -e "   -c  create the table in mo server,must specify the mo server info by -h,-P,-u,-p"
        echo -e "Examples:"
        echo "   bash run.sh -g -s 1        #to generate tpch data with scale[1G] to the dir[./data/1]"
	echo -e "   bash run.sh -l -s 1        #to load tpch data from the dir[./data/1] to MO,default addr and auth (127.0.0.1:6001 dump/111) "
        echo -e "   bash run.sh -c -s 1        #to create tpch tables in MO,dbname is tpch_1g"
        echo -e "   bash run.sh -q q1 -s 1     #to run the query q1 with 1G data"
        echo -e "   bash run.sh -q all -s 0.5  #to run all the queries with 0.5G data"
	echo "For more support,please email to sudong@matrixorigin.io"
        exit 1
        ;;
        ?)
        echo "Unkown parameter,please use -H to get help."
        exit 1;;
    esac
done

function execute() {
  echo "The query is ${QUERY}"
}


function gen() {
  echo -e "Start to generate tpch data scale[${SCALE}G] to the path ./data/${SCALE}"
  cd ${WORKSPACE}
  mkdir -p data/${SCALE}
  cd ${WORKSPACE}/dbgen
  ./dbgen -s ${SCALE}
  mv *.tbl ../data/${SCALE}/
  cd ${WORKSPACE}/data/${SCALE}/
  mv lineitem.tbl lineitem.tbl.old
  mv partsupp.tbl partsupp.tbl.old
  sed = lineitem.tbl.old | sed 'N;s/\n/|/' > lineitem.tbl
  sed = partsupp.tbl.old | sed 'N;s/\n/|/' > partsupp.tbl
  cd ${WORKSPACE}
}

function ctab() {
    echo -e "Start to creat table for tpch test in mo server,please wait....."
    cp mo.ddl tpch_table_temp.sql
    sed -i 's/tpch_${SCALE}g/tpch_'${SCALE/./_}'g/g' tpch_table_temp.sql
    #echo "mysql -h${SERVER} -P${PORT} -u${USER} -p{PASS} < tpch_table_temp.sql"
    mysql -h${SERVER} -P${PORT} -u${USER} -p${PASS} < tpch_table_temp.sql
    if [ $? -eq 0 ];then
      echo -e "The tables for tpch has been created successfully."
    else
      #local  result=`mysql -h${SERVER} -P${PORT} -u${USER} -p${PASS} < tpch_table_temp.sql`
      #echo ${result}
      echo -e "The tables for tpch has been created failed."
    fi
    #rm -rf tpch_table_temp.sql
}

function load() {
    echo -e "Start to load tpch ${SCALE}G data to mo server,please wait....."
    DBNAME=tpch_${SCALE/./_}g
    for tbl in data/${SCALE}/*.tbl
    do
      local table=`basename ${tbl} .tbl`
      local sql="load data infile '${WORKSPACE}/${tbl}' into table ${DBNAME}.${table} FIELDS TERMINATED BY '|' LINES TERMINATED BY '\n';"
      echo -e "Loading ${tbl} in to table ${table},please wait....."
      echo "${sql}"
      startTime=`date +%s.%N`
      mysql -h${SERVER} -P${PORT} -u${USER} -p${PASS} -e "${sql}" 2>/dev/null
      if [ $? -eq 0 ];then
	  endTime=`date +%s.%N`
          getTiming $startTime $endTime
          echo -e "The data for table ${table} has been loaded successfully,,and cost: ${cost}"
      else
          echo -e "The data for table ${table} has failed to be loaded."
      fi
    done
#     echo -e "Loading lineitem.tbl into table lineitem,please wait....."
#     echo "load data infile '${WORKSPACE}/data/lineitem.tbl' into table TPCH.lineitem FIELDS TERMINATED BY '|' LINES TERMINATED BY '\n';"
#     mysql -h${SERVER} -P${PORT} -u${USER} -p${PASS} -e "load data infile '${WORKSPACE}/data/lineitem.tbl' into table TPCH.lineitem FIELDS TERMINATED BY '|' LINES TERMINATED BY '\n';"
#     if [ $? -eq 0 ];then
#        echo -e "The data for table lineitem has been loaded successfully."
#     else
#        echo -e "The data for table lineitem has failed to be loaded."
#     fi
}

function query() {
    cd ${WORKSPACE}
    if [ ! -d ${WORKSPACE}/report/ ];then
        mkdir -p ${WORKSPACE}/report/
    fi
    if [ ! -d ${WORKSPACE}/report/rees_${SCALE}/ ];then
        mkdir -p ${WORKSPACE}/report/res_${SCALE}/
    fi
    rm -rf ${WORKSPACE}/report/rt_${SCALE}.txt
    #mkdir -p ${WORKSPACE}/report/${SCALE}
    #mkdir -p ${WORKSPACE}/report/${SCALE}/result/
    DBNAME=tpch_${SCALE/./_}g
    if [ "${QUERY}"x != "all"x ];then
      echo -e "Now start to execute the query ${QUERY},please wait....."
       startTime=`date +%s.%N`
      timeout 7200s result=`mysql -h${SERVER} -P${PORT} -u${USER} -p${PASS} ${DBNAME} < queries/${QUERY}.sql`
       if [ $? -eq 0 ];then
          endTime=`date +%s.%N`
          #cost=$[ $endTime - $startTime ]
          getTiming $startTime $endTime
          echo -e "The query ${QUERY}  has been executed successfully,and cost: ${cost}"
	  echo "${QUERY} : ${cost}" >> ${WORKSPACE}/report/rt_${SCALE}.txt
          echo "${result}" > ${WORKSPACE}/report/res_${SCALE}/${QUERY}.res
	  #echo -e "\n"
       else
          echo -e "TThe query ${QUERY}  has failed to  been executed."
	  echo "${result}" > ${WORKSPACE}/report/res_${SCALE}/${QUERY}.res
          #echo -e "\n"
       fi
    else
       for sql in queries/*
       do
         QUERY=${sql}
	 local name=`basename ${sql} .sql`
         echo -e "Now start to execute the query ${QUERY},please wait....."
         startTime=`date +%s.%N`
         result=`mysql -h${SERVER} -P${PORT} -u${USER} -p${PASS} ${DBNAME} < ${QUERY}`
         if [ $? -eq 0 ];then
           endTime=`date +%s.%N`
           getTiming $startTime $endTime
           echo -e "The query ${QUERY}  has been executed successfully,and cost: ${cost}"
	   echo "${name} : ${cost}" >> ${WORKSPACE}/report/rt_${SCALE}.txt
	   echo "${result}" > ${WORKSPACE}/report/res_${SCALE}/${name}.res
           #echo -e "\n"
         else
           echo -e "TThe query ${QUERY}  has failed to  been executed."
           #echo -e "\n"
         fi
       done
    fi
}

function getTiming(){
    start=$1
    end=$2

    start_s=`echo $start | cut -d '.' -f 1`
    start_ns=`echo $start | cut -d '.' -f 2`
    end_s=`echo $end | cut -d '.' -f 1`
    end_ns=`echo $end | cut -d '.' -f 2`

    time_micro=$(( (10#$end_s-10#$start_s)*1000000 + (10#$end_ns/1000 - 10#$start_ns/1000) ))
    time_ms=`expr $time_micro/1000  | bc `

    cost=${time_ms}
}

if [ "${METHOD}"x = "GEN"x ];then
  gen
fi

if [ "${METHOD}"x = "CTAB"x ];then
  ctab
fi

if [ "${METHOD}"x = "LOAD"x ];then
  load
fi

if [ "${METHOD}"x = "QUERY"x ];then
  #echo "${QUERY}"
  query
fi
