# pushpush
An isometric block pushing game.

Learning pico8, watching the [lazydev roguelike tutorials](https://www.youtube.com/watch?v=HnY7Inp74dw&list=PLea8cjCua_P3LL7J1Q9b6PJua0A-96uUS) for inspiration / code notions.

Still trying to figure out environment.

## notes on general render strategy
* We store a table of "cubes" with their x/y/z location in 3d space, as well as a camera direction.
* On updates to either cube locations or camera we sort our table based on distance to camera.
* We render our cubes in this sort order & insert our player character when necessary...

#### thoughts

We could store our player character in the same table as our cubes (especially if we have other objects that should live in this space...)

We could make our cube updates more performant by not sorting in full, rather by removing and inserting into an ordered list...



