---
title: "Spring Framework IoC 模块设计"
date: 2020-07-30T09:53:00+08:00
categories: ["编程"]
tags: ["Java", "Spring-Framework"]
draft: true
---

## 概念：IoC 和 DI

IoC（Inversion of Control）和 DI（Dependency Injection）从不同角度描述了 **对象定义其依赖关系** 这件事情。

// 定义

举例来说，下例中的 `public class A` 定义了一个字段 `private B b` 和一个构造方法 `public A(B b)`，此时 A 对象依赖了 B 对象，并且在 A 对象中设置 B 对象的方式是使用构造方法。在传统开发过程中，开发者会使用 `A a = new A(b)` 语句来创建 A 对象，这样便是直接定义 A 对象的依赖关系（A 对象依赖了 B 对象）。在 IoC 倡导的设计原则下，A 对象中的依赖关系是在 IoC 容器来定义的（即控制反转），并且 A 对象的依赖是由 IoC 容器来注入的（即依赖注入）。

```java
public class A {
    private B b;

    public A(B b) {
        this.b = b;
    }
}
```

## Spring IoC 容器

在 Spring Framework 在 `org.springframework.beans` 和 `org.springframework.context` 两个包中提供了 IoC 容器的基本实现。

## Spring IoC Bean

### Bean Definition

### Bean 依赖关系

### Bean 作用域

### Bean 生命周期

## Spring IoC 扩展点

### BeanPostProcessor

- ApplicationContextAwareProcessor
- CommonAnnotationBeanPostProcessor

### BeanFactoryPostProcessor

- PropertySourcesPlaceholderConfigurer

### FactoryBean

## Environment

### @Profile

### PropertySource

## 源码走读：ApplicationContext 初始化和获取 Bean

- BeanFactory
- ApplicationContext

- BeanDefinition
- DefaultListableBeanFactory
