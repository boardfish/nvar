---
layout: default
title: Contributing
---

# Contributing

_This project is intended to be a safe, welcoming space for collaboration. By participating in this project you agree to abide by the [Contributor Code of Conduct](CODE_OF_CONDUCT.md)._

Hi there! I'm thrilled that you'd like to contribute to this project. Your help is essential for keeping it great.

If you have any substantial changes that you would like to make, please [open a discussion](http://github.com/boardfish/nvar/discussions/new) first to discuss them with me. If you've encountered a bug, please [raise an issue](http://github.com/boardfish/nvar/issues/new) instead.

## Reporting bugs

When opening an issue to describe a bug, it's helpful to provide steps to reproduce it, either with failing tests in a pull request, or by sharing a repository that demonstrates the issue. Follow the installation instructions in the README to get started. If the problem is specific to Rails, you may want to use `rails new --minimal` to make a barebones Rails app that replicates your failure.

Add as little code as possible that's necessary to reproduce the issue. If possible, use the original code that caused the issue in your application. Publish the repository and add a link to the bug report issue.

## Submitting a pull request

1. [Fork](https://github.com/boardfish/nvar/fork) and clone the repository.
1. Configure and install the dependencies: `bundle`.
1. Make sure the tests pass on your machine: `bundle exec rspec`.
1. Create a new branch: `git checkout -b my-branch-name`.
1. Add tests, then make the changes that will get those tests to pass.
1. Add an entry to the top of `docs/CHANGELOG.md` for your changes, no matter how small they are. Every contribution makes `Nvar` just that little bit greater!
1. Push to your fork and [submit a pull request](https://github.com/boardfish/nvar/compare).
1. Pat yourself on the back and wait for your pull request to be reviewed and merged.

Here are a few things you can do that will increase the likelihood of your pull request being accepted:

- Write tests.
- Keep your change as focused as possible. If there are multiple changes you would like to make that aren't dependent upon each other, consider submitting them as separate pull requests.
- Write a [good commit message](http://tbaggery.com/2008/04/19/a-note-about-git-commit-messages.html).

## Releasing

If you are the current maintainer of this gem:

1. Run `rake release`.
