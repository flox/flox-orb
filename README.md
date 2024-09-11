<h1 align="center">
  <a href="https://flox.dev" target="_blank">
    <picture>
      <source media="(prefers-color-scheme: dark)"  srcset="img/flox-logo-white-on-black.png" />
      <source media="(prefers-color-scheme: light)" srcset="img/flox-logo-black-on-white.png" />
      <img src="img/flox-logo-black-on-white.png" alt="flox logo" />
    </picture>
  </a>
</h1>

<h2 align="center">
  Developer environments you can take with you
</h2>

<h3 align="center">
   &emsp;
   <a href="https://discourse.flox.dev"><b>Discourse</b></a>
   &emsp; | &emsp; 
   <a href="https://flox.dev/docs"><b>Documentation</b></a>
   &emsp; | &emsp; 
   <a href="https://flox.dev/blog"><b>Blog</b></a>
   &emsp; | &emsp;  
   <a href="https://twitter.com/floxdevelopment"><b>Twitter</b></a>
   &emsp;
</h3>

<p align="center">
  <a href="https://github.com/flox/flox-orb/blob/main/LICENSE">
    <img alt="GitHub" src="https://img.shields.io/github/license/flox/flox-orb?style=flat-square">
  </a>
  <a href="https://github.com/flox/flox/blob/main/CONTRIBUTING.md">
    <img alt="PRs Welcome" src="https://img.shields.io/badge/PRs-welcome-brightgreen.svg?style=flat-square"/>
  </a>
  <a href="https://github.com/flox/flox-orb/releases">
    <img alt="GitHub tag (latest by date)" src="https://img.shields.io/github/v/tag/flox/flox-orb?label=Version&style=flat-square">
  </a>
</p>

Use this Orb to install [Flox][flox-github], activate Flox environments and run
commands in those environments.

## ⭐ Getting Started

An example
```yml
version: '2.1'

orbs:
  flox: flox/flox-orb@1.0.0

workflows:
  use-flox-orb:
    machine:
      image: ubuntu-2204:current
    jobs:
      - flox/install                    # <- Install Flox
      - flox/activate:                  # <- Run a command in a Flox environment
          command: python --version
          environment: flox/nb
```

## 📫 Have a question? Want to chat? Ran into a problem?

We are happy to welcome you to our [Discourse forum][discourse] and answer your
questions! You can always reach out to us directly via the [flox twitter
account][twitter] or chat to us directly on [Matrix][matrix] or
[Discord][discord].


## 🤝 Found a bug? Missing a specific feature?

Feel free to [file a new issue][new-issue] with a respective title and
description on the the `flox/flox-orb` repository. If you already
found a solution to your problem, we would love to review your pull request!


## 🪪 License

The `flox-orb` is licensed under the MIT. See [LICENSE](./LICENSE).


[flox-github]: https://github.com/flox/flox 
[flox-website]: https://flox.dev
[new-issue]: https://github.com/flox/flox-orb/issues/new/choose
[discourse]: https://discourse.flox.dev
[twitter]: https://twitter.com/floxdevelopment
[matrix]: https://matrix.to/#/#flox:matrix.org
[discord]: https://discord.gg/5H7hN57eQR
[nix-website]: https://nixos.org
[nix-help-stores]: https://nixos.org/manual/nix/unstable/command-ref/new-cli/nix3-help-stores.html
[post-nixpkgs]: https://flox.dev/blog/nixpkgs
