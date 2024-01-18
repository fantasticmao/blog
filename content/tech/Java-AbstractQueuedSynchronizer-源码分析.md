---
title: "Java AbstractQueuedSynchronizer 源码分析"
date: 2020-11-10T15:19:28+08:00
categories: ["编程"]
tags: ["Java"]
draft: true
---

## 数据结构

AbstractQueuedSynchronizer 内部的数据结构比较很简单，由两个部分组成：

- 同步状态：用于记录同步器内的当前状态值，该状态字段可以被用于表示任何的含义。例如在 ReentrantLock 中表示已重入锁的个数，在 Semaphore 中表示可访问资源的个数。
- 等待队列：用于记录同步器内的等待线程队列，支持以独占和排它两种模式的等待机制。

```text
                          +-------+
                          | state |
                          +-------+
                              ^
              +---------------+---------------+
              |               |               |
         +---------+     +---------+     +---------+
NULL <-- | running | <-- | waiting | <-- | waiting |
         | thread0 | --> | thread1 | --> | thread2 | --> NULL
         +---------+     +---------+     +---------+
            head                            tail
```

{{< emgithub url="https://github.com/openjdk/jdk/blob/jdk8-b21/jdk/src/share/classes/java/util/concurrent/locks/AbstractQueuedSynchronizer.java#L516-L533" >}}

## 实现细节

## 使用案例

### ReentrantLock

### CountDownLatch

### Semaphore

### ThreadPoolExecutor.Worker

## 参考资料

- [从 ReentrantLock 的实现看 AQS 的原理及应用](https://tech.meituan.com/2019/12/05/aqs-theory-and-apply.html)
