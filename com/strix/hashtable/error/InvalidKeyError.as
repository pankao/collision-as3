package com.strix.hashtable.error {
    
    public class InvalidKeyError extends Error {
        
        public function InvalidKeyError( message:*="", id:*=0 ) {
            super(message, id);
        }
        
    }
    
}