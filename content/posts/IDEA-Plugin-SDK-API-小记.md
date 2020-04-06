---
title: "IDEA Plugin SDK API 小记"
date: 2019-05-19T23:25:08+08:00
categories: ["编程"]
tags: ["Java"]
draft: true
---

前阵子有个比较火的 [杨超越杯编程大赛](https://github.com/ccyyycy/ycy)，我参与并也开发了一个 IDEA 的小插件，插件名字叫做 [超越鼓励师](https://github.com/FantasticMao/ycy-intellij-plugin)。<!-- more -->

在技术调研和插件开发期间，我翻阅过 [官方文档](http://www.jetbrains.org/intellij/sdk/docs/welcome.html)，浏览过 [问答社区](https://intellij-support.jetbrains.com/hc/en-us/community/topics/200366979-IntelliJ-IDEA-Open-API-and-Plugin-Development)，Google 过相关资料，但依旧觉得 IDEA Plugin SDK API 的相关资料过于匮乏和不齐全，官方文档不够完善，英文资料也是不多，中文资料则是更少。想实现一个官方文档上没有提及的功能（例如实现一个 _Preferences_ 中的配置界面），需要深入查看 SDK 源码，或是借鉴其它插件的实现方式（如果碰巧有的话），否则就是一脸懵逼地完全无从下手。现在插件开发算是告一段落，插件上线至今也有 3k 的下载次数了，我就来捋捋和记录一下 IDEA 插件开发的相关知识。
