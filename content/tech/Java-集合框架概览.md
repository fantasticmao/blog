---
title: "Java 集合框架概览"
date: 2018-10-18T22:00:34+08:00
categories: ["编程"]
tags: ["Java", "Data Structure"]
keywords: ["Java", "集合框架", "数据结构"]
draft: true
---

本篇文章记录我所理解和掌握的在 JDK8 Collection Library 中的常用集合类，及其所涉及的数据结构和实现原理。<!--more-->

---

## Map

### HashMap

HashMap 使用一个 `transient Node<K, V>[] table` 字段存储 key-value 键值对的数据，`Node<K, V>` 默认情况下的 HashMap.Node 是链表类型，特殊情况下是 HashMap.TreeNode 红黑树类型。因为 HashMap.TreeNode 间接继承了 HashMap.Node，所以这两种类型可以同时适用于上述的 `table` 字段。

HashMap.Node 实现了 Map.Entry 接口，它为 HashMap 保存了 key-value 元素的基本数据和经过 `hash(object)` 方法计算的 key 的散列值。除此之外，HashMap.Node 作为链表的节点，它还保存了它的下一个节点。HashMap.Node 类的字段如下图所示：

![image](/images/Java集合框架概览/HashMapNode.png)

HashMap.TreeNode 间接继承了 HashMap.Node。当 HashMap.Node 类型的链表长度大于 HashMap 定义的常量 `TREEIFY_THRESHOLD` 时，链表就会被 `treeifyBin(Node<K,V>[], int)` 方法转置成 HashMap.TreeNode 类型的红黑树。（红黑树的数据结构此处暂不讨论）

综上所述，HashMap 中所涉及的数据结构如下图所示：

![image](/images/Java集合框架概览/HashMap.png)

#### 计算数组下标

HashMap 为了将节点均匀地分散在 `table` 数组上（避免哈希碰撞），使用节点 key 的哈希值进行了一系列的位运算，从而最终确定节点的数组下标。HashMap 计算节点的数组下标的关键代码如下图所示：

![image](/images/Java集合框架概览/HashMapHash.png)

阅读源码可以得出，在 HashMap 中计算节点的数组下标规则为：

- 当 key == null 时，数组下标为 0；
- 当 key != null 时，数组下标为 (table.length - 1) & (key.hashCode() ^ (key.hashCode() >>> 16))。

#### get 方法

HashMap get 方法的关键代码如下图所示：

![image](/images/Java集合框架概览/HashMapGet.png)

HashMap get 方法的关键步骤：

1. 根据 key，计算节点的数组下标；
2. 根据数组下标，获取对应的 Node 节点，判断该节点的哈希值和 key 是否与目标节点的哈希值和 key 匹配，若匹配成功则直接返回；
3. 若在 2 中匹配节点失败，则获取当前节点的下一个节点，依据当前节点的类型（链表或红黑树），使用不同方式遍历后续的所有节点，查找与目标节点的哈希值和 key 匹配的节点。若匹配成功则直接返回对应的节点；
4. 若在 2 和 3 中匹配节点失败，则表示目标元素不存在。get 方法最终返回的目标元素为 null。

#### put 方法

HashMap put 方法的关键代码如下图所示：

![image](/images/Java集合框架概览/HashMapPut.png)

HashMap put 方法的关键步骤：

1. 根据 key，计算节点的数组下标；
2. 根据数组下标，获取对应的 Node 节点，判断该节点是否为 null，若节点为 null 则直接为该节点赋值；
3. 若在 2 中的节点不为 null，则判断当前节点的哈希值和 key 是否与待插入节点的哈希值和 key 匹配，若匹配成功则获取该节点；
4. 若在 3 中匹配节点失败，则依据该节点的类型（链表或红黑树），使用不同方式遍历后续的所有节点，查找与待插入节点的哈希值和 key 匹配的节点。若匹配成功则获取对应的节点，如果匹配失败则为最后一个节点的下一个节点赋值。当在链表类型的节点中查找时，若发现链表长度大于或等于 HashMap 定义的常量 `TREEIFY_THRESHOLD` 时，则需将当前节点的类型由链表转置为红黑树；
5. 若在 3 或 4 中获取节点成功，则表示此次插入操作是替换旧节点，需要使用待插入元素的新值替换旧元素的旧值，并直接返回旧值；
6. 若在 3 和 4 中匹配节点失败，则表示此次插入操作是插入新节点，需要更新 HashMap 中统计信息的相关字段，并判断插入新元素后的 HashMap 是否需要扩容。此时 put 方法最终返回的旧元素值为 null。

#### resize 方法

HashMap resize 方法的关键代码如下图所示：

![image](/images/Java集合框架概览/HashMapResize.png)

HashMap resize 方法的关键步骤：

1. 计算 `newCap` 和 `newThr`，在正常扩容的情况下，`newCap` 是 `oldCap` 的两倍，`newThr` 是 `oldThr` 的两倍；
2. 创建新 `Node<K,V>[] newTab`;
3. 遍历旧 `Node<K,V>[] oldTab`，移动 `oldTab` 旧节点至 `newTab` 的新节点。

在 HashMap resize 移动节点时，计算新节点的数组下标逻辑为：

- 若 `oldTab` 上的节点没有后续节点，则将其移动到 `newTab[e.hash & (newCap - 1)]` 位置；
- 若 `oldTab` 上的节点存在后续节点，则通过 `(e.hash & oldCap) == 0` 来判断该节点的哈希值的最高位是否为零，若是则将其移动到 `newTab[j]` 位置，若不是则将其移动到 `newTab[j + oldCap]` 位置，其中 `j` 为该节点的原数组下标。

#### 注意事项

关于 HashMap，有以下几点是需要注意的：

1. HashMap 不保障线程安全；
2. HashMap 允许 key 和 value 是 null；
3. HashMap 以哈希算法确定节点的位置，不会保证节点的插入顺序；
4. 可以通过优化 HashMap 持有元素的 `hashCode()`，从而降低哈希碰撞的可能性。

#### 参考资料

- [Java 8 系列之重新认识 HashMap](https://tech.meituan.com/java_hashmap.html)

---

### LinkedHashMap

LinkedHashMap 基于 HashMap 实现了双向链表的功能。LinkedHashMap 继承了 HashMap，并添加了 `LinkedHashMap.Entry<K,V> head` 和 `LinkedHashMap.Entry<K,V> tail` 两给字段，用于保存双向链表的头和尾。LinkedHashMap 的内部节点 LinkedHashMap.Entry 继承了 HashMap.Entry，并添加了 `Entry<K,V> before, after` 两个字段，用于保存每个双向链表节点的上下位节点。LinkedHashMap 可以通过 `boolean accessOrder` 构造参数来指定双向链表的排序模型 —— 按访问顺序或按插入顺序，默认是按插入顺序。

LinkedHashMap 的数据结构如下图所示：

LinkedHashMap 本身并没有对 HashMap 的 get、put 等操作进行修改，而是通过重写 HashMap 中的几个钩子方法（hook method）来维护它本身和双向链表的相关字段。LinkedHashMap 重写的钩子方法主要涉及内部节点的创建、访问、增加和删除操作，相关代码如下图 1 和 2 中所示：

![image](/images/Java集合框架概览/LinkedHashMapVsHashMap.png)

#### 注意事项

关于 LinkedHashMap，有以下几点是需要注意的：

1. LinkedHashMap 按插入顺序的访问模型可以被用于实现 <a href="https://en.wikipedia.org/wiki/Cache_replacement_policies#Least_recently_used_(LRU)" target="_blank" rel="noopener">LRU</a> 算法，具体实现时仅需重写 `removeEldestEntry(Map.Entry<K,V> eldest)` 方法即可。

---

### TreeMap

TreeMap 基于红黑树算法实现，TreeMap 使用 `private transient Entry<K,V> root` 字段存储红黑树的根节点，使用 `private final Comparator<? super K> comparator` 字段存储内部节点的排序规则。

TreeMpa.Entry 实现了 Map.Entry 接口，它为 TreeMap 保存了 key-value 元素的基本数据和当前节点的父节点、左子节点、右子节点，以及当前节点红或黑的颜色。TreeMap.Entry 类的字段如下图所示：

![image](/images/Java集合框架概览/TreeMapEntry.png)

TreeMap 中所涉及的数据结构如下图所示：

![image](/images/Java集合框架概览/TreeMap.png)

#### get 方法

TreeMap get 方法的关键代码如下图所示：

TreeMap get 方法的关键步骤：

#### put 方法

TreeMap put 方法的关键代码如下图所示：

TreeMap put 方法的关键步骤：

#### remove 方法

TreeMap remove 方法的关键代码如下图所示：

TreeMap remove 方法的关键步骤：

#### 参考资料

- [红黑树深入剖析及 Java 实现](https://tech.meituan.com/redblack_tree.html)

---

### Hashtable

Hashtable 的数据结构与 HashMap 类似，其内部使用 `private transient Entry<?,?>[] table` 字段存储 key-value 键值对的数据，但与 HashMap 不同的是，Hashtable 的内部节点 Hashtable.Entry 只能是链表类型。Hashtable 并没有针对在哈希冲突严重的情况下，使用红黑树类型节点替换过长的链表类型节点。Hashtable 的所有方法都被 synchronized 关键字修饰，这意味着 Hashtable 是属于相对线程安全的类。

Hashtable 中所涉及的数据结构如下图所示：

![image](/images/Java集合框架概览/Hashtable.png)

---

### ConcurrentHashMap

---

### ConcurrentSkipListMap

### WeakHashMap

## List

### ArrayList

### LinkedList

### Vector

### Stack

### CopyOnWriteArrayList

## Set

### HashSet

### LinkedHashSet

### TreeSet

### CopyOnWriteArraySet

### ConcurrentSkipListSet

## Queue
