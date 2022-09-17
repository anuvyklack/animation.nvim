# Animation.nvim

An OOP library to create animations in Neovim (as far as terminal application
with unstable timer allows creating animations).

The animation library is build on top of libuv timers (since Neovim has nothing
else). But they are unstable: you can set it to repeat in 30 ms, but if the
event loop was busy, the timers' callback can be expired in, for example, 67
ms and callback will be called twice in a row.

To fight it, the library implements a self-adjustment timer.  The next snapshot
illustrates how does it work.  The period between frames is 25 ms, duration is
500 ms.  Note that 3rd and 15th frames were missed.

```
 1   elapsed 25   repeat 25   total  25
 2   elapsed 24   repeat 26   total  49
 ‧‧‧‧‧‧‧‧‧‧‧‧‧‧‧‧‧‧‧‧‧‧‧‧‧‧‧‧‧‧‧‧‧‧‧‧‧‧
 4   elapsed 54   repeat 22   total 103
 5   elapsed 23   repeat 24   total 126
 6   elapsed 23   repeat 26   total 149
 7   elapsed 26   repeat 25   total 175
 8   elapsed 25   repeat 25   total 200
 9   elapsed 42   repeat  8   total 242
10   elapsed 16   repeat 17   total 258
11   elapsed 17   repeat 25   total 275
12   elapsed 25   repeat 25   total 300
13   elapsed 25   repeat 25   total 325
14   elapsed 25   repeat 25   total 350
‧‧‧‧‧‧‧‧‧‧‧‧‧‧‧‧‧‧‧‧‧‧‧‧‧‧‧‧‧‧‧‧‧‧‧‧‧‧‧
16   elapsed 59   repeat 16   total 409
17   elapsed 16   repeat 25   total 425
18   elapsed 26   repeat 24   total 451
19   elapsed 23   repeat 26   total 474
stop ----------------------------------
```

# Installation

This library requires [middleclass](https://github.com/anuvyklack/middleclass/tree/master)
as dependency. To install it with [packer](https://github.com/wbthomason/packer.nvim)
plugin manager use this snippet:

```lua
use { 'anuvyklack/animation.nvim', 
   requires = 'anuvyklack/middleclass'
}
```

# Quick example

```lua
local Animation = require('animation')
local duration = 300 -- ms
local fps = 30 -- frames per second
local easing = require('animation.easing')

local i = 0

local function callback(fraction)
   i = i + 1
   print('frame ', i)
end

local animation = Animation(duration, fps, easing.line, callback)
animation:run()
```

# Animation class

### `Animation(duration, fps, easing, [callback])`
Or `Animation:new(duration, fps, easing, [callback])`. 

A constructor of animation object.

**Parameters:**

- **`duration`** : `integer`  

  The duration of animation in milliseconds.

- **`fps`:** `integer`  

  Frames per second.

- **`easing`:** `fun(ratio: number): number`  

  Easing function. To understand what it is check this [link](https://easings.net).
  The easing function should take a number in range from 0 to 1 and return
  a number from 0 to 1.

  You can find some of easing functions in [easing.lua](https://github.com/anuvyklack/animation.nvim/blob/main/lua/animation/easing.lua)
  file.

- **`callback`:** `fun(fraction: number): boolean|nil`, `optional`

  The function that will be called on every animation tick. Accept a `fraction`
  parameter, which is a number from 0 to 1 that `easing` function has returned.

  If `callback` function returns `true` the animation will be finished.

**Returns:** animation object

### `Animation:run()`

Start the animation. If animation is running — do nothing.

### `Animation:finish()`

Finish animation if it is running, else — do nothing.

### `Animation:is_running()`

Return `true` if animation is running, else return `false`.

### `Animation:set_callback(callback)`

Set the `callback` function. See `constructor` description for more info about
`callback` function.
