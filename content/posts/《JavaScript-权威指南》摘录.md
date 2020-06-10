---
title: "《JavaScript 权威指南》摘录 —— jQuery 类库"
date: 2017-04-21T15:44:01+08:00
categories: ["编程"]
tags: ["JavaScript", "jQuery"]
keywords: ["JavaScript", "jQuery"]
---

摘自[《JavaScript 权威指南》](https://book.douban.com/subject/10549733/)第 19 章 jQuery 类库。

JavaScript 的核心 API 设计的很简单，但由于不同浏览器之间的严重不兼容，导致客户端的 API 过于复杂。使用 JavaScript 框架或工具类库能简化通用操作，能隐藏浏览器之间的差异，这让很多程序员在开发 Web 应用时变得更简单。撰写本书时，最流行和广泛采用的类库之一就是 jQuery。<!--more-->

---

## jQuery 基础

jQuery 类库定义了一个全局函数：`jQuery()`。该函数使用频繁，因此在类库中还给它定义了一个快捷别名：`$()`。这是 jQuery 在全局命名空间中定义的唯一两个变量。

在 jQuery 类库中，最重要的方法是 `jQuery()`，也就是 `$()`。它的功能很强大，有 4 中不同的调用方式：

1. 传递 CSS 选择器字符串给 `$()`。当通过这种方式调用时，`$()` 返回当前文档中匹配该选择器的元素集；
2. 传递一个 Element、Document 或 Window 对象给 `$()`。在这种情况下，`$()` 只须简单地将 Element、Document、Window 对象封装成 jQuery 对象并返回；
3. 传递 HTML 文本字符串给 `$()`。在这种调用方式下 jQuery 会根据传入的文本创建好 HTML 元素并封装成 jQuery 对象返回；
4. 传入一个函数给 `$()`。此时，文档加载完毕且 DOM 可操作时，传入的函数将被调用。

   ```javascript
   jQuery(function () {
     // 文档加载完毕时调用
     // 所有 jQuery 代码放在这里
   });
   ```

传递 CSS 选择器字符串给 `$()`，它返回的 jQuery 对象表示匹配该选择器的元素集。**jQuery 对象是类数组，它们拥有 length 属性和介于 0 - length - 1 之间的数值属性。这意味着可以使用标准的数组标识方括号来访问 jQuery 对象的内容**。如果不想把数组标识用在 jQuery 对象上，可以使用 `size()` 来替代 length 属性，用 `get()` 来替代方括号索引。可以使用 `toArray()` 将 jQuery 对象转化为真实数组。

除了 length 属性，jQuery 对象还有其它三个属性：selector 属性是创建 jQuery 对象时的选择器字符串。context 属性是上下文对象，是传递给 `$()` 的第二个参数，如果没有的话，默认是 Document 对象。jquery 属性值是 jQuery 版本号。

可以使用 `each()` 方法来代替 for 循环遍历 jQuery 对象中的所有元素。`each()` 还会将索引值和该元素作为第一个和第二个参数传递给回调函数。**与 `forEach()` 不同，`each()` 中，如果回调函数在任一个元素上返回 false，遍历将在该元素后中止**。jQuery 方法通常隐式遍历匹配的元素，并操作它们。

jQuery 的 `map()` 和 `Array.prototype.map()` 相近。它将接收回调函数作为参数，并为 jQuery 对象中的每一个元素都调用回调函数，同时将回调函数的返回值收集起来，并封装成一个新的 jQuery 对象返回。`map()` 调用回调函数的方式和 `each()` 相同：元素的索引值作为第一个参数，元素本身作为 this 和第二个参数。

jQuery 的另一个基础方法是 `index()`。该方法接收一个元素作为参数，返回值是该元素在 jQuery 对象中的索引值，如果找不到的话，返回 -1。如果传递一个 jQuery 对象作为参数，`index()` 会对该对象的第一个元素进行搜索。如果传入的是字符串，`index()` 会把它当成 CSS 选择器，并返回 jQuery 对象中匹配该选择器的一组元素中第一个元素的索引值。如果什么都不传入，`index()` 会返回该 jQuery 对象中的第一个毗（pí）邻元素的索引值。

还有一个通用的 jQuery 方法是 `is()`。它接收一个选择器作为参数，如果选中元素至少有一个匹配该选择器时，则返回 true。可以在 `each()` 回调函数中使用它，例如：

```javascript
$("div").each(function () {
  // 对于每一个 <div> 元素
  if ($(this).is(":hidden")) return; // 跳过隐藏元素
  // 对可见元素做点什么
});
```

---

## jQeury 的 getter 和 setter

jQuery 对象上最简单、最常见的操作是获取（get）或设置（set）HTML 属性、CSS 样式、元素内容和位置高宽的值。jQuery 中的 getter 和 setter：

- **jQuery 使用同一个方法即当 getter 用又当 setter 用，而不是定义一对方法**。如果传入一个新值给该方法，则它设置此值；如果没有指定值，则它返回当前值；
- 用作 setter 时，这些方法会给 jQuery 对象中的每一个元素设置值，然后返回该 jQuery 对象以便链式调用；
- 用作 setter 时，这些方法经常接收对象参数。在这种情况下，该对象的每个属性都需指定一个将要被设置的键值对；
- 用作 setter 时，这些方法经常接收函数参数。在这种情况下，会调用该函数来计算需要被设置的值。调用该函数传入的 this 值是对应的元素，第一个参数是该元素的索引值，第二个参数是该元素的当前值；
- 用作 getter 时，这些方法只会查询元素集中的第一个元素，返回单个值。如果需要遍历所有元素，请使用 `map()`。

### 获取和设置 HTML 属性

`attr()` 是 jQuery 中用于 HTML 属性的 getter / setter。`attr()` 处理浏览器的兼容性和一些特殊情况，还可以让 HTML 属性名和 JavaScript 属性名可以等同使用，如 "for" - "htmlfor"、"class" - "className"。一个相关的函数是 `removeAttr()`。例子：

```javascript
$('form').attr('action'); // 获取第一个 form 元素的 action 属性
$('#icon').attr('src', 'icon.gif'); // 设置 src 属性
$('#banner').attr({src:'banner.gif', alt:'Adverisement', width:720, height:64});
$('a').attr('target', '_blank'); // 使所有链接在新窗口中打开
$('a').attr('target', function () {
  if (this.host == locaction.host) return '_self';
  else return '_blank';
}); // 非站内链接在新窗口中打开
$('a').attr({target:function () {...}}); // 可以像这样传入函数
$('a').removeAttr('target'); // 让所有连接在本窗口中打开
```

### 获取和设置 CSS 属性

`css()` 和 `attr()` 很类似，只是 `css()` 作用于元素的 CSS 样式，而不是元素的 HTML 属性。`css()` 返回元素的当前的样式，返回值可能来自 style 属性也可能来自样式表。`css()` 允许在 CSS 样式名中使用连字符或驼峰格式的 JavaScript 样式名。

```javascript
('h1').css('font-weight'); // 获取第一个 <h1> 的字体重量
('h1').css('fontWeight'); // 也可以采用驼峰格式
('h1').css('font'); // 错误：不可以获取复合样式
('h1').css('font-variant', 'smallcaps'); // 将样式设置在所有 <h1> 元素上
('div.note').css('board', 'solid black 2px'); // 设置复合样式
('h1').css({backgroundColor:'black', textColor:'white', fontVariant:'small-caps', padding:'10px 2px 4px 20px'. boarder:'dotted black 4px'});
('h1').css('font-size', function (i, curval) {
  return Math.round(1.25 * parseInt(vurval));
}); // 使所有的 <h1> 字体增加 25%
```

### 获取和设置 CSS 类

`addClass()` 和 `removeClass()` 用来从选中元素中添加和删除类。`toggleClass()` 在当元素还没有某些类时，给元素添加这些类，反之则删除。`hasClass()` 用来判断某类是否存在。例子：

```javascript
// 添加 CSS 类
$("h1").addClass("hilite");
$("h1+p").addClass("hilite first"); // 给 <h1> 后面的 <p> 添加两个类
$("section").addClass(function (n) {
  // 传递一个函数用以匹配
  return "section" + n; // 每一个元素添加自定义类
});

// 删除 CSS 类
$("p").removeClass("hilite"); // 从所有 <p> 元素中删除一个类
$("p").removeClass("hilite first"); // 允许一次删除多个类
$("section").removeClass(function (n) {
  // 从元素中删除自定义类
  return "section" + n;
});
$("div").removeClass(); // 删除所有 <div> 中的所有类

// 切换 CSS 类
$("tr:odd").toggleClass("oddrow"); // 如果该类不存在，则添加。如果存在则删除
$("h1").toggleClass("big bold"); // 一次切换两个类
$("h1").toggleClass(function (n) {
  // 切换用来函数计算出来的类
  return "big bold h1-" + n;
});
$("h1").toggleClass("hilite", true); // 类似 addClass
$("h1").toggleClass("hilite", false); // 类似 removeClass

// 检测 CSS 类
$("p").hasClass("first"); // 是否所有 p 元素都有该类
$("#lead").is(".first"); // 功能和上面类似
$("#lead").is(".first.hilite"); // is() 比 hasClass() 更灵活
```

### 获取和设置 HTML 表单值

`val()` 用来获取和设置 HTML 表单元素的 value 属性，还可以用于获取和设置复选框、单选按钮以及 `<select>` 元素的选中状态。

```javascript
$("#surname").val(); // 获取 surname 文本域的值
$("#usstate").val(); // 从 <select> 中获取单一值
$("select#extras").val(); // 从 <select multiple> 中获取一组值
$("input:radio[name=ship]:checked").val(); // 获取选中的单选按钮的值
$("#email").val("Invalid email address"); // 给文本域设置值
$("input:checkbox").val(["opt1", "opt2"]); // 选中带有这些名字或值的复选框
$("input:text").val(function () {
  // 重置所有文本域为默认值
  return this.defaultValue;
});
```

### 获取和设置元素的内容

`text()` 和 `html()` 用来获取和设置元素的纯文本或 HTML 内容。当不带参数调用时，`text()` 返回所有匹配元素的子孙文本节点的纯文本内容，`html()` 返回第一个匹配元素的 HTML 内容。如果传入字符串给 `text()` 或 `html()`，该字符串会用作该元素的纯文本或格式化 HTML 文本内容。

```javascript
var title = $("head title").text(); // 获取文档标题
var headline = $("h1").html(); // 获取第一个 <h1> 元素的 html
$("h1").text(function (n, current) {
  // 给每一个标题添加章节号
  return "§" + (n + 1) + ":" + current;
});
```

### 获取和设置元素的位置高宽

使用 `offset()` 可以获取或设置元素的位置。该方法相对文档来计算位置值，返回一个对象，带有 left 和 top 属性，代表 X 和 Y 坐标。

`position()` 很像 `offset()`，但它只能用作 getter，返回的元素是相对于其偏移父元素的，而不是相对于文档的。

用于获取元素宽度和高度的 getter / setter 共有 3 个。`width()` 和 `height()` 返回基本的宽度和高度，不包含内边距、边框、外边距。`innerWidth()` 和 `innerHeight()` 返回元素的宽度和高度，包含内边距的宽度和高度。`outerWidth()` 和 `outerHeight()` 通常返回的是包含元素内边距和边框的尺寸。

`scrollTop()` 和 `scrollLeft()` 可获取或设置元素的滚动条位置。这些方法可用在 Window 对象以及 Document 元素上。当用在 Document 对象上时，会获取或设置存放该 Document 的 Window 对象的滚动条位置。

### 获取和设置元素数据

jQuery 定义了一个名为 `data()` 的 getter / setter 方法，可用来获取或设置与文档元素、Document、Window 对象相关的数据。

`removeData()` 用来从元素中删除数据。如果不带参数调用 `removeData()`，它会删除与元素相关联的所有数据。

```javascript
$("div").data("x", 1); // 设置一些数据
$("div.nodata").removeData("x"); // 删除一些数据
var x = $("#mydiv").data(x); // 获取一些数据
```

---

## 修改文档结构

HTML 文档表示为一棵节点树，而不是一个字符的线性序列，因此插入、删除、替换操作不会像操作字符串和数组一样简单。

下面演示的每一个方法都接收一个参数，用于指定需要插入文档中的内容。该参数可以是用于指定新内容的纯文本或 HTML 字符串，也可以是 jQuery 对象、元素、文本节点。

```javascript
$("#log").append("<br>" + message); // 在 #log元素结尾处添加内容
$("h1").prepend("§"); // 在每个 <h1> 的起始处添加章节标识
$("h1").before("<hr>"); // 在每个 <h1> 的前面添加水平线
$("h1").after("<hr>"); // 在每个 <h1> 的后面添加水平线
$("hr").replaceWith("<br>"); // 替换 <hr> 元素为 <br>
$("h2").each(function () {
  // 将 <h2> 替换为 <h1>，内容保持不变
  var h2 = $(this);
  h2.replaceWith("<h1>" + h2.html() + "</h1>");
});
```

`clone()` 创建并返回每一个选中的元素的一个副本，其返回的 jQuery 对象还不是文档的一部分，但可以使用上一节的方法将其插入文档中。

jQuery 定义了 3 种包装函数。`warp()` 包装每一个选中元素，`wrapInner()` 包装每一个选中元素的内容，`warpAll()` 将选中元素作为一组来包装。这些方法通常传入一个新创见的包装元素或用来创建元素的 HTML 字符串。

`empty()` 会删除每个选中元素的所有字节点，但不会修改元素自身。`remove()` 会从文档中移除选中元素，如果传入一个参数，该参数会被当成选择器，jQeury 对象中只有匹配该选择器的元素才会被移除。`remove()` 会移除所有事件处理程序以及可能绑定到被移除元素上的其它数据。`detach()` 和 `remove()` 类似，但不会移除事件处理程序和数据。

---

## 使用 jQuery 处理事件

jQuery 定义了一个统一事件 API，可兼容 IE（包括 IE9 以下），并能在所有浏览器中工作。jQuery API 具有简单的形式，比标准或 IE 的事件 API 更容易使用。jQuery API 还具有更复杂、功能更齐全的形式，比标准 API 更强大。

### 事件处理程序的简单注册

jQuery 定义了简单的事件注册方法，可用于常用和普适的每一个浏览器事件。比如，给单击事件注册一个事件处理程序，只要调用 `click()` ：

```javascript
$("p").click(function () {
  $(this).css("background-color", "gray");
});
```

调用 jQuery 的事件注册方法可以给所有选中元素注册处理程序。下面是 jQuery 定义的简单事件处理程序注册的方法：

```javascript
blur()      focus()     mousedown()     mouseover()
click()     focusion()  mouseup()       resize()
dbclick()   focusout()  mouseenter()    scroll()
change()    keydown()   mouseleave()    load()
select()    keypress()  mousemove()     unload()
submit()    keyup()     mouseout()      error()
```

focus 和 blur 事件不支持冒泡，但 focusin 和 focusout 事件支持。相反地，mouseover 和 mouseout 事件支持冒泡，但 mouseenter 和 mouseleave 事件不支持。

resize 和 unload 事件类型只在 Window 对象中触发，如果想要给这两个事件类型注册处理程序，应该在 `$(window)` 上调用 `resize()` 和 `unload()`。`scroll()` 经常也用与 `$(window)` 对象上，但它可以用在有滚动条的任何元素上，比如当 CSS 的 overflow 属性设置为 scroll 或 auto 时。`load()` 可在 `$(window)` 上调用，用来给窗口注册加载事件处理程序，但经常更好的选择是，直接将初始化函数传给 `$()`。当然，还可以在 iframe 和图片上使用 `load()` 。`error()` 可用在 `<img>` 元素上，用来注册当图片加载失败时调用的处理程序。

除了这些简单的事件注册方法外，还有两个特殊形式的方法，有时很有用：

- `hover()` 用来给 mouseenter 和 mouseleave 事件注册处理程序。调用 `hover(f, g)` 就和先调用 `mouseenter(f)` 然后调用 `mouseleave(g)` 一样。如果仅传入一个参数，该参数函数会同时用做 enter 和 leave 事件的处理程序；
- `toggle()` 将事件处理程序绑定到单击事件。可以指定两个或多个处理程序函数，当单击事件发生时，jQuery 每次会调用一个处理程序函数。例如，如果调用 `toggle(f, g, h)`，第一次单击事件触发时，会调用函数 `f()`，第二次会调用 `g()`，第三次会调用 `h()`，然后第四次会再调用 `f()`。

### jQuery 事件处理程序

上面例子中的事件处理程序函数被当作是不带参数以及不返回值的，但 jQuery 调用每一个事件处理程序，实际上都传入了一个或多个参数，并且对处理程序的返回值进行了处理。**需要知道的最重要的一件事情是，每个事件处理程序都传入了一个 [jQuery 事件对象](#jQuery-事件对象) 作为第一个参数**。该对象的字段提供了与该事件相关的详细信息，比如鼠标指针的坐标。jQuery 模拟标准 Event 对象，即便在不支持的标准事件对象的浏览器中（像 IE8 及其以下），jQuery 事件对象在所有浏览器上都拥有一组相同的字段。

jQuery 事件处理程序函数的返回值始终是有意义的。如果处理程序返回 false，则与该事件相关联的默认行为，以及该事件接下来的冒泡都会被取消。也就是说，返回 false 等同于调用 Event 对象的 `preventDefault()` 和 `stopPropagation()`。同样，当事件处理程序返回一个值（非 undefined 值）时，jQuery 会将该值存储在 Event 对象的 result 属性中，该属性可以被后续调用的事件处理程序访问。

### jQuery 事件对象

jQuery 通过定义自己的 Event 对象来隐藏浏览器之间的实现差异。当一个 jQuery 事件处理程序被调用时，总会传入一个 jQuery 事件对象作为其第一个参数。jQuery 会将以下所有字段从原声 Event 对象中复制到 jQuery 事件对象上，尽管对于特定事件类型来说，有些字段值为 undefined。

```javascript
altKey      ctrlKey         newValue        screenX
attrChange  currentTarget   offsetX         screenY
attrName    detail          offsetY         shiftKey
bubbles     eventPhase      originalTarget  srcElement
button      formElement     pageX           target
cancelable  keyCode         pageY           toElement
charCode    layerX          prevValue       view
clientX     layerY          relatedNode     whellDelta
clientY     metaKey         relatedTarget   which
```

除了这些属性，jQuery 事件对象还定义了以下方法：

```javascript
preventDefault()            isDefaultPrevented()
stopPropagation()           isPropagationStopped()
stopImmediatePropagation()  isImmediatePropagationStopped()
```

### 触发事件

手动触发事件最简单的方式是不带参数调用事件注册的简单方法，比如 `click()` 或 `mouseover()`。与很多 jQuery 方法可以同时用做 getter 和 setter 一样，这些事件方法在带有一个参数时会注册事件处理程序，不带参数调用时则会触发事件处理程序。例如：

```javascript
$("#my_form").submit(); // 就和用户单击提交按钮一样
```

上面的 `submit()` 自己合成了一个 Event 对象，并触发了给 submit 事件注册的所有事件处理程序。如果这些事件处理程序没有返回 false 或调用 Event 对象的 `preventDefault()`，实际上将提交该表单。注意，通过这种方式手动调用时，冒泡事件依旧会冒泡。

需要特别注意，jQuery 的事件触发方法会触发所有使用 jQuery 事件注册方法注册的处理程序，也会触发通过 onsubmit 等 HTML 属性或 Element 属性定义的处理程序。但是，不能手动触发使用 `addEventListen()` 或 `attachEvent()` 注册的事件处理程序。

同时需要注意，jQuery 的事件触发机制是同步的（不涉及事件队列）。

### 事件处理程序的高级注册 & 实时事件

书中介绍使用 `bind()`，但实际建议使用 `on()`。

---

## 动画效果

jQuery 定义了 `fadeIn()` 和 `fadeOut()` 等简单的方法实现常见视觉效果。除了简单动画方法，jQuery 还定义了一个 `animate()`，用来实现更复杂的自定义动画。

**jQuery 动画是异步的**。调用 `fadeIn()` 等动画方法时，它会立刻返回，动画则在「后台」执行。如果一个元素已经在动画过程中，再调用一个动画方法时，新动画是不会立刻执行，而会延迟到当前动画结束后才执行。例如，可以让一个元素在持久显示前先闪烁一会：

```javascript
$("#blinker").fadeIn(100).fadeOut(100).fadeIn(100).fadeOut(100).fadeIn(100);
```

### 简单动画

- `fadeIn()`、`fadeOut()`、`fadeTo()`

  这是最简单的动画：`fadeIn()` 和 `fadeOut()` 简单地改变 CSS 的 opacity 属性显示或隐藏元素。两者都接受可选的时长和回调参数。`fadeTo()` 稍有不同，它需要传入一个 opacity 目标值，`fadeTo()` 会将元素的当前 opacity 值变化到目标之。调用 `fadeTo()` 时，第一参数必须是时长或选项对象，第二参数是 opacity 目标值，第三参数是回调函数。

- `show()`、`hide()`、`toggle()`

  `hide()` 和 `show()` 只是简单地立刻隐藏或显示选中元素，带有时长或选项对象时，它们会隐藏或显示有个动画过程。`toggle()` 可以改变在上面调用它的元素的可视状态：如果隐藏，则调用 `show()`，如果显示，则调用 `hide()`。

- `slideDown()`、`slideUp()`、`slideToggle()`

  `slideUp()` 会隐藏 jQuery 对象中的元素，方式是将其高度动态变化到 0 ，然后设置 CSS 的 display 属性为 none。`slideDown()` 执行反向操作，来使得隐藏的元素再次可见。`slideToggle()` 使用向上滑动或向下滑动动画来切换元素的可见性。

### 自定义动画

`animate()` 可以实现更多通用的动画效果。第一个参数是必需的，它必须是一个对象，该对象的属性指定要变化的 CSS 属性和它们的目标值。第二个参数是可选的，可以传入一个选项对象给 `animate()`。通常，`animate()` 接收两个对象参数，第一个指定动画内容，第二个指定如何定制动画。

1. 动画属性对象

   该对象的属性名必须是 CSS 属性，这些属性的值必须是动画的目标值。动画只支持数值属性：对于颜色、字体或 display 等枚举属性是无法实现动画效果的。如果属性值是数值，则默认单位是像素。如果属性值是字符串，可以指定单位。还可以指定相对值，用「+=」前缀表示增加，用「-=」前缀表示减少。jQuery 动画属性对象中，还可以使用 hide、show、toggle 这三个属性值。

   ```javascript
   $("p").animate({
     "margin-left": "+=.5in", // 增加段落缩进
     opacity: "-=.1", // 同时减少不透明度
   });
   $("img").animate({
     width: "hide",
     borderLeft: "hide",
     borderRight: "hide",
     paddingLeft: "hide",
     paddingRight: "hide",
   });
   ```

2. 动画选项对象

   该选项对象用来指定动画如何执行。duration 属性指定动画持续的毫秒时间，其值可以是 fast、slow 或任何 jQuery.fx.speeds 中定义的名称。complete 属性指定动画完成时的回调函数。setp 属性指定在动画每一步或每一帧调用的回调函数。在回调函数中，this 指向正在连续变化的元素，第一个参数则是正在变化的属性值。queue 属性指定动画是否需要队列化，即是否需要等到所有尚未发生的动画都完成后再执行该动画。默认情况下，所有动画都是队列化的。easing 属性指定缓动函数名，jQuery 默认使用的是命为 swing 的正弦函数。

---

## jQuery 中的 Ajax

在 Web 应用编程技术里，Ajax 很流行，它使用 HTTP 脚本来按需加载数据，而不需要刷新整个页面。jQuery 定义了一个高级工具方法和四个高级工具函数。这些高级工具都基于同一个强大的底层函数：`jQuery.ajax()`。

### load() 方法

`load()` 是所有 jQuery 工具中最简单的：向它传入一个 URL，它会异步加载该 URL 的内容，然后将内容插入每一个选中的元素，替换掉已经存在的任何内容。例如：

```javascript
// 每隔 60 秒加载并显示最新的状态报告
setInterval(function () {
  $("#status").load("status_report.html");
}, 60 * 1000);
```

`load()` 可以用来注册 load 事件。如果传给方法的第一个参数是函数而不是字符串，则 `load()` 是注册事件处理程序而不是 Ajax 方法。

如果只想显示被加载文档的一部分，可以在 URL 后面添加一个空格和一个 jQuery 选择器。当 URL 加载完成后，jQuery 会用指定的选择器来从加载好的 HTML 中选取需要显示的部分：

```javascript
// 加载并显示天气预告的温度部分
$("#temp").load("wheather_report.html #temperature");
```

除了 URL 参数，`load()` 还接受两个可选参数。第一个可选参数表示的数据，可以追加到 URL 后面，或者与请求一起发送。另一个可选参数是回调函数。如果没有指定任何数据，回调函数可以作为第二个参数传入。否则，它必须是第三个参数。在 jQuery 对象的每一个元素上都会调用回调函数，并且每次调用都会传入三个参数：被加载 URL 的完整文本内容、状态码字符串、以及用来加载该 URL 的 XMLHttpRequest 对象。其中，状态参数是 jQuery 的状态码，不是 HTTP 的状态码，其值是类似 success、error 和 timeout 的字符串。

| jQuery 状态码 | 描述                                                                                                                |
| ------------- | ------------------------------------------------------------------------------------------------------------------- |
| success       | 表示请求成功完成。                                                                                                  |
| notmodified   | 该状态码表示请求已经正常完成，但服务器返回的响应内容是 HTTP 304 Not-Modified，表示请求的 URL 内容和上次请求的相同。 |
| error         | 表示请求没有成功完成，原因是某些 HTTP 错误。                                                                        |
| timout        | 如果 Ajax 请求没有在选定的超时时间内完成，会调用错误回调，并传入该状态码。                                          |
| parsererror   | 该状态码表示 HTTP 请求已经成功完成，但 jQuery 无法按照期望的方式解析。                                              |

### Ajax 工具函数

jQuery 的其它 Ajax 高级工具不是方法，而是函数，可以通过 `jQuery` 或 `$` 直接调用，而不是在 jQuery 对象上调用。

#### jQuery.getScript()

`jQuery.getScript()` 函数的第一个参数是 JavaScript 代码文件的 URL。它会异步加载文件，加载完成之后在全局作用域执行该代码。它能同时适用于同源和跨源脚本：

```javascript
// 从其它服务器动态加载脚本
jQuery.getScript("http://example.com/js/widget.js");
```

可以传入回调函数作为第二个参数，在这种情况下，jQuery 会在代码加载和执行完成之后调用一次该回调函数：

```javascript
// 加载一个类库，并在加载完成时立刻使用它
jQuery.getScript("js/jquery.my.plugin.js", function () {
  $("div").my_plugin(); // 使用加载的类库
});
```

传递给 `jQuery.getScript()` 的回调函数，仅在请求成功完成时才会被调用。

#### jQuery.getJSON()

`jQuery.getJSON()` 和 `jQuery.getScript()` 类似：它会获取文本，然后特殊处理一下，再调用指定的回调函数。`jQuery.getJSON()` 获取到文本之后，不会将其当作脚本执行，而会将其解析为 JSON。`jQuery.getJSON()` 只有在传入了回调函数时才有用。当成功加载 URL，以及将内容成功解析为 JSON 后，解析的结果会作为第一个参数传入回调函数中。

```javascript
// 假设 data.json 包含文本：{"x":1, "y":2}
jQuery.getJSON("data.json", function (data) {
  // data 参数是对象 {x:1, y:2}
});
```

与 `jQuery.getScript()` 不同，`jQuery.getJSON()` 接受一个可选的数据对象参数，就和传入 `load()` 中的一样。

#### jQuery.get() 和 jQuery.post()

`jQuery.get()` 和 `jQuery.post()` 获取指定 URL 的内容，如果有数据的话，还可以传入指定数据，最后则将结果传递给指定的回调函数。`jQuery.get()` 使用 HTTP GET 请求来实现，`jQuery.post()` 使用 HTTP POST 请求实现。与 `jQuery.getJSON()` 一样，这两个方法也接受相同的三个参数：必须的回调函数，可选的数据字符串或对象，以及一个技术上可选但实际上总会使用的回调函数。调用的回调函数会被传入三个参数：第一个参数是返回的数据，第二个是 success 字符串，第三个则是 XMLHttpRequest 对象。

除了上面描述的三个参数，这两个方法还可以接受可选的第 4 个参数，该参数指定被请求数据的类型。`load()` 使用 html 类型，`jQuery.getScript()` 使用 script 类型，`jQuery.getJSON()` 则使用 json 类型。与上面这些专用函数相比，`jQuery.get()` 和 `jQuery.post()` 更灵活。该参数的有效值，在下面描述：

| dataType | 描述                                                                                                           |
| -------- | -------------------------------------------------------------------------------------------------------------- |
| text     | 将服务器的响应作为纯文本返回，不做任何处理。                                                                   |
| html     | 该类型和 text 类型一样，响应是纯文本。                                                                         |
| xml      | 请求的 URL 被认为指向 XML 格式的数据。                                                                         |
| script   | 请求的 URL 被认为指向 JavaScript 文件                                                                          |
| json     | 请求的 URL 被认为指向 JSON 格式的数据文件                                                                      |
| jsonp    | 请求的 URL 被认为指向服务器脚本，该脚本支持 JSONP 协议，可以将 JSON 格式的数据作为参数传递给客户端指定的函数。 |

### jQuery.ajax() 函数

jQuery 的所有 Ajax 工具最后都会调用 `jQuery.ajax()` —— 这是整个类库中最复杂的函数。`jQuery.ajax()` 仅接受一个参数：一个选项对象，该对象的属性指定 Ajax 请求如何执行的很多细节。例如，`jQuery.getScript(url, callback)` 与下面 `jQuery.ajax()` 的调用等价：

```javascript
jQuery.ajax({
  type: "GET", // HTTP 请求方法
  url: url, // 要获取数据的 URL
  data: null, // 不给 URL 添加任何数据
  dataType: "script", // 一旦获取到数据，立刻当作脚本执行
  success: callback, // 完成时调用该函数
});
```

可以通过 `jQuery.ajaxSetup()` 传入一个选项对象来设置任意选项的默认值：

```javascript
jQuery.ajaxSetup({
  timeout: 2000, // 在两秒后取消所有 Ajax 请求
  cache: false, // 通过给 URL 添加时间戳来禁用浏览器缓存
});
```

运行以上代码后，指定的 timeout 和 cache 选项会在所有未指定这两个选项值的 Ajax 请求中使用，包括 `jQuery.get()` 和 `load()` 等高级工具。

#### 通用选项

`jQuery.ajax()` 中最常用的选项如下：

- type

  指定 HTTP 的请求方法。默认是 GET，另一个常用值是 POST。可以指定其它 HTTP 的请求方法，比如 DELETE 或 PUSH，但不是所有浏览器都支持它们。

- url

  要获取的 URL。对于 GET 请求，data 选项会添加到该 URL 后。

- data

  添加到 URL 中（GET 请求）或在请求体中（POST 请求）发送的数据。

- dataType

  指定响应数据的预期类型，以及 jQuery 处理该数据的方式。

- contentType

  指定请求的 HTTP Content-Type 头。默认值是 application/x-www-form-urlencoded，这是 HTML 表单和绝大部分服务器脚本使用的正常值。

- timeout

  超时时间，单位是毫秒。

- cache

  对于 GET 请求，如果该选项设置为 false，jQuery 会添加一个「\_=」参数到 URL 中，或者替换已经存在的同名参数。该参数的值是当前时间（毫秒格式），这可以禁用基于浏览器的缓存。

- ifModified

  当选项值设置为 true 时，jQuery 会为请求的每一个 URL 记录 Last-Modified 和 If-None-Match 响应头的值，并会在接下来的请求中为相同的 URL 设置这些头部信息。这可以使得，如果上次请求后 URL 的内容没有改变，则服务器会发送回 HTTP 304 Not-Modified 响应。

- global

  该选项指定 jQuery 是否应该触发上面描述的 Ajax 请求过程中的事件。默认值是 true，设置该选项为 false 会禁用 Ajax 相关的所有事件。

#### 回调

下面的选项指定在 Ajax 请求的不同阶段调用的函数。

- context

  该选项指定回调函数在调用时的上下文对象 —— 就是 this。该选项没有默认值，如果不设置，this 会指向选项对象。

- beforeSend

  该选项指定 Ajax 请求发送到服务器之前激活的回调函数。第一个参数是 XMLHttpRequest 对象，第二个参数是该请求的选项对象。如果该回调函数返回 false，Ajax 请求会取消。注意跨域的 script 和 jsonp 请求没有使用 XMLHttpRequest 对象，因此不会触发 beforeSend 回调。

- success

  该选项指定 Ajax 请求成功完成时调用的回调函数。第一个参数是服务器发送的数据，第二个参数是 jQuery 状态码，第三个参数是用来发送该请求的 XMLHttpRequest 对象。

- error

  该选项指定 Ajax 请求不成功时调用的回调函数。该回调函数的第一个参数是该请求 XMLHttpRequest 对象，第二个参数是 jQuery 状态码。

- complete

  该选项指定 Ajax 请求完成时激活的回调函数。每一个 Ajax 请求或者成功时调用 success 回调，或者失败时调用 error 回调。在调用 success 或 error 后，jQuery 会调用 complete 回调。第一个参数是 XMLHttpRequest 对象，第二个参数是 jQuery 状态码。

#### 不常用的选项和钩子

下述的 Ajax 选项不经常使用。

- async

  脚本化的 HTTP 请求本身就是异步的。然而，XMLHttpRequest 对象提供了一个选项，可用来阻塞当前进程，直到接收到响应。如果想开启这一阻塞行为，可以设置该选项为 false。

- dataFilter

  该选项指定一个函数，用来过滤或预处理服务器返回的数据。第一个参数是从服务器返回的原始数据，第二个参数是 dataType 选项的值。

- jsonp

  跨域问题应由服务端解决，略。

- jsonpCallback

  跨域问题应由服务端解决，略。

- processData

  当设置 data 选项为对象时，jQuery 通常会将该对象转换成字符串，该字符串遵守标准的 application/x-www-form-urlencoded 格式。如果想省略掉该步骤，可以设置该选项为 false。

- scriptCharset

  对于跨域的 script 和 jsonp 请求，会使用 `<script>` 元素，该选项用来指定 `<script>` 元素的 charset 属性值。

- tranditional

  jQuery 1.4 改变了数据对象序列化为 application/x-wwww-form-urlencoded 字符串的方式。设置该选项为 true，可以让 jQuery 恢复到原来的方式。

- username, password

  如果请求需要密码验证，可以使用这两个选项来指定用户名和密码。

- xhr

  该选项指定一个工厂函数，用来获取 XMLHttpRequest 对象。

### Ajax 事件

jQuery 的 Ajax 函数还会在 Ajax 请求的每一个相同阶段触发自定义事件。下面的表格展示了这些回调函数和响应的事件。

| 回调       | 事件类型     | 处理程序注册方法 |
| ---------- | ------------ | ---------------- |
| beforeSend | ajaxSend     | ajaxSend()       |
| success    | ajaxSuccess  | ajaxSuccess()    |
| error      | ajaxError    | ajaxError()      |
| complete   | ajaxComplete | ajaxComplete()   |
| ajaxStart  | ajaxStart()  |
| ajaxStop   | ajaxStop()   |

可以使用 `bind()` 或上表第二列中的事件类型字符串来注册这些自定义 Ajax 事件，也可以使用第三列中的事件注册方法来注册。

由于 Ajax 事件是自定义事件，是由 jQuery 而不是浏览器产生的，因此传递给事件处理程序的 Event 对象不是很有用。这些事件的处理程序激活时在 event 参数后都带有两个额外的参数。第一个额外参数是 XMLHttpRequest 对象，第二个额外参数是 选项对象。

---

## jQuery 选择器和选取方法

### jQuery 选择器

在 CSS 选择器标准草案定义的选择器语法中，jQuery 支持相当完整的一套子集，同时还添加了一些非标准但很有用的伪类。

选择器语法有三层结构。`#test` 选取 id 属性为 test 的元素，`blockquote` 选取文档中的所有 blockquote 元素，而 `div.note` 则选取所有 class 属性为 note 的 div 元素。简单选择器可以组成「组合选择器」，比如 `div.note > p` 和 `blockquote i`。

#### 简单选择器

| 过滤器           | 含义                                                                          |
| ---------------- | ----------------------------------------------------------------------------- |
| **#id**          | 匹配 id 属性为 _id_ 的元素                                                    |
| **.class**       | 匹配 class 属性                                                               |
| [attr]           | 匹配拥有 attr 属性（和值无关）的所有元素                                      |
| **[attr=val]**   | 匹配拥有 attr 属性，且值为 val 的所有元素                                     |
| [attr!=val]      | 匹配没有 attr 属性，或 attr 属性值不为 val 的所有元素                         |
| [attr^=val]      | 匹配 attr 属性值以 val 开头的元素                                             |
| [attr$=val]      | 匹配 attr 属性值以 val 结尾的元素                                             |
| [attr*=val]      | 匹配 attr 属性值含有 val 的元素                                               |
| [attr~=val]      | 当其 attr 属性解释为一个由空格分隔的单词列表时，匹配其中包含单词 val 的元素   |
| [attr&#124;=val] | 匹配 attr 属性值以 val 开头且其后没有其它字符，或其它字符是以连字符开头的元素 |
| :animated        | 匹配正在动画中的元素，该动画是由 jQuery 产生的                                |
| :button          | 匹配 `<button type="button">` 和 `<input type="button">` 元素                 |
| :checkbox        | 匹配 `<input type="checkbox">` 元素                                           |
| :checked         | 匹配选中的 input 元素                                                         |
| :contains(text)  | 匹配含有指定 text 文本的元素                                                  |
| **:disabled**    | 匹配禁用的元素                                                                |
| **:empty**       | 匹配没有子节点、没有文本内容的元素                                            |
| **:enabled**     | 匹配没有禁用的元素                                                            |
| **:eq(n)**       | 匹配基于文档顺序，序号从 0 开始的选中列表中的第 n 个元素                      |
| :even            | 匹配列表中偶数序号的元素                                                      |
| :file            | 匹配 `<input type="file">` 元素                                               |
| **:first**       | 匹配列表中的第一个元素，和 `:eq(0)` 相同                                      |
| :first-child     | 匹配的元素是其父节点的第一个子元素                                            |
| **:gt(n)**       | 匹配基于文档顺序，序号从 0 开始的选中列表中序号大于 n 的元素                  |
| :has(sel)        | 匹配的元素拥有匹配内嵌选择器 sel 的子孙元素                                   |
| :header          | 匹配所有头元素：`<h1>`、`<h2>`、`<h3>`、`<h4>`、`<h5>`、`<h6>`                |
| **:hidden**      | 匹配所有在频幕上不可见的元素                                                  |
| :imge            | 匹配 `<input type="image">` 元素                                              |
| :input           | 匹配用户输入元素：`<input>`、`<textarea>`、`<select>`、`<button>`             |
| **:last**        | 匹配选中列表中的最后一个元素                                                  |
| :last-child      | 匹配的元素是其父节点的最后一个子元素                                          |
| **:lt(n)**       | 匹配基于文档顺序，序号从 0 开始的选中列表中序号小于 n 的元素                  |
| :nth(n)          | 与 `:eq(n)` 相同                                                              |
| :nth-child(n)    | 匹配的父元素是其父节点的第 n 个子元素                                         |
| :odd             | 匹配列表中的奇数                                                              |
| :only-child      | 匹配那些是其父节点唯一子节点的元素                                            |
| **:parent**      | 匹配是父节点的元素，与 `:empty` 相反                                          |
| :password        | 匹配 `<input type="password">` 元素                                           |
| :radio           | 匹配 `<input type="radio">` 元素                                              |
| :reset           | 匹配 `<input type="reset">` 和 `<button type="reset">` 元素                   |
| :selected        | 匹配选中的 `<option>` 元素                                                    |
| :submit          | 匹配 `<input type="submit">` 和 `<button type="submit">` 元素                 |
| :text            | 匹配 `<input type="text">` 元素                                               |
| **:visible**     | 匹配所有当前可见的元素                                                        |

通常来说，指定标签类型前缀，可以让过滤器运行得更高效。ID 过滤器是个例外，不添加标签前缀时，它会更高效。

#### 组合选择器

使用特殊操作符或「组合符」可以将简单选择器组合起来，表达文档树中元素之间的关系。

| 组合方式         | 含义                                                                       |
| ---------------- | -------------------------------------------------------------------------- |
| A &nbsp;&nbsp; B | 从匹配选择器 A 的元素的 **子孙元素** 中，选取匹配选择器 B 的文档元素       |
| A > B            | 从匹配选择器 A 的元素的 **子元素** 中，选取匹配选择器 B 的文档元素         |
| A + B            | 从匹配选择器 A 的元素的 **下一个兄弟元素** 中，选取匹配选择器 B 的文档元素 |
| A ~ B            | 从匹配选择器 A 的元素后面的 **兄弟元素** 中，选取匹配选择器 B 的文档元素   |

下面是组合选择器的一些例子：

```javascript
"blockquote i"; // 匹配 <blockquote> 里的 <i> 元素
"ol > li"; // <li> 元素是 <ol> 的直接子元素
"#output + *"; // id="output" 元素后面的兄弟元素
"div.note > h1 + p"; // 紧跟 <h1> 的 <p> 元素，在 <div class="note"> 里面
```

#### 选择器组

传递给 `$()` 函数，或在样式表中使用的选择器，就是选择器组。这是一个逗号分隔的列表，由一个或多个简单选择器或组合选择器构成。

下面是选择器组的一些例子：

```javascript
"h1, h2, h3"; // 匹配 <h1>、<h2> 和 <h3> 元素
"#p1 ,#p2, #p3"; // 匹配 id 为 p1、p2 或 p3 的元素
"div.note, p.note"; // 匹配 class="note" 的 <div> 和 <p> 元素
"body > p, div.note > p"; // <body> 和 <div class="note"> 的 <p> 子元素
```

### 选取方法

jQuery 还定义了一些选取方法，这些选取方法提供的多数功能与选择器语法的功能是一样的。

提取选中元素最简单的方式是按位置提取。`first()` 仅返回选中元素中的第一个 jQuery 对象，`last()` 则返回最后一个 jQuery 对象，`eq()` 返回指定序号的 jQuery 对象。

```javascript
var paras = $("p");
paras.first(); // 仅选取第一个 <p> 元素
paras.last(); // 仅选取最后一个 <p> 元素
paras.eq(1); // 选取第二个 <p> 元素
paras.eq(-2); // 选取倒数第二个 <p> 元素
paras[1]; // 第二个 <p> 元素自身
```

通过位置提取元素更通用的方法是 `slice()`。jQuery 的 `slice()` 与 `Array.slice()` 类似：接受开始和结束序号，返回从开始（包含）到结束（不包含）序号的 jQuery 对象。

```javascript
$("p").slice(2, 5); // 选取第 3、4、5 个 <p> 元素
$("div").slice(-3); // 选取最后 3 个 <div> 元素
```

`filter()` 是通用的选区过滤方法，有 3 种调用方式：

- 传递选择器字符串，`filter()` 会返回匹配该选择器字符串的新 jQuery 对象；
- 传递另一个 jQuery 对象，`filter()` 会返回一个包含这两个对象交集的新 jQuery 对象；
- 传递判断函数，`filter()` 会为每一个元素调用该判断函数，并返回包含所有函数执行结果为 true 的元素的新 jQuery 对象。

```javascript
$("div").filter(".note"); // 与 $('div.note') 一样
$("div").filter($(".note")); // 与 $('div.note') 一样
$("div").filter(function (idx) {
  // 与 $('div:even') 一样
  return idx % 2 == 0;
});
```

`not()` 与 `filter()` 一样，除了含义与 `filter()` 相反。

```javascript
$("div").not("#header, #footer"); // 除了两个特殊元素之外的所有 <div> 元素
```

`has()` 如果传入选择器会返回一个新的 jQuery 对象，仅包含子孙元素中匹配该选择器的元素。

```javascript
$("p").has("a[href]"); // 包含链接的段落
```

`add()` 会扩充选区，而不是对其进行过滤或提取。

```javascript
$("div, p"); // 使用选择器组
$("div").add("p"); // 给 add() 传入选择器
$("div").add($("p")); // 给 add() 传入 jQuery 对象
var paras = document.getElementByTagName("p"); // 类数组对象
$("div").add(paras); // 给 add() 传入元素数组
```

#### 将选中元素集用作上下文

jQuery 还定义了一些选取方法，可将当前选中元素作为上下文来使用。这些方法会使用该选中元素作为上下文或起始点，来得到新的选中元素，然后返回一个包含新选中元素并集的 jQuery 对象。

`find()` 会在每一个当前选中元素的子孙元素中，寻找与指定选择器匹配的元素，然后返回一个新的 jQuery 对象来代表所匹配的子孙元素集。`find()` 和 `filter()` 不同，`filter()` 不会选中新元素，只是简单地将当前选中的元素集进行缩减。

```javascript
$("div").find("p"); // 在 <div> 中查找 <p> 元素，与 $('div p') 相同
```

`children()` 返回每一个选中元素的直接子元素，支持使用可选的选择器参数进行过滤。

```javascript
// 寻找 id 为 header 和 footer 元素的子节点元素中的所有 <span> 元素
// 与 $('#header>span, #footer>span') 相同
$("#header, #fotter").childern("span");
```

`contents()` 与 `children()` 类似，不同的是它会返回每一个元素的所有子节点，包括文本及节点。

`next()` 和 `prev()` 返回每一个选中元素的下一个和上一个兄弟元素，如果传入了选择器字符串，则只会选中匹配该选择器的兄弟元素。

```javascript
$("h1").next("p"); // 与 $('h1+p') 相同
$("h1").prev(); // <h1> 元素前面的兄弟元素
```

`nextAll()` 和 `prevAll()` 返回每一个选中元素的前面或后面所有兄弟元素。`siblings()` 则返回每一个选中元素的所有兄弟元素。如果给这些方法传入选择器，则只会返回匹配该选择器的兄弟元素。

```javascript
$("#footer").nextAll("p"); // 紧跟 #footer 元素的所有 <p> 元素
$("#footer").prevAll(); // #footer 元素前面的所有兄弟元素
```

`parent()` 返回每一个选中元素的父节点。

```javascript
$("li").parent(); // 列表元素的父节点，比如 <ul> 和 <ol> 元素
```

`parents()` 返回每一个选中元素的祖先节点。

```javascript
$("a[href]").parents("p"); // 含有链接的 <p> 元素
```

#### 恢复到之前的选中元素集

为了实现方法的链式调用，很多 jQuery 对象的方法最后都会返回调用对象。虽然可以链式调用下去，但必须清楚地意识到，在链式调用后面所操作的元素集，可能已经不是该链式调用开始时的元素集了。

---

## 总结

即使是现在，面对诸如 Vue.js、Angular.js 等 MVVM 框架的兴起，jQuery 库依然很流行。可见掌握 jQuery 的使用对于一名 Web 开发人员的重要性。
