model my_node

/*
 * Node species
 */
species my_node {
  int node_number <- length(my_node) - 1; // node id
  int accum_traffic_count <- 0; // accumulated traffic count
  aspect base {
    draw square(50) color: #black;
    draw string(node_number) color: #black font: font('Helvetica', 5, #plain);
  }
}

