# Graphical Assets

This directory contains all of the graphical assets which come prebuilt into the Frame firmware. All of the `.png` files here are converted into `system_font.h` using the `create_sprites` tool which is a part of [`frameutils`](https://github.com/brilliantlabsAR/frame-utilities-for-python).

Install `frameutils` using `pip`:

```sh
pip3 install frameutils
```

Generate the font pack using the `create_sprites` command:

```sh
frameutils create_sprites -c 2 --header source/application/lua_libraries/graphical_assets source/application/lua_libraries/graphical_assets/system_font.h
```