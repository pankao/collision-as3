package com.strix.collision {
    
    public class Agent {
        
        public var
            id       : uint,
            volume   : Volume,
            mask     : uint,
            cells    : Vector.<uint>,
            buckets  : Vector.<uint>,
            boundsX1 : int,
            boundsX2 : int,
            boundsY1 : int,
            boundsY2 : int,
            onChange : Function;
            
        public function Agent( id:uint, volume:Volume, mask:uint ) {
            this.id = id;
            this.volume = volume;
            this.mask = mask;
        }

    }
    
}