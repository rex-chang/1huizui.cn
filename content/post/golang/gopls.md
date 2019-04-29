---
title: "使用 Gopls 代码提示"
date: 2019-04-29T10:43:09+08:00
draft: true
tags: ['golang', 'go']
---
VSCode 使用 language server 进行代码提示.

代码地址:

> https://github.com/saibing/tools

<!--more-->

```json
{
    "go.useLanguageServer": true,
    "go.alternateTools": {
        "go-langserver": "gopls"
    },
    "go.languageServerExperimentalFeatures": {
        "format": true,
        "autoComplete": true
    },
    "[go]": {
        "editor.snippetSuggestions": "none",
        "editor.formatOnSave": true,
        "editor.codeActionsOnSave": {
            "source.organizeImports": true
        },
    },
    "gopls": {
        "usePlaceholders": true,
        "enhancedHover": true
    }
}
```