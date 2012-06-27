package com.strix.collision {
    
    public final class PointQuery extends Collidable {

        public function PointQuery( id:uint, volume:Volume, mask:CollisionMask=null ) {
            if( mask == null ) {
                mask = new CollisionMask(0xffffffff);
            }
            
            super(id, volume, mask);
        }
        
    }
    
}