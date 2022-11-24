# mo-tpch
This project integrates operations of data generation,table creation,data loading and queries execution for TPCH benchmark test to MatrixOne product.

# How to use?

This tool is designed to test MatrixOne benchmark for TPCH or any other database functionalities with SQL. 

### 0. Install `make` tool if you don't have it yet.
Now this tool can only on Centos OS, and need to install `make` tool at first.
You can install `make` using the following command:

`yum -y install gcc automake autoconf libtool make`


### 1: Run your MatrixOne instance or other DB instance. 

Checkout [Install MatrixOne](https://docs.matrixorigin.io/0.4.0/MatrixOne/Get-Started/install-standalone-matrixone/) to launch a MatrixOne instance.

Or you can launch whatever database software as you want. 

### 2. Fork and clone this mo-tpch project. 

```
git clone https://github.com/matrixorigin/mo-tpch.git
```
### 3. Compile the TPCH data generation tool
```
> cd dbgen
> make
```
### 4. Run the test.

You can use this tool to generate the TPCH data,create TPCH tables,load data to MatrixOrigin(or other database),and execute TPCH queries(22 queries).

And these Opertions must be executed step by step as the following descriptions, or there will be errors unexpected during the test.

**Fisrt,you should generate TPCH data by the command:**

`./run.sh -g -s 1`

`-s` means the scale of the tpch data, unit G,default 1G.And you specify the scale according to the real test requirement.

After this opertion,the data generated will be placed to dir `./data/{scale}/`,and for this command,the dir is `./data/1/`.

Note: if the data for specified scale has been generated before,this operation will not
generate data repeatedly.


**Second,you should create TPCH database and tables by the command:**

`./run.sh -c -s 1`

`-s` means the scale of the tpch data, and here it specify the database name is `tpch_${scale}g`, for this command, `tpch_1g`

Note: if the database and tables have been created before,this operation will drop the database and tables,and re-create them.


**Third,you should load the TPCH data to tables by the command:**

`./run.sh -l -s 1`

`-s` means the scale of the tpch data, and here it means the data path is `./data/{scale}/` and the database name is `tpch_${SCALE}g`.

For this command, the data path is `./data/1/` and the database name is `tpch_1g`

**Then，you can run TPCH queries by the commands:**

`./run.sh -q all -s 1`

`./run.sh -q q3 -s 1`

`-q`  means run the tpch query sql,and can specify the certain query by q[1-22],or all.

`-s` means the scale of the tpch data.


**At last**

When all queries have been executed completedly,you can view the report from the dir `./report/`.

And the report file is named as `rt_{scale}.txt`, such as `rt_1.txt,rt_10.txt`, the content consists of response time of all the queries.


You can also run `./run.sh -H` to get the help:

```
Usage:　bash run.sh [option] [param] ...
Excute mo tpch task
   -h  mo server address
   -P  mo server port
   -u  mo server username
   -p  mo server password of the user[-u]
   -s  the scale of the tpch data ,unit G,default is 1G
   -q  run the tpch query sql,and can specify the certain query by q[1-22],or all
   -g  generate the tpch data,must specify scale through -s
   -l  load the tpch data to mo server,must specify scale by -s,and the mo server info by -h,-P,-u,-p
   -c  create the table in mo server,must specify the mo server info by -h,-P,-u,-p
Examples:
   bash run.sh -g -s 1        #to generate tpch data with scale[1G] to the dir[./data/1]
   bash run.sh -l -s 1        #to load tpch data from the dir[./data/1] to MO,default addr and auth (127.0.0.1:6001 dump/111) 
   bash run.sh -c -s 1        #to create tpch tables in MO,dbname is tpch_1g
   bash run.sh -q q1 -s 1     #to run the query q1 with 1G data
   bash run.sh -q all -s 0.5  #to run all the queries with 0.5G data
```
