
# Organisms

Organisms are the fancy name for plugins to Ecosystem. Often they are simply a Chef Wrapper Cookbook that besides installing a tool provides some wrapper integration to the rest of Ecosystem.

## Anatomy

Let's talk about the end result versus how these things get installed and configured. Firstly there is folder where organisms reside:

```
my-project/workspace-settings/organisms
```

Children of the organisms folder are an organism, let's take the example atom.

```
my-project/workspace-settings/organisms/atom
```

Organisms can integrate with Ecosystem through the shell, ruby, and rake. Ecosystem will find and source the bash file:

```
my-project/workspace-settings/organisms/atom/shell/lib/organism.bash
```

As well as the rake file:

```
my-project/workspace-settings/organisms/atom/rake/default.rake
```

And finally it will include this path in the ruby load path:

```
my-project/workspace-settings/organisms/atom/ruby/lib
```
