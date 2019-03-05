model blocked_road

global {
  graph my_graph;
  list<point> nodes;
  list<float> time_list; // list of time to arrive to next node;
  geometry shape <- square(200 #m);
  bool change_graph_action <- false;
  float curve_width_eff <- 0.05;
  float seed <- 1.0; // rng seed for reproducing the same result (dev mode)

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

  // stats
  list<float> speed_list -> {people collect each.speed};
  map<string, list> speed_histmap -> {distribution_of(speed_list, 10, min_free_speed, max_free_speed)};
  int nb_people_current -> {length(people)};
  int nb_trips_completed <- 0;
  float avg_speed -> {(mean(speed_list))};
  list<my_node> top_traffic_nodes -> {reverse(my_node sort_by each.traffic_count)};
  int node_traffic_sum -> {sum(top_traffic_nodes collect each.traffic_count)};
  float node_traffic_avg -> {mean(top_traffic_nodes collect each.traffic_count)};
  map<string, list> traffic_count_histmap -> {distribution_of(top_traffic_nodes collect each.traffic_count, 10)};

  init {
    add point(10, 10) to: nodes;
    add point(10, 90) to: nodes;
    add point(40, 20) to: nodes;
    add point(80, 50) to: nodes;
    add point(90, 20) to: nodes;
    add point(50, 90) to: nodes;
    add point(30, 20) to: nodes;
    add point(110, 50) to: nodes;
    add point(120, 20) to: nodes;
    add point(50, 120) to: nodes;
    add point(100, 110) to: nodes;
    loop i from: 0 to: length(nodes) - 1 {
      create my_node {
        location <- nodes[i];
      }

    }

    create road {
      shape <- curve(my_node[0].location, my_node[1].location, curve_width_eff);
      link_length <- shape.perimeter; // double link length test
      free_speed <- (min_free_speed + rnd(max_free_speed - min_free_speed)) with_precision 2;
      max_capacity <- min_capacity_val + rnd(max_capacity_val - min_capacity_val);
    }

    create road {
      shape <- curve(my_node[1].location, my_node[2].location, curve_width_eff);
      link_length <- shape.perimeter; // double link length test
      free_speed <- (min_free_speed + rnd(max_free_speed - min_free_speed)) with_precision 2;
      max_capacity <- min_capacity_val + rnd(max_capacity_val - min_capacity_val);
    }

    create road {
      shape <- curve(my_node[2].location, my_node[3].location, curve_width_eff);
      link_length <- shape.perimeter; // double link length test
      free_speed <- (min_free_speed + rnd(max_free_speed - min_free_speed)) with_precision 2;
      max_capacity <- min_capacity_val + rnd(max_capacity_val - min_capacity_val);
    }

    create road {
      shape <- curve(my_node[3].location, my_node[4].location, curve_width_eff);
      link_length <- shape.perimeter; // double link length test
      free_speed <- (min_free_speed + rnd(max_free_speed - min_free_speed)) with_precision 2;
      max_capacity <- min_capacity_val + rnd(max_capacity_val - min_capacity_val);
    }

    create road {
      shape <- curve(my_node[4].location, my_node[5].location, curve_width_eff);
      link_length <- shape.perimeter; // double link length test
      free_speed <- (min_free_speed + rnd(max_free_speed - min_free_speed)) with_precision 2;
      max_capacity <- min_capacity_val + rnd(max_capacity_val - min_capacity_val);
    }

    create road {
      shape <- curve(my_node[5].location, my_node[6].location, curve_width_eff);
      link_length <- shape.perimeter; // double link length test
      free_speed <- (min_free_speed + rnd(max_free_speed - min_free_speed)) with_precision 2;
      max_capacity <- min_capacity_val + rnd(max_capacity_val - min_capacity_val);
    }

    create road {
      shape <- curve(my_node[6].location, my_node[7].location, curve_width_eff);
      link_length <- shape.perimeter; // double link length test
      free_speed <- (min_free_speed + rnd(max_free_speed - min_free_speed)) with_precision 2;
      max_capacity <- min_capacity_val + rnd(max_capacity_val - min_capacity_val);
    }

    create road {
      shape <- curve(my_node[7].location, my_node[8].location, curve_width_eff);
      link_length <- shape.perimeter; // double link length test
      free_speed <- (min_free_speed + rnd(max_free_speed - min_free_speed)) with_precision 2;
      max_capacity <- min_capacity_val + rnd(max_capacity_val - min_capacity_val);
    }

    create road {
      shape <- curve(my_node[8].location, my_node[9].location, curve_width_eff);
      link_length <- shape.perimeter; // double link length test
      free_speed <- (min_free_speed + rnd(max_free_speed - min_free_speed)) with_precision 2;
      max_capacity <- min_capacity_val + rnd(max_capacity_val - min_capacity_val);
    }

    create road {
      shape <- curve(my_node[9].location, my_node[10].location, curve_width_eff);
      link_length <- shape.perimeter; // double link length test
      free_speed <- (min_free_speed + rnd(max_free_speed - min_free_speed)) with_precision 2;
      max_capacity <- min_capacity_val + rnd(max_capacity_val - min_capacity_val);
    }

    create road {
      shape <- curve(my_node[9].location, my_node[5].location, curve_width_eff);
      link_length <- shape.perimeter; // double link length test
      free_speed <- (min_free_speed + rnd(max_free_speed - min_free_speed)) with_precision 2;
      max_capacity <- min_capacity_val + rnd(max_capacity_val - min_capacity_val);
    }

    create road {
      shape <- curve(my_node[3].location, my_node[7].location, curve_width_eff);
      link_length <- shape.perimeter; // double link length test
      free_speed <- (min_free_speed + rnd(max_free_speed - min_free_speed)) with_precision 2;
      max_capacity <- min_capacity_val + rnd(max_capacity_val - min_capacity_val);
    }

    create road {
      shape <- curve(my_node[10].location, my_node[7].location, curve_width_eff);
      link_length <- shape.perimeter; // double link length test
      free_speed <- (min_free_speed + rnd(max_free_speed - min_free_speed)) with_precision 2;
      max_capacity <- min_capacity_val + rnd(max_capacity_val - min_capacity_val);
    }

    //     try reverse
    ask road {
      create road {
        int len <- length(myself.shape.points);
        shape <- curve(myself.shape.points[len - 1], myself.shape.points[0], curve_width_eff);
        link_length <- myself.link_length;
        free_speed <- myself.free_speed;
        max_capacity <- myself.max_capacity;
      }

    }

    // generate graph
    my_graph <- as_edge_graph(road where (!each.hidden)) with_weights (road as_map (each::each.link_length));
    // directed graph
    my_graph <- directed(my_graph);
    do create_people(nb_people_init);
    //    do create_people_test(5, 0, 2);

    //    do create_people_test(5, 1, 0);
    //    do create_people_test(30, 2, 0);

  }

  reflex generate_people when: every(spawn_interval) {
    do create_people(min_nb_people_spawn + rnd(max_nb_people_spawn - min_nb_people_spawn));
  }

  // empty list first then update min time
  reflex refresh_min_time {
    time_list <- [];
    do update_min_time;
    if (change_graph_action = true) {
      change_graph_action <- false;
    }

  }

  action create_people (int num_people) {
    create people number: num_people {
      int random_origin_index <- rnd(length(nodes) - 1);
      location <- nodes[random_origin_index]; // CHANGE HERE
      int random_dest_index <- rnd(length(nodes) - 1);
      loop while: random_origin_index = random_dest_index {
        random_dest_index <- rnd(length(nodes) - 1);
      }

      dest <- nodes[random_dest_index];
      try {
        shortest_path <- path_between(my_graph, location, dest);
      }

      catch {
        write "caught!!!";
        cant_find_path <- true;
        speed <- 0 #m / #s;
      }

      if (cant_find_path = false) {
        if (shortest_path = nil or length(shortest_path.edges) = 0) {
          cant_find_path <- true;
        } else {
        // Fixed road path
          fixed_edges <- shortest_path.edges collect (road(each));
          num_nodes_to_complete <- length(fixed_edges);
          current_road <- fixed_edges[current_road_index];
        }

      }

      speed <- 0 #m / #s;
      // increment traffic count at source location node
      my_node(location).traffic_count <- my_node(location).traffic_count + 1;
    }

  }

  action create_people_test (int num_people, int u_location, int u_dest) {
    create people number: num_people {
      int random_origin_index <- rnd(length(nodes) - 1);
      location <- nodes[u_location]; // CHANGE HERE
      int random_dest_index <- rnd(length(nodes) - 1);
      loop while: random_origin_index = random_dest_index {
        random_dest_index <- rnd(length(nodes) - 1);
      }

      dest <- nodes[u_dest];
      try {
        shortest_path <- path_between(my_graph, location, dest);
      }

      catch {
        write "caught!!!";
        cant_find_path <- true;
        speed <- 0 #m / #s;
      }

      if (cant_find_path = false) {
        if (shortest_path = nil or length(shortest_path.edges) = 0) {
          cant_find_path <- true;
        } else {
        // Fixed road path
          fixed_edges <- shortest_path.edges collect (road(each));
          num_nodes_to_complete <- length(fixed_edges);
          current_road <- fixed_edges[current_road_index];
        }

      }

      speed <- 0 #m / #s;
      // increment traffic count at source location node
      my_node(location).traffic_count <- my_node(location).traffic_count + 1;
    }

  }

  action update_min_time {
    list<people> selected_people <- people where ((!each.cant_find_path) and ((!each.is_in_blocked_road) or (each.is_in_blocked_road and
    each.current_road_index = each.num_nodes_to_complete - 1)));
    //    int dead_node_count <- -1;
//    write "selected people here" + selected_people;
    // only ask people that is not in blocked road or people in blocked road but the dest in on that road
    ask selected_people {
    // write "move";
//      write fixed_edges;

      // shape.points[1] = target/source of polyline edge, i.e. next node
      //      write "Here: " + fixed_edges[current_road_index].shape.points;
      current_road <- fixed_edges[current_road_index];
      int len <- length(current_road.shape.points);
      next_node <- point(current_road.shape.points[len - 1]);
      //      write next_node;
      // current road segment
      float true_link_length <- current_road.link_length; // link length (real_)
      //                  write "True link length: " + true_link_length;
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
          is_on_node <- false;
          if (is_in_blocked_road = false) {
            if (road_before_change != current_road) {
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
//    write "-----------";
  }

  // BPR equation
  float get_equi_speed (float free_speed, int current_volume, int max_capacity) {
    return free_speed / (1 + 0.15 * (current_volume / max_capacity) ^ 4);
  }

  action mouse_down_evt {
    geometry circ <- circle(1, #user_location);
    list<people> test <- people inside circ;
    if (length(test) > 0) {
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

  int node_counter <- 0;
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
  road road_before_change <- nil;
  graph mini_graph; // graph for people already in blocked road but still can move to dest in the same road.
  bool moving_in_blocked_road <- false;

  // Smart move
  reflex smart_move when: cant_find_path = false and is_road_jammed = false and (!is_in_blocked_road or (is_in_blocked_road and current_road_index = num_nodes_to_complete - 1)) {
    float epsilon <- 10 ^ -5;
    //    write "Before: " + real_dist_to_next_node;
    do follow path: shortest_path;
    // Handle epsilon (where calculation between float values with multiples decimals might cause error).
    float distance_to_next_node;
    using topology(my_graph) {
      distance_to_next_node <- self distance_to next_node;
    }

    real_dist_to_next_node <- distance_to_next_node * ratio;
    //    write "After: " + real_dist_to_next_node;
    if (real_dist_to_next_node < epsilon) {
//      write "epsilon!";
      self.location <- next_node.location;
    }

    // CHECK IF PERSON IS ON ONE NODE
    if (self overlaps next_node) {
//      write "OVERLAPS";
      current_road.current_volume <- current_road.current_volume - 1;
      my_node(next_node).traffic_count <- my_node(next_node).traffic_count + 1;
      // if its the final node
      if (current_road_index = num_nodes_to_complete - 1) {
      //        write "ARRIVED!";
        nb_trips_completed <- nb_trips_completed + 1;
        do die;
      } else {
        is_on_node <- true;
        is_road_jammed <- true;
        current_road_index <- current_road_index + 1;
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
      draw triangle(2.5) color: color;
    } else {
      draw circle(1.5) color: color;
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
    // people that are stuck x
      if ((self.current_road != nil) and (self.current_road.shape = myself.shape) and (is_on_node = false)) {
      //      if ((self overlaps myself) and (is_on_node = false)) {
      //        write "Stuck: " + self;
        is_in_blocked_road <- true;
      }

      if (is_in_blocked_road = false) {
        try {
          shortest_path <- path_between(my_graph, location, dest);
        }

        catch {
          write "caught!!!! in block action";
          write string(self) + " -> cant_find_path is now true";
          cant_find_path <- true;
          speed <- 0 #m / #s;
        }

        if (cant_find_path = false) {
        //          write string(self) + " " + shortest_path;
          if (shortest_path = nil or length(shortest_path.edges) = 0) {
            write "cant find path";
            cant_find_path <- true;
            speed <- 0 #m / #s;
          } else {
            fixed_edges <- shortest_path.edges collect (road(each));
            num_nodes_to_complete <- length(fixed_edges);
            current_road_index <- 0;
            current_road <- fixed_edges[current_road_index];
            road_before_change <- current_road;
            road new_current_road <- fixed_edges[current_road_index]; // new current road after re route
          }

        }

      }

    }

    // ask people in blocked road and have destination inside blocked road (current road = last road)
    // should be ONE TIME thing
    ask people where (each.is_in_blocked_road and (each.current_road_index = (each.num_nodes_to_complete - 1)) and !each.moving_in_blocked_road) {
      moving_in_blocked_road <- true;
      write "Created road!!";
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
    // people that are stuck
      if ((self.current_road != nil) and (self.current_road.shape = myself.shape) and (is_on_node = false)) {
      //      if ((self overlaps myself) and (is_on_node = false)) {
      //        write "Stuck: " + self;
        is_in_blocked_road <- false;
      }

      // for all people
      if (is_in_blocked_road = false) {
        try {
          shortest_path <- path_between(my_graph, location, dest);
        }

        catch {
          write "caught!!!! in block action";
          write string(self) + " -> cant_find_path is now true";
          cant_find_path <- true;
          speed <- 0 #m / #s;
          break;
        }

        //          write string(self) + " " + shortest_path;
        if (shortest_path = nil or length(shortest_path.edges) = 0) {
          write "cant find path";
          cant_find_path <- true;
          speed <- 0 #m / #s;
        } else {
          fixed_edges <- shortest_path.edges collect (road(each));
          num_nodes_to_complete <- length(fixed_edges);
          current_road_index <- 0;
          cant_find_path <- false;
          current_road <- fixed_edges[current_road_index];
          road_before_change <- current_road;
          road new_current_road <- fixed_edges[current_road_index]; // new current road after reroute
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
    } }
    //
}

/*
 * Node species
 */
species my_node {
  int node_number;
  bool dead_node <- false;
  int traffic_count <- 0;

  init {
    node_number <- node_counter;
    node_counter <- node_counter + 1;
  }

  aspect base {
  //    draw circle(1) color: #lightblue;
    draw string(node_number) color: #black font: font('Helvetica', 18, #plain);
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
    //    display traffic_count_at_nodes_chart {
    //    //      chart "Average traffic at 1 node" type: series size: {1, 0.5} position: {0, 0} x_label: "Cycle" y_label: "Count" {
    //    //        data "sum" value: node_traffic_avg color: #salmon;
    //    //      }
    //      chart "Traffic count histogram" type: histogram size: {1, 0.5} position: {0, 0} x_label: "Traffic count bin" y_label: "Frequency" {
    //        datalist list(traffic_count_histmap at "legend") value: list(traffic_count_histmap at "values");
    //      }
    //
    //      chart "Top-k populated nodes (highest traffic)" type: histogram size: {1, 0.5} position: {0, 0.5} x_label: "Node id" y_label: "Count" {
    //        datalist legend: (top_traffic_nodes collect ("Node " + string(each.node_number))) value: (top_traffic_nodes collect each.traffic_count);
    //      }
    //
    //    }
    //
    monitor "Low density road count" value: low_count color: #lime;
    monitor "Moderate density road count" value: moderate_count color: #blue;
    monitor "High density road count" value: high_count color: #yellow;
    monitor "Extreme density road count" value: extreme_count color: #orange;
    monitor "Traffic jam count" value: traffic_jam_count color: #red;
    monitor "Current number of people" value: nb_people_current;
    monitor "Number of trips completed" value: nb_trips_completed;
    monitor "Average speed" value: avg_speed with_precision 2 color: #deepskyblue;
    monitor "Node traffic sum" value: node_traffic_sum color: #crimson;
    monitor "Node traffic average" value: node_traffic_avg with_precision 2 color: #salmon;
  }

}