# build-in packages
import sys
import logging

LOGGER = logging.getLogger(__name__)
LOGGER.addHandler(logging.StreamHandler(sys.stdout))
LOGGER.setLevel(logging.DEBUG)

EMPTY_LINE = [""]
CW_BUTTON_STYLE_PRIMARY = "primary_button"
CW_BUTTON_STYLE_NORMAL = "button"


def dumps(md_lines):
    return "\n".join(md_lines)


def p(lines: list):
    return lines + EMPTY_LINE


def h1(text: str):
    return [f"# {text}"] + EMPTY_LINE


def h2(text: str):
    return [f"## {text}"] + EMPTY_LINE


def h3(text: str):
    return [f"### {text}"] + EMPTY_LINE


def h4(text: str):
    return [f"#### {text}"] + EMPTY_LINE


def bold(text: str):
    return f"**{text}**"


def inline(text: str):
    return f"`{text}`"


def code_block(code_lines: list):
    return ["```"] + code_lines + ["```"]


def cw_dashboard_reference(text: str, dashboard_name: str, style="hyperlink"):
    if style == CW_BUTTON_STYLE_PRIMARY:
        return f"[button:primary:{text}](#dashboards:name={dashboard_name})"
    elif style == CW_BUTTON_STYLE_NORMAL:
        return f"[button:{text}](#dashboards:name={dashboard_name})"
    else:
        return f"[{text}](#dashboards:name={dashboard_name})"


def cw_button(text: str, link: str, style=CW_BUTTON_STYLE_NORMAL):
    if style == CW_BUTTON_STYLE_PRIMARY:
        return f"[button:primary:{text}]({link})"
    else:
        return f"[button:{text}]({link})"


def table(headers: list, rows: list):
    _headers = [str(h) for h in headers]
    _rows = [[str(element) for element in row] for row in rows]
    table_header = [" | ".join(_headers)]
    table_header_holder = ["-----|" * (len(_headers) - 1) + "-----"]
    table_rows = [" | ".join(_row) for _row in _rows]
    return EMPTY_LINE + table_header + table_header_holder + table_rows + EMPTY_LINE
