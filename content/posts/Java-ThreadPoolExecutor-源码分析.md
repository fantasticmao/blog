---
title: "Java ThreadPoolExecutor 源码分析"
date: 2020-10-01T18:41:53+08:00
categories: ["编程"]
tags: ["Java"]
keywords: ["Java", "ThreadPoolExecutor", "线程池"]
---

本篇文章整理和分享 JDK8 线程池框架中的 ThreadPoolExecutor 源码分析，将会从 ThreadPoolExecutor 工作机制角度分析它在 [状态管理](#状态管理)、[提交任务](#提交任务)、[执行任务](#执行任务)、[拒绝任务](#拒绝任务) 和 [回收线程](#回收线程) 阶段时的设计思路和代码实现。线程池框架的介绍和使用不在本篇文章涵盖的范围之内。<!-- more -->

ThreadPoolExecutor 的工作机制可以参考我摘记的 [《Java 并发编程实战》笔记 - 线程池的使用 - 配置 ThreadPoolExecutor](https://www.yuque.com/fantasticmao/tech/qmk0b2) 篇章，文末有张图可以概览任务在提交至 ThreadPoolExecutor 时的大致流程：

```text
         +------------------------------------------------------------------------+
runnbale |                                              +-----------------------+ |
-------->|                                 True         | +------+ +------+     | |
         |--> workerCount < corePoolSize? ------------->| |Worker| |Worker| ... | |
runnbale |                 |               new Worker() | +------+ +------+     | |
-------->|           False |                            +-----------------------+ |
         |                 |                               |   |   |         ^    |
runnbale |                 |                            workQueue.take       |    |
-------->|                 |                               |   |   |         |    |
         |                 |                               v   v   v         |    |
         |                 |                 +---------------------------+   |    |
         |                 v         True    | +--------+ +--------+     |   |    |
         |         workQueue.offer? -------->| |Runnable| |Runnable| ... |   |    |
         |                 |                 | +--------+ +--------+     |   |    |
         |           False |                 +---------------------------+   |    |
         |                 |                      BlockingQueue<Runnable>    |    |
         |                 |                                                 |    |
         |                 V                    True                         |    |
         |      workerCount < maximumPoolSize? ------------------------------+    |
         |                 |                    new Worker()                      |
         |           False |                                                      |
         |                 |                                                      |
         |                 v                                                      |
         |        +-------------+------------+--------------+                     |
         |        |             |            |              |                     |
         |        v             v            v              v                     |
         |  CallerRunsPolicy  AbortPolicy  DiscardPolicy  DiscardOldestPolicy     |
         +------------------------------------------------------------------------+
```

---

## 状态管理

ThreadPoolExecutor 内部共有两个状态：workerCount 和 runState。workerCount 表示线程池中的有效线程数，是已经被允许运行并且还未结束的线程数量。runState 表示线程池在生命周期内的运行状态，具体的枚举值有 RUNNING、SHUTDOWN、STOP、TIDYING、TERMINATED。

ThreadPoolExecutor 将 workerCount 和 runState 两个状态合并在同一个 `AtomicInteger` 类型的 `ctl` 字段中，并会通过一系列位运算来分别获取设置 workerCount 和 runState 的具体值。其中，runState 会占据 `ctl` 字段中 int 值的高 3 位，workerCount 会占据剩下的 29 位，因此 ThreadPoolExecutor 支持的最大线程数量是 `2^29 - 1` 个，而不是 `2^32 -1` 个。将 workerCount 和 runState 两个状态设计成同一个字段的好处是可以使用一次 CAS 操作同时修改两个状态，从而避免发生 [竞态条件](https://en.wikipedia.org/wiki/Race_condition)和占用锁资源。`ctl` 字段中具体的位分配如下所示：

```text
[000][0 0000 0000 0000 0000 0000 0000 0000]
  |                    |
  v                    v
runState          workerCount
```

`ctl` 字段中包含的 workerCount 初始值为 0，runState 初始值为 RUNNING。ThreadPoolExecutor 源码中定义 `ctl` 字段，以及通过位运算来获取 workerCount 和 runState 的代码片段如下：

{{< emgithub url="https://github.com/openjdk/jdk/blob/jdk8-b21/jdk/src/share/classes/java/util/concurrent/ThreadPoolExecutor.java#L373-L375" >}}

{{< emgithub url="https://github.com/openjdk/jdk/blob/jdk8-b21/jdk/src/share/classes/java/util/concurrent/ThreadPoolExecutor.java#L384-L387" >}}

### workerCount

workerCount 表示线程池中的有效线程数，会占据 `ctl` 字段中 int 值的低位，只需使用 `AtomicInteger` 的 CAS 操作即可线程安全地并发修改其值。ThreadPoolExecutor 源码中修改 workerCount 的代码片段如下：

{{< emgithub url="https://github.com/openjdk/jdk/blob/jdk8-b21/jdk/src/share/classes/java/util/concurrent/ThreadPoolExecutor.java#L406-L427" >}}

### runState

runState 表示线程池在生命周期内的运行状态，各个枚举值对应的状态描述以及状态之间的转换流程如下所示：

| 枚举值     | 数值 | 描述                                                                     |
| ---------- | ---- | ------------------------------------------------------------------------ |
| RUNNING    | 111  | 接收新的任务，处理队列中的任务                                           |
| SHUTDOWN   | 000  | 不再接收新的任务，但会处理队列中的任务                                   |
| STOP       | 001  | 不再接收新的任务，不会处理队列中的任务，会中断进行中的任务               |
| TIDYING    | 010  | 所有任务已经终止，workerCount 已经为零，准备调用 `terminated()` 钩子方法 |
| TERMINATED | 011  | 调用 `terminated()` 钩子方法已经完成                                     |

```text
RUNNING  SHUTDOWN  STOP  TIDYING  TERMINATED
   |------->| (调用 shutdown())
   |--------------->| (调用 shutdownNow())
            |------>| (调用 shutdownNow())
            |-------------->| (当池中和队列中的任务都为空)
                    |------>| (当池中的任务为空)
                            |-------->| (调用 terminated() 已经完成)
```

将 runState 设计成上述五个枚举值的原因在于 ThreadPoolExecutor 内部的工作机制。首先，ThreadPoolExecutor 包含了一个用于缓冲任务执行的 workQueue，所以在关闭线程池的时候也需要考虑到 workQueue 中的线程状态（是否需要中断线程）。此外，ThreadPoolExecutor 还提供了一些待实现的扩展方法：`beforeExecute`、`afterExecute`、`terminated`，因此这些方法的执行进度也需要被考虑在线程池的运行状态之内。ThreadPoolExecutor 源码中定义 runState 枚举值，以及判断当前运行状态的代码片段如下：

{{< emgithub url="https://github.com/openjdk/jdk/blob/jdk8-b21/jdk/src/share/classes/java/util/concurrent/ThreadPoolExecutor.java#L377-L382" >}}

{{< emgithub url="https://github.com/openjdk/jdk/blob/jdk8-b21/jdk/src/share/classes/java/util/concurrent/ThreadPoolExecutor.java#L389-L404" >}}

## 提交任务

## 执行任务

## 拒绝任务

## 回收线程

---

## 参考资料

- [java.util.concurrent.ThreadPoolExecutor](https://github.com/openjdk/jdk/blob/jdk8-b21/jdk/src/share/classes/java/util/concurrent/ThreadPoolExecutor.java)
- [Java 线程池实现原理及其在美团业务中的实践](https://tech.meituan.com/2020/04/02/java-pooling-pratice-in-meituan.html)
