## Running build.yml locally

### Steps:

1. Install [nektos/act](https://github.com/nektos/act) (Simplest way is to install using homebrew by: `brew install act`)
2. Install the `gh` command line tool (`brew install gh`) and authenticate it using `gh auth login`.
3. Make sure your github account has read access to the [cli-binary](https://github.com/PreternaturalAI/cli-binary) repo.
4. From the root directory `merge`, run the following command:

```
sudo act -P macos-latest=-self-hosted -W '.github/workflows/build.yml' -s GITHUB_TOKEN="$(gh auth token)"
```

**Note:** `sudo` is required here because an internal dependency ([`maxim-lobanov/setup-xcode@v1`](https://github.com/maxim-lobanov/setup-xcode/blob/7f352e61cbe8130c957c3bc898c4fb025784ea1e/src/xcode-selector.ts#L51)) uses the `sudo` command and causes `act` execution to wait for a password interactively.