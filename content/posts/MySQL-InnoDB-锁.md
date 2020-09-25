---
title: "MySQL InnoDB 锁"
date: 2020-07-17T14:02:28+08:00
categories: ["数据库"]
tags: ["MySQL", "InnoDB"]
keywords: ["MySQL", "InnoDB", "锁"]
---

本篇文章记录自己在阅读 MySQL Reference Manual 时候，关于 InnoDB 锁的一些笔记。<!--more-->

---

## 锁的类型

在 InnoDB 中涉及的锁有以下类型：

- [Shared and Exclusive Locks](#共享锁和排它锁) 共享锁和排它锁
- [Intention Locks](#意向锁) 意向锁
- [Record Locks](#记录锁) 记录锁
- [Gap Locks](#间隙锁) 间隙锁
- [Next-Key Locks](#后键锁) 后键锁
- [Insert Intention Locks](#插入意向锁) 插入意向锁
- [AUTO-INC Locks](#自增锁) 自增锁
- [Predicate Locks for Spatial Indexes](#索引空间的谓词锁) 索引空间的谓词锁

### 共享锁和排它锁

InnoDB 实现了标准的行级锁，包括共享锁（shared locks，S）和排它锁（exclusive locks，X）：

- 共享锁允许持有该锁的事务读取行数据；
- 排它锁允许持有该锁的事务更新或者删除行数据。

如果事务 T1 在行 r 上持有共享锁，那么来自不同事务 T2 对行 r 上锁的请求，会按照如下方式处理：

- 可以立即授予 T2 对共享锁的请求。结果会导致 T1 和 T2 在行 r 上都会持有共享锁；
- 不可以立即授予 T2 对排它锁的请求。

如果事务 T1 在行 r 上持有排它锁，那么来自不同事务 T2 对行 r 上任何类型锁的请求都不会被立即授予。相反的，事务 T2 必须等待 T1 事务释放在行 r 上的锁。

### 意向锁

InnoDB 支持多种粒度的锁，允许行锁和表锁同时存在。例如 `LOCK TABLES ... WRITE` 语句会在指定的表上设置排它锁。InnoDB 使用意向锁来实现多种粒度的锁。意向锁是表级锁，用于指定事务稍后在表中某行上需要持有锁的类型（共享锁或者排它锁）。意向锁有两种类型：

- 意向共享锁（intention shared lock，IS）表示事务打算在表中的各行上设置共享锁；
- 意向排它锁（intention exclusive lock，IX）表示事务打算在表中的各行上设置排它锁。

例如 `SELECT ... FOR SHARE` 语句会设置 IS 锁，`SELECT ... FOR UPDATE` 语句会设置 IX 锁。

意向锁的使用规则如下：

- 事务在表中的行上获取共享锁之前，它必须先在表上获取 IS 锁或者更高强度的锁；
- 事务在表中的行上获取排它锁之前，它必须先在表上获取 IX 锁。

各种表级锁类型的兼容性如下：

|     | X        | IX         | S          | IS         |
| --- | -------- | ---------- | ---------- | ---------- |
| X   | Conflict | Conflict   | Conflict   | Conflict   |
| IX  | Conflict | Compatible | Conflict   | Compatible |
| S   | Conflict | Conflict   | Compatible | Compatible |
| IS  | Conflict | Compatible | Compatible | Compatible |

如果事务请求的锁与现有的锁互相兼容，则授予锁，如果冲突则不授予锁。事务会持续等待直到现有冲突的锁被释放。如果事务请求的锁与现有的锁发生冲突，并且是由于可能会导致 [死锁](https://dev.mysql.com/doc/refman/8.0/en/glossary.html#glos_deadlock) 而无法被授予的情况时，MySQL 会反馈一个错误。

除了对全表的请求（例如 `LOCK TABLES ... WRITE`）之外，意向锁不会锁定任何内容。意向锁的主要用途是表示有人正在锁定表中的行，或者是打算锁定表中的行。

意向锁中的事务数据类似于如下 `SHOW ENGINE INNODB STATUS` 语句和 [InnoDB monitor](https://dev.mysql.com/doc/refman/8.0/en/innodb-standard-monitor.html) 的输出：

```sql
TABLE LOCK table `test`.`t` trx id 10080 lock mode IX
```

### 记录锁

记录锁是对一条索引记录的锁。例如 `SELECT c1 FROM t WHERE c1 = 10 FOR UPDATE;` 语句会阻止任何其它事务插入、更新，或者删除 `t.c1` 值为 `10` 的行。

记录锁总是会锁定索引记录，即使表中没有定义索引。在这种情况下，InnoDB 会创建一个隐式的聚簇索引，并将这个索引用于记录锁。更多内容请见 [Clustered and Secondary Indexes](https://dev.mysql.com/doc/refman/8.0/en/innodb-index-types.html)。

记录锁中的事务数据类似于如下 `SHOW ENGINE INNODB STATUS` 语句和 [InnoDB monitor](https://dev.mysql.com/doc/refman/8.0/en/innodb-standard-monitor.html) 的输出：

```sql
RECORD LOCKS space id 58 page no 3 n bits 72 index `PRIMARY` of table `test`.`t`
trx id 10078 lock_mode X locks rec but not gap
Record lock, heap no 2 PHYSICAL RECORD: n_fields 3; compact format; info bits 0
 0: len 4; hex 8000000a; asc     ;;
 1: len 6; hex 00000000274f; asc     'O;;
 2: len 7; hex b60000019d0110; asc        ;;
```

### 间隙锁

间隙锁是对一个索引记录的区间的锁，或者是对第一个索引之前和最后一个索引之后的区间的锁。例如 `SELECT c1 FROM t WHERE c1 BETWEEN 10 and 20 FOR UPDATE;` 语句会阻止其它事务在 `t.c1` 列中插入值为 `15` 的记录，而不论列中是否已有这样的值，因为该范围内所有已有值的区间已经被锁定了。

间隙锁跨越的区间可能是单个索引值、多个索引值，甚至可能为空。

间隙锁是权衡性能和并发的一部分，并被用于某些特定的事务隔离级别。

使用唯一索引来锁定行从而进行查找唯一记录的语句，不需要锁定区间。但这不包括查询条件仅包含了多列唯一索引中部分列的情况。在这种情况下，还是会锁定区间。例如，如果 `id` 列具有唯一索引，如下语句仅会对 `id` 值为 `100` 的行使用记录锁进行锁定，并且这与其它事务是否会在前一个区间内插入记录无关。

```sql
SELECT * FROM child WHERE id = 100;
```

如果 `id` 列没有索引或者具有非唯一的索引，那么这条语句是会锁定前一个区间的。

还值得注意的是，不同事务可以在相同区间上持有互相冲突的锁。例如，事务 A 可以在一段区间上持有共享间隙锁（gap-S-lock），同时事务 B 也可以在相同区间上持有排它间隙锁（gap-X-lock）。允许间隙锁冲突的原因是，如果记录从索引上被清除了，那么不同事务在这个记录上持有的间隙锁必须被合并。

InnoDB 中的间隙锁是「完全抑制」的，这意味着使用间隙锁的唯一目的是防止其它事务在区间内插入数据。间隙锁是可以共存的。一个事务设置了的间隙锁不会阻止另一个事务在相同区间设置间隙锁。在这一点上，共享间隙锁和排它间隙锁没有区别。它们不会互相冲突，并且执行相同的功能。

间隙锁可以被显式禁用。这会发生在将事务的隔离级别设置为 READ COMMITTED 的时候。在这种情况下，间隙锁在查找和索引扫描时是禁用的，并且只会被用于外键约束检查和重复键检查。

使用 READ COMMITTED 隔离级别还有其它影响。在 MySQL 评估 WHERE 条件之后，不匹配的行上的记录锁会被释放。对于 UPDATE 语句，InnoDB 会采取「半一致性」读取，它会将最新提交的版本返回给 MySQL，以便 MySQL 可以确定该行是否与 UPDATE 语句里的 WHERE 条件匹配。

### 后键锁

后键锁是索引记录上的记录锁和索引记录之前区间的间隙锁的组合。

InnoDB 设置行级锁的方式是，当它在查找或者扫描表中的索引时，会在遇到的索引记录上设置共享锁或者排它锁。因此行级锁实际上是索引记录锁。索引记录上的后键锁也会影响该索引记录之前的「区间」。这也就是说，后键锁就是索引记录锁加上该索引记录之前的区间上的间隙锁。如果一个事务在索引记录 R 上持有共享锁或者排它锁，那么任何事务都不能在以索引顺序中 R 之前的区间内插入新的索引记录。

假设一个索引包含了值 `10`、`11`、`13` 和 `20`。该索引中可能的后键锁包括了以下区间，其中圆括号表示排除区间的端点，方括号表示包含区间的端点。

```text
(negative infinity, 10]
(10, 11]
(11, 13]
(13, 20]
(20, positive infinity)
```

对于最后一个的区间，后键锁将锁定索引中大于最大值的区间，并且「极限」伪记录的值大于实际的任何值。极限值不是真实的索引记录，因此，实际上，此时的后键锁仅会锁定跟随最大索引值的区间。

默认情况下，InnoDB 会在 REPEATABLE READ 事务隔离级别下运行。在这种情况下，InnoDB 会使用后键锁来查找和索引扫描，从而避免发生幻行（更多请见 [Phantom Rows](https://dev.mysql.com/doc/refman/8.0/en/innodb-next-key-locking.html)）。

后键锁中的事务数据类似于如下 `SHOW ENGINE INNODB STATUS` 语句和 [InnoDB monitor](https://dev.mysql.com/doc/refman/8.0/en/innodb-standard-monitor.html) 的输出：

```sql
RECORD LOCKS space id 58 page no 3 n bits 72 index `PRIMARY` of table `test`.`t`
trx id 10080 lock_mode X
Record lock, heap no 1 PHYSICAL RECORD: n_fields 1; compact format; info bits 0
 0: len 8; hex 73757072656d756d; asc supremum;;

Record lock, heap no 2 PHYSICAL RECORD: n_fields 3; compact format; info bits 0
 0: len 4; hex 8000000a; asc     ;;
 1: len 6; hex 00000000274f; asc     'O;;
 2: len 7; hex b60000019d0110; asc        ;;
```

### 插入意向锁

插入意向锁是在插入行之前由 INSERT 操作设置的一种间隙锁。该锁以这种方式表示准备插入行的意向，以便在同一段索引区间内插入行的多个事务不需要互相等待，如果它们不会在区间内的相同位置插入行的话。假设一个索引包含了值 `4` 和 `7`，并且有两个独立的事务尝试插入值 `5` 和 `6`，那么各自得，在获取待插入行上的排它锁之前，每个事务都会使用插入意向锁来锁定 `4` 和 `7` 之间的区间，而不会互相阻塞，因为这两个事务插入的行是不冲突的。

下面的示例演示了一个事务在获取待插入记录上的排它锁之前，设置了插入意向锁。这个示例涉及了两个客户端 A 和 B。

客户端 A 创建了一张表，包含两个索引记录（`90` 和 `102`），并且开始了一个事务，该事务会对 ID 大于 100 的索引记录设置排它锁。排它锁包括了在记录 `102` 之前的间隙锁：

```sql
mysql> CREATE TABLE child (id int(11) NOT NULL, PRIMARY KEY(id)) ENGINE=InnoDB;
mysql> INSERT INTO child (id) values (90),(102);

mysql> START TRANSACTION;
mysql> SELECT * FROM child WHERE id > 100 FOR UPDATE;
+-----+
| id  |
+-----+
| 102 |
+-----+
```

客户端 B 开始了一个事务，该事务会在区间内插入一条记录。这个事务在等待获取排它锁的同时，会设置一个插入意向锁。

```sql
mysql> START TRANSACTION;
mysql> INSERT INTO child (id) VALUES (101);
```

插入意向锁中的事务数据类似于如下 `SHOW ENGINE INNODB STATUS` 语句和 [InnoDB monitor](https://dev.mysql.com/doc/refman/8.0/en/innodb-standard-monitor.html) 的输出：

```sql
RECORD LOCKS space id 31 page no 3 n bits 72 index `PRIMARY` of table `test`.`child`
trx id 8731 lock_mode X locks gap before rec insert intention waiting
Record lock, heap no 3 PHYSICAL RECORD: n_fields 3; compact format; info bits 0
 0: len 4; hex 80000066; asc    f;;
 1: len 6; hex 000000002215; asc     " ;;
 2: len 7; hex 9000000172011c; asc     r  ;;...
```

### 自增锁

自增锁是一种特殊的表级锁，由插入到具有 AUTO_INCREMENT 列的表中的事务所使用的。在最简单的情况下，如果一个事务正在向表中插入数据，那么任何其它事务都必须等待执行它们自身向表中的插入操作，以便第一个事务插入的行可以接收到连续的主键值。

`innodb_autoinc_lock_mode` 配置项可以控制使用自增锁的算法。它可以允许你选择如何权衡可预测的自增值序列与插入操作的最大并发性。

更多详细信息请见 [AUTO_INCREMENT Handling in InnoDB](https://dev.mysql.com/doc/refman/8.0/en/innodb-auto-increment-handling.html)。

### 索引空间的谓词锁

InnoDB 支持对空间列进行空间索引（更多请见 [Optimizing Spatial Analysis](https://dev.mysql.com/doc/refman/8.0/en/optimizing-spatial-analysis.html)）。

涉及处理空间索引的锁定操作时，后键锁不能很好地支持 REPEATABLE READ 和 SERIALIZABLE 事务隔离级别。在多维数据中没有绝对的排序概念，因此并不清楚哪一个才是「后」键。

为了开启对包含空间索引的表的隔离级别的支持，InnoDB 会使用谓词锁。一个空间索引包含最小边界矩形（minimum bounding rectangle，MBR）值，因此 InnoDB 会通过在用于查询的 MBR 值上设置谓词锁来强制对索引进行一致性读取。其它事务不能插入或者修改将会匹配查询条件的行。

---

## 参考资料

- [InnoDB Locking](https://dev.mysql.com/doc/refman/8.0/en/innodb-locking.html)
