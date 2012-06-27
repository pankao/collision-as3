package com.strix.collision.spatialhash {
    
    import com.strix.collision.error.ParameterError;
    
    
    internal final class CountingBloomfilter {
        
        private var
            filter  : Vector.<uint>,
            sizeMod : uint;
        
        /**
        * A special-purpose, K=1, 4-bit Counting Bloom filter.
        */
        public function CountingBloomfilter( size:uint ) {
            if( size < 8 || (size & (size-1)) != 0 ) {
                throw new ParameterError("size must be a power of 2, and at least 8");
            }
            
            filter = new Vector.<uint>(size/8, true);
            sizeMod = (size/8)-1;
        }
        
        
        private static function hash( k:uint ) : uint {
            //32-bit integer hash function by Thomas Wang
            k = (k ^ 61) ^ (k >> 16);
            k += (k << 3);
            k ^= (k >> 4);
            k *= 0x27d4eb2d;
            k ^= (k >> 15);
            
            return k;
        }
        
        
        public function addMember( key:uint, reuseKey:Boolean=false ) : void {
            key = reuseKey ? key : hash(key);
            
            var dword    : uint = key & sizeMod,
                counters : uint = filter[dword],
                field    : uint = key & 7,
                counter  : uint = (counters >> (field<<2)) & 15; 
            
            //Bail out on overflow
            if( counter == 15 )
                return;
          
            counter++;
            counters &= ~(15 << (field<<2));
            counters |= (counter << (field<<2));
            
            filter[dword] = counters;
        }
        
        
        public function isMember( key:uint, reuseKey:Boolean=false ) : Boolean {
            key = reuseKey ? key : hash(key);
            
            var dword    : uint = key & sizeMod,
                counters : uint = filter[dword],
                field    : uint = key & 7,
                counter  : uint = (counters >> (field<<2)) & 15; 
            
            if( counter > 0 )
                return true;
            
            return false;
        }
        
        
        public function deleteMember( key:uint, reuseKey:Boolean=false ) : void {
            key = reuseKey ? key : hash(key);
            
            var dword    : uint = key & sizeMod,
                counters : uint = filter[dword],
                field    : uint = key & 7,
                counter  : uint = (counters >> (field<<2)) & 15; 
            
            //Bail out on over/underflow
            if( counter == 15 || counter == 0 )
                return;
            
            counter--;
            counters &= ~(15 << (field<<2));
            counters |= (counter << (field<<2));
            
            filter[dword] = counters;
        }
        
    }
    
}