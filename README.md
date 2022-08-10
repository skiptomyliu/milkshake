#  <img src="/images/icon_32x32@2x.png" width="32"> Milkshake: Pandora Radio macOS app

## MAINTENANCE MODE

## The app can no longer be logged into due to changes on Pandora login API.  There's an issue tracking this work in this [Issue](https://github.com/skiptomyliu/milkshake/issues/42#issuecomment-1003235490).  This repo is in indefinite hiatus until I can find time to migrate from the REST API to the [JSON API](https://6xq.net/pandora-apidoc/json/). 


<img src="/images/screenshot1.png"  width="290"> <img src="/images/screenshot2.png"  width="290"> <img src="/images/screenshot3.png"  width="290">
<img src="/images/screenshot4.png"  width="290"> <img src="/images/screenshot5.png"  width="290"> <img src="/images/screenshot6.png"  width="290">

Milkshake is a Mac OS X [Pandora](https://www.pandora.com) client.

If you don't have a Pandora account, you can [sign up here](https://www.pandora.com/account/register)

# Download v1.1.0
[.DMG Installer](https://github.com/skiptomyliu/milkshake/raw/master/App/Milkshake.dmg)


# Important note
This client isn't a full Pandora replacement.  This client doesn't support creating playlists, you'll still need to create them on [pandora.com](https://www.pandora.com) before seeing it on Milkshake.

# Features
  - Minimalist UI that focuses on album art
  - Shortcuts
  - Cross fading
  - Keep player as front window
  - Easy navigation
  - Pandora Premium users will be able to play on demand

# Shortcuts
Keys | Action 
--- | --- | 
^⌘]  | next song 
^⌘[  | previous song
^⌘P | pause song
^⌘R | repeat song
^⌘+| thumb up
^⌘-| thumb down 

If you want to modify the shortcuts, you can modify it in [AppDelegate.swift](https://github.com/skiptomyliu/milkshake/blob/master/Milkshake/AppDelegate.swift#L50-L113) and re-compile.  I haven't had time to overwrite the keyboard media keys.


Icons made by [Smashicons](https://www.flaticon.com/authors/smashicons) from [flaticon.com](https://www.flaticon.com/) is licensed by [CC 3.0 BY](http://creativecommons.org/licenses/by/3.0/)

