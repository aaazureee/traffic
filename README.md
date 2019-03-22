# Dynamic traffic simulation model
Dynamic traffic simulation model with smart re-routing strategy implemeted in GAMA platform, support dynamic user interaction and loading of external shape file to generate road graph network.

## Quick Overview
<p align="center">
  <img src="https://i.imgur.com/9WVC1iZ.png" alt="main simulation" />
  <br/>
  <i>Main traffic simulation</i>
</p>

The traffic simulation consists of a road network, which is based on a graph of nodes (intersection) and roads connecting these nodes. During the simulation, people will be initialized at a random source node, and is given a random destination node to travel to. People will move towards the destination node after each cycle in the simulation. When the person arrives at the destination node, it is removed from the simulation.   
This simulation replicates a real world traffic situation, meaning that vehicles aren’t allowed to overtake when they are travelling in the same road (i.e. same lane) by determining equilibrium speed using BPR equation. The model also handles congested road, i.e. traffic jam by preventing people from entering the road when the road is at its max capacity. Moreover, people agents have the possibility to apply a smart rerouting strategy based on the current conditions (for example, if the next road is congested, the agent might want to avoid this and choose a different path). The strategy is based on a neural network implementation, with application of genetic algorithm to find optimal strategy parameters. We refer the reader to [Johan Barthélemy and Timoteo Carletti, 2017](#references) for more detailed documentation.   
Moreover, it supports dynamic user interaction such as blocking and un-blocking a chosen road on the network graph and see how the people agent adapts to the situation.  
There are also data visualization graphs that will aid user's interpretation of the simulation (running in parallel with the main simulation), and text output data in CSV format concerning accumulated number of people passing through roads, nodes, and origin-destination matrix.

## Installation
### Step 1: Clone this repo  
`git clone https://github.com/aaazureee/traffic.git`
### Step 2: Install GAMA
Choose your OS version here: https://gama-platform.github.io/download
### Step 3: Import project
![import project](https://i.imgur.com/Z3tGfpk.png)
### Step 4: Run main simulation
Navigate to `~/models/Main.gaml` and run `traffic_simulation` experiment  
<p>
  <img src="https://i.imgur.com/s7u0axf.png" alt="run main"'/>
</p>  

## Folder structure
```
├───input_data/
│   ├───network_links.dbf
│   ├───network_links.prj
│   ├───network_links.shp
│   ├───network_links.shx
│   └───strategies.txt
└───models/
    ├───components/
    │   ├───File Saver.gaml
    │   ├───Node.gaml
    │   ├───People.gaml
    │   └───Road.gaml
    ├───traffic-results/
    │   ├───matrix_stats.txt
    │   ├───node-stats.txt
    │   └───road-stats.txt
    └───Main.gaml
```

## Detailed documentation
Please refer to this report for detailed documentation of this model.

## Authors and acknowledgment
* [Hieu Chu](mailto:chc116@uowmail.edu.au), University of Wollongong.
* [Dr. Johan Barthélemy](mailto:johan@uow.edu.au), University of Wollongong (supervisor).
* [Dr. Nicolas Verstaevel](mailto:nicolasv@uow.edu.au), University of Wollongong (supervisor).

## References
* [Bureau of Public Roads (BPR), 2019. Route assignment - Wikipedia](https://en.wikipedia.org/wiki/Route_assignment#Frank-Wolfe_algorithm).
* [Johan Barthélemy, Timoteo Carletti, 2017. A dynamic behavioural traffic assignment model with strategic agents. Transportation Research Part C: Emerging Technologies, Volume 85, pp. 23-46](https://www.sciencedirect.com/science/article/pii/S0968090X17302450).

## License
Distributed under the MIT License. See [LICENSE](LICENSE) for more information.
