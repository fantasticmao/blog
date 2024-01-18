---
title: "关于专栏《Java 核心技术 36 讲》"
date: 2018-05-09T12:39:42+08:00
categories: ["编程"]
tags: ["Java"]
draft: true
---

最近我在极客时间上订阅了一个专栏 —— [《Java 核心技术 36 讲》](https://time.geekbang.org/column/intro/82)。<!--more-->这是一个以 Java 经典面试题为切入点，来讲解和剖析相关领域知识的专栏。大致看了专栏的目录，发现其中涉及的知识点，即包含自己完全未接触过的知识点（广度不够），也包含接触过但仍然一知半解的知识点（深度不够），也包含相当熟悉但却回答不上的知识点（体系化不够）。

革命尚未成功，同志仍需努力。

对于学习技术这件事，记一些想法：要更侧重于通过阅读书籍 / 文档 / 手册 / RFC 等方式，而不是仅仅通过看视频 / 听分享 / 听演讲等方式获取新知识、学习新技术。记几个观点：学习需要自我驱动、学习的资料需要官方化、学习的知识需要体系化。

---

## 谈谈你对 Java 平台的理解

Java 是一种被广泛使用的面向对象编程语言，支持面向对象的封装、多态、继承三大特性。Java 的基本语法类似于 C 语言，相对规范和严谨（区别于 PHP、Python 等弱类型语言），支持 Annotaion、Generic、Lambda、Method Reference 等等。除此之外，Java 的核心类库和第三方库也十分丰富，核心类库包括 IO / NIO、Collection、Network、Concurrent、Security、Date / Time 等等，第三方库包括 Spring Framework、Netty、Hibernate、Jackson、Guava 等等。

Java 作为一个老牌且成熟的编程语言，其发展多年的虚拟机也经受了业界苛刻的考验。JVM（Java Virtual Machine）不仅支持了 Java 宣传标语 —— Write Once, Run Anywhere —— 的跨平台特性，并且提供了丰富的垃圾收集机制来自动分配和回收内存。其中，常用的垃圾收集器如 Serial、Parallel、CMS、G1 等。另外，JVM 除了支持 source code -> byte code -> machine code 的编译 & 解释运行方式，还支持 JIT（Just In Time）编译方式，能够极大提高 Java 程序的运行性能。最后，JVM 作为一个强大的虚拟机，还支持运行例如 Clojure、Scala、Groovy、JRuby、Jython 等等大量的符合 JVM 字节码规范的语言。

---

## Exception 与 Error 有什么区别

在 Java 标准异常中，`Throwable` 类表示任何可以被作为异常抛出的类，`Exception` 类和 `Error` 类都继承了 `Throwable` 类。

`Error` 类表示编译错误和系统错误，是在程序正常运行情况下，不大可能会出现的异常，例如 `OutOfMemoryError`、`StackOverflowError`。

`Exception` 类则表示可以被作为异常抛出的基本类型，是在程序正常运行情况下的可预料错误。`Exception` 类的异常分为 **受检查异常**（checked）和 **不受检查异常**（unchecked）。受检查异常必须在程序编译期被显示捕获和被正确处理，例如 `IOException`、`SQLException`。不受检查异常需继承于 `RuntimeException` 类，会在程序运行时被自动抛出，不需要被显示捕获，例如 `NullPointerException`、`ArrayIndexOutOfBoundsException`、`IllegalArgumentException`。

编写异常处理代码的最佳实践：

- Throw Early, Catch Late；
- 在知道如何处理异常的情况下，再捕获并处理异常；
- 尽量不要 try 整段代码块，也要避免使用异常控制代码流程；
- 不要掩盖 / 生吞异常，在抛出异常信息时避免泄漏敏感信息；
- 不要捕获类似 `Exception` 类的通用异常，而是应该捕获特定异常；
- 受检查异常被抛出后，往往不能被恢复，并且对函数式编程和三元表达式十分不友好；
- JDK 7 支持 multiple-catch 语法和基于 `java.lang.AutoCloseable` 接口的 try-with-resource 语法；
- 当程序未被中断时，finally 语句都会被正常执行，并且通常被用于清理系统资源。不应在 finally 语句中 return 方法的执行结果，因为这会导致异常信息的丢失。

---

## 谈谈 final、finally、finalize 有什么不同

final 关键字可以用于修饰变量、方法、类，并且在不同场景下的 final 关键字的语义不尽相同。当 final 修饰成员变量 / 局部变量 / 方法参数时，表示该变量的引用是不能被修改的；当 final 修饰方法时，表示该方法是不能被重写的；当 final 修饰类时，表示该类是不能被继承的。

需要注意的是，使用 final 修饰引用类型的变量时，并不代表此变量具有 [Immutable](https://en.wikipedia.org/wiki/Immutable_object) 的特性。例如在 `final List<String> list = new ArrayList<>()` 示例代码中，final 仅能保证 list 变量无法再次被赋值，而不能保证 list 的内容不被修改。

很多类似使用 final 可以提高性能的结论，都是基于假设得出的。实际上， JVM 对于 final 的优化，是和它的实现细节密切相关。在日常开发中，建议不要指望使用这些小技巧，来获得所谓的性能上的提升。关于这点，可以参阅 RednaxelaFX 在知乎上的相关回答：[final 修饰递归方法会提高效率吗？](https://www.zhihu.com/question/66083114/answer/242241071)、[JVM 对于声明为 final 的局部变量做了哪些性能优化？](https://www.zhihu.com/question/21762917/answer/19239387)

finally 关键字是在 try-finally 或 try-catch-finally 语句块中，保证 Java 代码必须被执行的一种机制。另外，若在 finally 语句块中需要关闭实现了 `java.lang.AutoCloseable` 接口的资源，则可以使用 JDK 7 中提供的 try-with-resource 语法简化代码。

需要额外注意的是，以下这段示例代码的 finally 语句块并不会被执行：

```java
try {
    // do something
    System.exit(1);
} finally {
    System.out.println("Print from finally");
}
```

finalize() 是基础类 `java.lang.Object` 的一个方法，它的设计目的在于保证对象被垃圾收集之前，完成特定资源的回收。然而 JVM 在垃圾收集时，需要对实现了 finalize() 的对象进行特殊处理，并且通过 finalize() 的实现方式都可以通过 try-finally 更好、更及时地实现。所以 finalize() 本质上已经成为了垃圾收集的阻碍者，它可能导致对象需要经过多轮垃圾收集周期才能被回收。现在，finalize 机制已经不被推荐使用，并且在 JDK 9 中被标记为 `@Deprecated`。

关于 JVM 对实现 finalize() 对象的特殊处理，可见[《深入理解 Java 虚拟机》](https://book.douban.com/subject/24722612/) 的 3.2.4 章节：

> 即使在可达性分析算法中的不可达的对象，也并非是「非死不可」的，这时候它们暂时处于「缓行」阶段。要真正宣告一个对象死亡，至少要经历两次标记过程：如果对象在进行可达性分析后发现没有与 GC Roots 相连接的引用链，那它将会被第一次标记并且进行一次筛选，筛选的条件是此对象是否有必要执行 finalize() 方法。当对象没有覆盖 finalize() 方法，或者 finalize() 方法已经被虚拟机调用过，虚拟机将这两个情况都视为「没有必要执行」。
>
> 如果这个对象被判定为有必要执行 finalize() 方法，那么这个对象将会被放置在一个叫做 F-Queue 的队列之中，并在稍后被一个由虚拟机自动建立的、低优先级的 Finalizer 线程去执行它。

---

## 强引用、软引用、弱引用、虚引用有什么区别

这个问题，可以在[《深入理解 Java 虚拟机》](https://book.douban.com/subject/24722612/) 的 3.2.3 章节中找到答案：

> 无论是通过 [引用计数算法（Reference Counting）](https://en.wikipedia.org/wiki/Reference_counting) 判断对象的引用数量，还是通过 [可达性分析算法（Tracing Garbage Collection）](https://en.wikipedia.org/wiki/Tracing_garbage_collection) 判断对象的引用链是否可达，判断对象是否存活都与「引用」有关。在 JDK 1.2 以前，Java 中的引用定义很传统：如果 reference 类型的数据中存储的数值代表的是另一块内存的起始地址，就称这块内存地址代表着一个引用。在 JDK 1.2 之后，Java 对引用的概念进行了扩充，将引用分为强引用（Strong Reference）、软引用（Soft Reference）、弱引用（Weak Reference）、虚引用（Phantom Reference）四种，这四种引用强度依次逐渐减弱。
>
> - 强引用就是指程序代码之中普遍存在的，类似 `Object obj = new Object()` 这类的引用。只要强引用还存在，垃圾收集器就永远不会回收被引用的对象。
> - 软引用是用来描述一些还有用但并非必需的对象。对于软引用关联着的对象，在系统将要发生内存溢出异常之前，将会把这些对象列进回收范围之中，进行第二次回收。如果这次回收还没有足够的内存，才会抛出内存溢出异常。
> - 弱引用也是用来描述非必需的对象，但是它的强度比软引用更弱一些，被弱引用关联的对象只能生存到下一次垃圾收集发生之前。当垃圾收集器工作时，无论当前内存是否足够，都会回收掉只被弱引用关联的对象。
> - 虚引用也称为幽灵引用或幻影引用，是最弱的一种引用关系。一个对象是否有虚引用的存在，完全不会对其生存时间构成影响，也无法通过虚引用来取得一个对象实例。为一个对象设置虚引用关联的唯一目的，就是能在这个对象被垃圾收集器回收时，收到一个系统通知。

软引用可以用来实现内存敏感的缓存机制，弱引用可以用来实现没有强制约束的关联关系。不同引用类型的应用案例有：

- `ThreadLocal.ThreadLocalMap` 使用弱引用存储 `ThreadLocal` 实例；
- `WeakCache<K, P, V>` 使用弱引用存储 Key 和 Value，使用强引用存储 SubKey；
- `com.google.common.cache.LocalCache` 支持使用软引用和弱引用的缓存失效策略，详情可参见 [文档](https://github.com/google/guava/wiki/CachesExplained#reference-based-eviction)。

---

## String、StringBuffer、StringBuilder 有什么区别

---

## 动态代理是基于什么原理

---

## int 和 Integer 有什么区别

---

## 对比 Vector、ArrayList、LinkedList 有什么区别

---

## 对比 Hashtable、HashMap、TreeMap 有什么区别

---

## 如何保证集合是线程安全的，ConcurrentHashMap 如何实现高效的线程安全

---

## Java 提供了哪些 IO 方式，NIO 如何实现多路复用

---

## Java 有几种文件拷贝方式，哪一种高效

---

## 谈谈接口和抽象类有什么区别

---

## 谈谈你知道的设计模式

---

## synchronized 和 ReentrantLock 有什么区别

---

## synchronized 底层如何实现，什么是锁的升级、降级

---

## 一个线程调用两次 start() 方法会出现什么情况

会抛出 `java.lang.IllegalThreadStateException` 异常。

---

## 什么情况下 Java 程序会产生死锁，如何定位、修复

在现代计算中，[死锁](https://en.wikipedia.org/wiki/Deadlock) 是一种特定的程序运行状态。当两个以上的运算单元（线程或进程），双方都在等待对方停止运行，以获取系统资源，但却没有一方提前退出时，就称为死锁。如下示例代码将会产生死锁问题：

```java
public static void main(String[] args) {
    Object lock1 = new Object();
    Object lock2 = new Object();

    new Thread(() -> { // 持有 lock1，等待 lock2
        synchronized (lock1) {
            try {
                TimeUnit.SECONDS.sleep(1);
            } catch (InterruptedException e) {
                e.printStackTrace();
            }
            synchronized (lock2) {
            }
        }
    }, "run1").start();

    new Thread(() -> { // 持有 lock2，等待 lock1
        synchronized (lock2) {
            try {
                TimeUnit.SECONDS.sleep(1);
            } catch (InterruptedException e) {
                e.printStackTrace();
            }
            synchronized (lock1) {
            }
        }
    }, "run2").start();
}
```

程序发生死锁时，可以借助 JDK 自带的 jstack 命令，分析线程的栈信息来排查和定位。具体思路是：区分线程状态 -> 查找 `BLOCKED` 状态的线程 -> 分析各个线程的 monitor 状态。以下是上例死锁程序的 jstack 输出：

```
Found one Java-level deadlock:
=============================
"run2":
  waiting to lock monitor 0x00007fc8f98204a8 (object 0x00000007957151e8, a java.lang.Object),
  which is held by "run1"
"run1":
  waiting to lock monitor 0x00007fc8f981dcc8 (object 0x00000007957151f8, a java.lang.Object),
  which is held by "run2"

Java stack information for the threads listed above:
===================================================
"run2":
	at priv.mm.thread.Deadlock.lambda$main$1(Deadlock.java:38)
	- waiting to lock <0x00000007957151e8> (a java.lang.Object)
	- locked <0x00000007957151f8> (a java.lang.Object)
	at priv.mm.thread.Deadlock$$Lambda$2/1389133897.run(Unknown Source)
	at java.lang.Thread.run(Thread.java:748)
"run1":
	at priv.mm.thread.Deadlock.lambda$main$0(Deadlock.java:25)
	- waiting to lock <0x00000007957151f8> (a java.lang.Object)
	- locked <0x00000007957151e8> (a java.lang.Object)
	at priv.mm.thread.Deadlock$$Lambda$1/317574433.run(Unknown Source)
	at java.lang.Thread.run(Thread.java:748)

Found 1 deadlock.
```

程序的死锁问题在大多数情况下都无法在线解决，通常只能重启应用，修正代码逻辑。

---

## Java 并发包提供了哪些并发工具

阅读 `java.util.concurrent` 的 [JavaDoc 文档](https://docs.oracle.com/javase/10/docs/api/java/util/concurrent/package-summary.html) 可以总结得出该包下提供的并发工具有：

- Executors
  - ThreadPoolExecutor
  - ScheduledThreadPoolExecutor
  - ForkJoinPool
- Queues
  - ConcurrentLinkedQueue
  - ConcurrentLinkedDeque
  - BlockingQueue
    - LinkedBlockingQueue
    - ArrayBlockingQueue
    - SynchronousQueue
    - PriorityBlockingQueue
    - DelayQueue
- Timing
- Synchronizers
  - Semaphore
  - CountDownLatch
  - CyclicBarrier
  - Phaser
  - Exchanger
- Concurrent Collections
  - ConcurrentHashMap
  - ConcurrentSkipListMap
  - ConcurrentSkipListSet
  - CopyOnWriteArrayList
  - CopyOnWriteArraySet

---

## 并发包中的 ConcurrentLinkedQueue 和 LinkedBlockingQueue 有什么区别

---

## Java 并发类库提供的线程池有哪几种，分别有什么特点

---

## AtomicInteger 底层实现原理是什么，如何在自己的产品代码中应用 CAS 操作

---

## 请介绍类加载过程，什么是双亲委派模型

---

## 有哪些方法可以在运行时动态生成一个 Java 类

---

## 谈谈 JVM 内存区域的划分，哪些区域可能发生 OOM

---

## 如何监控和诊断 JVM 堆内和对外内存使用情况

---

## Java 常见的垃圾收集器有哪些

---

## 谈谈你的 GC 调优思路

---

## Java 内存模型中的 Happen-Before 是什么
