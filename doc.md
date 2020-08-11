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
erizo_controller
```
