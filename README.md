# DevCeph

单机一键安装Ceph。

## Installation

系统要求：

 - Ubuntu 12.04 以上
 - 主机名不能是 localhost
 - 目录空间1GB以上

```
$cd /opt/
$git clone https://github.com/zhurongze/devceph.git
$cd devceph
$./devceph.sh install
$./devceph.sh start
$ceph -s
```

其他命令：
```
$./devceph.sh stop
$./devceph.sh restart
$./devceph.sh clean
$./devceph.sh uninstall
```
## Ceph Usage

创建一个新的pool:
```
$ceph osd pool create testpool 96 96
```

上传文件到testpool中:
```
$rados --pool=testpool put education.avi mm.avi
```

查看系统容量：
```
$ rados --pool=testpool ls
education.avi
$
$ rados df
pool name       category                 KB      objects       clones     degraded      unfound           rd        rd KB           wr        wr KB
data            -                          0            0            0            0           0            0            0            0            0
metadata        -                          0            0            0            0           0            0            0            0            0
rbd             -                          0            0            0            0           0            0            0            0            0
testpool        -                      30720            1            0            0           0            0            0            8        30720
  total used        10622440            1
  total avail       48153284
  total space       61921140
$ ceph df
GLOBAL:
    SIZE       AVAIL      RAW USED     %RAW USED 
    60469M     47024M     10373M       17.15     

POOLS:
    NAME         ID     USED       %USED     OBJECTS 
    data         0      0          0         0       
    metadata     1      0          0         0       
    rbd          2      0          0         0       
    testpool     3      30720K     0.05      1       

```

更多帮助
```
$ceph --help        #ceph 集群的命令
$rados --help       #rados对象存储的命令
$rbd  --help         #rbd块设备存储的命令
```

## Python-Rados

具体用法请参考 https://github.com/ceph/ceph/blob/master/src/test/pybind/test_rados.py
```
>>> import rados
>>> cc = rados.Rados(rados_id='admin', conffile='/etc/ceph/ceph.conf')
>>> cc.connect()
>>> cc.list_pools()
['data', 'metadata', 'rbd', 'testpool']
>>> ioctx = cc.open_ioctx('testpool')
>>> object_names = [obj.key for obj in ioctx.list_objects()]
>>> print object_names
['education.avi']
>>> 
```

