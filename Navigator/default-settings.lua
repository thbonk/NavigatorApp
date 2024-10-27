-- Settings for Navigator

--[[ The following structs with constants are predefined:

SpecialKey contains code for keys like function keys, delete etc.
  SpecialKeycase.upArrow
  SpecialKeycase.downArrow
  SpecialKeycase.leftArrow
  SpecialKeycase.rightArrow
  SpecialKeycase.carriageReturn
  SpecialKeycase.enter
  SpecialKeycase.delete
  SpecialKeycase.tab
  SpecialKeycase.backspace
  SpecialKeycase.home
  SpecialKeycase.end
  SpecialKeycase.pageUp
  SpecialKeycase.pageDown
  SpecialKeycase.help
  SpecialKeycase.f1
  SpecialKeycase.f2
  SpecialKeycase.f3
  SpecialKeycase.f4
  SpecialKeycase.f5
  SpecialKeycase.f6
  SpecialKeycase.f7
  SpecialKeycase.f8
  SpecialKeycase.f9
  SpecialKeycase.f10
  SpecialKeycase.f11
  SpecialKeycase.f12
  SpecialKeycase.f13
  SpecialKeycase.f14
  SpecialKeycase.f15
  SpecialKeycase.f16
  SpecialKeycase.f17
  SpecialKeycase.f18
  SpecialKeycase.f19
  SpecialKeycase.f20

ModifierFlags contains codes for modifier keys
  ModifierFlags.capsLock
  ModifierFlags.shift
  ModifierFlags.control
  ModifierFlags.option
  ModifierFlags.command
  ModifierFlags.numericPad
  ModifierFlags.help
  ModifierFlags.function

Events contains constants for predefined event names
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
]]--

-- new() always returns the same instance of the application settings
applicationSettings = ApplicationSettings.new();

-- Navigator doesn't open a window if this is to false, except there are windows persisted
applicationSettings:setOpenWindowOnStart(true);

-- Brings Navigator to front if the user does a double keypress of the modifier key
applicationSettings:setBringToFrontDoubleTapKey(ModifierFlags.command);

-- Path to the editor for opening Lua files
applicationSettings:setEditor("/Users/thomas/Programme/Visual Studio Code.app");

-- Shortcuts for events
applicationSettings:setShortcutForEvent(Events.navigateBack, {
    modifiers = { ModifierFlags.command },
    key = "b"
});

applicationSettings:setShortcutForEvent(Events.navigateToParent, {
    modifiers = { ModifierFlags.command },
    specialKey = SpecialKey.upArrow
});

applicationSettings:setShortcutForEvent(Events.reloadDirectoryContents, {
    modifiers = { ModifierFlags.command },
    key = "r"
});

applicationSettings:setShortcutForEvent(Events.renameSelectedFile, {
    modifiers = { ModifierFlags.option },
    key = "r"
});

applicationSettings:setShortcutForEvent(Events.showOrHideHiddenFiles, {
    modifiers = { ModifierFlags.shift, ModifierFlags.command },
    key = "i"
});

applicationSettings:setShortcutForEvent(Events.showActionBar, {
    modifiers = { ModifierFlags.shift, ModifierFlags.command },
    key = "p"
});

applicationSettings:setShortcutForEvent(Events.moveSelectedFilesToBin, {
    modifiers = {  },
    specialKey = SpecialKey.delete
});

applicationSettings:setShortcutForEvent(Events.deleteSelectedFiles, {
    modifiers = { ModifierFlags.control },
    specialKey = SpecialKey.delete
});

applicationSettings:setShortcutForEvent(Events.deleteFavorite, {
    modifiers = { ModifierFlags.command },
    specialKey = SpecialKey.delete
});

applicationSettings:setShortcutForEvent(Events.ejectVolume, {
    modifiers = { ModifierFlags.option },
    specialKey = SpecialKey.delete
});

applicationSettings:setShortcutForEvent(Events.pasteFiles, {
    modifiers = { ModifierFlags.command },
    key = "v"
});

applicationSettings:setShortcutForEvent(Events.copyFiles, {
    modifiers = { ModifierFlags.command },
    key = "c"
});

applicationSettings:setShortcutForEvent(Events.cutFiles, {
    modifiers = { ModifierFlags.command },
    key = "x"
});

applicationSettings:setShortcutForEvent(Events.toggleSidebar, {
    modifiers = { ModifierFlags.command },
    key = "s"
});
