# Building model
Simulates COVID spread on a smaller scale (i.e. buildings)

## Usage
1. Prepare these required shapefiles (see [this directory](../../Datasets/Danang%20Hospital/nephrology_department/) for an example):
    * `walls.shp`: polylines representing walls in a building, with gaps representing doors
    * `rooms.shp`: polygons representing rooms, and they should be properly enclosed by the walls in `walls.shp`

      NOTE: you can generate `rooms.shp` using a "closed" version of `walls.shp` with no door gaps (see step 2)
2. Run the experiment in [Generate Pedestrian Shapefiles.gaml](./Generate%20Pedestrian%20Shapefiles.gaml) to generate necessary shapefiles for pedestrian skill to work. You can also provide `closed_walls.shp` to generate `rooms.shp` if it has not been created yet.
3. In [Global.gaml](./Global.gaml), change this part to include floors of your liking:
   ```
   // Two exact same floor plans placed side by side
   list<string> floor_dirs <- [
       "Danang Hospital/nephrology_department", "Danang Hospital/nephrology_department"
   ];
   int num_layout_rows <- 1;
   int num_layout_columns <- 2;
   ```
4. Run the experiment in [Building Experiments.gaml](./Experiments/Building%20Experiments.gaml)
