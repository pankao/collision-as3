package com.strix.collision.spatialhash {
    
    import com.strix.collision.Collidable;
    import com.strix.collision.Collision;
    import com.strix.collision.CollisionMask;
    import com.strix.collision.PointQuery;
    import com.strix.collision.Volume;
    import com.strix.collision.VolumeQuery;
    import com.strix.collision.error.IllegalBoundsError;
    import com.strix.collision.error.InvalidObjectError;
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
            bucket          : Vector.<Vector.<Collidable>>,
            bucketMod       : uint,
            bucketTimestamp : Vector.<uint>,
            timestamp       : uint, 
            resolution      : uint,
            resolutionLog2  : uint;
            
            
        public function SpatialHash( resolution:uint, buckets:uint, mode:uint=DISCRETE_MODE ) {
            //Parameter for hashtable buckets, Parameter for filter size, Default for resolution, Power of 2 check
            this.mode = mode;
            this.object = new Hashtable;
            this.filter  = new CountingBloomfilter(32768);
            this.resolutionLog2 = Math.log(resolution)*Math.LOG2E;
            
            this.bucket = new Vector.<Vector.<Collidable>>(buckets, true);
            
            for( var i : uint = 0; i < buckets; i++ ) {
                this.bucket[i] = new Vector.<Collidable>;
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
        
        
        public function addObject( collidable:Collidable ) : void {
            if( collidable.volume.x1 < 0 ||
                collidable.volume.y1 < 0 ||
                collidable.volume.x2 >> resolutionLog2 > 65535 ||
                collidable.volume.y2 >> resolutionLog2 > 65535 ) {
                    throw new IllegalBoundsError("Object with ID " + collidable.id + " is out of bounds");
            }
            
            if( throwExceptions && object[collidable.id] != null )
                throw new InvalidObjectError("Object with ID " + collidable.id + " already exists.");

            collidable.cells = volumeToCells(collidable.volume);
            collidable.buckets = cellsToBuckets(collidable.cells);
            
            collidable.boundsX1 = collidable.volume.x1 >> resolutionLog2;
            collidable.boundsX2 = collidable.volume.x2 >> resolutionLog2;
            collidable.boundsY1 = collidable.volume.y1 >> resolutionLog2;
            collidable.boundsY2 = collidable.volume.y2 >> resolutionLog2;
            
            var numBuckets : uint = collidable.buckets.length;
            
            for( var i : uint = 0; i < numBuckets; i++ ) {
                bucket[collidable.buckets[i]].push(collidable);
            }
            
            collidable.onChange = function( notification:uint, data:* ) : void {
                updateObject(collidable);
            };
            
            if( mode == DISCRETE_MODE ) {
                collidable.volume.onChange.addListener(
                    Volume.ON_MOVE | Volume.ON_RESIZE | Volume.ON_TRANSLATE,
                    collidable.onChange,
                    this
                );
            } else if( mode == CONTINUOUS_MODE ) {
                collidable.volume.onChange.addListener(
                    Volume.ON_MOVE | Volume.ON_RESIZE | Volume.ON_SWEEP,
                    collidable.onChange,
                    this
                );
            }
            
            object[collidable.id] = collidable;
            addToFilter(collidable.cells);
        }
      
        
        public function deleteObject( collidable:Collidable ) : void {
            if( throwExceptions && object[collidable.id] == null )
                throw new InvalidObjectError("Object with ID " + collidable.id + " does not exist.");
            
            var collidable  : Collidable = object[collidable.id],
                numBuckets  : uint = collidable.buckets.length,
                bucketIndex : uint,
                bucketSize  : uint;
            
            for( var i : uint = 0; i < numBuckets; i++ ) {
                bucketIndex = collidable.buckets[i];
                bucketSize = bucket[bucketIndex].length;
                
                for( var j : uint = 0; j < bucketSize; j++ ) {
                    if( bucket[bucketIndex][j].id == collidable.id ) {
                        bucket[bucketIndex].splice(j, 1);
                        break;
                    }
                }
            }
            
            deleteFromFilter(collidable.cells);
            collidable.volume.onChange.removeListener(Notification.ALL, collidable.onChange);
            delete object[collidable.id];                
        }
            
   
        private function updateObject( collidable:Collidable ) : void {
            var x1 : uint = collidable.volume.x1 >> resolutionLog2,
                x2 : uint = collidable.volume.x2 >> resolutionLog2,
                y1 : uint = collidable.volume.y1 >> resolutionLog2,
                y2 : uint = collidable.volume.y2 >> resolutionLog2;
            
            var changed : Boolean =
                x1 != collidable.volume.x1 ||
                x2 != collidable.volume.x2 ||
                y1 != collidable.volume.y1 ||
                y2 != collidable.volume.y2;
            
            if( !changed )
                return;
            
            var numBuckets  : uint = collidable.buckets.length,
                bucketIndex : uint,
                bucketSize  : uint;
            
            for( var i : uint = 0; i < numBuckets; i++ ) {
                bucketIndex = collidable.buckets[i];
                bucketSize = bucket[bucketIndex].length;
                
                for( var j : uint = 0; j < bucketSize; j++ ) {
                    if( bucket[bucketIndex][j].id == collidable.id ) {
                        bucket[bucketIndex].splice(j, 1);
                        break;
                    }
                }
            }
            
            deleteFromFilter(collidable.cells);
            
            collidable.cells = volumeToCells(collidable.volume);
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
   
        
        public function queryVolume( volumeQuery:VolumeQuery, collisions:Vector.<Collision>=null, deduplicate:Boolean=true ) : Vector.<Collision> {
            var queryCells   : Vector.<uint> = volumeToFilteredCells(volumeQuery.volume),
                queryBuckets : Vector.<uint> = cellsToBuckets(queryCells);
            
            if( collisions == null ) {
                collisions = new Vector.<Collision>;
            }
            
            for each( var queryBucket : uint in queryBuckets ) {
                for each( var object : Collidable in bucket[queryBucket] ) {
                    if( !CollisionMask.interacts(volumeQuery.mask, object.mask) ) {
                        continue;
                    }
                    
                    if( mode == DISCRETE_MODE &&
                        Volume.intersectBoxBox(volumeQuery.volume, object.volume) ) {
                            collisions.push(new Collision(volumeQuery, object));
                    }
                        
                    if( mode == CONTINUOUS_MODE &&
                        Volume.intersectSweptBoxBox(volumeQuery.volume, object.volume) ) {
                            collisions.push(new Collision(volumeQuery, object));
                    }
                }
            }
            

            if( collisions.length > 0 ) {
                if( deduplicate ) {
                    collisions = uniqueCollisions(collisions);
                }
                
                return collisions;
            }
            
            return null;
        }

        
        public function queryPoint( pointQuery:PointQuery, collisions:Vector.<Collision>=null ) : Vector.<Collision> {
            var x    : uint = pointQuery.volume.x >> resolutionLog2,
                y    : uint = pointQuery.volume.x >> resolutionLog2,
                cell : uint = hash((y*65535) + x);

            if( !filter.isMember(cell, true) ) {
                return null;
            }
            
            if( collisions == null ) {
                collisions = new Vector.<Collision>;
            }
            
            var queryBucket : uint = cell & bucketMod;
            
            for each( var object : Collidable in bucket[queryBucket] ) {
                if( !CollisionMask.interacts(pointQuery.mask, object.mask) ) {
                    continue;
                }
                
                if( Volume.containBoxPoint(object.volume, pointQuery.volume) ) {
                    collisions.push(new Collision(pointQuery, object));
                }
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
                        var objectA : Collidable = bucket[i][j],
                            objectB : Collidable = bucket[i][k];
                        
                        if( !CollisionMask.interacts(objectA.mask, objectB.mask) ) {
                            continue;
                        }
                        
                        if( mode == DISCRETE_MODE &&
                            Volume.intersectBoxBox(objectA.volume, objectB.volume) ) {
                                collisions.push(new Collision(objectA, objectB));
                        }
                        
                        if( mode == CONTINUOUS_MODE &&
                            Volume.intersectSweptBoxBox(objectA.volume, objectB.volume) ) {
                                collisions.push(new Collision(objectA, objectB));
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

    }
    
}