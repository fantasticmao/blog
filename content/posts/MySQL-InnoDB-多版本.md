---
title: "MySQL InnoDB 多版本"
date: 2020-06-26T01:03:00+08:00
categories: ["数据库"]
tags: ["MySQL", "InnoDB"]
keywords: ["MySQL", "InnoDB", "Multi-Versioning", "多版本"]
---

本篇文章记录自己在阅读 MySQL Reference Manual 时候，关于 InnoDB 多版本的一些笔记。<!--more-->

---

## 多版本

InnoDB 是一个 [多版本的存储引擎](https://dev.mysql.com/doc/refman/8.0/en/glossary.html#glos_mvcc)：它会保留已更改行的旧版本信息，用于支持事务的特性，例如并发和回滚。这些信息以被称为 [回滚段](https://dev.mysql.com/doc/refman/8.0/en/glossary.html#glos_rollback_segment)（一种与 Oracle 中类似的数据结构）的数据结构存储在表空间中。InnoDB 使用回滚段中的信息来执行在事务回滚中所需要的回滚操作。它还会使用这些信息来构建行的早期版本，用于实现一致性读取。

InnoDB 会在内部为存储于数据库中的每行添加三个字段。一个 6 字节的 DB_TRX_ID 字段，用于表示插入或更新该行的最后一次事务的事务标识符。此外，删除操作在内部会被视为更新操作，此时该行中的一个特殊位会被标记成已删除。每行还包含了一个 7 字节的 DB_ROLL_PTR 字段，被称为滚动指针。滚动指针指向了一条写在回滚段中的撤销日志（undo log）记录。如果该行被更新了，那么包含了信息的撤销日志记录可以在必要的时候，把该行的内容重建到它被更新之前的版本。一个 6 字节的 DB_ROW_ID 字段，包含了一个行的 ID，会随着插入新行而单调增加。如果 InnoDB 自动生成了聚簇索引，那么该索引会包含行的 ID 值。否者，DB_ROW_ID 不会出现在任何索引中。

回滚段中的撤销日志分为插入和更新的撤销日志。插入撤销日志只会在事务回滚时被需要，并且在事务提交后可以被立即丢弃。更新撤销日志会被用于一致性读取，但仅当在没有 InnoDB 为已经分配了的快照（在一致性读取中，可能需要这个更新撤销日志中的快照信息来构建数据库行的早期版本）而存在的事务之后，才可以丢弃它们。

建议经常提交你的事务，包括仅会发出一致性读取的事务。否则，InnoDB 不会丢弃更新撤销日志中的数据，并且回滚段可能会变得太大从而填满了表空间。

回滚段中的撤销日志记录的物理大小通常小于它对应的插入或者更新的行。你可以使用这个信息来计算回滚段所需的空间大小。

在 InnoDB 多版本的体系中，当你使用 SQL 语句删除行的时候，该行并不会被立即从数据库中物理删除。当 InnoDB 丢弃为删除操作而写入的更新撤销日志记录的时候，它只会物理删除对应的行和索引记录。这个删除操作被称为 [清除](https://dev.mysql.com/doc/refman/8.0/en/glossary.html#glos_purge)，它运行速度非常快，通常会和执行删除操作的 SQL 语句所花费的时间相同。

如果你在表中以大约相同的速率，小批量地插入和删除行的时候，清除线程可能会落后于创建线程，并且表空间可能会由于这些「死」行而变得越来越大，从而使所有内容都受到磁盘的约束，变得非常缓慢。在这种情况下，请限制插入新行的操作，并通过调整 innodb_max_purge_lag 系统变量来为清除线程分配更多资源。更多内容请见 [InnoDB Startup Options and System Variables](https://dev.mysql.com/doc/refman/8.0/en/innodb-parameters.html)。

---

## 多版本和二级索引

InnoDB 的多版本并发控制（multiversion concurrency control，MVCC）对待二级索引的处理方式与对待聚簇索引的方式不同。聚簇索引中的记录会被就地更新，并且它们所隐藏的系统列指向了撤销日志中的条目，这些条目可以被用于重建早期版本的记录。与聚簇索引不同的是，二级索引不包含隐藏的系统列，也不会就地更新记录。

当二级记索引列被更新的时候，旧的二级索引记录会被标记成删除，新的记录会被插入，并且被标记删除的记录最终会被清除。当二级索引记录被标记成删除或者二级索引页被更（gèng）新的事务所更（gēng）新的时候，InnoDB 会在聚簇索引上查找数据库中的记录。在聚簇索引中，记录的 DB_TRX_ID 字段会被检查，并且会从撤销日志中检索记录的正确版本，如果记录在读取事务初始化之后被修改了的话。

如果二级索引记录被标记成删除或者二级索引页被更新的事务所更新了，那么 [覆盖索引](https://dev.mysql.com/doc/refman/8.0/en/glossary.html#glos_covering_index) 技术不会被使用。InnoDB 不会从索引结构中返回值，而是会在聚簇索引中查找记录。

然而，如果开启了 [索引条件下推（index condition pushdown，ICP）](https://dev.mysql.com/doc/refman/8.0/en/index-condition-pushdown-optimization.html) 优化，并且 WHERE 条件的一部分可以使用索引结构中的字段来被评估，那么 MySQL 服务会将 WHERE 条件的一部分下推给存储引擎，存储引擎会使用索引来进行评估。如果没有匹配到记录，那么在聚簇索引的查找可以被避免。如果匹配到了记录，那么 InnoDB 会在聚簇索引上查找记录，即使是在被标记删除的记录中。

---

## 参考资料

- [InnoDB Multi-Versioning](https://dev.mysql.com/doc/refman/8.0/en/innodb-multi-versioning.html)
