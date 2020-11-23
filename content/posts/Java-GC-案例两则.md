---
title: "Java GC 案例两则"
date: 2020-11-20T16:40:00+08:00
categories: ["编程"]
tags: ["Java", "JVM"]
keywords: ["Java", "GC"]
---

本篇文章记录和分享自己近期遇到的两个 GC 相关问题，以及对其的排查手段和解决思路。<!--more-->

在谈及的两个案例中，应用均是使用 `-XX:+UseConcMarkSweepGC` 参数来指定了 GC 收集器，因此本文分析和排查问题的前提也是对于该场景而言的。

---

## 知识储备

### Heap 空间划分

JVM 中采用的分代收集算法有两个假设：绝大多数的对象都是朝生夕灭的，熬过多次 GC 的对象就越难以消亡。基于这种假设，在应用配置了 `-XX:+UseConcMarkSweepGC` 参数的场景下，JVM 会将 Heap 空间划分为 Young Generation（新生代）和 Old Generation（老年代），并且 Young Generation 空间会再被划分为 Eden、From Survivor 和 To Survivor，如下图所示：

![image](/images/JavaGC案例两则/java-heap.svg)

在默认情况下，Young Generation 空间与 Old Generation 空间的大小比例为 1:2，即 Young Generation 空间会占用整个 Heap 空间占用 1/3，Old Generation 会占用整个 Heap 空间占用 2/3，该比例可以通过 `-XX:NewRatio=${ratio}` 参数来调节，同时也可以通过 `-Xmn${size}` 参数来直接指定 Young Generation 空间的大小。Young Generation 空间内的 Eden 空间与 From Survivor 空间、To Survivor 空间的大小比例为 8:1:1，该比例可以通过 `-XX:SurvivorRatio=${ratio}` 参数来调节。

### 分代 GC 过程

基于分代收集算法的假设，JVM 会对 Young Generation 空间和 Old Generation 空间采用不同的 GC 策略，其中对于 Young Generation 空间的 GC 被称为 Minor GC，对于 Old Generation 空间的 GC 被成为 Major GC，对于整个 Heap 空间的 GC 被称为 Full GC。

在 JVM 的设计中，新对象会优先被分配在 Young Generation 空间内的 Eden 空间。在经历一次 Minor GC 之后还存活的对象会通过「标记-复制」算法，和 From Survivor 空间内的对象一起，被 JVM 复制到 To Survivor 空间，同时 JVM 会直接清空 From Survivor 空间，并将当前使用的 To Survivor 空间作为下次 Minor GC 时的 From Survivor 空间。在经历多次 Minor GC 之后还存活的对象便会从 Young Generation 空间晋升至 Old Generation 空间，该最大晋升阈值可以通过 `-XX:MaxTenuringThreshold=${threshold}` 参数来调节。

Old Generation 空间比 Young Generation 空间更大，并且对象填充的速度也更慢，因此 Old Generation 空间发生 Major GC 的频率也会更低。但是，在 Old Generation 空间所发生的 Major GC 会比在 Young Generation 空间所发生的 Minor GC 更加耗时。一次 Minor GC 耗时可能只需要几毫秒，然而一次 Major GC 耗时可能需要几十毫秒到几秒（取决于 Old Generation 的大小）。

在应用配置了 `-XX:+UseConcMarkSweepGC` 参数的场景下，JVM 会采用 ParNew 收集器来回收 Young Generation 空间内的对象，采用 CMS + Serial Old 收集器来回收 Old Generation 区域的对象。ParNew 收集器是一种多线程并行收集器，它在默认情况下开启的收集器线程数量与处理器的核心数量相同。在处理器核心非常多的环境中，可以通过参数 `-XX:ParallelGCThreads=${threads}` 参数来限制 ParNew 收集器开启的线程数量。CMS 收集器是一种以获取最短停顿时间为目标的增量式（Incremental）的收集器，GC 过程分为四个阶段：初始标记、并发标记、重新标记、并发清除，其中的初始标记和重新标记阶段需要 Stop The World（即停顿工作线程），并发标记和并发清除阶段则可以和工作线程一起运行。在 CMS 收集器运行期间，可能会由于无法处理「浮动垃圾（Floating Garbage）」而产生的「并发失败（Concurrent Mode Failure）」问题和基于「标记-清除」算法实现而带来的内存空间碎片化问题，导致 JVM 无法继续在 Old Generation 上分配新对象，从而 JVM 会采用 Serial Old 收集器来作为 CMS 收集器的备用选项，对整个 Heap 空间执行一次完全 Stop The World 的耗时很久的 Full GC。

---

## 案例一

### 故障表现

钉钉群里接收到大量接口超时的报警，同时在链路里也查到大量接口调用超时的记录。

通过监控查看到应用在线上实例中的 JVM Heap 空间耗尽，并且频繁地发生 Major GC 和 Full GC。

### 问题分析

查看应用监控后台

### 解决思路

---

## 案例二

期望应用接口耗时保证在 10ms 之内，

---

## 参考资料

- [Launches a Java application](https://docs.oracle.com/javase/8/docs/technotes/tools/unix/java.html)
- [从实际案例聊聊 Java 应用的 GC 优化](https://tech.meituan.com/2017/12/29/jvm-optimize.html)
- [Java 中 9 种常见的 CMS GC 问题分析与解决](https://tech.meituan.com/2020/11/12/java-9-cms-gc.html)
