# 2. Docker와 Kubernates 첫 스탭

## 2.1 컨테이너 이미지의 생성/실행/공유
### 2.1.1 Docker 설치 및 Hello World 컨테이너 실행
CentOS 7 환경에서 Docker 설치법

```bash
#!/bin/bash
yum install -y yum-utils device-mapper-persistent-data lvm2
yum-config-manager --add-repo \
  https://download.docker.com/linux/centos/docker-ce.repo
yum makecache fast
yum install docker-ce -y
systemctl start docker
```
Busybox 이미지를 사용한 Hello World 실행

```bash
[root@localhost ~]# docker run busybox echo "Hello World"
Unable to find image 'busybox:latest' locally
latest: Pulling from library/busybox
0ffadd58f2a6: Pull complete
Digest: sha256:bbc3a03235220b170ba48a157dd097dd1379299370e1ed99ce976df0355d24f0
Status: Downloaded newer image for busybox:latest
Hello World
```

#### 동작 원리

![](images/figure2.1.png)

### 이미지 실행 방법

```
# docker run <image>
# docker run <image>:<tag>
```

### 2.1.2 간단한 Node.js app 생성 및 

```
[root@localhost ~]# mkdir nodejs_app

[root@localhost ~]# cd nodejs_app
[root@localhost nodejs_app]# cat <<'EOF' > app.js
const http = require('http');
const os = require('os');

console.log("Kubia server starting...");

var handler = function(request, response){
  console.log("Received request from " + request.connection.remoteAddress);
  response.writeHead(200);
  response.end("You've hit " + os.hostname() + "\n");
};

var www = http.createServer(handler)
www.listen(8080);
EOF
```

Node.js 응용프로그램을 실행하기 위해서는 Node.js 런타임이 설치되어있어야한다. 다음은 CentOS 7에서 Node.js를 설치하는 방법이다.

```
# yum install epel-release -y
# yum install nodejs -y
```

다음 명령을 통하여 생성한 app.js를 실행하여 HTTP 서버를 구동시킨다.

```
[root@localhost nodejs_app]# node app.js
Kubia server starting...
``` 
이제 다른 터미널이나 PC에서 해당 서버로 접근해본다.

```
[vagrant@localhost ~]$ curl http://localhost:8080
You've hit localhost.localdomain
```


### 2.1.3 Docker 이미지를 위한 Dockerfile 생성
위에서 생성한 node.js 응용프로그램을 실행하기위해서는 Node.js 런타임 라이브러리가 설치되어있어야 한다.
Docker 컨테이너 이미지를 만든 app.js과 함께 패키징하게되면 이러한 설치과정이 필요없다.

먼저 응용프로그램을 이미지에 패키징하려면 Dockerfile을 먼저 생성하여야 한다.

```
[root@localhost nodejs_app]# cat <<'EOF' > Dockerfile
FROM node:7
ADD app.js /app.js
CMD node app.js
EOF
```

### 2.1.4 컨테이너 이미지 빌드하기

```
[root@localhost nodejs_app]# docker build -t kubia .
```

```
[root@localhost nodejs_app]# docker build -t kubia .
Sending build context to Docker daemon  3.072kB
Step 1/3 : FROM node:7
7: Pulling from library/node
ad74af05f5a2: Pull complete
2b032b8bbe8b: Pull complete
a9a5b35f6ead: Pull complete
3245b5a1c52c: Pull complete
afa075743392: Pull complete
9fb9f21641cd: Pull complete
3f40ad2666bc: Pull complete
49c0ed396b49: Pull complete
Digest: sha256:af5c2c6ac8bc3fa372ac031ef60c45a285eeba7bce9ee9ed66dad3a01e29ab8d
Status: Downloaded newer image for node:7
 ---> d9aed20b68a4
Step 2/3 : ADD app.js /app.js
 ---> 3ef9f9b2a1b2
Removing intermediate container 59f58c42b7a9
Step 3/3 : CMD node app.js
 ---> Running in 58c4558cdd1a
 ---> ea7048f17f9f
Removing intermediate container 58c4558cdd1a
Successfully built ea7048f17f9f
Successfully tagged kubia:latest
```
![](images/figure2.2.png)

**이미지 레이어의 이해**

![](images/figure2.3.png)

다음 커맨드를 통하여 현 시스템에 설치된 컨테이너 이미지를 확인할 수 있다.

```
[root@localhost nodejs_app]# docker images
REPOSITORY                    TAG                 IMAGE ID            CREATED             SIZE
kubia                         latest              ea7048f17f9f        3 minutes ago       660MB
busybox                       latest              6ad733544a63        9 days ago          1.13MB
```

### 2.1.5 컨테이너 이미지 실행하기
```
# docker run --name kubia-container -p 8080:8080 -d kubia
```
kubia이미지를 사용하여 kubia-container라는 이름으로 Docker를 실행하라는 명령으로 각 옵션의 의미는 다음과 같다

* --name kubia-container | 컨테이너의 이름을 kubia-container로 지정하라는 의미
* -d | Backgroud로 실행 -> console을 분리(detach)하라는 의미
* -p 8080:8080 | 로컬 8080 포트를 내부 컨테이너의 8080 포트에 맵핑하라는 의미

**응용프로그램의 접근**
이제 백그라운드로 실행한 docker 컨테이너에 접근해보자. 
다음 실행 결과를보면 호스트이름이 현재 시스템 호스트이름이 아닌 컨테이너의 ID값인 11c1d0806a41가 반환된 것을 볼 수 있다.

```
[root@localhost nodejs_app]# curl localhost:8080
You've hit 11c1d0806a41
```

**실행되고 있는 모든 컨테이너 리스팅하기**

```
# docker ps
```
```
[root@localhost nodejs_app]# docker ps
CONTAINER ID        IMAGE               COMMAND                  CREATED             STATUS              PORTS                    NAMES
11c1d0806a41        kubia               "/bin/sh -c 'node ..."   6 minutes ago       Up 6 minutes        0.0.0.0:8080->8080/tcp   kubia-container
```

**컨테이너의 자세한 정보 확인하기** 

```
# docker inspect kubia-container
```

### 2.1.6 실행 중인 컨테이너 내부 보기

**현 컨테이너의 쉘 실행**

전에 생성한 node.js 이미지에는 bash 쉘을 포함하고 있음으로 다음 명령으로 쉘을 실행 할 수 있다.

```
# docker exec -t kubia-container bash
```

위 명령은 kubia-container 컨테이너 내의 bash를 실행시킨다. 이 bash 프로세스는 메인 컨테이너 프로세스와 같은 네임스페이스를 가진다.
이로 인하여 우리는 Node.js와 우리가 생성한 응용프로그램이 어떻게 컨테이너 내부에서 실행됨을 알 수가 있다.

* -i: STDIN을 계속 유지
* -t: 가상 터미널(TTY) 할당

**컨테이너 내부 확인**

```
root@11c1d0806a41:/# ps aux
USER       PID %CPU %MEM    VSZ   RSS TTY      STAT START   TIME COMMAND
root         1  0.0  0.0   4328   656 ?        Ss   10:17   0:00 /bin/sh -c node app.js
root         5  0.2  0.8 614424 16420 ?        Sl   10:17   0:00 node app.js
root        11  0.0  0.1  20236  1980 pts/0    Ss   10:18   0:00 bash
root        16  0.0  0.0  17492  1136 pts/0    R+   10:18   0:00 ps aux
root@11c1d0806a41:/#
```
실행 결과를 보면 단지 4개의 프로세스들만 보이고, 호스트 OS의 다른 프로세스들은 보이지 않음을 알 수 있다.

**호스트 OS에서 실행되는 컨테이너의 프로세스 확인**

```
[root@localhost ~]# ps aux |grep app.js | grep -v 'grep'
root      2974  0.0  0.0   4328   656 ?        Ss   10:17   0:00 /bin/sh -c node app.js
root      3001  0.0  0.8 614424 16420 ?        Sl   10:17   0:00 node app.js
```
컨테이너에서 실행되고 있는 프로세스들은 결국 호스트 OS에서 실행되고 있음을 확인할 수 있다. 그런데 자세히보면 프로세스 ID가 다름을 볼 수 있는데,
이는 컨테이너 자체 적으로 별도의 PID 네임스페이스를 사용하고 있음에 따라 완전히 독립된 프로세스 트리가지게되고 다른 프로세스 순번을 가지게 되는 것이다.

```
[root@localhost ~]# docker exec -it kubia-container ps aux | grep node
root         1  0.0  0.0   4328   656 ?        Ss   10:17   0:00 /bin/sh -c node
root         5  0.0  0.8 614424 16420 ?        Sl   10:17   0:00 node app.js
[root@localhost ~]# ps aux |grep node | grep -v 'grep'
root      2974  0.0  0.0   4328   656 ?        Ss   10:17   0:00 /bin/sh -c node app.js
root      3001  0.0  0.8 614424 16420 ?        Sl   10:17   0:00 node app.js
```

**독립된 컨테이너의 파일시스템**

```
root@11c1d0806a41:/# ls /
app.js	bin  boot  dev	etc  home  lib	lib64  media  mnt  opt	proc  root  run  sbin  srv  sys  tmp  usr  var
```

### 2.1.7 컨테이너의 종료 및 삭제

```
docker stop kubia-container
```

ps -a 옵션을 사용할 경우 해당 컨테이너가 종료되었으나 여전히 시스템에 남아있음을 확인할 수 있다.

```
[root@localhost ~]# docker ps
CONTAINER ID        IMAGE               COMMAND             CREATED             STATUS              PORTS               NAMES
[root@localhost ~]# docker ps -a
CONTAINER ID        IMAGE               COMMAND                  CREATED             STATUS                       PORTS               NAMES
11c1d0806a41        kubia               "/bin/sh -c 'node ..."   4 days ago          Exited (137) 2 minutes ago                       kubia-container
d5a881906cb7        busybox             "echo 'Hello World'"     4 days ago          Exited (0) 4 days ago                            hungry_colden
```

남아있는 컨테이너는 **docker rm** 명령을 통하여 완전히 삭제 시킬 수 있다.

```
[root@localhost ~]# docker rm kubia-container
kubia-container
[root@localhost ~]# docker ps -a
CONTAINER ID        IMAGE               COMMAND                  CREATED             STATUS                      PORTS               NAMES
d5a881906cb7        busybox             "echo 'Hello World'"     4 days ago          Exited (0) 4 days ago                           hungry_colden
```

### 2.1.7 이미지 레지스트리에 컨테이너 이미지 올리기
생성한 이미지를 다른 시스템에서 사용하기 위해서는 시스템들이 엑세스 할 수 있는 외부 이미지 레지스트리에 이미지를 먼저 등록해야한다.
레지스트리에 등록을 하기 위해서는 먼저 올리려는 컨테이너 이미지에 태그를 달아야 한다. 본 예제에서는 daehyung/kubia에 kubia 태그를 달았다(daehyung 대신 자신의 Docker Hub의 ID를 사용한다).

**이미지에 태그(Tag) 추가하기**

```
[root@localhost ~]# docker images
REPOSITORY                    TAG                 IMAGE ID            CREATED             SIZE
kubia                         latest              ea7048f17f9f        4 days ago          660MB
...SNIP...
[root@localhost ~]# docker tag kubia daehyung/kubia
``` 

**Docker Hub 로그인**

```
[root@localhost ~]# docker login
Login with your Docker ID to push and pull images from Docker Hub. If you don't have a Docker ID, head over to https://hub.docker.com to create one.
Username: daehyung
Password:
Login Succeeded
```

**이미지 올리기**

```
[root@localhost ~]# docker push daehyung/kubia
The push refers to a repository [docker.io/daehyung/kubia]
24db31c42e1d: Pushed
ab90d83fa34a: Pushed
8ee318e54723: Pushed
e6695624484e: Pushed
da59b99bbd3b: Pushed
5616a6292c16: Pushed
f3ed6cb59ab0: Pushed
654f45ecb7e3: Pushed
2c40c66f7667: Pushed
latest: digest: sha256:1bdbf39903764c5132da5e5a71c4a14bf005c633c8caee4f29d70b07f3c29867 size: 2213
```

**다른 시스템에서 이미지 실행하기**

```
[root@localhost ~]# docker run -p 8080:8080 -d daehyung/kubia
73409f39c1485d0999f828e153b33d174b4deeb80313cd65197809ef6eb9cf77
[root@localhost ~]# docker ps
CONTAINER ID        IMAGE               COMMAND                  CREATED             STATUS              PORTS                    NAMES
73409f39c148        daehyung/kubia      "/bin/sh -c 'node ..."   6 seconds ago       Up 6 seconds        0.0.0.0:8080->8080/tcp   focused_nobel
```

