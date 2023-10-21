---
title: "这个博客的构建和部署"
date: 2020-04-08T00:03:00+08:00
categories: ["闲聊"]
tags: ["Free Talk"]
keywords: ["个人博客", "搭建博客", "Hugo", "Hugo-Coder"]
---

最近几天打理了荒废很久的博客，从原先的 Hexo 迁移到了 Hugo，添加了 RSS、CDN 以及其它乱七八糟的功能，顺带还给这个博客主题提交了一个 SEO 优化相关的 [Pull Requests](https://github.com/luizdepra/hugo-coder/pull/300)。<!--more-->

整个博客迁移的过程费了挺多时间和精力，所以决定还是写一篇文章，主要记录这个博客构建和部署过程中的一些个性化配置相关内容。

---

## 概览

这个博客是以 Markdown 编写的，使用 Hugo 构建并且部署在 Github Pages 上，整个站点的运行架构如下：

![image](/images/build-and-deploy-of-this-blog/blog-architecture.png)

---

## 配置

在使用 Hugo 构建博客的静态资源时，主要有以下个性化配置：

- 支持原始 HTML 标签

  Hugo 在 0.60 版本之后默认使用 [Goldmark](https://github.com/yuin/goldmark/) 来解析 Markdown，这个组件默认不会渲染 Markdown 中的原始 HTML 标签，所以需要显式开启该功能。

  {{< emgithub url="https://github.com/fantasticmao/fantasticmao.github.io/blob/master/config.toml#L18-L21" >}}

- 配置 URL 风格

  为了兼容博客在 Hexo 时期已经被搜索引擎收录的 URL，所以配置了 `/:year/:month/:day/:filename/` 格式的 URL 风格。

  {{< emgithub url="https://github.com/fantasticmao/fantasticmao.github.io/blob/master/config.toml#L15-L16" >}}

- publishDir

  站点被托管于 GitHub Pages 仓库的 master 分支的 `/docs` 目录下，所以需要将生成静态资源的目录从默认的 `/public` 显式配置为 `/docs`。

  {{< emgithub url="https://github.com/fantasticmao/fantasticmao.github.io/blob/master/config.toml#L9" >}}

- 定制 footer.html

  需要按 [又拍云联盟](https://www.upyun.com/league) 和信息产业部的要求调整 footer 内容，所以编写了一个 [footer.html](https://github.com/fantasticmao/blog/blob/master/layouts/partials/footer.html) 页面，做了如下改动。

  {{< emgithub url="https://github.com/fantasticmao/fantasticmao.github.io/blob/master/layouts/partials/footer.html#L11-L16" >}}

  {{< emgithub url="https://github.com/fantasticmao/fantasticmao.github.io/blob/master/layouts/partials/footer.html#L20-L22" >}}

- RSS、Google Analytics

  Hugo 默认开启 RSS 功能，并且内置支持 Google Analytics，直接配置 GA 中的 Tracking ID 即可启用。

  {{< emgithub url="https://github.com/fantasticmao/fantasticmao.github.io/blob/master/config.toml#L13" >}}

- utterances

  评论系统选择使用 [utterances](https://utteranc.es/)，而不是 Hugo 内置支持的 Disqus。utterances 可以直接使用 GitHub 账号进行评论，相比 Disqus 更加方便一些。在 Hugo-Coder 主题中集成 utterances 也很方便，仅需几行配置即可。

  {{< emgithub url="https://github.com/fantasticmao/fantasticmao.github.io/blob/master/config.toml#L41-45" >}}

- Shortcodes

  为了更好的用户体验，编写了一些 [Hugo Shortcodes](https://github.com/fantasticmao/fantasticmao.github.io/tree/master/layouts/shortcodes)，用于展示哔哩哔哩中的视频，以及 [codepen](https://codepen.io/) 和 [emgithub](https://emgithub.com/) 中的示例代码。

---

## 部署

使用 GitHub Pages 部署站点的详细方式可以参考官方文档 [About GitHub Pages](https://docs.github.com/en/pages/getting-started-with-github-pages/about-github-pages)，这个博客选择的方式是将静态文件托管在 `<username>.github.io` 仓库的 `/docs` 目录下。

最终在部署博客时，需要先使用 `rm -rf ./docs/` 命令清空资源目录，再使用 `hugo` 命令构建站点，最后使用 `git push origin master` 命令部署至 GitHub Pages。这一系列命令对应的 Shell Script 是 [deploy.sh](https://github.com/fantasticmao/blog/blob/master/deploy.sh)，是我参考 Hugo 官方文档改写的。

在部署博客至 GitHub Pages 成功，并且可以通过 fantasticmao.github.io 域名访问之后，还需要在又拍云控制台中配置 CDN 服务的加速域名和回源地址。一言概之，就是需要在 DNS 服务商中将 blog.fantasticmao.cn 域名解析至又拍云 CDN 服务中提供的 CNAME，随后需要在又拍云控制台中配置 CDN 服务的回源地址为 fantasticmao.github.io，详细内容可以参考又拍云的 [帮助文档](https://help.upyun.com/knowledge-base/cdn-create-service/)。**需要注意的是，在又拍云控制台中配置回源地址时，需要额外配置回源 Host，否则访问站点会显示 404。**

---

## SEO

博客部署成功之后，还需要在百度和 Google 两大中文 / 英文搜索引擎中提交站点，便于用户根据关键字搜索。

百度需要在它的 [资源搜索平台](https://ziyuan.baidu.com/) 中提交站点，可以通过 DNS CNAME 解析的方式验证站点拥有权。

Google 需要在它的 [Google Search Console](https://search.google.com/search-console) 中提交站点，可以通过 DNS TXT 解析的方式验证站点拥有权。
