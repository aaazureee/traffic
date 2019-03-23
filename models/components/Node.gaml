model my_node

/** 
 * Node species on road graph network
 * 
 * @author Hieu Chu (chc116@uowmail.edu.au)
 */
species my_node {
  int node_number <- length(my_node) - 1; // node id
  int accum_traffic_count <- 0; // accumulated traffic count (number of people passing through nodes)
  aspect base {
    // representation in main simulation display is black space with ID number on top of the node
    draw square(50) color: #black;
    draw string(node_number) color: #black font: font('Helvetica', 5, #plain);
  }
}

