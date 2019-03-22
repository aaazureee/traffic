model people
import "./Road.gaml"

/*
 * People species
 */
species people skills: [moving] {
  rgb color <- #dimgray;
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
  bool has_radio <- flip(radio_prob); // whether people has radio (is notified of route change globally)
  graph mini_graph <- nil; // graph for people already in blocked road but still can move to dest in the same road.
  graph modified_graph <- nil; // graph for people who use re-route strategy.
  list<road> avoided_road <- [];
  bool moving_in_blocked_road <- false;
  bool stuck_same_location <- true;
  bool has_smart_strategy <- flip(smart_strategy_prob);
  float alpha;
  float theta;
  float real_time_spent <- 0.0;
  float free_flow_time_needed <- 0.0;
  float free_flow_time_spent <- 0.0;

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
    // Get current agent's graph network to calculate distance
    graph current_graph <- my_graph;
    if (mini_graph != nil) {
      current_graph <- mini_graph;
    } else if (modified_graph != nil) {
      current_graph <- modified_graph;
    }
    // Handle epsilon (where calculation between float values with multiples decimals might cause error).
    float distance_to_next_node;
    using topology(current_graph) {
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
      free_flow_time_spent <- free_flow_time_spent + free_flow_time_needed; // accumulate previous free flow time calculated from previous node
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
        
        // Smart re-route strategy
        if (has_smart_strategy and is_on_node and !cant_find_path) {
          do will_reroute(real_time_spent / free_flow_time_spent, current_road.current_volume / current_road.max_capacity);
        }       
      }

    }

  }
  
  
  action will_reroute(float normalized_time_spent, float next_link_saturation) {
    float epsilon <- 10 ^ -5;
    if (normalized_time_spent < 1 and (1 - normalized_time_spent) <= epsilon) {
      normalized_time_spent <- 1.0;
    }
//    write "Saturation: " + next_link_saturation;
//    write "Norm. time spent: " + normalized_time_spent;
    
    // Re-route strategy formula:
    float value <- (cos(alpha#to_deg) * normalized_time_spent + sin(alpha#to_deg) * next_link_saturation - theta);    
    if (value >= 0) {
      total_reroute_count <- total_reroute_count + 1;
//      write string(value) + " - true";
      graph new_graph <- directed(as_edge_graph(road where (!each.hidden and !each.blocked and each != current_road)) with_weights (road as_map (each::each.link_length)));      
      // try to compute new shortest path avoiding current road if possibile:
      path new_shortest_path;
      try {
        new_shortest_path <- path_between(new_graph, location, dest);
      }
    
      catch {       
        return;
      }
    
      // check for problem with shortest_path when there are no edges connecting a node
      if (new_shortest_path != nil and new_shortest_path.shape != nil and (new_shortest_path.shape.points[0] != location or new_shortest_path.shape.points[length(new_shortest_path.shape.points) - 1] !=
      dest)) {        
        return;
      }
    
      // if cannot find the shortest path
      if (new_shortest_path = nil or length(new_shortest_path.edges) = 0) {
        return;
      } else {
        fixed_edges <- new_shortest_path.edges collect (road(each));
        num_nodes_to_complete <- length(fixed_edges);
        current_road_index <- 0;
        current_road <- fixed_edges[current_road_index];
        cant_find_path <- false;
        add current_road to: avoided_road;
        shortest_path <- new_shortest_path;        
        modified_graph <- new_graph;        
      }
      
    } 
      
  }
  
  aspect base {
    if (is_in_blocked_road and current_road_index = num_nodes_to_complete - 1) {
      if (clicked = true) {
        draw circle(2) at: self.location color: #yellow;
        draw circle(2) at: self.dest color: #cyan;
        draw polyline([self.location, self.dest]) color: #orchid width: 5;
      }

    } else if (clicked = true and cant_find_path = false) {
      path new_path <- path_between(my_graph, location, dest);
      draw circle(2) at: point(new_path.source) color: #yellow;
      draw circle(2) at: point(new_path.target) color: #cyan;
      draw new_path.shape color: #orchid width: 5;
    }
    
    // Colorize people agent differently based on characteristic
    if (has_radio and has_smart_strategy) {
      color <- #lightcoral;
    } else if (has_radio) {
      color <- #darkviolet;
    } else if (has_smart_strategy) {
      color <- #saddlebrown;
    }

    if (is_in_blocked_road = true) {
      draw triangle(65) color: color;
    } else {
      draw circle(50) color: color;
    }

  }

}

