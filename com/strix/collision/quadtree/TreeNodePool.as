package com.strix.collision.quadtree {
    
    import com.strix.collision.Volume;
    
    
    internal final class TreeNodePool {
        
        private static const
            POOL_SIZE : uint = 128;
            
        private static var
            pool     : Vector.<TreeNode>,
            poolItem : int;
            
            
        {
            pool = new Vector.<TreeNode>(POOL_SIZE, true);
            
            for( poolItem = 0; poolItem < POOL_SIZE; poolItem++ ) {
                pool[poolItem] = new TreeNode(new Volume(0, 0, 0, 0), 0, 0, null, null);
            }
            
            poolItem = POOL_SIZE - 1;
        }
        
        
        public static function getObject(
            volume:Volume,
            depth:uint, maxDepth:uint,
            parent:TreeNode, root:TreeNode,
            mode:uint ) : TreeNode {
            
            if( poolItem < 0 ) {
                return new TreeNode(
                    volume,
                    depth, maxDepth,
                    parent, root,
                    mode
                );
            }
            
            var treeNode : TreeNode = pool[poolItem];
            
            delete pool[poolItem--];
            
            treeNode.volume = volume;
            treeNode.depth = depth;
            treeNode.maxDepth = maxDepth;
            treeNode.parent = parent;
            treeNode.root = root;
            treeNode.mode = mode;
            
            return treeNode;
        }
        
        
        public static function addObject( treeNode:TreeNode ) : void {
            if( !(poolItem < POOL_SIZE) )
                return;
            
            pool[poolItem++] = treeNode;
        }
        
    }
    
}