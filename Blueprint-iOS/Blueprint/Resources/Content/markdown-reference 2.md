---
title: Writing in Markdown - A Quick Reference
panelCategory: 'Developer'
date: 2026-03-20
description: A practical guide to markdown syntax - headings, code blocks, tables, blockquotes, and more.
tags: [software, beginner, completed]
author: Blueprint
published: true
---

# Writing in Markdown - A Quick Reference

Markdown is plain text that renders as formatted HTML. It's fast to write, beginner to read, and version-control friendly. Here's a reference for everything you need.

## Headers

Headers (also called "frontmatter") consist of information that isn't shown directly in the article body, but is instead used to organize the page: things like its category, description, tags, and author. Here's the actual frontmatter for this page:

```markdown
---
title: Writing in Markdown - A Quick Reference
panelCategory: 'Developer'
date: 2026-03-20
description: A practical guide to markdown syntax - headings, code blocks, tables, blockquotes, and more.
tags: [software, beginner, completed]
author: Blueprint
published: true
---
```

## Headings

```markdown
# H1 - Page title

## H2 - Section

### H3 - Subsection

#### H4 - Detail
```

## Text Formatting

| Syntax              | Result            |
| ------------------- | ----------------- |
| `**bold**`          | **bold**          |
| `*italic*`          | _italic_          |
| `` `inline code` `` | `inline code`     |
| `~~strikethrough~~` | ~~strikethrough~~ |

## Lists

**Unordered:**

```code
- Item one
- Item two
  - Nested item
  - Another nested item

```

which renders as:

- Item one
- Item two
  - Nested item
  - Another nested item

**Ordered:**

```code
1. First step
2. Second step
3. Third step
```

which renders as:

1. First step
2. Second step
3. Third step

## Code Blocks

Code can be represented as code blocks, or as inline code. For inline code, visit the table above. For code blocks, you need to enclose the code in triple backticks. Here is an example of how to do it:

````code
```java
public static void main(String[] args) {
    System.out.println("Hello, World!");
}
```
````

which renders as:

```java
public static void main(String[] args) {
    System.out.println("Hello, World!");
}
```

Fenced code blocks with language tags support syntax highlighting:

```javascript
function greet(name) {
	return `Hello, ${name}!`;
}

console.log(greet('World'));
```

```python
def fibonacci(n):
    if n <= 1:
        return n
    return fibonacci(n - 1) + fibonacci(n - 2)
```

## Blockquotes

```code
> "The best writing is rewriting."
> - E.B. White
```

which renders as:

> "The best writing is rewriting."
> - E.B. White

Blockquotes are useful for callouts, quotes, or emphasis.

## Links and Images

```markdown
[Link text](https://example.com)
![Alt text](/assets/markdown/image.png)
```

![md logo](/assets/markdown/images.png)

## Horizontal Rules

Use `---` to create a thematic break:

---

## Tables

```markdown
| Column A | Column B | Column C |
| -------- | -------- | -------- |
| Cell 1   | Cell 2   | Cell 3   |
| Cell 4   | Cell 5   | Cell 6   |
```

Renders as:

| Column A | Column B | Column C |
| -------- | -------- | -------- |
| Cell 1   | Cell 2   | Cell 3   |
| Cell 4   | Cell 5   | Cell 6   |

---

## 3D Models

To embed interactive 3D models, natively use the `<model-viewer>` component. It natively supports dragging, zooming, and dynamic shadowing out of the box!

> [!WARNING]  
> Web browsers do NOT natively support `.stl` format because it is inefficient for web rendering. You MUST convert `.stl` to `.glb` or `.gltf`.

**Importing Custom Assets**

1. **Convert to .glb:** If you designed in Fusion 360 or Blender, you can export natively as `glTF/GLB`. If using Onshape or you have a standalone `.stl` file, convert it freely using a [Model Converter](https://convert3d.org/stl-to-glb).
2. **Move to internal static folder:** Place the generated `.glb` file inside your codebase at `static/assets/models/your-mechanism.glb`.
3. **Reference it:** Reference the file inside your markup exactly like this: `src="/assets/models/your-mechanism.glb"`!

```html
<div
	style="width: 100%; height: 500px; border-radius: var(--radius-lg); overflow: hidden; border: 1px solid var(--border); background: var(--bg-secondary); margin: 2rem 0;"
>
	<model-viewer
		src="https://modelviewer.dev/shared-assets/models/RobotExpressive.glb"
		alt="A 3D model of a robot mechanism"
		auto-rotate
		camera-controls
		style="width: 100%; height: 100%; background-color: transparent;"
		shadow-intensity="1"
	>
	</model-viewer>
</div>
```

---

That covers practically everything you'll ever need. Now go write something!
