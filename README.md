#	배포하기
* AWS가입하고 서비스 콘솔 실행하기
* Key Pair 생성하기


## KeyPair 생성하기
Service > ec2 > NETWORK&SECURITY > Key Pairs
> 키페어를 생성하면 .pem 확장자가 달린 키를 다운받을 수 있다. 이 키는 최초 1회만 다운로드 가능하므로 반드시 잘 보관한다. 
> 
> 이후 이 키를 ~/.ssh 폴더에 저장한다.
> 
> 



## 우분투 서버 설치 이후 초기 설정
```

```


## uwsgi 설정하기
### 웹서버 관리용 유저 생성
```
sudo adduser deploy(<-유저 네임)
```
### uwsgi 설치
```
(virtualenv 환경 내부에서)
pip install uwsgi

* 만약 requirements.txt에 이미 있으면 재설치 필요없음
```

#### uWSGI 정상 동작 확인

```
uwsgi --http :8080 --home (virtualenv경로) --chdir (django프로젝트 경로) -w (프로젝트명).wsgi
```

ex) pyenv virtualenv이름이 mysite-env, django프로젝트가 /srv/mysite/django_app, 프로젝트명이 mysite일 경우

```
uwsgi --http :8080 --home ~/.pyenv/versions/mysite-env --chdir /srv/mysite/django_app -w mysite.wsgi
```

실행 후 <ec2도메인>:8080으로 접속하여 요청을 잘 받는지 확인





## nginx 설정하기 (백그라운드 설정)

### uwsgi.service 파일 작성하기
작성 경로 : deploy\_ec2 > .config_secret > uwsgi > uwsgi.service  

```
[Unit]
Description=uWSGI service
After=syslog.target

[Service]
ExecStart=/home/ubuntu/.pyenv/versions/deploy_ec2/bin/uwsgi --ini /srv/deploy_ec2/.config_secret/uwsgi/deploy.ini

Restart=always
KillSignal=SIGQUIT
Type=notify
StandardError=syslog
NotifyAccess=all

[Install]
WantedBy=multi-user.target
```

### deploy.ini 파일 작성하기
작성 경로 : deploy\_ec2 > .config_secret > uwsgi > deploy.ini  

```
[uwsgi]
home = /home/ubuntu/.pyenv/versions/deploy_ec2
chdir = /srv/deploy_ec2/django_app
module = config.wsgi.deploy

uid = deploy
gid = deploy

socket = /tmp/ec2.sock
chmod-socket = 666
shown-socket = deploy:deploy

enable-threads = true
master = true

vacuum = true
logger = file:/tmp/uwsgi.log
```

### debug.ini 파일 추가 (안해도 되긴함) - 이건 로컬용
작성 경로 : deploy\_ec2 > .config_secret > uwsgi > debug.ini  

```
[uwsgi]
home = /usr/local/var/pyenv/versions/deploy_ec2
chdir = /Users/gaius/project/django/deploy_ec2/django_app
module = config.wsgi.debug
http = :8000
```

---

### nginx 설치

```
sudo apt-get install software-properties-common python-software-properties
sudo add-apt-repository ppa:nginx/stable
sudo apt-get update
sudo apt-get install nginx
nginx -v
```

### nginx.conf 파일 만들기

nginx 설치 직후 ```cat /etc/nginx/nginx.conf``` 의 내용을 복사해서 다음 경로에 복붙

**삭제된 코멘트와 살린부분, 수정된 부분이 어떤 점들인지 유의할 것!**

[수정사항] 
> user 유저이름  
> server_names_hash_bucket_size 250 (주석 해제)
> 



작성 경로 : deploy\_ec2 > .config_secret > nginx > nginx.conf  

```
user deploy;
worker_processes auto;
pid /run/nginx.pid;
include /etc/nginx/modules-enabled/*.conf;

events {
    worker_connections 768;
}

http {

    sendfile on;
    tcp_nopush on;
    tcp_nodelay on;
    keepalive_timeout 65;
    types_hash_max_size 2048;

    server_names_hash_bucket_size 250;

    include /etc/nginx/mime.types;
    default_type application/octet-stream;

    ssl_protocols TLSv1 TLSv1.1 TLSv1.2; # Dropping SSLv3, ref: POODLE
    ssl_prefer_server_ciphers on;

    access_log /var/log/nginx/access.log;
    error_log /var/log/nginx/error.log;


    gzip on;
    gzip_disable "msie6";

    include /etc/nginx/conf.d/*.conf;
    include /etc/nginx/sites-enabled/*;
}

```
### ec2.conf 파일 만들기
작성 경로 : deploy\_ec2 > .config_secret > nginx > ec2.conf  

**여기서는 location의 uwsgi_pass		unix:(소켓경로) 이 부분을 변경**(소켓의 경로는  deploy\_ec2 > .config_secret > uwsgi > deploy.ini에서 작성된 소켓경로를 따와서 붙인다. 앞에 //를 붙인다.(총 /가 3개)

```
server {
    listen 80;
    server_name *.compute.amazonaws.com;
    charset utf-8;
    client_max_body_size 128M;


    location / {
        uwsgi_pass    unix:///tmp/ec2.sock;
        include       uwsgi_params;
    }
}
```


### 서버에 실제 파일 복사해서 이동시키고, 링크만들어서 실제로 백그라운드 실행이 되도록 하기

```
# server's terminal

nginx설정파일을 서버 구동을 위해서 이동
sudo cp -f /srv/deploy_ec2/.config_secret/nginx/nginx.conf /etc/nginx/nginx.conf

nginx설정 파일 두번째 것을 서버 구동을 위해서 이동
sudo cp -f /srv/deploy_ec2/.config_secret/nginx/ec2.conf /etc/nginx/sites-available

uwsgi서비스 파일을 서버 구동을 위해서 이동
sudo cp -f /srv/deploy_ec2/.config_secret/uwsgi/uwsgi.service /etc/systemd/system/uwsgi.service

sites-available폴더에 있는 설정파일을 링크걸어서 enable폴더에 삽입
sudo ln -s /etc/nginx/sites-available/ec2.conf /etc/nginx/sites-enabled/ec2.conf

sites-enabled폴더에 원래 있던 default파일 삭제
sudo rm /etc/nginx/sites-enabled/default

```

### uwsgi, nginx 재시작
```
sudo systemctl restart uwsgi nginx
```

### 오류발생 시
```
(오류 발생한 서비스에 따라 아래 명령어 실행)
sudo systemctl status uwsgi.service
sudo systemctl status nginx.service
``` 

#### 로그 확인
```
sudo cat /tmp/uwsgi.log
sudo cat /var/log/nginx/error.log
```



# DOCKER
https://subicura.com/2017/01/19/docker-guide-for-beginners-1.html

레이어 저장방식  : 공간이 엄청 효율적이다.
독허브

## docker 설치
구글링에서 docker for mac 검색 > 다운로드 후 설치



## docker ubuntu 초기 설정
###
```
```
도커파일이 있는 곳에서
```
docker build -t updated_ubuntu .
```





















