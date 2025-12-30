# feather-melpa

A [MELPA](https://github.com/melpa/melpa) fork that generates daily JSON recipe files for [feather.el](https://github.com/conao3/feather.el).

[![Build Status](https://img.shields.io/travis/conao3/feather-melpa/master.svg?style=flat-square)](https://travis-ci.org/conao3/feather-melpa)
[![License](https://img.shields.io/github/license/conao3/feather-melpa.svg?style=flat-square)](https://github.com/conao3/feather-melpa/blob/master/LICENSE)

## Overview

This repository tracks the upstream MELPA repository and automatically generates JSON recipe files via Travis CI cron jobs every day. The generated files are available in the `html/` and `html-stable/` directories as `recipes.json`.

## Background

This fork incorporates changes from [PR #5888](https://github.com/melpa/melpa/pull/5888) to support the feather.el package manager.

## About MELPA

MELPA is a growing collection of `package.el`-compatible Emacs Lisp packages built automatically from upstream source code using simple recipes. For more information about MELPA itself, visit [melpa.org](https://melpa.org/).

## Recipe Format

Packages are specified by files in the `recipes` directory using the following format:

```elisp
(<package-name>
 :fetcher [git|github|gitlab|hg|bitbucket]
 [:url "<repo url>"]
 [:repo "user/repo-name"]
 [:commit "commit"]
 [:branch "branch"]
 [:version-regexp "<regexp>"]
 [:files ("<file1>" ...)])
```

### Key Properties

- **`:fetcher`** - Repository type: `git`, `github`, `gitlab`, `hg`, or `bitbucket`
- **`:url`** - Repository URL (required for `git` and `hg` fetchers)
- **`:repo`** - GitHub/GitLab/Bitbucket repository in `user/repo-name` format
- **`:commit`** - Specific commit SHA or ref to checkout
- **`:branch`** - Branch name to use
- **`:version-regexp`** - Regex for extracting version from tags
- **`:files`** - List of files to include in the package

### Example

```elisp
(smex :repo "nonsequitur/smex" :fetcher github)
```

## Build Commands

The `Makefile` provides the following targets:

| Command | Description |
|---------|-------------|
| `make all` | Build all packages and compile index.html |
| `make recipes/<NAME>` | Build a specific recipe |
| `make json` | Build all JSON files |
| `make archive.json` | Generate archive.json with all compiled packages |
| `make recipes.json` | Generate recipes.json with all available packages |
| `make clean` | Clean all generated files |
| `make html` | Build index.html |

## API

The core functionality is in `package-build/package-build.el`, maintained in a [separate repository](https://github.com/melpa/package-build).

### Functions

- `(package-build-all)` - Build packages for all recipes
- `(package-build-archive NAME)` - Build a single package archive

### Variables

- `package-build-working-dir` - Staging directory for repositories
- `package-build-archive-dir` - Output directory for built packages
- `package-build-recipes-dir` - Directory containing recipe files

## License

See [LICENSE](LICENSE) for details.
