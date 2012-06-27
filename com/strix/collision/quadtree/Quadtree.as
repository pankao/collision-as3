package com.strix.collision.quadtree {

    import com.strix.collision.Collidable;
    import com.strix.collision.Collision;
    import com.strix.collision.CollisionMask;
    import com.strix.collision.PointQuery;
    import com.strix.collision.Volume;
    import com.strix.collision.VolumeQuery;
    import com.strix.collision.error.IllegalBoundsError;
    import com.strix.collision.error.InvalidObjectError;
    import com.strix.collision.error.InvalidVolumeError;
    import com.strix.hashtable.Hashtable;
   
    
    public final class Quadtree {
        
        private var
            rootNode   : TreeNode,
            idTreeNode : Hashtable,
            mode       : uint;
            
        public static const
            DISCRETE_MODE   : uint = 0,
            CONTINUOUS_MODE : uint = 1;
            
        public static var
            throwExceptions : Boolean = true;
        
            
        /**
        * Create a new Quadtree.
        * 
        * @param x Centroid x-coordinate
        * @param y Centroid y-coordinate
        * @param hw Half-width (radius)
        * @param maxDepth Maximum depth
        */
        public function Quadtree( volume:Volume, maxDepth:uint, mode:uint=DISCRETE_MODE ) {
            this.rootNode = new TreeNode(volume, 0, maxDepth-1, null, null, mode);
            this.rootNode.root = this.rootNode;
            this.idTreeNode = new Hashtable;
            this.mode = mode;
        }
        
        
        /**
        * Add an object to the Quadtree.
        * 
        * @param id Object ID
        * @param volume Object volume
        * @param mask Object collision mask
        */
        public function addObject( collidable:Collidable ) : void {
            if( throwExceptions && idTreeNode[collidable.id] != null )
                throw new InvalidObjectError("Object with ID " + collidable.id + " already exists.");
            
            if( throwExceptions && !Volume.containBoxBox(rootNode.volume, collidable.volume) )
                throw new IllegalBoundsError("Object with ID " + collidable.id + " has illegal bounds.");
            
            idTreeNode[collidable.id] = rootNode.addObject(collidable);
        }
        
        
        /**
        * Delete an object from the Quadtree.
        * 
        * @param id Object ID
        */
        public function deleteObject( collidable:Collidable ) : void {
            var treeNode : TreeNode = idTreeNode[collidable.id] as TreeNode;
            
            if( throwExceptions && treeNode == null )
                throw new InvalidObjectError("Object with ID " + collidable.id + " does not exist.");
            
            treeNode.deleteObject(collidable);
            delete idTreeNode[collidable.id];
        }
        
        
        /**
        * Find all object IDs in a given region of interest.
        * 
        * @param roi An volume representing the region of interest
        * @param mask Collision mask to be used
        */
        public function queryVolume( volumeQuery:VolumeQuery ) : Vector.<uint> {
            if( throwExceptions && !Volume.containBoxBox(rootNode.volume, volumeQuery.volume) )
                throw new IllegalBoundsError("Region of interest has illegal bounds.");
            
            var objects : Vector.<uint> = new Vector.<uint>;
            
            rootNode.queryVolume(volumeQuery, objects);
            
            if( objects.length > 0 ) {
                return objects;
            }
            
            return null;
        }
        
        
        /**
         * Find all object IDs at a given point.
         * 
         * @param x X-coordinate
         * @param y Y-coordinate
         * @param mask Collision mask to be used
         */
        public function queryPoint( pointQuery:PointQuery ) : Vector.<uint> {
            pointQuery.volume.resize(0, 0);
            
            if( throwExceptions && !Volume.containBoxPoint(rootNode.volume, pointQuery.volume) )
                throw new IllegalBoundsError("Query is out of bounds.");
            
            var objects : Vector.<uint> = new Vector.<uint>;
            
            rootNode.queryPoint(pointQuery, objects);
            
            if( objects.length > 0 ) {
                return objects;
            }
            
            return null;
        }
       
        
        /**
        * Find all colliding object IDs.
        */
        public function queryCollisions() : Vector.<Collision> {
            var collisions : Vector.<Collision> = new Vector.<Collision>;
            
            rootNode.queryCollisions(collisions);
            
            if( collisions.length > 0 ) {
                return collisions;
            }
            
            return null;
        }
        
    }
    
}