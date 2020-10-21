---
title: "MySQL InnoDB 事务隔离级别实践"
date: 2020-09-10T15:58:10+08:00
categories: ["数据库"]
tags: ["MySQL", "InnoDB"]
keywords:
  - "MySQL"
  - "InnoDB"
  - "Isolation Levels"
  - "隔离级别"
---

本篇文章首先简单介绍 InnoDB 中聚簇索引和二级索引的概念和对应的数据结构，然后介绍在 MySQL 中查看事务信息和事务中加锁信息的方式，最后通过具体案例来实践 InnoDB 事务中各种隔离级别的特性。<!--more-->

---

## 聚簇索引和二级索引

---

## 事务和加锁信息

依据 MySQL Reference Manual 中的描述，在 MySQL 中可以通过 information_schema.innodb_trx 表、performance_schema.data_locks 表以及 performance_schema.data_lock_waits 表来查看事务信息和事务中加锁信息。Reference Manual 原文请见 [InnoDB INFORMATION_SCHEMA Transaction and Locking Information](https://dev.mysql.com/doc/refman/8.0/en/innodb-information-schema-transactions.html)。

information_schema 数据库的 innodb_trx 表存储了 InnoDB 内部当前正在执行的每个事务的信息，包括事务的执行状态（具体的枚举值有 RUNNING、LOCK WAIT、ROLLING BACK 和 COMMITTING）、事务的开始时间和正在执行的 SQL 语句等等。例如在下图的示例中，事务当前的执行状态 `trx_state` 是 RUNNING，事务的开始时间是 `trx_started` 是 2020-09-10 10:58:46，事务当前正在执行的 SQL 语句 `trx_query` 是 SELECT * FROM information_schema.innodb_trx，事务当前的隔离级别 `trx_isolation_level` 是 REPEATABLE READ。

![image](/images/MySQLInnoDB事务隔离级别实践/information_schema-innodb_trx.png)

performance_schema 数据库的 `data_locks` 表存储了每个事务中的加锁相关信息，包括锁的类型、加锁的模式、加锁的请求状态、与锁关联的数据等等。例如在下图的示例中，ID 为 271694 的事务在 test 数据库的 t 表上持有一个意向排它锁（ID 为 140668958211400:1965:140669201488992）和一个在主键索引上的记录锁（ID 为 140668958211400:867:4:2:140669205596704），ID 为 271695 的事务在 test 数据库的 t 表上持有一个意向排它锁（ID 为 140668958212240:1965:140669201491008），并在正在阻塞等待在主键索引上的记录锁（ID 为 140668958212240:867:4:2:140669205601312）。

![image](/images/MySQLInnoDB事务隔离级别实践/performance_schema-data_locks.png)

performance_schema 数据库的 `data_lock_waits` 表存储了被阻塞的事务之间的等待锁相关信息，包括请求获取锁的 ID、请求获取锁的事务 ID、阻塞等待锁的 ID、阻塞等待锁的事务 ID 等等。例如在下图的示例中，ID 为 271695 的事务请求获取 ID 为 140668958212240:867:4:2:140669205601312 的锁，并且被 ID 为 271694 事务中的 ID 为 140668958211400:867:4:2:140669205596704 的锁所阻塞。

![image](/images/MySQLInnoDB事务隔离级别实践/performance_schema-data_lock_waits.png)

---

## 隔离级别实践

### READ UNCOMMITTED

### READ COMMITTED

### REPEATABLE READ

### SERIALIZABLE

---

## 参考资料

- [Clustered and Secondary Indexes](https://dev.mysql.com/doc/refman/8.0/en/innodb-index-types.html)
- [InnoDB INFORMATION_SCHEMA Transaction and Locking Information](https://dev.mysql.com/doc/refman/8.0/en/innodb-information-schema-transactions.html)
