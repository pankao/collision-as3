package com.strix.collision {
    
    import com.strix.collision.error.InvalidVolumeError;
    import com.strix.collision.error.NotImplementedError;
    import com.strix.notification.Notification;
    
    
    public class Volume {
        
        //Attributes
        public var
            x  : Number,
            y  : Number,
            rx : Number,
            ry : Number,
            sx : Number,
            sy : Number;
        
        //Derived attributes
        public var
            x1  : Number,
            x2  : Number,
            y1  : Number,
            y2  : Number,
            sx1 : Number,
            sx2 : Number,
            sy1 : Number,
            sy2 : Number,
            srx : Number,
            sry : Number;

        public var
            onChange : Notification;
            
        public var
            disposable : Boolean;
        
        public static const
            ON_MOVE      : uint = 1 << 0,
            ON_TRANSLATE : uint = 1 << 1,
            ON_SWEEP     : uint = 1 << 2,
            ON_RESIZE    : uint = 1 << 3;
        

            
        public function Volume( x:Number, y:Number, rx:Number=NaN, ry:Number=NaN ) {
            onChange = new Notification;
            
            this.x = x;
            this.y = y;
            this.rx = isNaN(rx) ? 0.0 : rx;
            this.ry = isNaN(ry) ? rx : ry;     
            this.sx = 0.0;
            this.sy = 0.0;
            
            update();
        }
        
        
        public function update() : void {
            x1 = sx1 = x-rx;
            x2 = sx2 = x+rx;
            y1 = sy1 = y-ry;
            y2 = sy2 = y+ry;
            srx = rx;
            sry = ry;
            
            if( sx != 0.0 || sy != 0.0 ) {
                sx1 += sx < 0.0 ? sx : 0.0;
                sx2 += sx > 0.0 ? sx : 0.0;
                sy1 += sy < 0.0 ? sy : 0.0;
                sy2 += sy > 0.0 ? sy : 0.0;
                srx += sx > 0.0 ? sx : -sx;
                sry += sy > 0.0 ? sy : sy;
            }
        }
        
        
        public function get symmetric() : Boolean {
            var delta : Number = rx-ry;
            
            return (delta < 0 ? -delta : delta) < Utils.EPS;
        }
        
        
        public function moveTo( x:Number, y:Number ) : void {
            this.x = x;
            this.y = y;
            this.sx = 0.0;
            this.sy = 0.0;
            
            update();
            onChange.dispatch(ON_MOVE, null);
        }
        
        
        public function translate( x:Number, y:Number ) : void {
            this.x += x;
            this.y += y;
            this.sx = 0.0;
            this.sy = 0.0;            
            
            update();
            onChange.dispatch(ON_TRANSLATE, null);
        }
        
        
        public function sweep( x:Number, y:Number ) : void {
            this.sx = x;
            this.sy = y;
            
            update();
            onChange.dispatch(ON_SWEEP, null);
        }
        
        
        public function resize( rx:Number, ry:Number=NaN ) : void {
            this.rx = rx;
            this.ry = isNaN(ry) ? rx : ry;
            this.sx = 0.0;
            this.sy = 0.0;
                
            update();
            
            onChange.dispatch(ON_RESIZE, null);
        }
        
        
        public static function intersectBoxBox( a:Volume, b:Volume ) : Boolean {
            if( a.sx2 < b.sx1 || a.sx1 > b.sx2 )
                return false;
            
            if( a.sy2 < b.sy1 || a.sy1 > b.sy2 )
                return false;
            
            return true;
        }
        
        
        public static function intersectBoxCircle( box:Volume, circle:Volume ) : Boolean {
            if( !circle.symmetric )
                throw new InvalidVolumeError("circle must be a symmetric bounding volume")
            
            if( circle.x < box.sx1-circle.srx || circle.x > box.sx2+circle.srx )
                return false;
            
            if( circle.y < box.sy1-circle.sry || circle.y > box.sy2+circle.sry )
                return false;
            
            return true;
        }
        
        
        public static function intersectCircleCircle( a:Volume, b:Volume ) : Boolean {
            if( !a.symmetric || !b.symmetric )
                throw new InvalidVolumeError("circle must be a symmetric bounding volumes")
            
            var rs2 : Number = a.srx*a.srx + b.srx*b.srx,
                dot : Number = a.x*b.x + a.y*b.y;
            
            return dot <= rs2;
        }
        
        
        public static function intersectSweptBoxBox( a:Volume, b:Volume ) : Boolean {
            var sx : Number = b.sx - a.sx,
                sy : Number = b.sy - a.sy,
                t1 : Number = 0.0,
                t2 : Number = 1.0;
            
            if( sx == 0.0 && sy == 0.0 ) {
                return intersectBoxBox(a, b);
            }
            
            if( sx < 0.0 ) {
                if( b.sx2 < a.sx1 ) return false;
                if( a.sx2 < b.sx1 ) t1 = Math.max((a.sx2-b.sx1) / sx, t1);
                if( b.sx2 > a.sx1 ) t2 = Math.min((a.sx1-b.sx2) / sx, t2);
            } else if( sx > 0.0 ) {
                if( b.sx1 > a.sx2 ) return false;
                if( b.sx2 < a.sx1 ) t1 = Math.max((a.sx1-b.sx2) / sx, t1);
                if( a.sx2 > b.sx1 ) t2 = Math.min((a.sx2-b.sx1) / sx, t2);
            }
            
            if( t1 > t2 )
                return false;
            
            if( sy < 0.0 ) {
                if( b.sy2 < a.sy1 ) return false;
                if( a.sy2 < b.sy1 ) t1 = Math.max((a.sy2-b.sy1) / sy, t1);
                if( b.sy2 > a.sy1 ) t2 = Math.min((a.sy1-b.sy2) / sy, t2);
            } else if( sy > 0.0 ) {
                if( b.sy1 > a.sy2 ) return false;
                if( b.sy2 < a.sy1 ) t1 = Math.max((a.sy1-b.sy2) / sy, t1);
                if( a.sy2 > b.sy1 ) t2 = Math.min((a.sy2-b.sy1) / sy, t2);
            }
            
            if( t1 > t2 )
                return false;
            
            return true;
        }
        
        
        public static function intersectSweptCircleCircle( circleA:Volume, circleB:Volume ) : Boolean {
            var sx : Number = circleB.x-circleA.x,
                sy : Number = circleB.y-circleA.y,
                vx : Number = circleB.sx-circleA.sx,
                vy : Number = circleB.sy-circleA.sy,
                rs : Number = circleA.rx+circleB.rx,
                c  : Number = Utils.dot(sx, sy, sx, sy) - rs*rs;
            
            if( c < 0.0 )
                return true;
            
            var a : Number = Utils.dot(vx, vy, vx, vy);
            
            if( a < Utils.EPS )
                return false;
            
            var b : Number = Utils.dot(vx, vy, sx, sy);
            
            if( b >= 0.0 )
                return false;
            
            var d : Number = b*b - a*c;
            
            if( d < 0.0 )
                return false;
            
            return true;
            
            
                
        }
        
        
        public static function containBoxBox( outer:Volume, inner:Volume ) : Boolean {
            if( inner.sx1 < outer.sx1 || inner.sx2 > outer.sx2 )
                return false;
            
            if( inner.sy1 < outer.sy1 || inner.sy2 > outer.sy2 )
                return false;
            
            return true;
        }
        
        
        public static function containBoxCircle( outer:Volume, inner:Volume ) : Boolean {
            if( inner.sx1 < outer.sx1 || inner.sx2 > outer.sx2 )
                return false;
            
            if( inner.sy1 < outer.sy1 || inner.sy2 > outer.sy2 )
                return false;
            
            return true;
        }
        
        
        public static function containBoxPoint( box:Volume, point:Volume ) : Boolean {
            if( point.x < box.sx1 || point.x > box.sx2 )
                return false;
            
            if( point.y < box.sy1 || point.y > box.sy2 )
                return false;
            
            return true;
        }
        
        
        public static function containCircleCircle( outer:Volume, inner:Volume ) : Boolean {
            if( inner.sx1 < outer.sx1 || inner.sx2 > outer.sx2 )
                return false;
            
            if( inner.sy1 < outer.sy1 || inner.sy2 > outer.sy2 )
                return false;
            
            return true;
        }
        
        
        public static function containCirclePoint( outer:Volume, inner:Volume ) : Boolean {
            if( Math.abs(outer.x-inner.x) > outer.rx )
                return false;
            
            if( Math.abs(outer.y-inner.y) > outer.sry )
                return false;
            
            return true;
        }
    }
    
}