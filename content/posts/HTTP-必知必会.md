---
title: "HTTP 必知必会"
date: 2017-12-15T22:36:26+08:00
categories: ["网络基础"]
tags: ["HTTP"]
draft: true
---

摘自[《图解 HTTP》](https://book.douban.com/subject/25863515/)，并参考自维基百科与各系列 RFC。<!-- more -->

为了避免阅读歧义，本篇博客中术语「请求」、「响应」、「连接」会均用英文术语 `Request`、`Response`、`Connection` 表达。

---

# 协议概述

## 发展历史

1989 年，[Tim Berners-Lee](https://en.wikipedia.org/wiki/Tim_Berners-Lee) 和他的团队在 [CERN](https://en.wikipedia.org/wiki/CERN)（European Organization for Nuclear Research，欧洲核子研究中心）发明了 HTTP 和 HTML，以及相关 web 服务器与 web 浏览器的技术。同年，他首次提出了 World Wide Web 项目，也就是现在众所周知的万维网。

1991 年，HTTP 协议的第一个版本 HTTP/0.9 发布。这个版本仅有一个 GET 方法，客户端向服务端请求网页，服务端响应且仅能响应 HTML 页面给客户端。

1995 年，[Dave Raggett](https://en.wikipedia.org/wiki/Dave_Raggett) 领导了 HTTP 工作组，他希望通过扩展操作、扩展协商、提供更丰富的元信息等手段来扩展 HTTP 协议，并且希望通过添加额外的方法和首部字段来与更加高效的安全协议绑定。

1995 年 12 月，HTTP 工作组本计划发布协议的新标准，但并未发布。

1996 年，[RFC-1945](https://tools.ietf.org/html/rfc1945) 正式发布，并且认可了 HTTP/1.0。

1996 年初，HTTP/1.1 的预标准已经被各大主流的浏览器迅速支持。截止 1996 年 3 月，HTTP/1.1 的预标准已经被 Arena、Netscape 2.0、Netscape Navigator Gold 2.01、Mosaic 2.7、Lynx 2.5、Internet Explorer 2.0 所支持，并且用户使用新浏览器访问网页的速度非常快。在 1996 年 3 月，当时的一家网络公司报告称，因特网上超过 40% 的浏览器已经兼容 HTTP/1.1，并且截止同年 6 月，超过 65% 的浏览器已经兼容 HTTP/1.1。

1997 年 1 月，HTTP/1.1 正式发布为 [RFC-2068](https://tools.ietf.org/html/rfc2068)。

1999 年 6 月，HTTP/1.1 的改进和更新版发布为 [RFC-2616](https://tools.ietf.org/html/rfc2616)。

2007 年，HTTPbis 工作组成立，旨在修正和简化 HTTP/1.1 规范。

2014 年 6 月，HTTP 工作组发布并更新了 HTTP/1.1 的六份规范：

- [RFC-7230](https://tools.ietf.org/html/rfc7230) Hypertext Transfer Protocol (HTTP/1.1): Message Syntax and Routing
- [RFC-7231](https://tools.ietf.org/html/rfc7231) Hypertext Transfer Protocol (HTTP/1.1): Semantics and Content
- [RFC-7232](https://tools.ietf.org/html/rfc7232) Hypertext Transfer Protocol (HTTP/1.1): Conditional Requests
- [RFC-7233](https://tools.ietf.org/html/rfc7233) Hypertext Transfer Protocol (HTTP/1.1): Range Requests
- [RFC-7234](https://tools.ietf.org/html/rfc7234) Hypertext Transfer Protocol (HTTP/1.1): Caching
- [RFC-7235](https://tools.ietf.org/html/rfc7235) Hypertext Transfer Protocol (HTTP/1.1): Authentication

2015 年 5 月，HTTP/2 正式发布为 [RFC-7540](https://tools.ietf.org/html/rfc7540)。<!-- https://tools.ietf.org/html/rfc7230#page-78 -->

---

## 术语解释

> HTTP is a stateless request/response protocol that operates by exchanging messages across a reliable transport- or session-layer "connection".

HTTP 是一个无状态的 `Request`／`Response` 机制的协议，通过在传输层或会话层的可靠的 `Connection` 之间交换信息来工作的。

> An HTTP "client" is a program that establishes a connection to a server for the purpose of sending one or more HTTP requests. An HTTP "server" is a program that accepts connections in order to service HTTP requests by sending HTTP responses.

HTTP 客户端是为了发送一个或多个 `Request`，而与服务端建立 `Connection` 的程序。HTTP 服务端是为了以发送 `Response` 来服务 `Request`，而接受客户端发起 `Connection` 的程序。

> The terms "client" and "server" refer only to the roles that these programs perform for a particular connection. The same program might act as a client on some connections and a server on others.

Client and Server：术语「客户端」和「服务端」仅指程序在特定 `Connection` 上执行的角色。同一个程序可能在一个 `Connection` 上作为客户端，而在另一个 `Connection` 上作为服务端。

> The term "user agent" refers to any of the various client programs that initiate a request, including (but not limited to) browsers, spiders (web-based robots), command-line tools, custom applications, and mobile apps.

User Agent：术语「用户代理」指任意可以发起 `Request` 的客户端程序，包括但不限于浏览器、网络爬虫、命令行工具、定制应用、移动应用（App）。

> The term "origin server" refers to the program that can originate authoritative responses for a given target resource.

Origin Server：术语「源服务器」指可以为给定的目标资源作出原始性的权威性的 `Response` 的程序。

> The terms "upstream" and "downstream" are used to describe directional requirements in relation to the message flow: all messages flow from upstream to downstream.

Upstream and Downstream：术语「上游」和「下游」是用于描述关于信息流动的方向说明：所有的信息都从上游流向下游。

> The terms "inbound" and "outbound" are used to describe directional requirements in relation to the request route: "inbound" means toward the origin server and "outbound" means toward the user agent.

Inbound and Outbound：术语「入站」和「出站」是用于描述关于请求路由的方向说明：入站是指朝向源服务器，出站是指朝向用户代理。

> A "proxy" is a message-forwarding agent that is selected by the client, usually via local configuration rules, to receive requests for some type(s) of absolute URI and attempt to satisfy those requests via translation through the HTTP interface.

Proxy：「代理」是客户端通常以本地的配置规则，而选择的信息转发中介，用于接收一些绝对 URI 类型的请求，并且尝试通转译 HTTP 接口来满足这些请求。

> A "gateway" (a.k.a. "reverse proxy") is an intermediary that acts as an origin server for the outbound connection but translates received requests and forwards them inbound to another server or servers.

Gateway：「网关」（又称「反向代理」）是一个作为源服务器出站连接的中介，但也会转译接收到的请求，并将它们转发入站到其它一台或多台服务器。

> A "tunnel" acts as a blind relay between two connections without changing the messages.

Tunnel：「隧道」是两个连接之间的隐蔽中转（blind relay），并且不改变其中的任何信息。

> A "cache" is a local store of previous response messages and the subsystem that controls its message storage, retrieval, and deletion. A cache stores cacheable responses in order to reduce the response time and network bandwidth consumption on future, equivalent requests.

Cache：「缓存」是一份之前 `Response` 信息的本地存储，和其控制信息存储、检索、删除的子系统。缓存会存储可缓存的 `Responses`，为了减少后续等效的 `Requests` 的响应时间和网络带宽消耗。

---

## 报文简析

![image](/images/HTTP必知必会/1.png)

Common Method Properties: Safe Methods、Idempotent Methods、Cacheable Methods

Message Body: Transfer-Encoding、Content-Length、Message Body Length

推荐阅读：

- [RFC-7230#page-19](https://tools.ietf.org/html/rfc7230#page-19) Message Format
- [RFC-7231#page-21](https://tools.ietf.org/html/rfc7231#page-21) Request Methods
- [RFC-7231#page-33](https://tools.ietf.org/html/rfc7231#page-33) Request Header Fields
- [RFC-7231#page-47](https://tools.ietf.org/html/rfc7231#page-47) Response Status Codes
- [RFC-7231#page-64](https://tools.ietf.org/html/rfc7231#page-64) Response Header Fields

---

# 实现机制

## 无状态和 Cookie

HTTP 是一种不保存状态，即无状态（stateless）的协议。HTTP 协议自身不对 `Request` 和 `Response` 之间的通信状态进行保存。也就是说在 HTTP 协议这个级别，网络通讯过程中对于任何发送的 `Request` 或 `Response` 都不会做持久化处理。这是为了更快地处理大量事务，确保协议的可伸缩性，而特意把 HTTP 协议设计成如此简单。

随着 Web 的不断发展，因无状态而导致业务处理变得棘手的情况增多了。HTTP 协议为了实现期望保持状态的功能，于是引入了 Cookie 技术。

[Cookie](https://en.wikipedia.org/wiki/HTTP_cookie) 技术通过在 `Request` 和 `Response` 报文中写入 Cookie 信息来控制客户端的状态。它会根据从服务端发送的 `Response` 报文内的一个叫做 `Set-Cookie` 的首部字段，通知客户端保存 Cookie 值。当下次客户端再往该服务端发送 `Request` 时，客户端会自动在报文中加入 Cookie 值后发送出去。此时，服务端发现客户端发送过来的 Cookie 值后，会去检查究竟是从哪一个客户端发来的，然后对比服务端上的记录，最后得到请求之前的状态信息。

Wireshark 抓包示意图：

![image](/images/HTTP必知必会/Cookie.png)

---

## HTTP 内容协商

一个 [URI](https://en.wikipedia.org/wiki/Uniform_Resource_Identifier) 可能对应多种不同表现形式的资源，例如不同的语言、不同的编码、不同的媒体类型。[HTTP 内容协商](https://en.wikipedia.org/wiki/Content_negotiation)（HTTP content negotiation）机制允许对同一个 URI 提供多个不同版本的资源，以便客户端能指定和获取最适合它们的版本资源。HTTP 协议提供了以下几种不同的内容协商机制：`server-driven`、`agent-driven`、`transparent`、其它混合的组合。

server-driven：服务端驱动（或称主动）内容协商是根据在服务端上执行的算法来选择资源的最合适的表现形式。这通常是基于客户端所提供的可接受标准来执行的。具体来说，当客户端向服务端发送 `Request` 时，在请求首部的 `Accept` 系列字段中给出可接受的媒体类型和相关的质量因素，而服务端则按照客户端所提供的这些参数，选择其最合适的资源版本返回 `Response`。

Wireshark 抓包示意图：

![image](/images/HTTP必知必会/HTTP-content-negotiation.png)

agent-driven：用户代理驱动（或称被动）内容协商是根据在客户端上执行的算法来选择资源的最合适的表现形式。这通常是基于服务端所提供的资源的表现形式列表和元数据，以此来执行的。

其它内容协商机制：略。

---

## HTTP 持久连接

在 HTTP 协议的初始版本中，每进行一次 HTTP 通信就要建立和断开一次 TCP `Connection`，这样频繁地建立和断开无谓的 TCP `Connection` 会增加网络通信的开销，于是 HTTP/1.1 提出了 [HTTP 持久连接](https://en.wikipedia.org/wiki/HTTP_persistent_connection)（HTTP persistent connection，也称作 HTTP keep-alive 或 HTTP connection reuse）机制。它可以使用同一个 `Connection` 来发送多个 `Request` 和接收多个 `Response`，而不是为每一个新的 `Request` 或 `Response` 都打开新的 `Connection`。

在 HTTP/1.0 中，没有官方的 keep-alive 操作。为了实现持久连接，通常的操作是在现有版本的协议上添加一个标记。比如，如果浏览器支持的话，它会在请求首部字段中添加 `Connection: Keep-Alive`，然后当服务端接收到 `Request` 并返回 `Response` 的时候，则会在响应首部字段中添加 `Connection: Keep-Alive`。这样做，HTTP 就不会中断 TCP `Connection`，然后当客户端发送另一个 `Request` 时，HTTP 就会使用同一个 TCP `Connection`。这种情况会一直持续到客户端或服务端的任意一方，在明确提出断开连接之后终止。

在 HTTP/1.1 中，所有的连接默认都是持久连接，除非特殊声明不支持。

使用多个连接和使用持久连接的对比图（图片来源自维基百科）：

![image](https://upload.wikimedia.org/wikipedia/commons/thumb/d/d5/HTTP_persistent_connection.svg/450px-HTTP_persistent_connection.svg.png)

Wireshark 抓包示意图：

![image](/images/HTTP必知必会/HTTP-persistent-connection-1.png)

![image](/images/HTTP必知必会/HTTP-persistent-connection-2.png)

---

## HTTP 管线化

HTTP 持久连接使多个请求以管线化的方式发送成为可能。[HTTP 管线化](https://en.wikipedia.org/wiki/HTTP_pipelining)（HTTP pipelining）可以在单个 TCP `Connection` 上并行发送多个客户端的 `Request`，且不需要在发送过程中等待服务端的 `Response`。管线化机制可以提升动态加载 HTML 页面的速度，特别是在高延迟的网络环境下，如连接卫星的网络环境。但对于正常宽带连接的网络环境，提升效果却不是很明显。因为对于客户端并行发送的网络请求，服务端还是需要以相同的顺序响应，这就有可能造成了 HOL blocking（Head-of-line blocking，队头阻塞）。

非幂等性的请求，如 POST 请求，不应该被管线化。GET 和 HEAD 请求在任何情况下都可以被管线化。其它幂等性的请求，如 PUT 和 DELETE 请求，取决于当前请求是否依赖其它请求，来决定其是否可以被管线化。

HTTP 管线化需要客户端和服务端的同时支持。虽然使用 HTTP/1.1 协议可以确认服务端是支持管线化机制的，但这并不意味着服务端必须返回管线化的结果。如果客户端选择了非管线化的 `Request`，服务端则会正常返回非管线化的 `Response`。

使用非管线化和管线化的对比图（图片来源自维基百科）：

![image](https://upload.wikimedia.org/wikipedia/commons/thumb/1/19/HTTP_pipelining2.svg/640px-HTTP_pipelining2.svg.png)

Wireshark 抓包示意图：

![image](/images/HTTP必知必会/HTTP-pipelining.png)

PS：在理想情况下，HTTP 响应报文是作为整包且有序地发送给客户端的，并且服务端会在响应报文中使用 `Content-Length` 首部字段标志响应实体的长度，因此客户端可以依据 `Content-Length` 值来计算当前响应实体的结束和下一个响应实体的开始。而使用 HTTP 持久连接和 HTTP 管线化，则会使客户端难以确认服务端返回的响应的先后顺序，以至于 `Content-Length` 无法被正常使用。为了解决这个问题，HTTP/1.1 引入了 [分块传输编码](#HTTP-分块传输编码)。它定义了一个 `last-chunk` 比特位，可以用来设置每一个响应的结束标识，客户端也由此可以得知每一个响应实体的结束状态了。

---

## HTTP 压缩

[HTTP 压缩](https://en.wikipedia.org/wiki/HTTP_compression)（HTTP compression） 是一种在客户端和服务端之间使用压缩算法传输内容的数据传输机制，它可以充分利用带宽，提升网络传输速率。

客户端在发送 `Request` 时，通过在请求首部中添加 `Accept-Encoding` 字段，告知服务端其所支持的压缩方式。服务端在返回 `Response` 时，通过在响应首部中添加 `Content-Encoding` 或 `Transfer-Encoding` 字段，告知客户端其所使用的压缩方式。常见的压缩方式，举例如下：

- gzip：基于 GNU zip 的压缩方式；
- deflate：基于 deflate 算法的压缩方式；
- compress：基于 UNIX compress 的压缩方式（不推荐大多数应用使用）；
- identity：默认值，不压缩内容；

Wireshark 抓包示意图：

![image](/images/HTTP必知必会/HTTP-compression.png)

---

## HTTP 分块传输编码

[HTTP 分块传输编码](https://en.wikipedia.org/wiki/Chunked_transfer_encoding)（HTTP Chunked transfer encoding）是一种允许服务端将 `Response` 数据分块传输给客户端的数据传输机制。在分块传输编码中，数据流被分成一系列不重叠的「数据块」，以字节为单位被发送，且彼此独立地被客户端接收。

在一次 HTTP `Response` 报文中，通过使用 `Transfer-Encoding:chunked` 指示当前 `Response` 是分块传输编码的，并以最终传输一个 0 字节的「数据块」为结束标识。

Wireshark 抓包示意图：

![image](/images/HTTP必知必会/HTTP-chunked-transfer-encoding.png)

---

## HTTP 缓存

[HTTP 缓存](https://en.wikipedia.org/wiki/Web_cache)（HTTP cache）是一种为了减少网络请求的带宽延迟，从而对页面进行临时存储的技术。通过缓存技术，可以使 `Request` 在满足特定条件的情况下，直接从缓存中获取 `Response` 信息，以此提升页面加载速度和减少对服务器的压力。HTTP 协议定义了三种控制缓存的基本机制：`freshness`、`validation`、`invalidation`。

freshness：机制允许一个 `Response` 在不需要源服务器重新校验的情况下，可以被直接用作于响应 `Request`，并且 `Response` 新鲜程度可以由客户端和服务端同时控制。例如，`Expires` 响应首部字段可以指定缓存的失效日期，`Cache-Control: max-age` 指令可以告知缓存的有效时间（单位为秒）。

Validation 机制用于校验一个被缓存的 `Response` 在过时之后，是否依旧有效。例如，如果响应首部中包含 `Last-Modified` 字段，那么则可以使用一个包含 `If-Modified-Since` 请求首部字段的 [条件请求](https://developer.mozilla.org/en-US/docs/Web/HTTP/Conditional_requests)（conditional request），来查看缓存是否已经被更新。除此之外还有 [ETag](https://en.wikipedia.org/wiki/HTTP_ETag)（entity tag）机制，它同时支持强校验和弱校验。

Invalidation 机制通常是针对使用缓存技术的副作用。例如，一个关联着缓存数据的 URL，若被以 PUT/POST/DELETE 方法请求了，那么其缓存数据就会失效。

Wireshark 抓包示意图：

![image](/images/HTTP必知必会/HTTP-cache.png)

更全面地了解 HTTP 条件请求，推荐阅读：[RFC 7232 - Hypertext Transfer Protocol (HTTP/1.1): Conditional Requests](https://tools.ietf.org/html/rfc7232)

更全面地了解 HTTP 缓存机制，推荐阅读：[RFC 7234 - Hypertext Transfer Protocol (HTTP/1.1): Caching](https://tools.ietf.org/html/rfc7234)。<!-- [浅谈浏览器http的缓存机制](http://www.cnblogs.com/vajoy/p/5341664.html) --> <!-- [What's the difference between Cache-Control: max-age=0 and no-cache?](https://stackoverflow.com/questions/1046966/whats-the-difference-between-cache-control-max-age-0-and-no-cache/1383359#1383359) -->

---

# 安全问题

## 被窃听

## 被伪装

## 被篡改

---

# 其它

## HTTPS

## HTTP2

## REST

## WebSocket
