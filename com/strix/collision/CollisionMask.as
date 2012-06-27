package com.strix.collision {
    
    public class CollisionMask {
        
        public var mask : uint = 0;
        
        
        public function CollisionMask( mask:uint=0 ) {
            this.mask = mask;
        }
        
        
        public function addGroup( group:uint ) : CollisionMask {
            mask |= 1 << group;
            
            return this;
        }
        
        
        public function addAction( group:uint ) : CollisionMask {
            mask |= 1 << (group+16);
            
            return this;
        }
        
        
        public static function interacts( a:CollisionMask, b:CollisionMask ) : Boolean {
            var groupsA  : uint = uint(a.mask & 0xffff),
                actionsA : uint = uint((a.mask >> 16) & 0xffff),
                groupsB  : uint = uint(b.mask & 0xffff),
                actionsB : uint = uint((b.mask >> 16) & 0xffff);
            
            return (actionsA & groupsB) != 0 || (actionsB & groupsA) != 0;
        }

        
        public function interactsWith( other : CollisionMask ) : Boolean {
            return CollisionMask.interacts(this, other);
        }
        
    }
    
}