package com.strix.collision.spatialhash {
    
    import com.strix.collision.Agent;
    import com.strix.collision.Collision;
    import com.strix.collision.Mask;
    import com.strix.collision.Volume;
    import com.strix.collision.error.IllegalBoundsError;
    import com.strix.collision.error.InvalidObjectError;
    import com.strix.collision.pool.VolumePool;
    import com.strix.hashtable.Hashtable;
    import com.strix.notification.Notification;
    
    
    public class SpatialHash {
        
        public static const
            DISCRETE_MODE   : uint = 0,
            CONTINUOUS_MODE : uint = 1;
        
        public static var
            throwExceptions : Boolean = true;
        
        private var
            mode            : uint,
            object          : Hashtable,
            filter          : CountingBloomfilter,
            bucket          : Vector.<Vector.<InternalAgent>>,
            bucketMod       : uint,
            bucketTimestamp : Vector.<uint>,
            timestamp       : uint, 
            resolution      : uint,
            resolutionLog2  : uint;
            
            
        public function SpatialHash(
            mode:uint=DISCRETE_MODE,
            resolution:uint=64,
            buckets:uint=64,
            filterSize:uint=32768 ) {
            
            this.mode = mode;
            this.object = new Hashtable;
            this.filter  = new CountingBloomfilter(filterSize);
            this.resolutionLog2 = Math.log(resolution)*Math.LOG2E;
            
            this.bucket = new Vector.<Vector.<InternalAgent>>(buckets, true);
            
            for( var i : uint = 0; i < buckets; i++ ) {
                this.bucket[i] = new Vector.<InternalAgent>;
            }
            
            this.bucketTimestamp = new Vector.<uint>(buckets, true);
        }
        
        
        private static function hash( k:uint ) : uint {
            //32-bit integer hash function by Thomas Wang
            k = (k ^ 61) ^ (k >> 16);
            k += (k << 3);
            k ^= (k >> 4);
            k *= 0x27d4eb2d;
            k ^= (k >> 15);
            
            return k;
        }
        
        
        private function volumeToCells( volume:Volume ) : Vector.<uint> {
            var x1 : uint = volume.x1 >> resolutionLog2,
                x2 : uint = volume.x2 >> resolutionLog2,
                y1 : uint = volume.y1 >> resolutionLog2,
                y2 : uint = volume.y2 >> resolutionLog2;
            
            var cells : Vector.<uint> = new Vector.<uint>((1+x2-x1) * (1+y2-y1), true),
                cell  : uint = 0;
            
            for( var x : uint = x1; x <= x2; x++ ) {
                for( var y : uint = y1; y <= y2; y++ ) {
                    cells[cell++] = hash((y*65535) + x);
                }    
            }
            
            return cells;
        }
        
        
        private function volumeToFilteredCells( volume:Volume ) : Vector.<uint> {
            var x1 : uint = volume.x1 >> resolutionLog2,
                x2 : uint = volume.x2 >> resolutionLog2,
                y1 : uint = volume.y1 >> resolutionLog2,
                y2 : uint = volume.y2 >> resolutionLog2;
            
            var cells : Vector.<uint> = new Vector.<uint>,
                cell  : uint = 0;
            
            for( var x : uint = x1; x <= x2; x++ ) {
                for( var y : uint = y1; y <= y2; y++ ) {
                    cell = hash((y*65535) + x);
                    if( filter.isMember(cell, true) ) {
                        cells.push(cell);
                    }
                }    
            }
            
            return cells;
        }
        
        
        private function cellsToBuckets( cells:Vector.<uint> ) : Vector.<uint> {
            var numCells    : uint = cells.length,
                buckets     : Vector.<uint> = new Vector.<uint>,
                bucketIndex : uint;
            
            timestamp++;
            
            for( var i : uint = 0; i < numCells; i++ ) {
                bucketIndex = cells[i] & bucketMod;
                
                if( bucketTimestamp[bucketIndex] == timestamp )
                    continue;
                
                bucketTimestamp[bucketIndex] = timestamp;
                buckets.push(bucketIndex);
            }
            
            return buckets;
        }
        
        
        private function addToFilter( cells:Vector.<uint> ) : void {
            var numCells : uint = cells.length;
            
            for( var i : uint = 0; i < numCells; i++ ) {
                filter.addMember(cells[i], true);
            }
        }
        
        
        private function deleteFromFilter( cells:Vector.<uint> ) : void {
            var numCells : uint = cells.length;
            
            for( var i : uint = 0; i < numCells; i++ ) {
                filter.deleteMember(cells[i], true);
            }
        }
        
        
        public function addObject( agent:Agent ) : void {
            
            if( agent.x1 < 0 ||
                agent.y1 < 0 ||
                agent.x2 >> resolutionLog2 > 65535 ||
                agent.y2 >> resolutionLog2 > 65535 ) {
                    throw new IllegalBoundsError("Object with ID " + agent.id + " is out of bounds");
            }
            
            if( throwExceptions && object[agent.id] != null )
                throw new InvalidObjectError("Object with ID " + agent.id + " already exists.");

            var internalAgent : InternalAgent = new InternalAgent;
            
            internalAgent.agent = agent;
            
            internalAgent.cells = volumeToCells(internalAgent.agent);
            internalAgent.buckets = cellsToBuckets(internalAgent.cells);
            
            internalAgent.boundsX1 = internalAgent.agent.x1 >> resolutionLog2;
            internalAgent.boundsX2 = internalAgent.agent.x2 >> resolutionLog2;
            internalAgent.boundsY1 = internalAgent.agent.y1 >> resolutionLog2;
            internalAgent.boundsY2 = internalAgent.agent.y2 >> resolutionLog2;
            
            var numBuckets : uint = internalAgent.buckets.length;
            
            for( var i : uint = 0; i < numBuckets; i++ ) {
                bucket[internalAgent.buckets[i]].push(internalAgent);
            }
            
            internalAgent.onChange = function( notification:uint, data:* ) : void {
                updateObject(internalAgent);
            };
            
            if( mode == DISCRETE_MODE ) {
                internalAgent.agent.onChange.addListener(
                    Volume.ON_MOVE | Volume.ON_RESIZE | Volume.ON_TRANSLATE,
                    internalAgent.onChange,
                    this
                );
            } else if( mode == CONTINUOUS_MODE ) {
                internalAgent.agent.onChange.addListener(
                    Volume.ON_MOVE | Volume.ON_RESIZE | Volume.ON_SWEEP,
                    internalAgent.onChange,
                    this
                );
            }
            
            object[internalAgent.agent.id] = internalAgent;
            addToFilter(internalAgent.cells);
        }
      
        
        public function deleteObject( collidable:Agent ) : void {
            if( throwExceptions && object[collidable.id] == null )
                throw new InvalidObjectError("Object with ID " + collidable.id + " does not exist.");
            
            var internalAgent : InternalAgent = object[collidable.id],
                numBuckets  : uint = internalAgent.buckets.length,
                bucketIndex : uint,
                bucketSize  : uint;
            
            for( var i : uint = 0; i < numBuckets; i++ ) {
                bucketIndex = internalAgent.buckets[i];
                bucketSize = bucket[bucketIndex].length;
                
                for( var j : uint = 0; j < bucketSize; j++ ) {
                    if( bucket[bucketIndex][j].agent.id == collidable.id ) {
                        bucket[bucketIndex].splice(j, 1);
                        break;
                    }
                }
            }
            
            deleteFromFilter(internalAgent.cells);
            internalAgent.agent.onChange.removeListener(Notification.ALL, internalAgent.onChange);
            delete object[collidable.id];                
        }
            
   
        private function updateObject( collidable:InternalAgent ) : void {
            var x1 : uint = collidable.agent.x1 >> resolutionLog2,
                x2 : uint = collidable.agent.x2 >> resolutionLog2,
                y1 : uint = collidable.agent.y1 >> resolutionLog2,
                y2 : uint = collidable.agent.y2 >> resolutionLog2;
            
            var changed : Boolean =
                x1 != collidable.agent.x1 ||
                x2 != collidable.agent.x2 ||
                y1 != collidable.agent.y1 ||
                y2 != collidable.agent.y2;
            
            if( !changed )
                return;
            
            var numBuckets  : uint = collidable.buckets.length,
                bucketIndex : uint,
                bucketSize  : uint;
            
            for( var i : uint = 0; i < numBuckets; i++ ) {
                bucketIndex = collidable.buckets[i];
                bucketSize = bucket[bucketIndex].length;
                
                for( var j : uint = 0; j < bucketSize; j++ ) {
                    if( bucket[bucketIndex][j].agent.id == collidable.agent.id ) {
                        bucket[bucketIndex].splice(j, 1);
                        break;
                    }
                }
            }
            
            deleteFromFilter(collidable.cells);
            
            collidable.cells = volumeToCells(collidable.agent);
            collidable.buckets = cellsToBuckets(collidable.cells);
            
            collidable.boundsX1 = x1;
            collidable.boundsX2 = x2;
            collidable.boundsY1 = y1;
            collidable.boundsY2 = y2;
            
            numBuckets = collidable.buckets.length;
            
            for( i = 0; i < numBuckets; i++ ) {
                bucket[collidable.buckets[i]].push(collidable);
            }
            
            addToFilter(collidable.cells);
        }
   
        
        public function queryVolume( volume:Volume, mask:uint, collisions:Vector.<Agent>=null, deduplicate:Boolean=true ) : Vector.<Agent> {
            var queryCells   : Vector.<uint> = volumeToFilteredCells(volume),
                queryBuckets : Vector.<uint> = cellsToBuckets(queryCells);
            
            if( collisions == null ) {
                collisions = new Vector.<Agent>;
            }
            
            for each( var queryBucket : uint in queryBuckets ) {
                for each( var object : Agent in bucket[queryBucket] ) {
                    if( !Mask.interacts(mask, object.mask) ) {
                        continue;
                    }
                    
                    if( mode == DISCRETE_MODE &&
                        Volume.intersectBoxBox(volume, object) ) {
                            collisions.push(object);
                    }
                        
                    if( mode == CONTINUOUS_MODE &&
                        Volume.intersectSweptBoxBox(volume, object) ) {
                            collisions.push(object);
                    }
                }
            }
            
            if( volume.disposable ) {
                VolumePool.reclaim(volume);
            }

            if( collisions.length > 0 ) {
                if( deduplicate ) {
                    collisions = uniqueAgents(collisions);
                }
                
                return collisions;
            }
            
            return null;
        }

        
        public function queryPoint( point:Volume, mask:uint, collisions:Vector.<Collision>=null ) : Vector.<Collision> {
            var x    : uint = point.x >> resolutionLog2,
                y    : uint = point.y >> resolutionLog2,
                cell : uint = hash((y*65535) + x);

            if( !filter.isMember(cell, true) ) {
                return null;
            }
            
            if( collisions == null ) {
                collisions = new Vector.<Collision>;
            }
            
            var queryBucket : uint = cell & bucketMod;
            
            for each( var object : Agent in bucket[queryBucket] ) {
                if( !Mask.interacts(mask, object.mask) ) {
                    continue;
                }
                
                if( Volume.containBoxPoint(object, point) ) {
                    collisions.push(object);
                }
            }
            
            if( point.disposable ) {
                VolumePool.reclaim(point);
            }

            if( collisions.length > 0 ) {
                return collisions;
            }
            
            return null;
        }
       
        
        public function queryCollisions() : Vector.<Collision> {
            var buckets    : uint = bucket.length,
                objects    : uint,
                collisions : Vector.<Collision> = new Vector.<Collision>;                
            
            for( var i : uint = 0; i < buckets; i++ ) {
                objects = bucket[i].length;
                
                for( var j : uint = 0; j < objects-1; j++ ) {
                    for( var k : uint = j+1; k < objects; k++ ) {
                        var objectA : InternalAgent = bucket[i][j],
                            objectB : InternalAgent = bucket[i][k];
                        
                        if( !Mask.interacts(objectA.agent.mask, objectB.agent.mask) ) {
                            continue;
                        }
                        
                        if( mode == DISCRETE_MODE &&
                            Volume.intersectBoxBox(objectA.agent, objectB.agent) ) {
                                collisions.push(
                                    new Collision(
                                        objectA.agent,
                                        objectB.agent,
                                        Mask.actions(objectA.agent.mask, objectB.agent.mask),
                                        Mask.actions(objectB.agent.mask, objectA.agent.mask)
                                    )
                                );
                        }
                        
                        if( mode == CONTINUOUS_MODE &&
                            Volume.intersectSweptBoxBox(objectA.agent, objectB.agent) ) {
                                collisions.push(
                                    new Collision(
                                        objectA.agent,
                                        objectB.agent,
                                        Mask.actions(objectA.agent.mask, objectB.agent.mask),
                                        Mask.actions(objectB.agent.mask, objectA.agent.mask)
                                    )
                                );
                        }
                    }
                }
            }
            
            if( collisions.length > 0 ) {
                collisions = uniqueCollisions(collisions);
                return collisions;
            }
            
            return null;
            
        }
        
        public static function uniqueCollisions( vector:Vector.<Collision> ) : Vector.<Collision> {
            if( vector.length == 0 ) {
                return vector;
            }
            
            vector.sort(
                function( collisionA:Collision, collisionB:Collision ) : int {
                    if( collisionA.a.id < collisionB.a.id )
                        return -1;
                    
                    if( collisionA.a.id > collisionB.a.id )
                        return 1;
                    
                    return 0;
                }
            );
            
            var deduplicated : Vector.<Collision> = new Vector.<Collision>,
                current      : Collision = vector[0];
            
            deduplicated.push(current);
            
            for( var i : uint = 1; i < vector.length; i++ ) {
                if( vector[i] != current ) {
                    current = vector[i];
                    deduplicated.push(current);
                }
            }
            
            return deduplicated;
        }
        
        
        public static function uniqueAgents( vector:Vector.<Agent> ) : Vector.<Agent> {
            if( vector.length == 0 ) {
                return vector;
            }
            
            vector.sort(
                function( agentA:Agent, agentB:Agent ) : int {
                    if( agentA.id < agentB.id )
                        return -1;
                    
                    if( agentA.id > agentA.id )
                        return 1;
                    
                    return 0;
                }
            );
            
            var deduplicated : Vector.<Agent> = new Vector.<Agent>,
                current      : Agent = vector[0];
            
            deduplicated.push(current);
            
            for( var i : uint = 1; i < vector.length; i++ ) {
                if( vector[i] != current ) {
                    current = vector[i];
                    deduplicated.push(current);
                }
            }
            
            return deduplicated;
        }

    }
    
}