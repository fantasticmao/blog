---
title: "GC 对性能的影响对比"
date: 2018-11-14T10:21:22+08:00
categories: ["编程"]
tags: ["Java", "JVM"]
---

本篇文章记录一个普通 Web 应用在访问量逐渐增加的情况下，不同类型 GC 对应用性能影响的趋势对比。<!--more-->在比较应用性能时，仅以响应时间（Latency）和吞吐量（Throughput）为应用的性能指标。

由于不同类型 GC 本该适用于不同类型的应用（例如 Serial GC 适合运行单核 CPU 机器上的小应用，G1 GC 适合运行大内存的应用），所以此次比较结果不能得出各个 GC 谁优谁劣的绝对结论。

---

## 以响应时间为性能指标

![image](/images/GC对性能的影响对比/latency-table.png)

![image](/images/GC对性能的影响对比/latency-img.png)

---

## 以吞吐量为性能指标

![image](/images/GC对性能的影响对比/throughput-table.png)

![image](/images/GC对性能的影响对比/throughput-img.png)

---

## 比较测试结果，总结得出

1. Serial GC 在不同强度的并发下，吞吐量和响应时间表现均为最差；
2. Parallel GC 号称是吞吐量优先 GC，但表现却并没有比 CMS GC 和 G1 GC 好很多；
3. 在并发强度逐渐增高的情况下，CMS GC 和 G1 GC 相比 Serial GC 和 Parallel GC 的响应时间表现更好；
4. 在并发强度不高的情况下，CMS GC 相比 G1 GC 的吞吐量表现要稍微好一些。
