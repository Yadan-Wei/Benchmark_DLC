# Amazon CloudWatch Markdown Writer

Generate markdown text to be used with in Amazon CloudWatch Dashboard using python code.

## Tutorial

### 1.Import

```
from asimov_image_security_scan import cloudwatch_markdown as md
```

### 2.Full Markdown lines
Those functions can be used to compose full markdown lines.
```
header1 = md.h1("Header 1")

header2 = md.h2("Header 2")

header3 = md.h3("Header 3")

header4 = md.h4("Header 4")

paragraph = md.p(["This", "Is", "a", "paragraph", "!!!"])

code_block = md.code_block([
    "import pytest",
    "from asimov_image_security_scan import cloudwatch_markdown as md",
])
```


### 3.Partial Markdown Line
There are markdown you will need to insert into as part of the line. Like making a substring **bold** or `inline code`.
```
bold = md.bold("I'm Bald!!!")

inline = md.inline("from asimov_image_security_scan import cloudwatch_markdown as md")
```

### 4.CloudWatch specialties 
CloudWatch's markdown can render a special syntax called dashboard reference. We support it here too.
```
cw_dashboard_reference = md.cw_dashboard_reference("This is a link to other dashboard", "dashboard_name")
```

### 5.Compose the final markdown document
`md_text` below is the generated full markdown document.
```
from asimov_image_security_scan import cloudwatch_markdown as md
header1 = md.h1("Header 1")
header2 = md.h2("Header 2")
header3 = md.h3("Header 3")
header4 = md.h4("Header 4")
paragraph = md.p(["This", "Is", "a", "paragraph", "!!!"])
code_block = md.code_block([
    "import pytest",
    "from asimov_image_security_scan import cloudwatch_markdown as md",
])
table = md.table(headers=["one", "two", "three"], rows=[[1, 2, 3], [4, 5, 6], [7, 8, 9]])
md_text = md.dumps(header1 + header2 + header3 + header4 + paragraph + code_block + table)
```
