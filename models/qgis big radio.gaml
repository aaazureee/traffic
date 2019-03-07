model small_radio

global {
  graph my_graph; 
  list<point> nodes;
  list<float> time_list; // list of time to arrive to next node;  
  bool change_graph_action <- false;
  float curve_width_eff <- 0.05;
  float seed <- 1.0; // rng seed for reproducing the same result (dev mode);
  
  file shape_file_roads <- file("../fresh/cacto.shp");
  geometry shape <- envelope(shape_file_roads);

  // Category: people related variables
  int nb_people_init <- 50;
  int min_nb_people_spawn <- 10 min: 0 max: 99;
  int max_nb_people_spawn <- 20 min: 0 max: 99;
  int spawn_interval <- 20 min: 0 max: 99;

  // Category: road density count
  int low_count -> {length(road where (each.status = "low"))};
  int moderate_count -> {length(road where (each.status = "moderate"))};
  int high_count -> {length(road where (each.status = "high"))};
  int extreme_count -> {length(road where (each.status = "extreme"))};
  int traffic_jam_count -> {length(road where (each.status = "traffic_jam"))};

  // Category: road related variables
  float min_free_speed <- 7.0 #m / #s;
  float max_free_speed <- 15.0 #m / #s;
  int min_capacity_val <- 5;
  int max_capacity_val <- 10;

  // Stats
  list<float> speed_list -> {people collect each.speed};
  map<string, list> speed_histmap -> {distribution_of(speed_list, 10, min_free_speed, max_free_speed)};
  int nb_people_current -> {length(people)};
  int nb_trips_completed <- 0;
  float avg_speed -> {mean(speed_list)};

  // Stats of people who cant find path      
  list<people> list_people_cant_find_path -> {people where (each.cant_find_path and each.is_on_node and !each.stuck_same_location)}; // acumulated number of people who cant find the shortest path during the simulation
  int num_people_cant_find_path <- 0;

  // Node accumulated traffic count
  list<my_node> top_traffic_nodes -> {my_node sort_by -each.accum_traffic_count};
  int node_accum_traffic_sum -> {sum(top_traffic_nodes collect each.accum_traffic_count)};
  int k_node <- 15 min: 1 max: 20;

  // Road accumulated traffic count
  list<road> top_traffic_roads -> {road sort_by -each.accum_traffic_count};
  int road_accum_traffic_sum -> {sum(top_traffic_roads collect (each.accum_traffic_count))};
  int k_road <- 15 min: 1 max: 20;

  // orig-dest count
  list<list<int>> orig_dest_matrix;

  init {
    // load road network from shape file
    create road from: shape_file_roads;
    int road_counter <- 0;
    ask road {
      name <- 'road' + string(road_counter);
      link_length <- shape.perimeter; // double link length test
      free_speed <- (min_free_speed + rnd(max_free_speed - min_free_speed)) with_precision 2;
      max_capacity <- min_capacity_val + rnd(max_capacity_val - min_capacity_val);
      road_counter <- road_counter + 1;
      
      // Create nodes between roads (non-duplicate check)
      point start <- shape.points[0];
      point end <- shape.points[length(shape.points) - 1];
      if (length(my_node overlapping start) = 0) {
        create my_node {
          location <- start;
        }

      }

      if (length(my_node overlapping end) = 0) {
        create my_node {
          location <- end;
        }

      }
    }
                    
//    create road {
//      shape <- curve(my_node[0].location, my_node[1].location, curve_width_eff);
//      link_length <- shape.perimeter; // double link length test
//      free_speed <- (min_free_speed + rnd(max_free_speed - min_free_speed)) with_precision 2;
//      max_capacity <- min_capacity_val + rnd(max_capacity_val - min_capacity_val);
//    }
//
//    create road {
//      shape <- curve(my_node[1].location, my_node[2].location, curve_width_eff);
//      link_length <- shape.perimeter; // double link length test
//      free_speed <- (min_free_speed + rnd(max_free_speed - min_free_speed)) with_precision 2;
//      max_capacity <- min_capacity_val + rnd(max_capacity_val - min_capacity_val);
//    }
//
//    create road {
//      shape <- curve(my_node[2].location, my_node[3].location, curve_width_eff);
//      link_length <- shape.perimeter; // double link length test
//      free_speed <- (min_free_speed + rnd(max_free_speed - min_free_speed)) with_precision 2;
//      max_capacity <- min_capacity_val + rnd(max_capacity_val - min_capacity_val);
//    }
//
//    create road {
//      shape <- curve(my_node[0].location, my_node[3].location, curve_width_eff);
//      link_length <- shape.perimeter; // double link length test
//      free_speed <- (min_free_speed + rnd(max_free_speed - min_free_speed)) with_precision 2;
//      max_capacity <- min_capacity_val + rnd(max_capacity_val - min_capacity_val);
//    }

    //     try reverse
//    ask road {
//      create road {
//        int len <- length(myself.shape.points);
//        shape <- curve(myself.shape.points[len - 1], myself.shape.points[0], curve_width_eff);
//        link_length <- myself.link_length;
//        free_speed <- myself.free_speed;
//        max_capacity <- myself.max_capacity;
//      }
//
//    }

    // populate orig dest matrix based on number of nodes
    int max_len <- length(my_node);
    orig_dest_matrix <- list_with(max_len, list_with(max_len, 0));

    // generate graph
    my_graph <- as_edge_graph(road where (!each.hidden)) with_weights (road as_map (each::each.link_length));
    // directed graph
    my_graph <- directed(my_graph);
    
    // init people
    do batch_create_people(nb_people_init);
        
    create file_saver number: 1;
    write length(people);
  }

  reflex generate_people when: every(spawn_interval) {
    do batch_create_people((min_nb_people_spawn + rnd(max_nb_people_spawn - min_nb_people_spawn)) - 1);
  }

  // empty list first then update min time
  reflex refresh_min_time {
    time_list <- [];
    do update_min_time;
    if (change_graph_action = true) {
      change_graph_action <- false;
    }

  }
  
  action batch_create_people(int number) {
    loop i from: 0 to: number - 1 {         
      bool result <- create_people();
      loop while: !result {
        result <- create_people();
      }
    }
  }
  
  // private helper function
  bool create_people  {
    bool result <- true;
    create people {
      int random_origin_index <- rnd(length(my_node) - 1);
      location <- my_node[random_origin_index].location; // CHANGE HERE
      int random_dest_index <- rnd(length(my_node) - 1);
      loop while: random_origin_index = random_dest_index {
        random_dest_index <- rnd(length(my_node) - 1);
      }

      dest <- my_node[random_dest_index].location;
      try {
        shortest_path <- path_between(my_graph, location, dest);
      }

      catch {
        result <- false;
        do die;
      }

      // check for problem with shortest_path when there are no edges connecting a node
      if (shortest_path != nil and shortest_path.shape != nil and (shortest_path.shape.points[0] != location or shortest_path.shape.points[length(shortest_path.shape.points) - 1]
      != dest)) {
        result <- false;
        do die;
      }
      
      if (cant_find_path = false) {
        
        if (shortest_path = nil or length(shortest_path.edges) = 0) {
          result <- false;
          do die;
        } else {
        // Fixed road path          
          fixed_edges <- shortest_path.edges collect (road(each));
          num_nodes_to_complete <- length(fixed_edges);
          current_road <- fixed_edges[current_road_index];
          orig_dest_matrix[random_origin_index][random_dest_index] <- orig_dest_matrix[random_origin_index][random_dest_index] + 1;
          result <- true;
        }

      }

      speed <- 0 #m / #s;
      // increment traffic count at source location node
      my_node(location).accum_traffic_count <- my_node(location).accum_traffic_count + 1;      
    }
    return result;
  }

  action create_people_test (int num_people, int u_location, int u_dest) {
    create people number: num_people {
      location <- my_node[u_location].location;
      dest <- my_node[u_dest].location;
      try {
        shortest_path <- path_between(my_graph, location, dest);
      }

      catch {
        do die;
      }

      // check for problem with shortest_path when there are no edges connecting a node
      if (shortest_path != nil and shortest_path.shape != nil and (shortest_path.shape.points[0] != location or shortest_path.shape.points[length(shortest_path.shape.points) - 1]
      != dest)) {
        do die;
      }

      if (cant_find_path = false) {
        if (shortest_path = nil or length(shortest_path.edges) = 0) {
          do die;
        } else {
        // Fixed road path          
          fixed_edges <- shortest_path.edges collect (road(each));
          num_nodes_to_complete <- length(fixed_edges);
          current_road <- fixed_edges[current_road_index];
          orig_dest_matrix[u_location][u_dest] <- orig_dest_matrix[u_location][u_dest] + 1;
        }

      }

      speed <- 0 #m / #s;
      // increment traffic count at source location node
      my_node(location).accum_traffic_count <- my_node(location).accum_traffic_count + 1;
    }

  }

  action update_min_time {
    list<people> selected_people <- people where ((!each.cant_find_path or (each.cant_find_path and !each.is_on_node)) and ((!each.is_in_blocked_road) or (each.is_in_blocked_road
    and each.current_road_index = each.num_nodes_to_complete - 1)));
    // only ask people that is not in blocked road or people in blocked road but the dest in on that road
    ask selected_people {
      if (self overlaps dest) {
        nb_trips_completed <- nb_trips_completed + 1;
        do die;
      }
      current_road <- fixed_edges[current_road_index];
      int len <- length(current_road.shape.points);
      next_node <- point(current_road.shape.points[len - 1]);
      //      write next_node;
      // current road segment
      float true_link_length <- current_road.link_length; // link length (real_)
      //      write "True link length: " + true_link_length;
      float distance_to_next_node;
      // distance along the curve (must use graph topology because normal distance is euclidean distance
      // i.e. not distance on the curve, which is what we want).
      graph current_graph;
      if (is_in_blocked_road and current_road_index = num_nodes_to_complete - 1) {
      //        write "In updating speed, calculating to minigraph";
        current_graph <- mini_graph;
      } else {
      //        write "Using normal graph";
        current_graph <- my_graph;
      }

      using topology(current_graph) {
        distance_to_next_node <- self distance_to next_node; // gama distance (2d graph)
      }
      //      float distance_to_next_node <- self distance_to next_node; // gama distance (2d graph)
      //      float distance_to_next_node <- topology(current_road) distance_between [self, next_node];
      //      write "next node: " + next_node;
      //      write "GAMA distance: " + distance_to_next_node;
      if (is_road_jammed = true) {
        is_road_jammed <- current_road.current_volume = current_road.max_capacity; // is person stuck?
        speed <- 0 #m / #s;
      }
      //      write string(current_road.current_volume) + "/" + current_road.max_capacity;
      //      write "JAMMED STATUS: " + is_road_jammed;
      if (is_road_jammed = false) { // only do stuff is road is not jammed
      // FIND initial RATIO + speed at start of each road
        if (is_on_node = true or change_graph_action = true) {
        // Handle special road blockage, re-calculate things
          if (change_graph_action = true) {
            ratio <- true_link_length / current_road.shape.perimeter;
          } else {
            ratio <- true_link_length / distance_to_next_node;
          }

          speed <- myself.get_equi_speed(current_road.free_speed, current_road.current_volume, current_road.max_capacity);
          if (is_in_blocked_road = false) {
            if (is_on_node) {
              current_road.current_volume <- current_road.current_volume + 1; // increase traffic volume of the road
            }

          }

        }

        //        write "RATIO: " + ratio;
        real_dist_to_next_node <- distance_to_next_node * ratio;
        float travel_time <- real_dist_to_next_node / speed;
        //        write string(self) + ", speed: " + speed + ", travel time: " + travel_time;
        //        write "Travelled: " + (speed * travel_time);
        //        write "Location: " + location;
        //        write "Real dist to next node: " + real_dist_to_next_node;
        add travel_time to: time_list;
        //        write "//////////////";
      }

    }

    float min_time;
    min_time <- min(time_list);
    ask selected_people {
      step <- min_time;
    }

    //    write "Min:" + min_time;
    write "-----------";
  }

  // BPR equation
  float get_equi_speed (float free_speed, int current_volume, int max_capacity) {
    return free_speed / (1 + 0.15 * (current_volume / max_capacity) ^ 4);
  }

  action mouse_down_evt {
    geometry circ <- circle(15, #user_location);
    list<people> test <- people inside circ;
    if (length(test) > 0) {
      write test;
      people selected_person <- test[0];
      write selected_person;
      ask selected_person {
        if (clicked = true) {
          clicked <- false;
        } else {
          clicked <- true;
        }

      }

    }

  }

}

/*
 * People species
 */
species people skills: [moving] {
  rgb color <- rgb([rnd(255), rnd(255), rnd(255)]);
  point dest; // destination node
  path shortest_path; // shortest path
  list<road> fixed_edges;
  int num_nodes_to_complete;
  int current_road_index <- 0;
  point next_node;
  bool is_on_node <- true;
  bool clicked <- false; // gui variable
  float ratio <- 1.0;
  float real_dist_to_next_node;
  road current_road;
  bool is_road_jammed <- true;
  bool is_in_blocked_road <- false;
  bool cant_find_path <- false;
  bool has_radio <- flip(0.5); // whether people is notified of route change globally
  graph mini_graph; // graph for people already in blocked road but still can move to dest in the same road.
  bool moving_in_blocked_road <- false;
  bool stuck_same_location <- true;

  reflex update_unique_stuck_count when: !stuck_same_location {
    write "I am " + self + ", is now stuck at same location after first cycle";
    stuck_same_location <- true;
  }

//  reflex {
//    write string(self) + " has radio: " + has_radio;
//  }

  // Attempt to reroute when stuck at one node and cant find path
  reflex reroute_attempt when: cant_find_path and is_on_node {
    write string(self) + " attempt reroute";
    try {
      shortest_path <- path_between(my_graph, location, dest);
    }

    catch {
      cant_find_path <- true;
      speed <- 0 #m / #s;
      return;
    }

    // check for problem with shortest_path when there are no edges connecting a node
    if (shortest_path != nil and shortest_path.shape != nil and (shortest_path.shape.points[0] != location or shortest_path.shape.points[length(shortest_path.shape.points) - 1] !=
    dest)) {
      cant_find_path <- true;
      speed <- 0 #m / #s;
      return;
    }

    // if cannot find the shortest path
    if (shortest_path = nil or length(shortest_path.edges) = 0) {
      cant_find_path <- true;
      speed <- 0 #m / #s;
    } else {
      fixed_edges <- shortest_path.edges collect (road(each));
      num_nodes_to_complete <- length(fixed_edges);
      current_road_index <- 0;
      current_road <- fixed_edges[current_road_index];
      cant_find_path <- false;
    }

  }

  // Smart move
  reflex smart_move when: (!cant_find_path or (cant_find_path and !is_on_node)) and !is_road_jammed and (!is_in_blocked_road or (is_in_blocked_road and
  current_road_index = num_nodes_to_complete - 1)) {
    float epsilon <- 10 ^ -5;
    // Accumulate traffic on agent's shortest's path road
    if (is_on_node = true) {
      current_road.accum_traffic_count <- current_road.accum_traffic_count + 1;
    }

    do follow path: shortest_path;
    is_on_node <- false;
    // Handle epsilon (where calculation between float values with multiples decimals might cause error).
    float distance_to_next_node;
    using topology(my_graph) {
      distance_to_next_node <- self distance_to next_node;
    }

    real_dist_to_next_node <- distance_to_next_node * ratio;
    if (real_dist_to_next_node < epsilon or ((self distance_to next_node) * ratio) < epsilon) {
      self.location <- next_node.location;
    }

    // CHECK IF PERSON IS ON ONE NODE
    if (self overlaps next_node) {
      current_road.current_volume <- current_road.current_volume - 1;
      my_node(next_node).accum_traffic_count <- my_node(next_node).accum_traffic_count + 1;
      // if its the final node
      if (current_road_index = num_nodes_to_complete - 1 or self overlaps dest) {
        nb_trips_completed <- nb_trips_completed + 1;
        do die;
      } else {
        is_on_node <- true;
        is_road_jammed <- true;
        current_road_index <- current_road_index + 1;
        current_road <- fixed_edges[current_road_index];
        if (cant_find_path and is_on_node) {
          num_people_cant_find_path <- num_people_cant_find_path + 1;
          stuck_same_location <- false;
          speed <- 0 #m / #s;
        }

        // if next road is blocked, do reroute:
        if (current_road.blocked = true and !cant_find_path) {
          write "Next road is blocked, doing reroute " + self;
          try {
            shortest_path <- path_between(my_graph, location, dest);
          }

          catch {
            num_people_cant_find_path <- num_people_cant_find_path + 1;
            cant_find_path <- true;
            stuck_same_location <- false;
            speed <- 0 #m / #s;
            return;
          }

          // check for problem with shortest_path when there are no edges connecting a node
          if (shortest_path != nil and shortest_path.shape != nil and shortest_path.shape.points[length(shortest_path.shape.points) - 1] != dest) {
            num_people_cant_find_path <- num_people_cant_find_path + 1;
            cant_find_path <- true;
            stuck_same_location <- false;
            speed <- 0 #m / #s;
            return;
          }

          // if cannot find the shortest path
          if (shortest_path = nil or length(shortest_path.edges) = 0) {
            num_people_cant_find_path <- num_people_cant_find_path + 1;
            cant_find_path <- true;
            stuck_same_location <- false;
            speed <- 0 #m / #s;
          } else {
            fixed_edges <- shortest_path.edges collect (road(each));
            num_nodes_to_complete <- length(fixed_edges);
            current_road_index <- 0;
            current_road <- fixed_edges[current_road_index];
          }

        }

      }

    }

  }

  aspect base {
    if (is_in_blocked_road and current_road_index = num_nodes_to_complete - 1) {
      if (clicked = true) {
        draw circle(2) at: point(self.location) color: #yellow;
        draw circle(2) at: point(self.dest) color: #cyan;
        draw polyline([self.location, self.dest]) color: #pink width: 5;
      }

    } else if (clicked = true and cant_find_path = false) {
      path new_path <- path_between(my_graph, location, dest);
      draw circle(2) at: point(new_path.source) color: #yellow;
      draw circle(2) at: point(new_path.target) color: #cyan;
      draw new_path.shape color: #pink width: 5;
    }

    if (is_in_blocked_road = true) {
      draw triangle(15) color: color;
    } else {
      draw circle(15) color: color;
    }

  }

}

/*
 * Road species
 */
species road {
  float link_length;
  float free_speed;
  int max_capacity;
  int current_volume <- 0;
  float link_full_percentage -> {current_volume / max_capacity};
  rgb color;
  bool blocked <- false;
  bool hidden <- false;
  string status;
  int accum_traffic_count <- 0; // Accumulated traffic count (number of agents passing through road)

  // user command section
  user_command "Block" action: block;
  user_command "Unblock" action: unblock;
  user_command "View direction" action: view_direction;

  action block {
    write "block .";
    self.blocked <- true;
    // regenerate new graph without the edge/road just selected
    my_graph <- as_edge_graph(road where (!each.hidden and !each.blocked)) with_weights (road as_map (each::each.link_length));
    // directed graph
    my_graph <- directed(my_graph);
    // global switch toggle
    change_graph_action <- true;
    ask people {
    //          write "HERE I AM: " + self;
    //          write length(people);
    //      write "Current road: " + current_road;
      bool exit_flag <- false;
      if (cant_find_path = true) {
        exit_flag <- true;
      }

      if (!exit_flag) {
      // people that are stuck in middle of the road
        if ((self.current_road != nil) and (self.current_road.shape = myself.shape) and (is_on_node = false)) {
        //      if ((self overlaps myself) and (is_on_node = false)) {
          write "Stuck: " + self;
          is_in_blocked_road <- true;
        }

        // people that have their next road blocked
        bool next_road_is_blocked <- false;
        if ((self.current_road != nil) and (self.current_road.shape = myself.shape) and (is_on_node = true)) {
          write string(self) + " has next road blocked.";
          next_road_is_blocked <- true;
        }

        // Only re route for people who has radio or has their next road blocked
        if (is_in_blocked_road = false and (has_radio or next_road_is_blocked)) {
          write "Selected reroute in BLOCK: " + self;
          path new_shortest_path; // new shortest path for comparison
          try {
            new_shortest_path <- path_between(my_graph, location, dest);
          }

          catch {
            write "caught!!!! in block action";
            write string(self) + " -> cant_find_path is now true";
            cant_find_path <- true;
          }

          if (new_shortest_path != nil and new_shortest_path.shape != nil and new_shortest_path.shape.points[length(new_shortest_path.shape.points) - 1] != dest) {
            write "Fixed no edges connecting node. " + self;
            cant_find_path <- true;
          }

          if (cant_find_path = false) {
          //          write string(self) + " " + shortest_path;
            if (new_shortest_path = nil or length(new_shortest_path.edges) = 0) {
              write string(self) + " cant find path (expected)";
              cant_find_path <- true;
            } else {
              fixed_edges <- new_shortest_path.edges collect (road(each));
              num_nodes_to_complete <- length(fixed_edges);
              current_road_index <- 0;
              current_road <- fixed_edges[current_road_index];
              shortest_path <- new_shortest_path;
            }

          }

          if (cant_find_path and is_on_node) {
            num_people_cant_find_path <- num_people_cant_find_path + 1;
            stuck_same_location <- false;
            speed <- 0 #m / #s;
          }

        }

      }

    }

    // ask people in blocked road and have destination inside blocked road (current road = last road)
    // should be ONE TIME thing
    ask people where (each.is_in_blocked_road and (each.current_road_index = (each.num_nodes_to_complete - 1)) and !each.moving_in_blocked_road) {
      moving_in_blocked_road <- true;
      //      write "Created road!!";
      create road {
        shape <- curve(myself.current_road.shape.points[0], myself.next_node, curve_width_eff);
        link_length <- myself.current_road.shape.perimeter; // double link length test
        free_speed <- myself.current_road.free_speed;
        max_capacity <- myself.current_road.max_capacity;
        hidden <- true;
      }
      // Just this line!
      mini_graph <- as_edge_graph([road[length(road) - 1]]) with_weights ([road[length(road) - 1]] as_map (each::each.link_length));
      mini_graph <- directed(mini_graph);
    }

    // ask people in blocked road but has destination outside of blocked road 
    // correctly update speed for data stats  
    ask people where (each.is_in_blocked_road and (each.current_road_index != (each.num_nodes_to_complete - 1))) {
      speed <- 0 #m / #s;
    }

  }

  // un-block command
  action unblock {
    self.blocked <- false;
    // regenerate new graph without the edge/road just selected
    my_graph <- as_edge_graph(road where (!each.hidden and !each.blocked)) with_weights (road as_map (each::each.link_length));
    // directed graph
    my_graph <- directed(my_graph);
    // global switch toggle
    change_graph_action <- true;
    ask people {
    // people that are stuck in middle of road
      if (self.current_road != nil and self.current_road.shape = myself.shape and is_on_node = false) {
      //      if ((self overlaps myself) and (is_on_node = false)) {
      //        write "Stuck: " + self;
        is_in_blocked_road <- false;
      }

      // people that are nearby a road that is recently unblocked
      bool next_road_is_unblocked <- false;

      // if agent is on node and that node's location is the starting point of the unblocked road, agent will re-route
      if (self.location = myself.shape.points[0] and is_on_node = true) {
        write "I am" + self + " with current road: " + self.current_road;
        next_road_is_unblocked <- true;
      }

      if (is_in_blocked_road = false and (has_radio or next_road_is_unblocked)) {
        bool exit_flag <- false;
        write "Selected reroute in UNBLOCK: " + self;
        path new_shortest_path; // new shortest path for comparison
        try {
          new_shortest_path <- path_between(my_graph, location, dest);
        }

        catch {
        //          write "caught!!!! in block action";
        //          write string(self) + " -> cant_find_path is now true";
          cant_find_path <- true;
          if (is_on_node) {
            speed <- 0 #m / #s;
          }

          exit_flag <- true;
        }
        
        if (new_shortest_path != nil and new_shortest_path.shape != nil and new_shortest_path.shape.points[length(new_shortest_path.shape.points) - 1] != dest) {
            write "Fixed no edges connecting node. " + self;
            cant_find_path <- true;
          }

        if (!exit_flag) {
          if (new_shortest_path = nil or length(new_shortest_path.edges) = 0) {
          //          write "cant find path";
            cant_find_path <- true;
          } else {
            fixed_edges <- new_shortest_path.edges collect (road(each));
            num_nodes_to_complete <- length(fixed_edges);
            current_road_index <- 0;
            cant_find_path <- false;
            current_road <- fixed_edges[current_road_index];
            shortest_path <- new_shortest_path;
          }

        }

        if (cant_find_path and is_on_node) {
          num_people_cant_find_path <- num_people_cant_find_path + 1;
          stuck_same_location <- false;
          speed <- 0 #m / #s;
        }

      }

    }

  }

  // View road info i.e. direction
  action view_direction {
    int len <- length(self.shape.points);
    write "source: " + my_node(self.shape.points[0]).node_number + ", dest: " + my_node(self.shape.points[len - 1]).node_number;
  }

  aspect base {
    if (link_full_percentage < 0.25) {
      color <- #lime;
      status <- "low";
    } else if (link_full_percentage < 0.5) {
      color <- #blue;
      status <- "moderate";
    } else if (link_full_percentage < 0.75) {
      color <- #yellow;
      status <- "high";
    } else {
      color <- #orange;
      status <- "extreme";
    }

    if (link_full_percentage = 1) {
      color <- #red;
      status <- "traffic_jam";
    }

    if (blocked = true) {
      color <- #purple;
    }

    if (!hidden) {
      draw shape color: color width: 2;
//      draw string(self.shape.perimeter with_precision 2) color: #black font: font('Helvetica', 8, #plain);
    } //
  } }

  /*
 * Node species
 */
species my_node {
  int node_number <- length(my_node) - 1; // node id
  int accum_traffic_count <- 0; // accumulated traffic count
  aspect base {
    draw string(node_number) color: #black font: font('Helvetica', 5, #plain);
  }

}

/*
 * Helper class to save data output to external file
 */
species file_saver {
// result (data output) directory
  file result_dir <- folder('./traffic-results');
  string node_stats_file <- "./traffic-results/node-stats.txt";
  string road_stats_file <- "./traffic-results/road-stats.txt";
  string matrix_stats_file <- './traffic-results/matrix_stats.txt';

  // input header for first time only
  init {
    do clear_file;
    do write_node_header;
    do write_road_header;
  }

  // save data stats output every 5 cycle
  reflex save_output when: every(5 #cycle) {
    do write_node_output;
    do write_road_output;
    do write_matrix_output;
  }

  /* Clear file before writing data */
  action clear_file {
    loop txt_file over: result_dir {
      save to: (string(result_dir) + '/' + txt_file) type: "text" rewrite: true; // empty file before simulation runs
    }

  }

  // for node stats file header
  action write_node_header {
    string node_header <- "cycle,";
    ask my_node {
      node_header <- node_header + "node" + self.node_number;
      if (self.node_number != length(my_node) - 1) {
        node_header <- node_header + ",";
      }

    }

    save node_header to: node_stats_file type: "text";
  }

  // for road stats file header
  action write_road_header {
    string road_header <- "cycle,";
    ask road {
      road_header <- road_header + self.name;
      if (self.name != "road" + string(length(road) - 1)) {
        road_header <- road_header + ",";
      }

    }

    save road_header to: road_stats_file type: "text";
  }

  // orig_dest stats file header
  action write_matrix_output {
    string matrix_header <- "Cycle: " + cycle + "\r\n";
    loop i from: 0 to: length(orig_dest_matrix) - 1 {
      loop j from: 0 to: length(orig_dest_matrix[i]) - 1 {
        matrix_header <- matrix_header + orig_dest_matrix[i][j];
        if (j != length(orig_dest_matrix[i]) - 1) {
          matrix_header <- matrix_header + ",";
        }

      }

      matrix_header <- matrix_header + "\r\n";
    }

    save matrix_header to: matrix_stats_file type: "text" rewrite: false;
  }

  // write node stats output in a row
  action write_node_output {
    string node_output <- "cycle" + string(cycle) + ",";
    ask my_node {
      node_output <- node_output + self.accum_traffic_count;
      if (self.node_number != length(my_node) - 1) {
        node_output <- node_output + ",";
      }

    }

    save node_output to: node_stats_file type: "text" rewrite: false;
  }

  // write road stats output in a row
  action write_road_output {
    string road_output <- "cycle" + string(cycle) + ",";
    ask road {
      road_output <- road_output + self.accum_traffic_count;
      if (self.name != "road" + string(length(road) - 1)) {
        road_output <- road_output + ",";
      }

    }

    save road_output to: road_stats_file type: "text" rewrite: false;
  }

}

experiment my_experiment type: gui {
  parameter "Min number people spawn per interval:" var: min_nb_people_spawn category: "People";
  parameter "Max number people spawn per interval:" var: max_nb_people_spawn category: "People";
  parameter "Spawn interval (in cycle):" var: spawn_interval category: "People";
  output {
    display main_display type: opengl background: #white {
      species road aspect: base;
      species people aspect: base;
      species my_node aspect: base;
      event [mouse_down] action: mouse_down_evt;
    }

//    display top_populated_location_chart refresh: every(1 #cycle) {
//      chart "Top-" + k_node + " populated nodes (highest accumulated traffic)" type: histogram size: {1, 0.5} position: {0, 0} x_label: "Node id" y_label:
//      "Accumulated traffic count" {
//        datalist legend: (copy_between(top_traffic_nodes, 0, k_node) collect ("Node " + string(each.node_number))) value: (copy_between(top_traffic_nodes, 0, k_node) collect
//        each.accum_traffic_count);
//      }
//
//      chart "Top-" + k_road + " populated road (highest accumulated traffic)" type: histogram size: {1, 0.5} position: {0, 0.5} x_label: "Road id" y_label:
//      "Accumulated traffic count" {
//        datalist legend: (copy_between(top_traffic_roads, 0, k_road) collect (each.name)) value: (copy_between(top_traffic_roads, 0, k_road) collect
//        each.accum_traffic_count);
//      }
//
//    }

    //    display traffic_density_chart {
    //      chart "Traffic density count series" type: series size: {1, 0.5} position: {0, 0} x_label: "Cycle" y_label: "Count" {
    //        data "Low" value: low_count color: #lime style: line;
    //        data "Moderate" value: moderate_count color: #blue style: line;
    //        data "High" value: high_count color: #yellow style: line;
    //        data "Extreme" value: extreme_count color: #orange style: line;
    //        data "Traffic jam" value: traffic_jam_count color: #red style: line;
    //      }
    //
    //      chart "Traffic density pie chart" type: pie style: exploded size: {0.5, 0.5} position: {0, 0.5} {
    //        data "Low" value: low_count color: #lime;
    //        data "Moderate" value: moderate_count color: #blue;
    //        data "High" value: high_count color: #yellow;
    //        data "Extreme" value: extreme_count color: #orange;
    //        data "Traffic jam" value: traffic_jam_count color: #red;
    //      }
    //
    //      chart "Traffic density bar chart" type: histogram size: {0.5, 0.5} position: {0.5, 0.5} x_label: "Traffic density category" y_label: "Count" {
    //        data "Low" value: low_count color: #lime;
    //        data "Moderate" value: moderate_count color: #blue;
    //        data "High" value: high_count color: #yellow;
    //        data "Extreme" value: extreme_count color: #orange;
    //        data "Traffic jam" value: traffic_jam_count color: #red;
    //      }
    //
    //    }
    //
    //    display speed_chart {
    //      chart "Average speed series" type: series size: {1, 0.5} position: {0, 0} x_label: "Cycle" y_label: "Average speed (m/s)" {
    //        data "Average speed" value: avg_speed color: #deepskyblue;
    //      }
    //
    //      chart "Speed distribution" type: histogram size: {1, 0.5} position: {0, 0.5} x_label: "Speed bin (m/s)" y_label: "Frequency" {
    //        datalist list(speed_histmap at "legend") value: list(speed_histmap at "values");
    //      }
    //
    //    }
    //

    //    
//    monitor "Low density road count" value: low_count color: #lime;
//    monitor "Moderate density road count" value: moderate_count color: #blue;
//    monitor "High density road count" value: high_count color: #yellow;
//    monitor "Extreme density road count" value: extreme_count color: #orange;
//    monitor "Traffic jam count" value: traffic_jam_count color: #red;
//    monitor "Current number of people" value: nb_people_current;
//    monitor "Number of trips completed" value: nb_trips_completed;
//    monitor "Average speed" value: avg_speed with_precision 2 color: #deepskyblue;
//    monitor "Accumulated node traffic sum" value: node_accum_traffic_sum color: #crimson;
//    monitor "Accumulated road traffic sum" value: road_accum_traffic_sum color: #purple;
//    monitor "List of people who cant find path at unique location" value: list_people_cant_find_path color: #aqua;
//    monitor "Accumulated number of people who cant find path" value: num_people_cant_find_path color: #brown;
  }

}