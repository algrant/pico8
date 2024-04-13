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


#### Think about scene graph / ds's

* store groups
* iterate in render order for drawing...

scene = {
    camera_dir = 0 - 15 -- currently 15 directions...

    objs = {
        [id] = { id, gid, x, y, z, ... }
        ...
    }
    -- for draw
    ordered_ids = { id_a, id_b, id_c ... }

    groups = {
        [gid] = {id1, id2, ... }
    }
}


* update_camera_dir(new_dir) => {

}

-- obj must have { x, y, z, t?, c? }
* add_obj(obj, unsorted=true) => {
    -- add to objs
    -- insert into ordered_ids
}

* get_obj(id) =>
* get_group (id_p) => {id_o, id_p, id_q ...}
* move_obj (idx, dx, dy) => {
    local can_move = true
    local obj =
    for id in all(get_group(idx)) do

    end
}
*
