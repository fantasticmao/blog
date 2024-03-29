---
title: "<Unix 环境高级编程> 谈及的几种 IO 模型"
date: 2020-11-18T11:14:00+08:00
categories: ["编程"]
tags: ["Linux", "IO"]
---

## 前言

本篇文章记录自己在阅读 [《Unix 环境高级编程》](https://book.douban.com/subject/25900403/) 时候，关于书中谈及的几种 IO 模型的一些笔记。<!--more-->

## 阻塞 IO

Unix 系统中的文件 IO 函数 `open`、`read`、`write`，以及标准 IO 库中的函数 `getc` / `putc`、`fgets` / `fputs`、`fread` / `fwrite` 都属于阻塞 IO，这些函数可能会使进程永远阻塞，例如在以下场景时：

- 如果某些文件类型（例如读管道、终端设备、网络代理）的数据并不存在，读操作可能会使调用者永远阻塞；
- 如果数据不能被相同的文件类型立即接收（例如管道中没有空间、网络流量控制），写操作可能会使调用者永远阻塞。

通常会基于「多线程」的方式来避免在单线程中发生阻塞，不过这种方式将会需要处理线程之间的同步工作。

## 非阻塞 IO

非阻塞 IO 可以使 `open`、`read`、`write` 这类 IO 操作不会永远阻塞，在这类操作无法完成的时候，它会立即给调用者返回一个错误，表示该操作如果继续执行的话将会导致阻塞。

对于一个给定的描述符，有两种方式可以将其指定为非阻塞 IO：

1. 对于尚未打开的描述符，可以在调用 `open` 函数时指定 `O_NOBLOCK` 标志；
2. 对于已经打开的描述符，可以通过调用 `fcntl` 函数来添加 `O_NOBLOCK` 标志。

通常会基于「轮询」的方式来使用非阻塞 IO 进行读写，不过这种方式将会消耗额外的 CPU 资源。

## IO 多路复用

以 telnet 命令为例来讲述多路复用机制的适用场景。首先介绍 telnet 命令的工作机制：

1. 本地机器上的 telnet 命令从终端（标准输入）中读取用户的输入，将所读的数据写入到网络连接，然后发送给远程的 telnetd 守护进程；
2. 远程机器上的 telnetd 守护进程会将用户的输入发送给 shell，并且会将 shell 的输出写回到网络连接，然后发送给本地的 telnet 命令；
3. 本地机器上的 telnet 命令从网络连接中读取 shell 的输出，将所读的数据写回到终端（标准输出）。

![image](/images/read-io-models-in-apue/telnet.svg)

从 telnet 命令的工作机制可以得知，telnet 命令在工作时会有两个输入和两个输出。在实现 telnet 命令时，对于 IO 模型的选择应该考虑以下几点：

- 如果 telnet 命令是运行在单线程中的，那么不能在任意一个输入中使用阻塞 IO，因为这将会导致另一个输入发生阻塞；
- 如果 telnet 命令是运行在多线程中的，那么可以使两个输入分别运行在两个线程中，但是这样会需要处理线程之间的同步工作；
- 可以使用非阻塞 IO 来轮询读取两个输入的数据，但是这样会消耗额外的 CPU 资源；

对于 telnet 命令的工作机制，一种比较好的实现方式是使用 IO 多路复用。在使用 IO 多路复用的时候，开发者需要先构建一个感兴趣的描述符（通常不止一个）列表，然后调用一个函数，该函数会在列表中某个描述符已经准备好进行 IO 操作时才会返回。用于执行 IO 多路复用的函数有 `poll`、`pselect`、`select`，当从这些函数返回时，进程会被告知哪些描述符已经准备好可以进行 IO 操作。

## 异步 IO

信号机制提供了一种以异步形式通知某种事件已经发生的方法。由 BSD 和 System V 派生的所有系统都提供了某种形式的异步 IO，支持使用一个信号（在 System V 中是 SIGPOLL，在 BSD 中是 SIGIO）通知进程，对某个描述符所关心的某个事件已经发生。

但是，这些形式的异步 IO 是受限制的：它们不能用在所有的文件类型上，而且只能使用一个信号。因此如果要对一个以上的描述符进行异步 IO 时，那么进程在接收到该信号时不会知道该信号对应了哪一个描述符。

## 参考资料

- [《UNIX 环境高级编程》](https://book.douban.com/subject/25900403/)
  - 阻塞 IO：第 3 章、第 5 章
  - 非阻塞 IO：第 14.2 章
  - IO 多路复用：第 14.4 章
  - 异步 IO：第 14.5 章
