model people
import "./Road.gaml"

/** 
 * People species definition with smart rerouting strategy function
 * 
 * @author Hieu Chu (chc116@uowmail.edu.au)
 */
species people skills: [moving] {
  rgb color <- #dimgray; // color representation in main simulation display
  point dest; // destination node
  path shortest_path; // shortest path
  list<road> fixed_edges; 
  int num_nodes_to_complete;
  int current_road_index <- 0;
  point next_node;
  bool is_on_node <- true; // check if people agent is on the node
  bool clicked <- false; // gui variable to show shortest path
  float ratio <- 1.0; // ratio between 2D gama graph and real world link length distance
  float real_dist_to_next_node; // real world distance to next node
  road current_road; // current road
  bool is_road_jammed <- true; // if next road is at full capacity
  bool is_in_blocked_road <- false; // if people agent is in blocked road
  bool cant_find_path <- false; // if people agent cannot find the shortest path
  bool has_radio <- flip(radio_prob); // whether people has radio (is notified of route change globally)
  graph mini_graph <- nil; // graph for people already in blocked road but still can move to dest in the same road.
  graph modified_graph <- nil; // graph for people who use re-route strategy.
  list<road> avoided_road <- []; // list of roads that people who use re-route strategy will avoid (congested).
  bool moving_in_blocked_road <- false; // for people who are already in blocked road but still can move to dest in the same road
  bool stuck_same_location <- true; // variable to increment global number of people who cannot find the path
  bool has_smart_strategy <- flip(smart_strategy_prob); // whether people has smart reroute strategy applied
  float alpha; // alpha weights for reroute strategy
  float theta; // theta weights for reroute strategy
  float real_time_spent <- 0.0; // real time spent in the simulation
  float free_flow_time_needed <- 0.0; // free flow time needed to travel to next node
  float free_flow_time_spent <- 0.0; // free flow time spent in the simulation

  /**
   * Reflex function that will increment the total number of people who cannot find shortest path
   * only if they are not stuck at same location (to avoid duplicating counts).
   * 
   * @params stuck_same_location if people is stuck at the same location
   */
  reflex update_unique_stuck_count when: !stuck_same_location {
    stuck_same_location <- true;
  }

  /**
   * Reflex function to attempt to reroute when stuck at one node and cant find path
   * 
   * @params cant_find_path if people cannot find the shortest path
   * @params is_on_node if people is on the node
   */
  reflex reroute_attempt when: cant_find_path and is_on_node {
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

 /**
   * Main reflex function that enables selected people based on criteria to travel in the simulation
   * 
   * @params cant_find_path if people cannot find the shortest path
   * @params is_on_node if people is on the node
   * @params is_road_jammed is next road at full capacity
   * @params is_in_blocked_road if people is inside blocked road
   * @params current_road_index current road index (based on shortest path road count)
   * @params num_nodes_to_complete number of nodes need to pass through to go to destination
   */
  reflex smart_move when: (!cant_find_path or (cant_find_path and !is_on_node)) and !is_road_jammed and (!is_in_blocked_road or (is_in_blocked_road and
  current_road_index = num_nodes_to_complete - 1)) {
    float epsilon <- 10 ^ -5; // epsilon is used when the distance calculation with multiple decimals might cause error.
    // Accumulate traffic on agent's shortest's path road
    if (is_on_node = true) {
      current_road.accum_traffic_count <- current_road.accum_traffic_count + 1;
    }

    do follow path: shortest_path;  // Move according to the shortest path
    is_on_node <- false; //
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

    // Check if after moving, the people agent ends up on the node
    if (self overlaps next_node) {
      current_road.current_volume <- current_road.current_volume - 1; // increase current road's volume
      my_node(next_node).accum_traffic_count <- my_node(next_node).accum_traffic_count + 1; // increase node's traffic count
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
        // Handle people who cannot find shortest path
        if (cant_find_path and is_on_node) {
          num_people_cant_find_path <- num_people_cant_find_path + 1;
          stuck_same_location <- false;
          speed <- 0 #m / #s;
        }

        // if next road is blocked, attempt to reroute:
        if (current_road.blocked = true and !cant_find_path) {
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
        
        // Apply smart reroute strategy if people has_smart_strategy
        if (has_smart_strategy and is_on_node and !cant_find_path) {
          do will_reroute(real_time_spent / free_flow_time_spent, current_road.current_volume / current_road.max_capacity);
        }       
      }

    }

  }
  
  /**
   * Function to compute the output whether the people agent will reroute (choose different path),
   * based on current local conditions passed through parameters
   * 
   * @params normalized_time_spent it's the real time spent divided by free flow time spent
   * @params next_link_saturation it's the current volume divided by max_capacity
   */
  action will_reroute(float normalized_time_spent, float next_link_saturation) {
    float epsilon <- 10 ^ -5;
    if (normalized_time_spent < 1 and (1 - normalized_time_spent) <= epsilon) {
      normalized_time_spent <- 1.0;
    }
    
    // Re-route strategy formula (Heavistep function)
    float value <- (cos(alpha#to_deg) * normalized_time_spent + sin(alpha#to_deg) * next_link_saturation - theta);    
    // If output = 1, will attempt to avoid congested road
    if (value >= 0) {
      total_reroute_count <- total_reroute_count + 1;
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
    
    // People inside blocked road is shaped differently (triangle)
    if (is_in_blocked_road = true) {
      draw triangle(65) color: color;
    } else {
      draw circle(50) color: color;
    }

  }

}

