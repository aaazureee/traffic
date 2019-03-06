/**
* Name: Definition of a chart display
* Author:
* Description: 6th part of the tutorial: Road Traffic
* Tags: chart
*/
model tutorial_gis_city_traffic

global {
  file shape_file_roads <- file("../fresh/cacto.shp");
  //  file shape_file_nodes <- file("../fresh/node-test.shp");
  geometry shape <- envelope(shape_file_roads);
  float step <- 1 #s;
  int nb_people <- 100;
  graph the_graph;

  init {
    create road from: shape_file_roads;
    int road_counter <- 0;
    ask road {
      name <- 'road' + string(road_counter);
      road_counter <- road_counter + 1;
    }

    //    int node_counter <- 0;
    //    create testNode from: shape_file_nodes;
    //    ask testNode {
    //      name <- 'testNode' + string(node_counter);
    //      node_number <- node_counter;
    //      node_counter <- node_counter + 1;
    //    }

    //        ask road {
    //          create road {
    //            shape <- polyline(reverse(myself.shape.points));
    //          }
    //    
    //        }

    //    ask road {
    //      ask road {
    //        if (myself.shape.points[0] = self.shape.points[length(self.shape.points) - 1] and self.shape.points[0] = myself.shape.points[length(myself.shape.points) - 1] and self !=
    //        myself) {
    //          write string(myself) + " --- " + self;
    //        }
    //
    //        //        write myself.destruction_coeff; // outer = myself, inner=self.
    //      }
    //
    //    }
    write "------------------";
    ask road {
      point start <- shape.points[0];
      point end <- shape.points[length(shape.points) - 1];
      if (length(testNode overlapping start) = 0) {
        create testNode {
          location <- start;
        }

      }

      if (length(testNode overlapping end) = 0) {
        create testNode {
          location <- end;
        }

      }

    }

    map<road, float> weights_map <- road as_map (each::(each.shape.perimeter));
    the_graph <- as_edge_graph(road) with_weights weights_map;
    the_graph <- directed(the_graph);

    //      create people {
    //        location <- testNode(180).location;
    //        the_target <- testNode(181).location;
    //        shortest_path <- path_between(the_graph, location, the_target);
    //      }
    loop i from: 0 to: nb_people - 1 {
      bool result <- gen_people();
      loop while: (result = false) {
        result <- gen_people();
      }

    }

    write length(people);
  }

  bool gen_people {
    bool result <- true;
    create people {
      int random_origin_index <- rnd(length(testNode) - 1);
      location <- testNode[random_origin_index].location; // CHANGE HERE
      int random_dest_index <- rnd(length(testNode) - 1);
      loop while: random_origin_index = random_dest_index {
        random_dest_index <- rnd(length(testNode) - 1);
      }

      the_target <- testNode[random_dest_index].location;
      try {
        shortest_path <- path_between(the_graph, location, the_target);
      }

      catch {
        result <- false;
        do die;
      }

      if (shortest_path = nil or length(shortest_path.edges) = 0) {
        result <- false;
        do die;
      }

    }

    return result;
  }

}

species testSpecies {
}

species testNode {
  int node_number;

  aspect base {
    draw string(node_number) color: #black font: font('Helvetica', 5, #plain);
    //    draw circle(50) color: #yellow;
  }

}

species people skills: [moving] {
  rgb color <- #yellow;
  point the_target <- nil;
  path shortest_path;
  float speed <- 1 #m / #s;
  //  reflex move when: the_target != nil {
  //    path path_followed <- self goto [target::the_target, on::the_graph, return_path::true];
  //    list<geometry> segments <- path_followed.segments;
  //    loop line over: segments {
  //      float dist <- line.perimeter;
  //    }
  //
  //    if the_target = location {
  //      the_target <- nil;
  //    }
  //
  //  }
  reflex move {
    write shortest_path;
    do follow path: shortest_path;
    if (self overlaps the_target) {
      do die;
    }

  }

  aspect base {
    draw circle(15) color: color border: #black;
  }

}

species road {
  float destruction_coeff <- 1 + ((rnd(100)) / 100.0) max: 2.0;
  int colorValue <- int(255 * (destruction_coeff - 1)) update: int(255 * (destruction_coeff - 1));
  rgb color <- rgb(min([255, colorValue]), max([0, 255 - colorValue]), 0) update: rgb(min([255, colorValue]), max([0, 255 - colorValue]), 0);

  aspect base {
    draw shape color: color;
  }

}

experiment road_traffic type: gui {
  output {
    display city_display type: opengl {
      species road aspect: base;
      species people aspect: base;
      species testNode aspect: base;
    }

    //    display chart_display refresh: every(10 #cycles) {
    //      chart "Road Status" type: series size: {1, 0.5} position: {0, 0} {
    //        data "Mean road destruction" value: mean(road collect each.destruction_coeff) style: line color: #green;
    //        data "Max road destruction" value: road max_of each.destruction_coeff style: line color: #red;
    //      }
    //
    //      chart "People Objectif" type: pie style: exploded size: {1, 0.5} position: {0, 0.5} {
    //        data "Working" value: people count (each.objective = "working") color: #magenta;
    //        data "Resting" value: people count (each.objective = "resting") color: #blue;
    //      }
    //
    //    }

  }

}
