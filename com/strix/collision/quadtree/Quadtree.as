package com.strix.collision.quadtree {

    import com.strix.collision.Agent;
    import com.strix.collision.Collision;
    import com.strix.collision.Mask;
    import com.strix.collision.Volume;
    import com.strix.collision.error.IllegalBoundsError;
    import com.strix.collision.error.InvalidObjectError;
    import com.strix.collision.error.InvalidVolumeError;
    import com.strix.collision.pool.VolumePool;
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
        
            
        public function Quadtree( volume:Volume, mode:uint=Quadtree.DISCRETE_MODE, maxDepth:uint=8  ) {
            this.rootNode = new TreeNode(volume, 0, maxDepth-1, null, null, mode);
            this.rootNode.root = this.rootNode;
            this.idTreeNode = new Hashtable;
            this.mode = mode;
        }
        

        public function addAgent( agent:Agent ) : void {
            if( throwExceptions && idTreeNode[agent.id] != null )
                throw new InvalidObjectError("Object with ID " + agent.id + " already exists.");
            
            if( throwExceptions && !Volume.containBoxBox(rootNode.volume, agent.volume) )
                throw new IllegalBoundsError("Object with ID " + agent.id + " has illegal bounds.");
            
            idTreeNode[agent.id] = rootNode.addObject(agent);
        }
        

        public function deleteAgent( agent:Agent ) : void {
            var treeNode : TreeNode = idTreeNode[agent.id] as TreeNode;
            
            if( throwExceptions && treeNode == null )
                throw new InvalidObjectError("Object with ID " + agent.id + " does not exist.");
            
            treeNode.deleteObject(agent);
            delete idTreeNode[agent.id];
        }

        
        public function queryVolume( volume:Volume, mask:uint=Mask.ALL_ACTIONS ) : Vector.<Agent> {
            if( throwExceptions && !Volume.containBoxBox(rootNode.volume, volume) )
                throw new IllegalBoundsError("Region of interest has illegal bounds.");
            
            var objects : Vector.<Agent> = new Vector.<Agent>;
            
            rootNode.queryVolume(volume, mask, objects);
            
            if( volume.disposable ) {
                VolumePool.reclaim(volume);
            }
            
            if( objects.length > 0 ) {
                return objects;
            }
            
            return null;
        }

        
        public function queryPoint( point:Volume, mask:uint=Mask.ALL_ACTIONS ) : Vector.<Agent> {
            if( throwExceptions && !Volume.containBoxPoint(rootNode.volume, point) )
                throw new IllegalBoundsError("Query is out of bounds.");
            
            var agents : Vector.<Agent> = new Vector.<Agent>;
            
            rootNode.queryPoint(point, mask, agents);
            
            if( point.disposable ) {
                VolumePool.reclaim(point);
            }
            
            if( agents.length > 0 ) {
                return agents;
            }
            
            return null;
        }
       

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