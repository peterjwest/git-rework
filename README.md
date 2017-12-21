# Git rework

## Split a commit into multiple commits by working backwards

Git rework exists to simplify rebasing large commits.
It works by letting you work backwards from the finished commit, splitting as you go.

## Rationale

This repository has a branch `example-repo` which you can use to test this utility.

Clone this repository then run `git submodule init`, `git submodule update` to download this branch into the `example-repo` folder.

This branch has a commit "Example large commit" which we want to split. The commit creates/updates 6 files, which depend on each other (with pseudo-code `import` statements):

```
      A
     /  \
    B    \
   / \    |
  |   C   |
   \ / \ /
    D   F
    |
    E
```

How can we split this commit? Well you _could_ remove the import and any related code from A, stage it and stash the other files, then commit A, unstash the files and then redo the changes to A. Then repeat this process for every further commit you want to split.

This requires removing a lot of files from each commit and adding them back again; which tends to be very error prone.

Git rework approaches this from the other direction, by removing features one by one, the process is much simpler.

## Usage

1) Check out the commit you want to rebase
2) Initialise Git rework: `git rework`, the diff of the commit will be staged
3) Remove some portion of the changes, update related code and commit the remainder, but phrase the commit message _as if you were adding the changes_
4) Run `git rework --continue`, the remaining diff of the original commit will be staged
5) Repeat 3 and 4 until you have the first commit you want to make, commit this as a normal commit
6) Run `git rework --continue` once more to finish the process

If anything goes wrong you can run `git rework --abort` to revert to the original commit.

## Installation

You can use this as a standalone bash script e.g. `./rework.sh`, or install it as a git alias:

```bash
git config --global alias.rework '!/path/to/rework.sh'
```
