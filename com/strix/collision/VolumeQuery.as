package com.strix.collision {
    
    public final class VolumeQuery extends Collidable {

        public function VolumeQuery( id:uint, volume:Volume, mask:CollisionMask=null ) {
            if( mask == null ) {
                mask = new CollisionMask(0xffffffff);
            }
            
            super(id, volume, mask);
        }

    }
    
}