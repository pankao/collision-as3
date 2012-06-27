package com.strix.collision {
    
    import com.strix.collision.error.InvalidVolumeError;
    import com.strix.collision.error.InvalidVolumeError;
    import com.strix.collision.error.NotImplementedError;
    import com.strix.notification.Notification;
    
    
    public class Volume {
        
        public var
            x  : Number,
            y  : Number,
            rx : Number,
            ry : Number;
            
        public var
            sx : Number,
            sy : Number;
        
        public var
            x1 : Number,
            x2 : Number,
            y1 : Number,
            y2 : Number;

        public var
            onChange : Notification;
        
        public static const
            ON_MOVE      : uint = 1 << 0,
            ON_TRANSLATE : uint = 1 << 1,
            ON_SWEEP     : uint = 1 << 2,
            ON_RESIZE    : uint = 1 << 3;
        

        public function Volume( x:Number, y:Number, rx:Number, ry:Number ) {
            onChange = new Notification;
            
            this.x = x;
            this.y = y;
            this.rx = rx;
            this.ry = ry;     
            
            setBounds();
        }
        
        
        protected function setBounds() : void {
            x1 = x-rx;
            x2 = x+rx;
            y1 = y-ry;
            y2 = y+ry;
        }
        
        
        public function get symmetric() : Boolean {
            return Math.abs(rx-ry) < 0.0000002;
        }
        
        
        public function moveTo( x:Number, y:Number ) : void {
            this.x = x;
            this.y = y;
            
            setBounds();
            onChange.dispatch(ON_MOVE, null);
        }
        
        
        public function translate( x:Number, y:Number ) : void {
            this.x += x;
            this.y += y;
            
            setBounds();
            onChange.dispatch(ON_TRANSLATE, null);
        }
        
        
        public function sweep( x:Number, y:Number ) : void {
            sx = x;
            sy = y;
            
            x1 = Math.min(this.x, this.x+sx)-rx;
            x2 = Math.max(this.x, this.x+sx)+rx;
            y1 = Math.min(this.y, this.y+sy)-ry;
            y2 = Math.max(this.y, this.y+sy)+ry;
            
            onChange.dispatch(ON_SWEEP, null);
        }
        
        public function resize( rx:Number, ry:Number ) : void {
            this.rx = rx;
            this.ry = ry;
            
            setBounds();
            
            onChange.dispatch(ON_RESIZE, null);
        }
        
        public static function intersectBoxBox( a:Volume, b:Volume ) : Boolean {
            if( a.x2 < b.x1 || a.x1 > b.x2 )
                return false;
            
            if( a.y2 < b.y1 || a.y1 > b.y2 )
                return false;
            
            return true;
        }
        
        
        public static function intersectBoxCircle( box:Volume, circle:Volume ) : Boolean {
            if( !circle.symmetric )
                throw new InvalidVolumeError("circle must be a symmetrical bounding volume")
            
            if( circle.x < box.x1-circle.rx || circle.x > box.x2+circle.rx )
                return false;
            
            if( circle.y < box.y1-circle.ry || circle.y > box.y2+circle.ry )
                return false;
            
            return true;
        }
        
        
        public static function intersectCircleCircle( a:Volume, b:Volume ) : Boolean {
            if( !a.symmetric || !b.symmetric )
                throw new InvalidVolumeError("circles must be a symmetrical bounding volumes")
            
            var radii2     : Number = (a.rx+b.rx) * (a.rx+b.rx),
                dotProduct : Number = (a.x*b.x + a.y*b.y);
            
            return dotProduct <= radii2;
        }
        
        
        public static function intersectSweptBoxBox( a:Volume, b:Volume ) : Boolean {
            throw new NotImplementedError;
        }
        
        
        public static function intersectSweptBoxCircle( a:Volume, b:Volume ) : Boolean {
            throw new NotImplementedError;
        }
        
        
        public static function intersectSweptCircleCircle( a:Volume, b:Volume ) : Boolean {
            throw new NotImplementedError;
        }
        
        
        public static function containBoxBox( outer:Volume, inner:Volume ) : Boolean {
            if( inner.x1 < outer.x1 || inner.x2 > outer.x2 )
                return false;
            
            if( inner.y1 < outer.y1 || inner.y2 > outer.y2 )
                return false;
            
            return true;
        }
        
        
        public static function containBoxPoint( box:Volume, point:Volume ) : Boolean {
            if( point.x < box.x1 || point.x > box.x2 )
                return false;
            
            if( point.y < box.y1 || point.y > box.y2 )
                return false;
            
            return true;
        }
        
    }
    
}