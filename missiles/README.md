# Missiles
these are lua script to guide a missile to hit their target based on specific condition or path

## table of content:
| file | description |
| :--- | :---------: |
| AA-missile.lua | this script will derived the target velocity from their past position on its own, and calculate the optimum intercept point (least time) |

## issues:
| file | issues |
| :--- | :----: |
| AA-missile.lua | if the target move to erratically it will likely missed! and also since it will find the optimum intercept point nomatter what, if you face eratic enemy that can move up and down very fast the script will try to aim underwater |