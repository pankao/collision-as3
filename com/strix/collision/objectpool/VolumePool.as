package com.strix.collision.objectpool {
    
    import com.strix.collision.Volume;
    
    
    public class VolumePool {
        
        private static const
            POOL_SIZE : uint = 128;
        
        private static var
            pool     : Vector.<Volume>,
            poolItem : int;
        
        
        {
            pool = new Vector.<Volume>(POOL_SIZE, true);
            
            for( poolItem = 0; poolItem < POOL_SIZE; poolItem++ ) {
                pool[poolItem] = new Volume(0.0, 0.0, 0.0, 0.0);
            }
            
            poolItem = POOL_SIZE - 1;
        }
        
        
        public static function get( x:Number, y:Number, rx:Number, ry:Number ) : Volume {
            if( poolItem < 0 ) {
                return new Volume(x, y, rx, ry);
            }
            
            var volume : Volume = pool[poolItem];
            
            pool[poolItem--] = null;
            
            volume.x = x;
            volume.y = y;
            volume.rx = rx;
            volume.ry = ry;
            volume.sx = 0.0;
            volume.sy = 0.0;
            volume.updateBounds();
            
            return volume;
        }
        
        
        public static function reclaim( volume:Volume ) : void {
            if( !(poolItem < POOL_SIZE) )
                return;
            
            volume.onChange.reset();
            pool[poolItem++] = volume;
        }
        
    }
}