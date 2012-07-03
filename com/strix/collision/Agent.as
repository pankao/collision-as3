package com.strix.collision {
    
    public class Agent extends Volume {
        
        public var
            id   : uint,
            mask : uint;
        
        public function Agent( id:uint, mask:uint, x:Number, y:Number, rx:Number=NaN, ry:Number=NaN ) {
            super(x, y, rx, ry);
            
            this.id = id;
            this.mask = mask;
        }
        
    }
    
}