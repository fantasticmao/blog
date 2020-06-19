---
title: "Java synchronized 工作机制"
date: 2020-06-16T11:14:46+08:00
categories: ["编程"]
tags: ["Java"]
keywords: ["Java", "synchronized", "轻量级锁", "偏向锁", "JOL"]
draft: true
---

在 Java 中可以使用 synchronized 关键字来修饰静态方法、实例方法或者代码块，分别用于锁定 Class 对象、 this 对象和指定对象，从而保证一段方法或者代码块的同步执行。synchronized 不同于 `java.util.concurrent` 中的 Lock 接口，它仅是 Java 语法中的一个保留关键字，具体实现由 JVM 提供。

本篇文章以 OpenJDK Wiki 中的 [《Synchronization and Object Locking》](https://wiki.openjdk.java.net/display/HotSpot/Synchronization) 文章 ~~简单翻译~~ 展开，讲述 Java synchronized 工作原理，并使用 OpenJDK 工具 [Java Object Layout (JOL)](https://openjdk.java.net/projects/code-tools/jol/) 来观察和验证对象头中 markword 与 synchronized 锁升级策略关系。

---

## synchronized 和对象锁

- thin Locking 轻量级锁
- Biased Locking 偏向锁
- Fat Locking 重量级锁

## 对象锁的升级策略

- markword
- OpenJDK 源码

## 使用 OpenJDK JOL 观察对象锁的状态

- 字节序
- JOL

## 参考资料

- [Synchronization and Object Locking](https://wiki.openjdk.java.net/display/HotSpot/Synchronization)
- [不可不说的Java“锁”事](https://tech.meituan.com/2018/11/15/java-lock.html)
- [OpenJDK: JOL](https://openjdk.java.net/projects/code-tools/jol/)