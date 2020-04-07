---
title: "IntelliJ IDEA 插件开发"
date: 2019-05-19T23:25:08+08:00
categories: ["编程"]
tags: ["Java", "IntelliJ IDEA"]
draft: true
---

前阵子有个比较火的 [杨超越杯编程大赛](https://github.com/ccyyycy/ycy)，我参加并开发了一个 IntelliJ IDEA 的小插件，插件名字叫做 [超越鼓励师](https://github.com/FantasticMao/ycy-intellij-plugin)，现在已经发布到 [JetBrains Plugin Repository](https://plugins.jetbrains.com/plugin/12204-programmer-motivator-chaoyue-yang----) 上，至今也有 6k 的下载量了。<!-- more -->

在插件开发期间，我翻阅过 [官方文档](https://www.jetbrains.org/intellij/sdk/docs/intro/welcome.html)、浏览过 [讨论社区](https://intellij-support.jetbrains.com/hc/en-us/community/topics/200366979-IntelliJ-IDEA-Open-API-and-Plugin-Development)、Google 过不少资料，觉得 IntelliJ IDEA Open API 的相关资料十分匮乏和不齐全：官方文档不够完善，英文资料不多，中文资料则更是少。以至于，自己想实现一个官方文档上没有提及的功能（例如实现一个 _Preferences_ 中的配置界面），需要在 GitHub 上查找和借鉴其它插件的已有实现方式（如果碰巧有的话），并且需要深入查看 SDK 源码，否则便是完全地无从下手。

现在插件开发算是告一段落，我就来捋捋和记录一下这段时间所学习的 IntelliJ IDEA 插件开发相关概念和一些 API。

---
