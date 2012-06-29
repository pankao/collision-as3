package com.strix.collision {
    
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
            
            this.x1 = 0.0;
            this.x2 = 0.0;
            this.y1 = 0.0;
            this.y2 = 0.0;
            
            this.sx = 0.0;
            this.sy = 0.0;
            
            updateBounds();
        }
        
        
        public function updateBounds( sweptVolume:Boolean=false ) : void {
            if( !sweptVolume ) {
                x1 = x-rx;
                x2 = x+rx;
                y1 = y-ry;
                y2 = y+ry;
            } else {
                x1 = Math.min(x, x+sx) - rx;
                x2 = Math.max(x, x+sx) + rx;
                y1 = Math.min(y, y+sy) - ry;
                y2 = Math.max(y, y+sy) + ry;
            }
        }
        
        
        public function get symmetric() : Boolean {
            return Math.abs(rx-ry) < Utils.EPS;
        }
        
        
        public function moveTo( x:Number, y:Number ) : void {
            this.x = x;
            this.y = y;
            this.sx = 0.0;
            this.sy = 0.0;
            
            updateBounds();
            onChange.dispatch(ON_MOVE, null);
        }
        
        
        public function translate( x:Number, y:Number ) : void {
            this.x += x;
            this.y += y;
            
            updateBounds();
            onChange.dispatch(ON_TRANSLATE, null);
        }
        
        
        public function sweep( x:Number, y:Number ) : void {
            this.sx = x;
            this.sy = y;
            
            updateBounds(true);
            onChange.dispatch(ON_SWEEP, null);
        }
        
        
        public function resize( rx:Number, ry:Number=NaN ) : void {
            this.rx = rx;
            this.ry = isNaN(ry) ? rx : ry;
            this.sx = 0.0;
            this.sy = 0.0;
                
            updateBounds();
            
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
                throw new InvalidVolumeError("circle must be a symmetric bounding volume")
            
            if( circle.x < box.x1-circle.rx || circle.x > box.x2+circle.rx )
                return false;
            
            if( circle.y < box.y1-circle.ry || circle.y > box.y2+circle.ry )
                return false;
            
            return true;
        }
        
        
        public static function intersectCircleCircle( a:Volume, b:Volume ) : Boolean {
            if( !a.symmetric || !b.symmetric )
                throw new InvalidVolumeError("circle must be a symmetric bounding volumes")
            
            var rs2 : Number = a.rx*a.rx + b.rx*b.rx,
                dot : Number = a.x*b.x + a.y*b.y;
            
            return dot <= rs2;
        }
        
        
        public static function intersectSweptBoxBox( a:Volume, b:Volume ) : Boolean {
            var ax1 : Number = a.x1 - a.sx,
                ax2 : Number = a.x2 - a.sx,
                ay1 : Number = a.y1 - a.sy,
                ay2 : Number = a.y2 - a.sy,
                bx1 : Number = b.x1 - b.sx,
                bx2 : Number = b.x2 - b.sx,
                by1 : Number = b.y1 - b.sy,
                by2 : Number = b.y2 - b.sy;
            
            var sx : Number = b.sx - a.sx,
                sy : Number = b.sy - a.sy,
                t1 : Number = 0.0,
                t2 : Number = 1.0;
            
            if( sx < 0.0 ) {
                if( bx2 < ax1 ) return false;
                if( ax2 < bx1 ) t1 = Math.max((ax2-bx1) / sx, t1);
                if( bx2 > ax1 ) t2 = Math.min((ax1-bx2) / sx, t2);
            } else if( sx > 0.0 ) {
                if( bx1 > ax2 ) return false;
                if( bx2 < ax1 ) t1 = Math.max((ax1-bx2) / sx, t1);
                if( ax2 > bx1 ) t2 = Math.min((ax2-bx1) / sx, t2);
            }
            
            if( t1 > t2 )
                return false;
            
            if( sy < 0.0 ) {
                if( by2 < ay1 ) return false;
                if( ay2 < by1 ) t1 = Math.max((ay2-by1) / sy, t1);
                if( by2 > ay1 ) t2 = Math.min((ay1-by2) / sy, t2);
            } else if( sy > 0.0 ) {
                if( by1 > ay2 ) return false;
                if( by2 < ay1 ) t1 = Math.max((ay1-by2) / sy, t1);
                if( ay2 > by1 ) t2 = Math.min((ay2-by1) / sy, t2);
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
            if( inner.x1 < outer.x1 || inner.x2 > outer.x2 )
                return false;
            
            if( inner.y1 < outer.y1 || inner.y2 > outer.y2 )
                return false;
            
            return true;
        }
        
        
        public static function containBoxCircle( outer:Volume, inner:Volume ) : Boolean {
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
        
        
        public static function containCircleCircle( outer:Volume, inner:Volume ) : Boolean {
            if( inner.x1 < outer.x1 || inner.x2 > outer.x2 )
                return false;
            
            if( inner.y1 < outer.y1 || inner.y2 > outer.y2 )
                return false;
            
            return true;
        }
        
        
        public static function containCirclePoint( outer:Volume, inner:Volume ) : Boolean {
            if( Math.abs(outer.x-inner.x) > outer.rx )
                return false;
            
            if( Math.abs(outer.y-inner.y) > outer.ry )
                return false;
            
            return true;
        }
    }
    
}