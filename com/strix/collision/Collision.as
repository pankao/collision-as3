package com.strix.collision {
    
    public final class Collision {
        
        public var
            a : Collidable,
            b : Collidable;
            
        public function Collision( a:Collidable, b:Collidable ) {
            this.a = a.id < b.id ? a : b;
            this.b = a.id < b.id ? b : a;
        }
        
    }
    
}