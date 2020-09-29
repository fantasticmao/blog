---
title: "MySQL InnoDB 事务模型"
date: 2020-08-15T13:11:00+08:00
categories: ["数据库"]
tags: ["MySQL", "InnoDB"]
keywords:
  - "MySQL"
  - "InnoDB"
  - "Transaction Model"
  - "事务模型"
  - "Isolation Levels"
  - "隔离级别"
---

本篇文章记录自己在阅读 MySQL Reference Manual 时候，关于 InnoDB 事务模型的一些笔记。<!--more-->

InnoDB 事务模型中的目标是将 [多版本](https://dev.mysql.com/doc/refman/8.0/en/glossary.html#glos_mvcc) 数据库的最佳特性与传统的两阶段锁定相结合。InnoDB 会以 Oracle 的风格，在行级别上执行锁定，并且默认运行非锁定的 [一致性读取](https://dev.mysql.com/doc/refman/8.0/en/glossary.html#glos_consistent_read)。InnoDB 中的锁信息会以节省空间的方式存储，因此它不需要锁升级。通常，InnoDB 允许多个用户锁定表中的每一行或者是随机子集的多行，同时也不会导致 InnoDB 内存耗尽。

---

## 事务隔离级别

事务的隔离性是数据库处理数据的基础功能之一。隔离性（Isolation）是 [ACID](https://dev.mysql.com/doc/refman/8.0/en/glossary.html#glos_acid) 首字母中的 I。隔离级别是一个在当多个事务同时进行更改和执行查询时，用于微调性能和可靠性、一致性和结果的可重复性的设置项。

InnoDB 提供了 SQL 1992 标准中全部的四种隔离级别：READ UNCOMMITTED（未提交读）、READ COMMITTED（提交读）、REPEATABLE READ（可重复读）和 SERIALIZABLE（可串行化）。默认的隔离级别是 REPEATABLE READ。

用户可以使用 SET TRANSACTION 语句改变单个会话或者所有子连接中的隔离级别。可以在命令行或者选项文件中使用 \-\-transaction-isolation 选项，来设置 MySQL 服务中的所有连接默认的隔离级别。有关隔离级别和级别设置语法的详细信息，请见 [SET TRANSACTION Statement](https://dev.mysql.com/doc/refman/8.0/en/set-transaction.html)。

InnoDB 使用不同的锁定策略来支持此处描述的各个隔离级别。你可以使用默认的 REPEATABLE READ 级别保持高度的一致性，用于操作对 ACID 敏感的关键数据。或者，你可以在批量生成报表等场景下（精确一致性和结果可重复性的重要性小于最小化锁定的开销），使用 READ COMMITTED 或者是 READ UNCOMMITTED 级别来放宽对一致性的要求。SERIALIZABLE 强制执行比 REPEATABLE READ 更严格的规则，并且主要用于一些特殊情况，例如 [XA](https://dev.mysql.com/doc/refman/8.0/en/glossary.html#glos_xa) 事务和解决并发和 [死锁](https://dev.mysql.com/doc/refman/8.0/en/glossary.html#glos_deadlock) 问题的时候。

下面的列表描述了 MySQL 是如何支持不同的隔离级别。列表项以最常用的级别到最不常用的级别的方式排列。

- REPEATABLE READ

  这是 InnoDB 默认的隔离级别。在同一个事务中的 [一致性读取](https://dev.mysql.com/doc/refman/8.0/en/glossary.html#glos_consistent_read) 会读取首次读取时建立的 [快照](https://dev.mysql.com/doc/refman/8.0/en/glossary.html#glos_snapshot)。这意味着如果你在同一个事务中发出了几个普通（非锁定） SELECT 语句，这些 SELECT 语句彼此之间是一致的。更多内容请见 [Consistent Nonlocking Reads](https://dev.mysql.com/doc/refman/8.0/en/innodb-consistent-read.html)。

  对于 [锁定读取](https://dev.mysql.com/doc/refman/8.0/en/glossary.html#glos_locking_read)（带有 FOR UPDATE 或者 FOR SHARE 的 SELECT）、UPDATE 和 DELETE 语句，锁定的行为取决于语句是在唯一索引上使用了具有唯一性的查询条件，还是使用了范围性的查询条件。

  - 对于在唯一索引上使用了具有唯一性的查询条件，InnoDB 仅会锁定找到的索引记录，而不会锁定它之前的 [区间](https://dev.mysql.com/doc/refman/8.0/en/glossary.html#glos_gap)。
  - 对于其它查询条件，InnoDB 会锁定扫描的索引范围，使用 [间隙锁](https://dev.mysql.com/doc/refman/8.0/en/glossary.html#glos_gap_lock) 或者 [后键锁](https://dev.mysql.com/doc/refman/8.0/en/glossary.html#glos_next_key_lock) 来阻止其它会话在该范围所覆盖的区间内的插入操作。更多内容请见 [InnoDB Locking](https://dev.mysql.com/doc/refman/8.0/en/innodb-locking.html)。

- READ COMMITTED

  即使是在同一个事务中，每个一致性读取都会设置和读取它自己的新快照。更多关于一致性读取的内容请见 [Consistent Nonlocking Reads](https://dev.mysql.com/doc/refman/8.0/en/innodb-consistent-read.html)。

  对于锁定读取（带有 FOR UPDATE 或者 FOR SHARE 的 SELECT）、UPDATE 和 DELETE 语句，InnoDB 仅会锁定索引记录，而不是它们之前的区间，因此可以在锁定的记录旁边自由地插入新的记录。间隙锁只会被用于外键约束检查和重复键检查。

  由于间隙锁被禁用了，因此可能会产生幻行问题，因为其它会话可以在区间内插入新的行。更多关于幻行的内容请见 [Phantom Rows](https://dev.mysql.com/doc/refman/8.0/en/innodb-next-key-locking.html)。

  READ COMMITTED 隔离级别仅支持基于行的 binlog。如果将 READ COMMITTED 和 binlog_format=MIXED 一起使用，MySQL 服务就会自动记录基于行的日志。

  使用 READ COMMITTED 还有额外的影响：

  - 对于 UPDATE 或者 DELETE 语句，InnoDB 仅会锁定它所更新或者删除的行。在 MySQL 评估 WHERE 条件之后，不匹配的行上的记录锁将会被释放。这大大降低了发生死锁的可能性，虽然发生死锁仍然是可能的。
  - 对于 UPDATE 语句，如果行已经被锁定，InnoDB 会执行「半一致性读取」，它会将最新提交的版本返回给 MySQL，以便 MySQL 可以确定该行是否与 UPDATE 语句里的 WHERE 条件匹配。如果该行匹配成功（必须被更新），MySQL 会再次读取该行，并且在这一次中 InnoDB 会锁定该行或者等待锁定该行。

  考虑下面的例子，从表的定义开始：

  ```sql
  CREATE TABLE t (a INT NOT NULL, b INT) ENGINE = InnoDB;
  INSERT INTO t VALUES (1,2),(2,3),(3,2),(4,3),(5,2);
  COMMIT;
  ```

  在这种情况下，该表还没有索引，所以查询和索引扫描会使用隐藏的聚簇索引（更多内容请见 [Clustered and Secondary Indexes](https://dev.mysql.com/doc/refman/8.0/en/innodb-index-types.html)）而不是索引列来锁定记录。

  假设有一个会话，它使用了这些语句来执行 UPDATE：

  ```sql
  # Session A
  START TRANSACTION;
  UPDATE t SET b = 5 WHERE b = 3;
  ```

  同时假设有第二个会话，它在第一个会话之后使用了这些语句来执行 UPDATE：

  ```sql
  # Session B
  UPDATE t SET b = 4 WHERE b = 2;
  ```

  InnoDB 在执行每个 UPDATE 的时候，它会首先在各行上获取排它锁，然后再确定是否要对其进行修改。如果 InnoDB 不会修改该行，它将会释放锁。否则，InnoDB 会保留该锁直到事务结束。这会影响事务的处理，如下所示。

  当使用默认的 REPEATABLE READ 隔离级别时，第一个 UPDATE 会在它读取的每行上获取一个 X 锁，并且不会释放其中的任何一个：

  ```text
  x-lock(1,2); retain x-lock
  x-lock(2,3); update(2,3) to (2,5); retain x-lock
  x-lock(3,2); retain x-lock
  x-lock(4,3); update(4,3) to (4,5); retain x-lock
  x-lock(5,2); retain x-lock
  ```

  第二个 UPDATE 在尝试获取任何一个锁的时候会被阻塞（因为第一个 UPDATE 已经持有了所有行的锁），并且直到第一个 UPDATE 提交或者回滚之前不会继续执行：

  ```text
  x-lock(1,2); block and wait for first UPDATE to commit or roll back
  ```

  如果改用 READ COMMITTED 隔离级别时，第一个 UPDATE 会在它读取的每行上获取一个 X 锁，并且会释放它不会修改的行上的锁：

  ```text
  x-lock(1,2); unlock(1,2)
  x-lock(2,3); update(2,3) to (2,5); retain x-lock
  x-lock(3,2); unlock(3,2)
  x-lock(4,3); update(4,3) to (4,5); retain x-lock
  x-lock(5,2); unlock(5,2)
  ```

  然而，如果 WHERE 条件包括了索引列，并且 InnoDB 使用了索引，那么在设置和保留记录锁的时候，只有索引列才会被考虑。在下面的例子中，第一个 UDPATE 设置和保留了 b = 2 的行上的 X 锁。第二个 UPDATE 会在尝试获取相同记录上的 X 锁时被阻塞，因为它也使用了在 b 列上定义的索引。

  ```sql
  CREATE TABLE t (a INT NOT NULL, b INT, c INT, INDEX (b))  ENGINE = InnoDB;
  INSERT INTO t VALUES (1,2,3),(2,2,4);
  COMMIT;

  # Session A
  START TRANSACTION;
  UPDATE t SET b = 3 WHERE b = 2 AND c = 3;

  # Session B
  UPDATE t SET b = 4 WHERE b = 2 AND c = 4;
  ```

  READ COMMITTED 隔离级别可以在 MySQL 启动时设置，或者在运行时更改。在运行时，可以为所有会话全局设置，也可以为每个会话单独设置。

- READ UNCOMMITTED

  SELECT 语句会以非阻塞的方式执行，但可能会使用早期版本的行。因此，使用这个隔离级别的时候，读取操作是非一致性的。这种现象也被称为 [脏读](https://dev.mysql.com/doc/refman/8.0/en/glossary.html#glos_dirty_read)。除此之外，这个隔离级别的工作方式类似于 READ COMMITTED。

- SERIALIZABLE

  这个隔离级别类似于 REPEATABLE READ，但 InnoDB 会隐式地将所有普通的 SELECT 语句转换成 SELECT ... FOR SHARE，如果关闭了 autocommit 的话。如果开启了 autocommit 的话，SELECT 自己本身就是一个事务。因此，它被认为是只读的，并且如果是执行一致性（非阻塞）读取和无需阻塞其它事务的话，那么它是可序列化的。（如果其它事务已经修改了选中的行，为了使普通 SELECT 被强制阻塞，请禁用 autocommit。）

## 自动提交、提交、回滚

在 InnoDB 中，所有的用户行为都是发生在事务中的。如果开启了 autocommit 模式的话，每个 SQL 语句自己会形成一个单独的事务。默认情况下，MySQL 会在每个新连接开始会话时开启 autocommit，所以如果 SQL 语句没有返回错误的话，MySQL 会在每个语句之后执行一次提交。如果一条语句返回了错误，提交或者回滚的行为则要取决于该错误。更多内容请见 [InnoDB Error Handling](https://dev.mysql.com/doc/refman/8.0/en/innodb-error-handling.html)。

开启了 autocommit 的会话可以通过 START TRANSACTION 或者 BEGIN 语句开始一段多语句的事务，并且可以通过 COMMIT 或者 ROLLBACK 语句来结束它。更多内容请见 [START TRANSACTION, COMMIT, and ROLLBACK Statements](https://dev.mysql.com/doc/refman/8.0/en/commit.html)。

如果在会话中使用 SET autocommit = 0 关闭了 autocommit 的话，那么该会话始终都会打开一个事务。 COMMIT 和 ROLLBACK 语句会结束该事务并且会开启一个新的事务。

如果关闭了 autocommit 的会话在结束时没有显式提交事务，MySQL 则会回滚该事务。

一些语句会隐式地结束事务，就像你在执行该语句之前已经执行了 COMMIT 一样。更多内容请见 [Statements That Cause an Implicit Commit](https://dev.mysql.com/doc/refman/8.0/en/implicit-commit.html)。

COMMIT 语句表示当前事务中所做的更改会被持久化，并且会对其它会话可见。另一方面，ROLLBACK 语句会取消当前事务中所做的所有更改。COMMIT 和 ROLLBACK 语句都会释放当前事务中设置的 InnoDB 锁。

## 一致性非锁定读取

[一致性读取](https://dev.mysql.com/doc/refman/8.0/en/glossary.html#glos_consistent_read) 意味着 InnoDB 会使用多版本来向查询呈现数据库在某个时刻的快照。该查询将会看到在这个时刻之前提交的事务所做的更改，之后所做的或者还未提交的事务所做的更改不会被看到。这个规则的例外是查询可以看到同一个事务中的之前语句所做的更改。这个例外情况会导致以下异常：如果你在表中更新了某些行，SELECT 会看到这些被更新的行的最新版本，但也可能会看到任何行的旧版本。如果其它会话同时更新了同一张表，这个异常意味着你可能会看到该表处于一个在数据库中永远不会存在的状态。

如果事务的隔离级别是 REPEATABLE READ（默认级别），那么在同一事务中的所有一致性读取会读取由在该事务中的第一个读取所建立的快照。你可以通过提交当前事务然后发出新的查询，来为查询获取更新的快照。

在 READ COMMITTED 隔离级别中，事务中的每个一致性读取都会设置和读取它自己的新快照。

一致性读取是 InnoDB 在 READ COMMITTED 和 REPEATABLE READ 隔离级别中处理 SELECT 语句的默认模式。一致性读取不会在它访问的表上设置任何锁，因此其它会话可以在执行一致性读取的的表上，同时自由地修改这些表。

假设你正在以默认的 REPEATABLE READ 隔离级别运行 MySQL 服务。当你发出一个一致性读取（即普通的 SELECT 语句）的时候，InnoDB 会为你的事务分配一个时间点，你的查询可以使用该时间点来查看数据库。如果其它事务删除了一行并在该时间点之后提交了事务，你则会看不到该行已经被删除了。插入和更新会以相似的方式被处理。

你可以通过提交你的事务来推进你的时间点，然后执行另一个 SELECT 或者 START TRANSACTION WITH CONSISTENT SNAPSHOT。

这被称为多版本并发控制（multi-versioned concurrency control，MVCC）。

在下面的例子中，会话 A 仅会在 B 已经提交了插入操作并且 A 也已经提交时，才能看到 B 插入的行，以便时间点被推进至 B 的提交之后。

```sql
             Session A              Session B

           SET autocommit=0;      SET autocommit=0;
time
|          SELECT * FROM t;
|          empty set
|                                 INSERT INTO t VALUES (1, 2);
|
v          SELECT * FROM t;
           empty set
                                  COMMIT;

           SELECT * FROM t;
           empty set

           COMMIT;

           SELECT * FROM t;
           ---------------------
           |    1    |    2    |
           ---------------------
```

如果你希望看到数据库的「最新」状态，那么请使用 READ COMMITTED 隔离级别或者 [锁定读取](https://dev.mysql.com/doc/refman/8.0/en/glossary.html#glos_locking_read)：

```sql
SELECT * FROM t FOR SHARE;
```

在 READ COMMITTED 隔离级别中，事务中的每个一致性读取都会设置和读取它自己的新快照。在 FOR SHARE 中，会发生锁定读取：SELECT 会一直阻塞，直到包含最新状态的事务结束（更多内容请见 [Locking Reads](https://dev.mysql.com/doc/refman/8.0/en/innodb-locking-reads.html)）。

一致性读取不适用于某些 DDL 语句：

- 一致性读取不适用于 DROP TABLE，因为 MySQL 无法使用已经删除并且被 InnoDB 破坏了的表。
- 一致性读取不适用于会创建原表的临时副本的并且会在创建临时副本时删除原表的 ALTER TABLE 操作。当你在事务中重新发出一个一致性读取时，新表中的行会是不可见的，因为这些行在获取事务的快照时是不存在的。在这种情况下，事务会返回一个错误：ER_TABLE_DEF_CHANGED，「表的定义已经被修改，请重试事务」。

对于未指定 FOR UPDATE 或者 FOR SHARE 的查询子句，比如 INSERT INTO ... SELECT、UPDATE ... (SELECT)，和 CREATE TABLE ... SELECT，查询的类型会有所不同：

- 默认情况下，InnoDB 会对这些语句使用更强的锁，并且 SELECT 部分的行为会类似于 READ COMMITTED，即使是在同一个事务中，每个一致性读取都会设置和读取它自己的新快照。
- 为了在这种情况下执行非阻塞读取，需要将隔离级别设置为 READ UNCOMMITTED 或者 READ COMMITTED，用于避免在选择的表中所读取的行上设置锁。

## 锁定读取

---

## 参考资料

- [InnoDB Transaction Model](https://dev.mysql.com/doc/refman/8.0/en/innodb-transaction-model.html)
- [Transaction Isolation Levels](https://dev.mysql.com/doc/refman/8.0/en/innodb-transaction-isolation-levels.html)
- [autocommit, Commit, and Rollback](https://dev.mysql.com/doc/refman/8.0/en/innodb-autocommit-commit-rollback.html)
- [Consistent Nonlocking Reads](https://dev.mysql.com/doc/refman/8.0/en/innodb-consistent-read.html)
- [Locking Reads](https://dev.mysql.com/doc/refman/8.0/en/innodb-locking-reads.html)
