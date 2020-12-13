---
title: "Java RocketMQ 源码分析"
date: 2020-12-11T14:53:11+08:00
categories: ["编程"]
tags: ["Java"]
keywords: ["Java", "RocketMQ", "消息队列"]
draft: true
---

本篇文章对业界知名的消息队列 Apache RocketMQ 进行源码分析，将会从 RocketMQ 工作机制角度分析它在 [创建 Topic](#创建-topic)、[发送消息](#发送消息)、[消费消息](#消费消息)、[存储消息](#存储消息) 和 [检索消息](#检索消息) 阶段的设计思路和代码实现。在本篇文章中，将不会对 RocketMQ 的基本概念和架构设计多做介绍，关于这方面的详细内容可以参考 [RocketMQ 官方文档](https://github.com/apache/rocketmq/blob/39bb9386f10d5d8dfe81183c172a3a86f6d313bd/docs/cn/README.md)。<!--more-->

---

## 创建 Topic

在 RocketMQ 中有两种机制可以创建 Topic：自动创建和手动创建。

若 Broker 已经开启 `autoCreateTopicEnable` 参数，则 RocketMQ 可以在 Broker 处理消息阶段，自动创建不存在的 Topic。其中待创建的 Topic 的读写队列数和权限的配置与另一个名为 `TBW102` 的特殊 Topic 一致。

{{< emgithub url="https://github.com/apache/rocketmq/blob/39bb9386f10d5d8dfe81183c172a3a86f6d313bd/broker/src/main/java/org/apache/rocketmq/broker/topic/TopicConfigManager.java#L156-L228" >}}

若 Broker 没有开启 `autoCreateTopicEnable` 参数，则需要在 Producer 发送消息之前，通过 RocketMQ 控制台或者 [mqadmin updateTopic](https://github.com/apache/rocketmq/blob/39bb9386f10d5d8dfe81183c172a3a86f6d313bd/tools/src/main/java/org/apache/rocketmq/tools/command/topic/UpdateTopicSubCommand.java#L33) 命令来手动创建 Topic。

## 发送消息

### 发送方式

sync、async、oneway

### 顺序消息

通过选择同一个 Message Queue

### 数据分片

在 Producer 发送消息阶段时，使用轮询算法进行负载均衡，将消息数据分片至可用的 Broker。

{{< emgithub url="https://github.com/apache/rocketmq/blob/39bb9386f10d5d8dfe81183c172a3a86f6d313bd/client/src/main/java/org/apache/rocketmq/client/impl/producer/TopicPublishInfo.java#L69-L85" >}}

## 消费消息

### 消费方式

Pull、Push

## 存储消息

## 检索消息

### 通过 Topic + 时间范围

### 通过 Topic + Message Key

### 通过 Topic + Message ID

---

同步双写

消息分片的逻辑

消费消息

Message Queue 和 commit log 的关系
