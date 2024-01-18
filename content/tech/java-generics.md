---
title: "Java 泛型的擦除"
date: 2017-01-02T20:12:26+08:00
categories: ["编程"]
tags: ["Java"]
---

本篇文章介绍 Java 的一个残缺实现，确切地说是 Java SE5 为向后兼容而采取的折中实现 —— 泛型，记录内容包括基本语法、通配符和边界、泛型擦除。<!--more-->

## 泛型简介

泛型程序设计是程序设计语言的一种风格或范式。泛型允许程序员在强类型程序设计语言中编写代码时使用一些以后才指定的类型，在实例化时作为参数指明这些类型。

Java 泛型的参数只可以代表类，不能代表个别对象。由于 Java 泛型的类型参数之实际类型在编译时会被消除，所以无法在运行时得知其类型参数的类型，而且无法直接使用基本值类型作为泛型类型参数。Java 编译程序在编译泛型时会自动加入类型转换的编码，故运行速度不会因为使用泛型而加快。—— 摘自 [维基百科](https://zh.wikipedia.org/wiki/%E6%B3%9B%E5%9E%8B)

一个泛型参数，也被称为一个类型变量，是用于指定一个泛型类型名称的标识符。 因为他们接受一个或多个参数，这些类被称为参数化的类或参数化的类型。—— 摘自 [菜鸟教程](http://www.runoob.com/java/java-generics.html)

我的简单理解：泛型在编程语言概念中是顾名思义的 **泛化的类型**，而在 Java 的实现中则是一个为了 **参数化类型** 的语法。它可以使我们编写更健壮更抽象的 Java 代码，但同时它因为存在缺陷而经常被人诟病。

## 基本语法

### 泛型类

定义泛型类时，需在类名后添加一个尖括号包裹的 **参数类型**，然后在实例化类时，需要使用 **具体类型** 替换 **参数类型**。在代码中 **参数类型** 代表的就是类实例化时的 **具体类型**，如下是一个泛型类：

```java
public class Generic<T> {
    private T t;

    public T getT() {
        return t;
    }

    public void setT(T t) {
        this.t = t;
    }
}
```

### 泛型接口

同上，泛型接口的定义与泛型类并没什么区别。

### 泛型方法

泛型类／接口对类型的泛化应用于整个类之上，而泛型方法则仅限于当前方法。《Java 编程思想》书中提供了一个编写泛型代码的基本原则：无论何时，只要你能做到，你就应该尽量使用泛型方法。这也意味着我们应该尽可能地缩小类型泛化的应用范围。

需要注意的一点是，泛型类对于 static 方法是无效的。因为 JVM 在加载类的 static 方法时，此时类还处于初始化状态，类的实例也还未创建，所以类的 static 方法自然也还无法得知类的实例的 **具体类型**。如下例中的类是无法通过编译的：

```java
public class GenericStaticMethod<T> {
    public static void foo(T t) {
        // error
    }
}
```

但泛型方法对于 static 方法是生效的，因为方法级别的 **参数类型** 与类的实例无关，static 方法获取 **具体类型** 也并不依赖于类的实例。定义泛型方法，只需将 **参数类型** 放置于方法返回值之前即可，如下是修改上例后的泛型方法：

```java
public class GenericStaticMethod {
    public static <T> void foo(T t) {
        // OK
    }
}
```

另外，当类中同时存在类级别和方法级别的 **参数类型** 时，此时方法中的参数代表的是泛型方法的 **具体类型**。例如，以下代码的输出结果是 `class java.lang.Integer`。

```java
public class GenericStaticMethod<T> {
    public static <T> void foo(T t) {
        System.out.println(t.getClass());
    }

    public static void main(String[] args) {
        new GenericStaticMethod<String>().foo(1);
    }
}
```

### 多个参数类型

泛型类／接口／方法均可以声明多个参数类型，如典型 key-value 结构的泛型类 Map：

```java
public interface Map<K,V> {
    V get(Object key);

    V put(K key, V value);
}
```

### 通配符和边界

在泛型中使用有界通配符可以指定泛型的参数类型转换的边界。

`<? extends T>` 表示一个属于 T 子类的未知类型，意味着 T 是 ? 的上界。

`<? super T>` 表示一个属于 T 超类的未知类型（包括 T），意味着 T 是 ? 的下界。

## 泛型擦除

Java 泛型是使用擦除来实现的，这意味着当在使用泛型时，类在运行时的任何 **具体类型** 信息都将被擦除。下面来具体说一说 Java 泛型的擦除。

### 擦除的实质

泛型机制可以使 **参数类型** 灵活地应用于多种 **具体类型**，也可以使编译器在编译期就能检查类型转换的正确性。但实际上，泛型代码在由编译器编译之后，存储于字节码中的 **参数类型** 并不是 **具体类型**，而只是一个 `java.lang.Object` 类型（不使用边界的情况下），因此 `List<Integer>` 在编译之后实际存储的只是 `List<Object>`，并且 `new ArrayList<Integer>().getClass() == new ArrayList<String>().getClass()` 的执行结果也会是 true。Java 泛型的缺陷也正如 [官方文档](https://docs.oracle.com/javase/tutorial/extra/generics/simple.html) 中所说的那样：

> It is misleading, because the declaration of a generic is never actually expanded in this way. There aren't multiple copies of the code--not in source, not in binary, not on disk and not in memory. If you are a C++ programmer, you'll understand that this is very different than a C++ template.

反编译例 [Generic 泛型类](#泛型类) 中的代码，可见结果如下图。这也证实了 Java 在字节码文件中存储泛型类的 **具体类型** 确实只是简单的 `java.lang.Object` 类型，也就意味着类在运行时的 **具体类型** 已经被擦除了。

![image](/images/java-generics/1.png)

由于擦除现象的存在，泛型代码在不指定边界的情况下，其类定义的 **参数类型** 在代码运行时只能被作为 `java.lang.Object` 使用，我们因此也无法使用反射获取 **具体类型** 的任何信息。

在 Java 泛型的具体实现中，编译器将会把泛型类在运行时的 `java.lang.Object` 类型转成编译期的 **具体类型**。Java 泛型的这种实现机制就好似 [Generic 泛型类](#泛型类) 代码是如下这样编写的：

```java
public class Generic<T> {
    private Object t;

    public T getT() {
        return (T) t;
    }

    public void setT(Object t) {
        this.t = t;
    }
}
```

### 如何弥补擦除

为了明确类在运行时的 **具体类型**，我们可以使用 Java 泛型的 [边界](#通配符和边界) 来指定擦除的边界。将 [Generic 泛型类](#泛型类) 的 **参数类型** 调整为 `<T extends Number>` 然后再次进行反编译，结果如下图。可见此时的 **参数类型** 在代码运行时确实仅被擦除到了 `java.lang.Number` 类型，我们也由此可以在泛型代码中调用 `java.lang.Number` 的所有属性和方法。

![image](/images/java-generics/2.png)

除此之外，我们还可以通过显示地传入 `java.lang.Class` 对象，结合使用反射来弥补一些泛型擦导致的缺陷。以及，数组类型的泛型定义可以通过 `List<T>` 来替换。如下所示：

```java
public class Erased<T> {
    private T t;

    // Bad Demo
    // public void foo() {
    //     boolean f = t instanceof Integer;  ok
    //     this.t = new T();                  error
    //     T[] array1 = new T[10];            error
    //     T[] array2 = (T[]) new Object[10]; unchecked cast
    // }

    public void foo(Class<T> clazz) throws Exception {
        boolean f = t instanceof Integer; // ok
        this.t = clazz.newInstance(); // ok
        List<T> array1 = new ArrayList<>(); // ok
    }
}
```

## 总结

泛型作为 Java SE5 才出现的特性，不仅必须向后兼容，还必须支持迁移兼容性。出于这一点考虑，Java 设计者们最终选择了采用擦除来实现泛型。也正是由于擦除，使得 Java 可以允许泛型代码和非泛型代码共存，能在不破坏现有类库的情况下，使非泛型的代码迁移到泛型的代码。

同时 Java 泛型的实现机制 —— 擦除 带来的缺陷也是显著的，它使我们无法在代码运行时获取它所定义的真正类型。不过，结合使用边界来弥补，它或许并没那么糟糕。正确地理解擦除，恰当地使用边界，泛型对于编写健壮的 Java 代码依旧具有非常重要的意义。
