package com.strix.collision.quadtree {
    
    import com.strix.collision.Agent;
    import com.strix.collision.Collision;
    import com.strix.collision.Mask;
    import com.strix.collision.Volume;
    import com.strix.collision.error.IllegalBoundsError;
    import com.strix.collision.error.InternalError;
    import com.strix.notification.Notification;
    
    
    internal final class TreeNode {

        private static const
            READD           : Boolean = true,
            DISCRETE_MODE   : uint = 0,
            CONTINUOUS_MODE : uint = 1;
        
        public var
            volume : Volume;
                
        public var
            mode     : uint,
            depth    : uint,
            maxDepth : uint,
            root     : TreeNode,
            parent   : TreeNode,
            children : Vector.<TreeNode>;
        
        public var
            objects       : Vector.<Agent>,
            objectChanged : Vector.<Function>;
        
            
        public function TreeNode(
            volume:Volume,
            depth:uint, maxDepth:uint,
            parent:TreeNode, root:TreeNode,
            mode:uint=DISCRETE_MODE ) {
            
            this.volume = volume;
            
            this.depth = depth;
            this.maxDepth = maxDepth;
            
            this.parent = parent;
            this.root = root;
            this.children = new Vector.<TreeNode>(4, true);
            
            this.objects = new Vector.<Agent>;
            this.objectChanged = new Vector.<Function>;
            
            this.mode = mode;
        }
        
        
        public function addObject( object:Agent, readd:Boolean=false ) : TreeNode {
            if( Quadtree.throwExceptions && !Volume.containBoxBox(volume, object) )
                throw new IllegalBoundsError("Attempted to insert and object with, or update an object to, illegal bounds.");
            
            //If object exceeds half-width x half-width, it straddles some axis, and must be stored here
            if( object.srx > volume.rx || object.sry > volume.ry )
                return addObjectToSelf(object, readd);
            
            //If maximum depth has been reached, object must be stored here
            if( depth >= maxDepth )
                return addObjectToSelf(object, readd);
            
            var quad       : uint = 0,
                quadVolume : Volume = new Volume(volume.x, volume.y, volume.rx*0.5, volume.rx*0.5);

            //Attempt to fit the object into one of the quadrants
            for( var qy : uint = 0; qy < 2; qy++ ) {
                for( var qx : uint = 0; qx < 2; qx++ ) {
                    quadVolume.moveTo((volume.x-quadVolume.rx)+qx*volume.rx, (volume.y-quadVolume.ry)+qy*volume.rx);
  
                    if( Volume.containBoxBox(quadVolume, object) ) {
                        if( children[quad] == null ) {
                            children[quad] = TreeNodePool.getObject(
                                new Volume(
                                    quadVolume.x,
                                    quadVolume.y,
                                    quadVolume.rx,
                                    quadVolume.ry
                                ),
                                depth+1, maxDepth,
                                this, root,
                                mode
                            );
                        }
                        
                        return children[quad].addObject(object);
                    }
                    
                    quad++;
                }
            }
            
            //Object did not fit into any of the quadrants
            return addObjectToSelf(object, readd);
        }

        
        private function addObjectToSelf( object:Agent, readd:Boolean=false ) : TreeNode {
            if( readd )
                return this;
            
            objects.push(object);
            objectChanged.push(
                function() : void {
                    if( Volume.containBoxBox(volume, object) ) {
                        //Object is still contained by self
                        if( this !== addObject(object, READD) )
                            deleteObject(object);
                    } else {
                        //Object is no longer contained by self
                        deleteObject(object);
                        root.addObject(object);
                    }
                }
            );
            
            if( mode == DISCRETE_MODE ) {
                object.onChange.addListener(
                    Volume.ON_MOVE | Volume.ON_RESIZE | Volume.ON_TRANSLATE,
                    objectChanged[objectChanged.length-1],
                    this
                );
            } else if( mode == CONTINUOUS_MODE ) {
                object.onChange.addListener(
                    Volume.ON_MOVE | Volume.ON_RESIZE | Volume.ON_SWEEP,
                    objectChanged[objectChanged.length-1],
                    this
                );
            }
            
            return this;
        }
        
        
        public function queryVolume( query:Volume, mask:uint, collisions:Vector.<Agent> ) : void {
            var quad       : uint,
                quadVolume : Volume = new Volume(
                    volume.x-volume.rx*0.5,
                    volume.y-volume.rx*0.5,
                    volume.rx*0.5,
                    volume.rx*0.5
                );

            //Collect all object IDs intersected by the query
            for( var object : uint = 0; object < objects.length; object++ ) {
                if( !Mask.interacts(mask, objects[object].mask) )
                    continue;
                
                if( mode == DISCRETE_MODE && Volume.intersectBoxBox(query, objects[object]) )
                    collisions.push(objects[object]);
                
                if( mode == CONTINUOUS_MODE && Volume.intersectSweptBoxBox(query, objects[object]) )
                    collisions.push(objects[object]);

            }
            
            //Descend into all quadrants intersected by the query
            for( var qy : uint = 0; qy < 2; qy++ ) {
                for( var qx : uint = 0; qx < 2; qx++ ) {
                    quadVolume.translate(qx*volume.rx, qy*volume.rx);

                    if( children[quad] != null && Volume.intersectBoxBox(volume, quadVolume) )
                        children[quad].queryVolume(query, mask, collisions);
                    
                    quad++;
                }
            }
        }
        
        
        public function queryPoint( point:Volume, mask:uint, collisions:Vector.<Agent> ) : void {
            var quad       : uint,
                quadVolume : Volume = new Volume(
                    volume.x-volume.rx*0.5,
                    volume.y-volume.rx*0.5,
                    volume.rx*0.5,
                    volume.rx*0.5
                );
            
            //Collect all object IDs intersected by the query
            for( var object : uint = 0; object < objects.length; object++ ) {
                if( !Mask.interacts(mask, objects[object].mask) )
                    continue;
                
                if( Volume.containBoxPoint(objects[object], point) )
                    collisions.push(objects[object]);
            }
            
            //Descend into all quadrants intersected by the query
            for( var qy : uint = 0; qy < 2; qy++ ) {
                for( var qx : uint = 0; qx < 2; qx++ ) {
                    quadVolume.translate(qx*volume.rx, qy*volume.rx);
                    
                    if( children[quad] != null &&
                        Volume.containBoxPoint(quadVolume, point) ) {
                            children[quad].queryPoint(point, mask, collisions);
                    }
                    
                    quad++;
                }
            }
        }

        
        public function queryCollisions( collisions:Vector.<Collision> ) : void {
            //Test all objects at this node against each other
            for( var i : uint = 0; i < objects.length-1; i++ ) {
                for( var j : uint = i+1; j < objects.length; j++ ) {
                    if( !Mask.interacts(objects[i].mask, objects[j].mask) )
                        continue;
                    
                    if( mode == DISCRETE_MODE && Volume.intersectBoxBox(objects[i], objects[j]) )
                        collisions.push(
                            new Collision(
                                objects[i],
                                objects[j],
                                Mask.actions(objects[i].mask, objects[j].mask),
                                Mask.actions(objects[j].mask, objects[i].mask)
                            )
                        );
                    
                    if( mode == CONTINUOUS_MODE && Volume.intersectSweptBoxBox(objects[i], objects[j]) )
                        collisions.push(
                            new Collision(
                                objects[i],
                                objects[j],
                                Mask.actions(objects[i].mask, objects[j].mask),
                                Mask.actions(objects[j].mask, objects[i].mask)
                            )
                        );
                }
            }
            
            //Test all objects at this node against all ancestor objects
            var ancestor : TreeNode = parent;
            
            while( ancestor != null ) {
                for( i = 0; i < objects.length; i++ ) {
                    for( j = 0; j < ancestor.objects.length; j++ ) {
                        if( !Mask.interacts(objects[i].mask, ancestor.objects[j].mask) )
                            continue;
                        
                        if( mode == DISCRETE_MODE && Volume.intersectBoxBox(objects[i], ancestor.objects[j]) )
                            collisions.push(
                                new Collision(
                                    objects[i],
                                    ancestor.objects[j],
                                    Mask.actions(objects[i].mask, ancestor.objects[j].mask),
                                    Mask.actions(ancestor.objects[j].mask, objects[i].mask)
                                )
                            );
                        
                        if( mode == CONTINUOUS_MODE && Volume.intersectSweptBoxBox(objects[i], ancestor.objects[j]) )
                            collisions.push(
                                new Collision(
                                    objects[i],
                                    ancestor.objects[j],
                                    Mask.actions(objects[i].mask, ancestor.objects[j].mask),
                                    Mask.actions(ancestor.objects[j].mask, objects[i].mask)
                                )
                            );
                    }
                }

                ancestor = ancestor.parent;
            }
            
            //Descend into all active children
            for( i = 0; i < 4; i++ ) {
                if( children[i] != null )
                    children[i].queryCollisions(collisions);
            }
        }
        
        
        public function deleteObject( object:Agent ) : void {
            for( var i : uint = 0; i < objects.length; i++ ) {
                if( objects[i].id == object.id ) {
                    objects[i].onChange.removeListener(Notification.ALL, objectChanged[i]);
                    objects.splice(i, 1);
                    return;
                }
            }
        }
        
        
        public function deleteChild( child:TreeNode ) : void {
            var activeChildren : uint = 0,
                childIndex     : int = -1;
            
            for( var quad : uint = 0; quad < 4; quad++ ) {
                if( children[quad] === child ) {
                    childIndex = quad;
                } else if( children[quad] != null ) {
                    activeChildren++;
                }
            }
            
            if( childIndex == -1 )
                throw new InternalError("Attempted to delete an non-existent child");
            
            TreeNodePool.addObject(children[childIndex]);
            
            children[childIndex] = null;
            
            if( activeChildren == 0 && objects.length == 0 )
                parent.deleteChild(this);
        }
        
    }
    
}