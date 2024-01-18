---
title: "Java RocketMQ 源码分析"
date: 2020-12-11T14:53:11+08:00
categories: ["编程"]
tags: ["Java"]
draft: true
---

本篇文章对业界知名的消息队列 Apache RocketMQ 进行源码分析，将会从 RocketMQ 工作机制角度分析它在 [创建 Topic](#创建-topic)、[发送消息](#发送消息)、[消费消息](#消费消息)、[存储消息](#存储消息) 和 [检索消息](#检索消息) 阶段的设计思路和代码实现。在本篇文章中，将不会对 RocketMQ 的基本概念和架构设计多做介绍，关于这方面的详细内容可以参考 [RocketMQ 官方文档](https://github.com/apache/rocketmq/blob/39bb9386f10d5d8dfe81183c172a3a86f6d313bd/docs/cn/README.md)。<!--more-->

## 创建 Topic

在 RocketMQ 中有两种机制可以创建 Topic：自动创建和手动创建。

若 Broker 已经开启 `autoCreateTopicEnable` 参数，则 RocketMQ 可以在 Broker 处理消息阶段，自动创建不存在的 Topic。其中待创建的 Topic 的读写队列数和权限的配置与另一个名为 `TBW102` 的特殊 Topic 一致。

{{< emgithub url="https://github.com/apache/rocketmq/blob/39bb9386f10d5d8dfe81183c172a3a86f6d313bd/broker/src/main/java/org/apache/rocketmq/broker/topic/TopicConfigManager.java#L156-L228" >}}

若 Broker 没有开启 `autoCreateTopicEnable` 参数，则需要在 Producer 发送消息之前，通过 RocketMQ 控制台或者 [mqadmin updateTopic](https://github.com/apache/rocketmq/blob/39bb9386f10d5d8dfe81183c172a3a86f6d313bd/tools/src/main/java/org/apache/rocketmq/tools/command/topic/UpdateTopicSubCommand.java#L33) 命令来手动创建 Topic。

## 发送消息

### 发送方式

sync、async、oneway

发送重试

### 顺序消息

通过选择同一个 Message Queue

### 负载均衡

在 Producer 发送消息阶段时，使用轮询算法进行负载均衡，将消息数据分片至可用的 Broker。

{{< emgithub url="https://github.com/apache/rocketmq/blob/39bb9386f10d5d8dfe81183c172a3a86f6d313bd/client/src/main/java/org/apache/rocketmq/client/impl/producer/TopicPublishInfo.java#L69-L85" >}}

## 消费消息

### 获取方式

Pull、Push

### 消费模式

集群消费、广播消费

{{< emgithub url="https://github.com/apache/rocketmq/blob/39bb9386f10d5d8dfe81183c172a3a86f6d313bd/client/src/main/java/org/apache/rocketmq/client/impl/consumer/DefaultMQPushConsumerImpl.java#L597-L607" >}}

### 负载均衡

消费者端的负载均衡实现类是 RebalanceImpl 类。

{{< emgithub url="https://github.com/apache/rocketmq/blob/39bb9386f10d5d8dfe81183c172a3a86f6d313bd/client/src/main/java/org/apache/rocketmq/client/impl/consumer/RebalanceImpl.java#L257-L307" >}}

### 消费重试

Broker 接收到 Consumer 发回的消费失败的消息：

{{< emgithub url="https://github.com/apache/rocketmq/blob/39bb9386f10d5d8dfe81183c172a3a86f6d313bd/broker/src/main/java/org/apache/rocketmq/broker/processor/SendMessageProcessor.java#L85-L90" >}}

获取重试队列 Topic 名称：

{{< emgithub url="https://github.com/apache/rocketmq/blob/39bb9386f10d5d8dfe81183c172a3a86f6d313bd/broker/src/main/java/org/apache/rocketmq/broker/processor/SendMessageProcessor.java#L142" >}}

将真实的 Topic 放置到消息的扩展属性中：

{{< emgithub url="https://github.com/apache/rocketmq/blob/39bb9386f10d5d8dfe81183c172a3a86f6d313bd/broker/src/main/java/org/apache/rocketmq/broker/processor/SendMessageProcessor.java#L171-L174" >}}

消费重试次数大于最大次数时，将消息放置到死信队列（DLQ，Dead Letter Queue）中：

{{< emgithub url="https://github.com/apache/rocketmq/blob/39bb9386f10d5d8dfe81183c172a3a86f6d313bd/broker/src/main/java/org/apache/rocketmq/broker/processor/SendMessageProcessor.java#L184-L197" >}}

将消息的重试次数加一：

{{< emgithub url="https://github.com/apache/rocketmq/blob/39bb9386f10d5d8dfe81183c172a3a86f6d313bd/broker/src/main/java/org/apache/rocketmq/broker/processor/SendMessageProcessor.java#L217" >}}

存储待消费重试的消息：

{{< emgithub url="https://github.com/apache/rocketmq/blob/39bb9386f10d5d8dfe81183c172a3a86f6d313bd/broker/src/main/java/org/apache/rocketmq/broker/processor/SendMessageProcessor.java#L221" >}}

## 存储消息

commitlog

## 检索消息

### 通过 Topic + Message ID

Message ID 中含有了该消息存储于 Broker 的地址（IP + Port）和该消息位于 CommitLog 的偏移量。解析 Message ID 的代码如下：

{{< emgithub url="https://github.com/apache/rocketmq/blob/39bb9386f10d5d8dfe81183c172a3a86f6d313bd/common/src/main/java/org/apache/rocketmq/common/message/MessageDecoder.java#L84-L101" >}}

### 通过 Topic + Message Key

基于 IndexFile 实现

同步双写

MessageQueue 对于消费者来说就是 ConsumerQueue，是为了提高消费者性能的 CommitLog 索引。
