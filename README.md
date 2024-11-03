# Navigator

A file manager for macOS.

The targeted user group of Navigator are power users and developers as it is completely 
controllable with the keyboard. Most of the function are even only reachable via a hotkey
or a command in the action bar. Navigator can be extended using Lua.

## Lua API

When Navigator is starting, it executes the file `~/.config/Navigator/init.lua`. Application settings
can be changed and commands can be defined. It is possible to structure every Lua artefact in dedicated
files that can be loaded using the Lua function [`require`](https://www.lua.org/pil/8.1.html). The Lua
`package.path` is extended by `~/.config/Navigator/?.lua`.

### LuaRocks Integration

Navigator scripts can use Lua packages that are installed using [LuaRocks](https://luarocks.org). 
To tell the Lua VM started within Navigator where LuaRocks installs its packages you first of all have
to get the paths by running the shell command

```bash
luarocks path
``` 

In the `init.lua` file you then have to adjust `package.path` and `package.cpath`, for example:

```lua
package.path = package.path .. ";" .. "<LUA_PATH output of luarocks>"
package.cpath = package.cpath .. ";" .. "<LUA_CPATH output of luarocks>"
```

Don't overwrite `package.path` and `package.cpath` but extend it.

### Application Settings

Navigator can be configured using the object `ApplicationSettings`. It provides the following functions.

<table>
    <tr>
        <th>Function</th>
        <th>Parameters</th>
        <th>Return Value</th>
        <th>Description</th>
    </tr>
    <tr>
        <td valign="top">setOpenWindowOnStart</td>
        <td valign="top">
            <ul>
                <li>openOnStart: bool</li> 
            </ul>
        </td>
        <td valign="top">None</td>
        <td valign="top">
            Set the flag that determines whether a window shall be opened when the application launches.
            If windows have been persisted, they will be opened regardless of the value of this setting.
        </td>        
    </tr>
    <tr>
        <td valign="top">openWindowOnStart</td>
        <td valign="top">None</td>
        <td valign="top">bool</td>
        <td valign="top">
            Returns the flag that determines whether a window shall be opened when the application launches.
        </td>        
    </tr>
    <tr>
        <td valign="top">setBringToFrontDoubleTapKey</td>
        <td valign="top">
            <ul>
                <li>modifierFlag: int</li> 
            </ul>
        </td>
        <td valign="top">None</td>
        <td valign="top">Sets the modifier flag that bring the application to the front when double tapped.</td>        
    </tr>
    <tr>
        <td valign="top">bringToFrontDoubleTapKey</td>
        <td valign="top">None</td>
        <td valign="top">int</td>
        <td valign="top">Returns the modifier flag that bring the application to the front when double tapped.</td>        
    </tr>
    <tr>
        <td valign="top">setEditor</td>
        <td valign="top">
            <ul>
                <li>applicationPath: string</li> 
            </ul>
        </td>
        <td valign="top">None</td>
        <td valign="top">Sets the path to the editor app bundle for editing Lua files.</td>        
    </tr>
        <tr>
        <td valign="top">editor</td>
        <td valign="top">
            None
        </td>
        <td valign="top">string</td>
        <td valign="top">Returns the path to the editor app bundle for editing Lua files.</td>        
    </tr>
    <tr>
        <td valign="top">setShortcutForEvent</td>
        <td valign="top">
            <ul>
                <li>eventName: string</li>
                <li>shortcut: { modifiers: [int], key: int or specialKey: int }</li>
            </ul>
        </td>
        <td valign="top">None</td>
        <td valign="top">Sets the shortcut key combination for the given event name.</td>        
    </tr>
    <tr>
        <td valign="top">shortcutForEvent</td>
        <td valign="top">
            <ul>
                <li>eventName: string</li>
            </ul>
        </td>
        <td valign="top">{ modifiers: [int], key: int or specialKey: int }</td>
        <td valign="top">Returns the shortcut key combination for the given event name.</td>        
    </tr>
</table>

The following constants for special keys are predefined:

```
  SpecialKey.upArrow
  SpecialKey.downArrow
  SpecialKey.leftArrow
  SpecialKey.rightArrow
  SpecialKey.carriageReturn
  SpecialKey.enter
  SpecialKey.delete
  SpecialKey.tab
  SpecialKey.backspace
  SpecialKey.home
  SpecialKey.end
  SpecialKey.pageUp
  SpecialKey.pageDown
  SpecialKey.help
  SpecialKey.f1
  SpecialKey.f2
  SpecialKey.f3
  SpecialKey.f4
  SpecialKey.f5
  SpecialKey.f6
  SpecialKey.f7
  SpecialKey.f8
  SpecialKey.f9
  SpecialKey.f10
  SpecialKey.f11
  SpecialKey.f12
  SpecialKey.f13
  SpecialKey.f14
  SpecialKey.f15
  SpecialKey.f16
  SpecialKey.f17
  SpecialKey.f18
  SpecialKey.f19
  SpecialKey.f20
```

The following constants for modifier flags are predefined:

```
  ModifierFlags.capsLock
  ModifierFlags.shift
  ModifierFlags.control
  ModifierFlags.option
  ModifierFlags.command
  ModifierFlags.numericPad
  ModifierFlags.help
  ModifierFlags.function
```
The following constants are predefined for event names:

```
  Events.navigateBack
  Events.navigateToParent
  Events.showFileInfos
  Events.showActionBar
  Events.showOrHideHiddenFiles
  Events.reloadDirectoryContents
  Events.renameSelectedFile
  Events.moveSelectedFilesToBin
  Events.deleteSelectedFiles
  Events.deleteFavorite
  Events.ejectVolume
  Events.pasteFiles
  Events.copyFiles
  Events.cutFiles
  Events.toggleSidebar
``` 

### Application

TODO

## Licenses

### Icons

#### FileshareIcon

Smooth Leopard Icons 

made by Susumu Yoshida (Copyright © 2009 McDo DESIGN.com)
http://www.mcdodesign.com/

### Dependencies

#### Apple Sample Code

Copyright © Apple Inc.

Permission is hereby granted, free of charge, to any person obtaining 
a copy of this software and associated documentation files (the 
"Software"), to deal in the Software without restriction, including 
without limitation the rights to use, copy, modify, merge, publish, 
distribute, sublicense, and/or sell copies of the Software, and to 
permit persons to whom the Software is furnished to do so, subject 
to the following conditions:

The above copyright notice and this permission notice shall be 
included in all copies or substantial portions of the Software.

THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS 
OR IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF 
MERCHANTABILITY, FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. 
IN NO EVENT SHALL THE AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY 
CLAIM, DAMAGES OR OTHER LIABILITY, WHETHER IN AN ACTION OF CONTRACT, 
TORT OR OTHERWISE, ARISING FROM, OUT OF OR IN CONNECTION WITH THE 
SOFTWARE OR THE USE OR OTHER DEALINGS IN THE SOFTWARE.

#### Causality

https://github.com/dannys42/Causality.git

Copyright 2020 Danny Sung

Licensed under the Apache License, Version 2.0 (the "License");
you may not use this file except in compliance with the License.
You may obtain a copy of the License at

   http://www.apache.org/licenses/LICENSE-2.0

Unless required by applicable law or agreed to in writing, software
distributed under the License is distributed on an "AS IS" BASIS,
WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
See the License for the specific language governing permissions and
limitations under the License.

#### DSFActionBar

https://github.com/dagronf/DSFQuickActionBar

MIT License

Copyright (c) 2022 Darren Ford

Permission is hereby granted, free of charge, to any person obtaining a 
copy of this software and associated documentation files (the "Software"), 
to deal in the Software without restriction, including without limitation 
the rights to use, copy, modify, merge, publish, distribute, sublicense, 
and/or sell copies of the Software, and to permit persons to whom the 
Software is furnished to do so, subject to the following conditions:

The above copyright notice and this permission notice shall be included in 
all copies or substantial portions of the Software.

THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR 
IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY, 
FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE 
AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER 
LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM, 
OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN THE 
SOFTWARE.

#### Magnet

https://github.com/Clipy/Magnet

The MIT License (MIT)

Copyright (c) 2015-2020 Clipy Project

Permission is hereby granted, free of charge, to any person obtaining a copy
of this software and associated documentation files (the "Software"), to deal
in the Software without restriction, including without limitation the rights
to use, copy, modify, merge, publish, distribute, sublicense, and/or sell
copies of the Software, and to permit persons to whom the Software is
furnished to do so, subject to the following conditions:

The above copyright notice and this permission notice shall be included in all
copies or substantial portions of the Software.

THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR
IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY,
FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE
AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER
LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM,
OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN THE
SOFTWARE.

#### SnapKit

https://github.com/SnapKit

Copyright (c) 2011-Present SnapKit Team

Permission is hereby granted, free of charge, to any person obtaining a copy
of this software and associated documentation files (the "Software"), to deal
in the Software without restriction, including without limitation the rights
to use, copy, modify, merge, publish, distribute, sublicense, and/or sell
copies of the Software, and to permit persons to whom the Software is
furnished to do so, subject to the following conditions:

The above copyright notice and this permission notice shall be included in
all copies or substantial portions of the Software.

THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR
IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY,
FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE
AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER
LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM,
OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN
THE SOFTWARE.
