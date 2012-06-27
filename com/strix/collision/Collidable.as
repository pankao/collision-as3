package com.strix.collision {
    
    public class Collidable {
        
        public var
            id       : uint,
            volume   : Volume,
            mask     : CollisionMask,
            cells    : Vector.<uint>,
            buckets  : Vector.<uint>,
            boundsX1 : int,
            boundsX2 : int,
            boundsY1 : int,
            boundsY2 : int,
            onChange : Function;
            
        public function Collidable( id:uint, volume:Volume, mask:CollisionMask ) {
            this.id = id;
            this.volume = volume;
            this.mask = mask;
        }

    }
    
}