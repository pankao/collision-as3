collision-as3
=============

Broadphase collision detection library for ActionScript 3.

Status: Please note that this is still in Alpha: documentation might be slightly out of date, certain unit tests are missing.

<br>

## News
 - 2012-07-20: A new, hybrid container is in the works, which will combine quadtrees, spatial hashing and SAP
 
<br>

## Features
 - Object-oriented system
 - Continuous and discrete collision detection
 - Spatially partitioned containers
   - Quadtree
   - Spatial Hash Grid
 - Generic bounding volume
 - Manage objects through easy-to-extend Agent class
 - Starling integration (work in progress)


## Getting started
### Hello world!
```actionscript
//Create spatial containers
var quadtree    : Quadtree = new Quadtree(new Volume(500.0, 500.0, 500.0));
var spatialHash : SpatialHash = new SpatialHash();

//Create two agents
var agentA : Agent = new Agent(1, Mask.ALL, 50.0, 50.0, 10.0));
var agentB : Agent = new Agent(2, Mask.ALL, 80.0, 50.0, 10.0));

//Add agents to containers
quadtree.addAgent(agentA);
quadtree.addAgent(agentB);
spatialHash.addAgent(agentA);
spatialHash.addAgent(agentB);

//Manipulate agents
agentA.translate(7.5, 0.0);
agentB.translate(-7.5, 0.0);

//Handle collisions
for each( var collision : Collision in spatialHash.queryCollisions() ) {
   //...
}

//Issue some aribtrary queries
var queryA : Vector.<Agent> = quadtree.queryVolume(new Volume(65.0, 50.0, 20.0));
var queryB : Vector.<Agent> = spatialHash.queryPoint(new Volume(65.0, 50.0));

//Clean up
quadtree.deleteAgent(agentA);
quadtree.deleteAgent(agentB);
spatialHash.deleteAgent(agentA);
spatialHash.deleteAgent(agentB);
```


## Documentation
Working with containers:
 - [Quadtree](https://github.com/martinkallman/collision-as3/wiki/Quadtree-class)
 - [Spatial Hash](https://github.com/martinkallman/collision-as3/wiki/SpatialHash-class)

Working with objects:
 - [Agent](https://github.com/martinkallman/collision-as3/wiki/Agent-class)
 - [Volume](https://github.com/martinkallman/collision-as3/wiki/Volume-class)
 - [Mask](https://github.com/martinkallman/collision-as3/wiki/Mask-class)
 - [Collision](https://github.com/martinkallman/collision-as3/wiki/Collision-class)

Working with 3rd party code:
 - [Integrating with Starling](https://github.com/martinkallman/collision-as3/wiki/Integrating-with-starling)