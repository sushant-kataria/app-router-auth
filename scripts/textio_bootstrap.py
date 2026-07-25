# Injected before grantpath Python patches (Windows-safe text matching).
# Strips NUL bytes and normalizes CRLF so exact string replacements work
# on checkouts that used core.autocrlf=true.
from pathlib import Path as _GrantpathPath

_grantpath_orig_read_text = _GrantpathPath.read_text
_grantpath_orig_write_text = _GrantpathPath.write_text


def _grantpath_read_text(self, encoding="utf-8", errors="strict"):
    data = self.read_bytes().replace(b"\0", b"")
    return data.decode(encoding, errors).replace("\r\n", "\n").replace("\r", "\n")


def _grantpath_write_text(self, data, encoding="utf-8", errors="strict", newline=None):
    if isinstance(data, str):
        data = data.replace("\r\n", "\n").replace("\r", "\n")
    # Always write LF; avoids re-introducing CRLF mid-patch on Windows.
    return _grantpath_orig_write_text(self, data, encoding=encoding, errors=errors)


_GrantpathPath.read_text = _grantpath_read_text  # type: ignore[method-assign]
_GrantpathPath.write_text = _grantpath_write_text  # type: ignore[method-assign]
