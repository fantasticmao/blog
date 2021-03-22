---
title: "MySQL InnoDB 和 ACID 模型"
date: 2020-06-19T17:26:26+08:00
categories: ["数据库"]
tags: ["MySQL", "InnoDB"]
keywords: ["MySQL", "InnoDB", "ACID"]
---

本篇文章记录自己在阅读 MySQL Reference Manual 时候，关于 InnoDB 和 ACID 模型的一些笔记。<!--more-->

---

## ACID 模型

ACID 模型是指一系列数据库设计原则，它强调了可靠性对于业务数据和关键任务的重要性。MySQL 内置的 InnoDB 存储引擎严格遵守了 ACID 模型，不会因为诸如软件崩溃或者硬件故障之类的异常情况，而导致数据丢失或者毁坏的问题。当用户使用符合 ACID 模型的功能时候，就不必再写一套一致性检查和崩溃恢复机制的轮子了。除此之外，当用户有额外的软件保障措施或者使用了超高可靠性的硬件的时候，或者业务容许少量的数据丢失和不一致的时候，用户可以调整 MySQL 的设置，通过牺牲一些 ACID 的可靠性来换取系统更高的性能或者吞吐量。

下面讨论 MySQL 的功能特性（特指 InnoDB 存储引擎中）在 ACID 模型上的一些实践。

ACID 模型的 **原子性** 主要涉及了 InnoDB 事务。相关的 MySQL 特性如下：

- [自动提交](#自动提交)；
- [`COMMIT`](https://dev.mysql.com/doc/refman/8.0/en/commit.html) 语句；
- [`ROLLBACK`](https://dev.mysql.com/doc/refman/8.0/en/commit.html) 语句；
- `information_schema` 数据库中的操作数据。

ACID 模型的 **一致性** 主要涉及了 InnoDB 内部用于防止数据崩溃的处理措施。相关的 MySQL 特性如下：

- InnoDB [双写缓冲区](#双写缓冲区)；
- InnoDB [崩溃恢复](#崩溃恢复)。

ACID 模型的 **隔离性** 主要涉及了 InnoDB 事务，特别是应用于每个事务的隔离级别。相关的 MySQL 特性如下：

- [自动提交](#自动提交)；
- [`SET ISOLATION LEVEL`](https://dev.mysql.com/doc/refman/8.0/en/set-transaction.html) 语句；
- InnoDB 锁的底层细节。

ACID 模型的 **持久性** 涉及了 MySQL 在运行于特定硬件情况下的具体配置。因为用户可能会使用各式各样的不同性能的 CPU、网络设备和存储设备，所以这方面是最为复杂和难以提供指导建议的。相关的 MySQL 特性如下：

- InnoDB [双写缓冲区](#双写缓冲区)，通过配置项 _innodb_doublewrite_ 来开启和关闭；
- 配置项 _innodb_flush_log_at_trx_commit_；
- 配置项 _sync_binlog_；
- 配置项 _innodb_file_per_table_；
- 存储设备中的写入缓冲；
- 存储设备中的备份电池；
- 运行 MySQL 的操作系统，特别是对于 `fsync()` 系统调用的支持情况；
- 运行 MySQL 服务的机器和存储 MySQL 数据的设备的供电情况；
- 用户的备份策略，例如备份的频率和类型、备份数据的有效期；
- 对于分布式或者托管数据的应用，MySQL 服务所在位置的数据中心的特征情况，以及数据中心之间的网络连接情况。

---

## 相关术语

### ACID

ACID 是代表了原子性（Atomicity）、一致性（Consistency）、隔离性（Isolation）、持久性（Durability）的首字母缩写。这些特性是一个数据库系统所需要的，并且也与 **事务** 的概念息息相关。InnoDB 事务遵循了 ACID 原则。

事务是一组可以 **提交（committed）** 或者 **回滚（rolled back）** 的原子工作单元。当一个事务对数据库进行多次更改的时候，所有更改要么在事务提交之后成功，要么在事务回滚之后撤销。

在事务提交之前或者回滚之后，或者在事务进行中时，数据库始终都会保持一致的状态。如果在事务中跨越多表更新数据，那么事务在执行的时候，会查询到这些数据的所有新值或者所有旧值，不会存在新旧值混合的情况。

事务在执行的时候是被互相保护（隔离），它们不能互相干扰，也不能看到彼此还未提交的数据。这种隔离机制是通过 **锁** 来实现的。有经验的用户可以在确保事务不会互相干扰的前提下，调整事务的 **隔离级别**，通过牺牲少量事务的保护性来提高系统的并发性。

事务的执行结果是可持久化的：一旦事务提交操作执行成功，那么事务所产生的数据更改就是安全的，不会因为电源故障、系统崩溃、竞态条件或者其它非数据库应用容易遭受的潜在危险而丢失。持久性通常涉及写入数据至磁盘，并且会有一定数量的冗余措施，以防止写入操作期间电源故障或者系统崩溃的问题。

### 自动提交

自动提交（autocommit）是 MySQL 会在每个 SQL 执行之后触发提交操作的设置选项。不建议在对 InnoDB 表执行多个 SQL 语句的事务中开启自动提交。自动提交有助于提高对 InnoDB 表的只读事务的性能，从而最大程度地减少锁的使用和撤销日志（undo log）数据的产生。对于不支持事务的 MyISAM 表，开启自动提交也是可以正常工作的。

### 双写缓冲区

InnoDB 会使用的一种叫做双写（doublewrite）的刷新文件缓冲区的技术。在写入 page 数据至 data files 之前，InnoDB 会首先将数据写入至一个叫做双写缓冲区（doublewrite buffer）的区域。只有在写入和刷新数据至双写缓冲区完成之后，InnoDB 才会将 page 数据写入至 data files 中。如果操作系统、存储子系统或者 MySQL 服务进程在写入 page 数据期间崩溃了，InnoDB 稍后可以在 [崩溃恢复](#崩溃恢复) 期间从双写缓冲区中查找到完整的 page 数据副本。

虽然数据会被写入两次，但并不需要两倍的 IO 开销或者两次 IO 操作。数据会通过一次 `fsync()` 系统调用，以一个较大的顺序块写入缓冲区。

可以通过指定 `innodb_doublewrite=0` 来关闭双写缓冲区功能。

### 崩溃恢复

崩溃恢复（crash recovery）是在 MySQL 崩溃之后重启时执行的清理活动。对于 InnoDB 表，未完成的事务中更改的数据是通过重做日志（redo log）来恢复的。在 MySQL 崩溃之前，已提交的事务中更改的，但还未写入 data files 的数据，是通过 [双写缓冲区](#双写缓冲区) 来恢复的。当 MySQL 正常关闭时，这类活动是在停机期间通过清除操作执行的。

在 MySQL 正常运行期间，已提交的事务中更改的数据在写入 data files 之前，可以在更改缓冲区（change buffer）中暂存一段时间。在保持数据的最新状态（将会导致运行时引入更多的性能开销）和缓存数据以做备份（将会导致停机和重启时花费更多的时间）之间，存在着一个微妙的平衡。

---

## 参考资料

- [InnoDB and the ACID Model](https://dev.mysql.com/doc/refman/8.0/en/mysql-acid.html)
- [MySQL Glossary#ACID](https://dev.mysql.com/doc/refman/8.0/en/glossary.html#glos_acid)
- [MySQL Glossary#autocommit](https://dev.mysql.com/doc/refman/8.0/en/glossary.html#glos_autocommit)
- [MySQL Glossary#doublewrite buffer](https://dev.mysql.com/doc/refman/8.0/en/glossary.html#glos_doublewrite_buffer)
- [MySQL Glossary#crash recovery](https://dev.mysql.com/doc/refman/8.0/en/glossary.html#glos_crash_recovery)
