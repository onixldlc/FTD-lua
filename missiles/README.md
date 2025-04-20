# Missiles
these are lua script to guide a missile to hit their target based on specific condition or path

## table of content:
| file | description |
| :--- | :---------: |
| AA-missile.lua | this script will derived the target velocity from their past position on its own, and calculate the optimum intercept point (least time) |
| rod_from_god-carrier-missile.lua | this script will guide your huge missile to 2000m above the target, and rain rod_from_god with a remote guidance system. the aim is to hit the target with multiple missile placed in generaly the same spot, which in a way would bore a hole from above and hopefully kill the ai before it even get the chance to close in and fire a shot |

## issues:
| file | issues |
| :--- | :----: |
| AA-missile.lua | if the target move to erratically it will likely missed! and also since it will find the optimum intercept point nomatter what, if you face eratic enemy that can move up and down very fast the `script will try to aim underwater if the enemy ` |
| rod_from_god-carrier-missile.lua | since i don't know how to tell the lua script to target a specific block that i want it to target, this weapon system came with a `3 meter of inaccuracy`... altho after testing, a rod_from_god with HEAT tip and as much explosive as you can usually does the job, also the cost of `material to fire one of these weapon is quite huge`, like in the 5000-10000 range. whilst it's quite pricey, you are paying for a longrange precision strikes! as it can hit anything from 8km away with a 3m inaccuracy |