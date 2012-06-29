package com.strix.collision {
    
    public final class Collision {
        
        public var
            a          : Agent,
            b          : Agent,
            actionsA   : uint,
            actionsB   : uint;
            
        public function Collision( a:Agent, b:Agent, actionsA:uint=0, actionsB:uint=0 ) {
            if( a.id < b.id ) {
                this.a = a;
                this.b = b;
                this.actionsA = actionsA;
                this.actionsB = actionsB;
            } else {
                this.a = b;
                this.b = a;
                this.actionsA = actionsB;
                this.actionsB = actionsA;
            }
        }
        
    }
    
}