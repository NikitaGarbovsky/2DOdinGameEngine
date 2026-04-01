package leveldata

Level_File :: struct {
    version : u32,
    tile_layers : [dynamic]Tile_Layer_Data, 
    // entities : [dynamic]Entity_Instance_Data, // #TODO: Implement when entities save data exists
}

// Mapped json object holding
Tile_Layer_Data :: struct {
    name : string,
    tiles : [dynamic]Tile_Placement_Data,
}

// Mapped json object representing a single tiles placement
Tile_Placement_Data :: struct {
    x : i32,
    y : i32,
    tile : string,
}