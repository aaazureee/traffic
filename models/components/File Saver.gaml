model file_saver
import "../Main.gaml"
 
/** 
 * Helper class to save data output to external file
 * 
 * @author Hieu Chu (chc116@uowmail.edu.au)
 */ 
species file_saver {
  file result_dir <- folder('./traffic-results'); // result (data output) directory
  string node_stats_file <- "./traffic-results/node-stats.txt";
  string road_stats_file <- "./traffic-results/road-stats.txt";
  string matrix_stats_file <- './traffic-results/matrix-stats.txt';

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
    if (write_matrix_output) {
      do write_matrix_output;
    }

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

  // orig_dest matrix stats output
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
