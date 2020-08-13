#### 文件夹结构
```angular2
build           程序编译出来的目录，依赖也安装在这里
cert            ssl需要使用的证书放在这里的
doc             官方的文档，对项目理解没多大用
erizo           c语言写的核心代码，音视频相关的代码
erizoApi        c语言写的，暴露erizo的接口出来(看上去需要编译成node.bin)
erizo_controller      (有点复杂，需要深入研究)
extras
    basic_example     demo
    docker            docker版本（里面只有一个.sh文件）
    vagrant           看上去像是一键安装什么的
feature-review  暂时不需要关注
scripts         一些自动安装相关的shell脚本
spine           看上去像是提供一些工具，和一些测试用的。（应该是工具）
test            测试目录
utils           里面只有一个release.sh    
```

重点关注：
```angular2
nuve            最上层架构
    nuveAPI         nuve提供的api（3000端口提供服务）
erizo_controller
```

nuveAPI分析 - 感觉架构很一般，代码质量感觉也很一般
```angular2
1. 通讯通过token进行加解密
2. 用mongo存储主要数据
3. 通过rpc调用，调用nuveController(走rabbitmq)
4. 所以nuveAPI需要提供服务的话，还需要通过initErizo_controller.sh来开启erizoController
```

ErizoController研究
```angular2
这玩意儿，又调用了rpc去调用erizoAgent
```

erizoAgent研究
```angular2
erizoAgent又会去调用
../erizoJS/erizoJS.js 启动js，看到这儿才发现，这个erizoJS是erizo的核心程序
```


