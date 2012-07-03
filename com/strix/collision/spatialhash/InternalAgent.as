package com.strix.collision.spatialhash {
    import com.strix.collision.Agent;
    
    internal class InternalAgent {
        
        public var
            agent    : Agent,
            cells    : Vector.<uint>,
            buckets  : Vector.<uint>,
            boundsX1 : int,
            boundsX2 : int,
            boundsY1 : int,
            boundsY2 : int,
            onChange : Function;
        
    }
}