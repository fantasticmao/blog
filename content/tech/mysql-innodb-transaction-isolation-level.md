---
title: "MySQL InnoDB 事务隔离级别实践"
date: 2020-09-10T15:58:10+08:00
categories: ["数据库"]
tags: ["MySQL", "InnoDB"]
---

## 前言

本篇文章首先简单介绍在 MySQL 中查看事务信息和事务中加锁信息的方式，然后通过具体案例来实践 InnoDB 事务中各种隔离级别的特性。<!--more-->

<!--
本篇文章首先简单介绍 InnoDB 中聚簇索引和二级索引的概念和对应的数据结构，然后介绍在 MySQL 中查看事务信息和事务中加锁信息的方式，最后通过具体案例来实践 InnoDB 事务中各种隔离级别的特性。

## 聚簇索引和二级索引
-->

## 事务和加锁信息

依据 MySQL 官方参考手册中的描述，在 MySQL 中可以通过 information_schema.innodb_trx 表、performance_schema.data_locks 表以及 performance_schema.data_lock_waits 表来查看事务信息和事务中加锁信息。参考手册的原文请见 [InnoDB INFORMATION_SCHEMA Transaction and Locking Information](https://dev.mysql.com/doc/refman/8.0/en/innodb-information-schema-transactions.html)。

information_schema 数据库的 innodb_trx 表存储了 InnoDB 内部当前正在执行的每个事务的信息，包括事务的执行状态（具体的枚举值有 RUNNING、LOCK WAIT、ROLLING BACK 和 COMMITTING）、事务的开始时间和正在执行的 SQL 语句等等。

在下图的示例中，事务当前的执行状态 `trx_state` 是 RUNNING，事务的开始时间是 `trx_started` 是 2020-09-10 17:35:35，事务当前正在执行的 SQL 语句 `trx_query` 是 SELECT SLEEP(5)，事务当前的隔离级别 `trx_isolation_level` 是 REPEATABLE READ。

![image](/images/mysql-innodb-transaction-isolation-level/information_schema-innodb_trx.png)

performance_schema 数据库的 data_locks 表存储了每个事务中的加锁相关信息，其中的一些重要字段定义如下：

- `ENGINE_TRANSACTION_ID` 字段表示事务的 ID，与 innodb_trx 表中的 `trx_id` 字段对应；
- `ENGINE_LOCK_ID` 字段表示事务中持有或者等待的锁的 ID，在指定存储引擎的条件下，该字段的值是唯一的；
- `LOCK_TYPE` 字段表示加锁的类型，对于 InnoDB 来说，`LOCK_TYPE` 值为 RECORD 表示行级锁，值为 TABLE 表示表级锁；
- `LOCK_MODE` 字段表示加锁的模式，对于 InnoDB 来说，`LOCK_MODE` 可能的值为 S、X、IS、IX、AUTO_INC 和 UNKNOWN，并且除了 AUTO_INC 和 UNKNOWN 之外的其它模式在默认情况下均表示使用了间隙锁或者后键锁；
- `LOCK_STATUS` 字段表示加锁请求的状态，对于 InnoDB 来说，`LOCK_STATUS` 值为 GRANTED 表示事务当前正在持有锁，值为 WAITING 表示事务当前正在等待锁；
- `LOCK_DATA` 字段表示与锁关联的数据，对于 InnoDB 来说，该字段只有在加锁的类型为行级锁时才会有值，否则该字段的值显示为 NULL。当加锁是发生在主键索引上时，该字段的值为主键索引上被锁定的索引值。当加锁是发生在二级索引上时，该字段的值为二级索引上被锁定的索引值和该二级索引对应的主键索引上的索引值。如果表中没有定义主键索引的话，那么该字段会选择表中的唯一索引上的索引值或者 InnoDB 的内部行号来显示，具体的使用规则请参考 InnoDB 的聚簇索引和二级索引。

在下图的示例中，ID 为 271842 的事务在 t 表上持有一个 ID 为 140668958212240:1966:140669201491008 的意向排它锁和一个在主键索引上的 ID 为 140668958212240:868:4:2:140669205601312 的记录锁。

![image](/images/mysql-innodb-transaction-isolation-level/performance_schema-data_locks.png)

performance_schema 数据库的 data_lock_waits 表存储了被阻塞的事务之间的等待锁相关信息，其中的一些重要字段定义如下：

- `REQUESTING_ENGINE_LOCK_ID` 字段表示请求获取锁的 ID；
- `REQUESTING_ENGINE_TRANSACTION_ID` 字段表示求获取锁的事务的 ID；
- `BLOCKING_ENGINE_LOCK_ID` 字段表示阻塞等待锁的 ID；
- `BLOCKING_ENGINE_TRANSACTION_ID` 字段表示阻塞等待锁的事务的 ID。

在下图的示例中，ID 为 271844 的事务请求获取 ID 为 140668958213080:868:4:2:140669205682208 的锁，并且被 ID 为 271843 事务中的 ID 为 140668958212240:868:4:2:140669205601312 的锁所阻塞。

![image](/images/mysql-innodb-transaction-isolation-level/performance_schema-data_lock_waits.png)

## 隔离级别实践

InnoDB 提供了 SQL 1992 标准中全部的四种隔离级别：READ UNCOMMITTED（未提交读）、READ COMMITTED（提交读）、REPEATABLE READ（可重复读）和 SERIALIZABLE（可串行化），并且默认的隔离级别是 REPEATABLE READ。

MySQL 在内部通过不同的加锁策略来实现不同的隔离级别，不同的隔离级别对数据的一致性和查询结果的可重复性有着不同的表现，开发者可以通过设置不同的隔离级别来权衡事务的一致性与可用性。下面通过几个案例来实践和观察各种隔离级别的特性。

在以下所有案例中，演示表的结构和初始数据都如下图中所示，其中 id 字段为自增主键，a 字段具有唯一索引，b 字段具有普通索引，c 字段不具有索引：

![image](/images/mysql-innodb-transaction-isolation-level/init-table-and-data.png)

### READ UNCOMMITTED

在 READ UNCOMMITTED 隔离级别下，SELECT 语句会以非阻塞的方式运行，当前事务可能会读取到其它事务中尚未提交的数据。这种现象被称为 **脏读**。

在下图的示例中，左半图中的事务在执行第二个 SELECT 语句的时候，便可以读取到右半图中的事务所更改的尚未提交的数据。

![image](/images/mysql-innodb-transaction-isolation-level/read-uncommitted.png)

### READ COMMITTED

在 READ COMMITTED 隔离级别下，SELECT 语句会以一致性非锁定读取的方式运行，当前事务不会读取到其它事务中尚未提交的数据，但可以读取到其它事务中已经提交的数据，因此查询结果是不具有可重复性的。这种现象被称为 **不可重复读**。

在下图的示例中，左半图中的事务在执行第二个 SELECT 语句的时候，不会读取到右半图中的事务所更改的尚未提交的数据，但是当左半图中的事务在执行第三个 SELECT 语句的时候，便可以读取到右半图中的事务所更改的已经提交的数据。

![image](/images/mysql-innodb-transaction-isolation-level/read-committed.png)

在 READ COMMITTED 隔离级别下，还需要注意的是，对于锁定读取（带有 FOR UPDATE 或者 FOR SHARE 的 SELECT）、UPDATE、DELETE 语句，InnoDB 只会使用记录锁，而不会使用间隙锁或者后键锁，因此其它事务可以在被锁定的记录范围内随意地插入新的记录。这种问题被称为 **幻行（Phantom Rows）**。

在下图的示例中，左半图中的事务使用了 SELECT ... FOR UPDATE 语句来锁定读取 a ∈ (25, +∞) 范围内的记录，然而该事务在二级索引上加锁的模式 `LOCK_MODE` 却是 X 和 REC_NOT_GAP，这说明了该事务并没有使用间隙锁或者后键锁来锁定 a ∈ (25, +∞) 区间，因此此时右半图中的事务便可以在 a ∈ (25, +∞) 范围内任意地执行插入操作（但是不能执行修改或者删除操作，因为现有的数据已经被锁定了），并且不会被阻塞。

![image](/images/mysql-innodb-transaction-isolation-level/read-committed-phantom-rows-1.png)

![image](/images/mysql-innodb-transaction-isolation-level/read-committed-phantom-rows-2.png)

### REPEATABLE READ

在 REPEATABLE READ 隔离级别下，SELECT 语句会以一致性非锁定读取的方式运行，会读取事务在被建立时刻的快照数据，当前事务不会读取到其它事务中所更改的数据，其它事务也无法更改当前事务中所读取的数据，因此查询结果是具有可重复性的。但由于当前事务中所读取的仅是快照中的数据，与此同时，其它事务中所更改的数据也的确生效了，因此可能会产生所谓的 **幻读（Phantom Reads）** 问题。

在下图的示例中，左半图中的事务在执行第二个和第三个 SELECT 语句的时候，均不会读取到右半图中的事务所更改的数据，但是当左半图中的事务在执行 UPDATE 语句的时候，便会受到右半图中的事务所更改的数据带来的影响。

![image](/images/mysql-innodb-transaction-isolation-level/repeatable-read.png)

在 READ COMMITTED 隔离级别下，还需要注意的是，对于锁定读取（带有 FOR UPDATE 或者 FOR SHARE 的 SELECT）、UPDATE、DELETE 语句，InnoDB 使用锁的行为是根据查询语句的具体条件来决定的：

- 对于在唯一索引上查询唯一结果的查询条件，InnoDB 仅会使用记录锁来锁定该条记录；
- 对于其它情况下的查询条件，InnoDB 则会使用间隙锁或者后键锁来锁定该查询所扫描的记录。

在下图的示例中，左半图中的事务使用了 SELECT ... FOR UPDATE 语句来锁定读取 a ∈ (25, +∞) 范围内的记录，并且该事务在二级索引上加锁的模式 `LOCK_MODE` 是 X，这说明了该事务使用了间隙锁或者后键锁来锁定 a ∈ (25, +∞) 区间，因此此时右半图中的事务在 a ∈ (25, +∞) 范围内执行的插入操作会被阻塞。

![image](/images/mysql-innodb-transaction-isolation-level/repeatable-read-phantom-reads-1.png)

![image](/images/mysql-innodb-transaction-isolation-level/repeatable-read-phantom-reads-2.png)

### SERIALIZABLE

在 REPEATABLE READ 隔离级别下，SELECT 语句会以锁定读取的方式运行，InnoDB 会隐式地将所有普通的 SELECT 语句转换成 SELECT ... FOR SHARE 语句，当前事务中所读取的数据不会被其它事务所更改。

在下图的示例中，左半图中的事务在执行普通的 SELECT 语句的时候，会锁定查询所涉及的记录，并且右半图中的事务在更改该记录时会被阻塞。

![image](/images/mysql-innodb-transaction-isolation-level/serializable.png)

## 参考资料

- [Clustered and Secondary Indexes](https://dev.mysql.com/doc/refman/8.0/en/innodb-index-types.html)
- [InnoDB Locking](https://dev.mysql.com/doc/refman/8.0/en/innodb-locking.html)
- [Transaction Isolation Levels](https://dev.mysql.com/doc/refman/8.0/en/innodb-transaction-isolation-levels.html)
- [InnoDB INFORMATION_SCHEMA Transaction and Locking Information](https://dev.mysql.com/doc/refman/8.0/en/innodb-information-schema-transactions.html)
- [MySQL 事务隔离级别和锁](https://developer.ibm.com/zh/technologies/databases/articles/os-mysql-transaction-isolation-levels-and-locks/)
