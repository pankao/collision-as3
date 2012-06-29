package com.strix.collision {
    
    public class Mask {
        
        public static const
            ALL_GROUPS  : uint = 0x0000ffff,
            ALL_ACTIONS : uint = 0xffff0000,
            ALL         : uint = 0xffffffff,
            NONE        : uint = 0;
        
        
        public static function addGroups( mask:uint, ... Arguments ) : uint {
            for each( var group : uint in Arguments ) {
                mask |= group;
            }
           
            
            return mask;
        }
        
        
        public static function addActions( mask:uint, ... Arguments ) : uint {
            for each( var action : uint in Arguments ) {
                mask |= action;
            }
            
            
            return mask;
        }
        
        
        public static function interacts( a:uint, b:uint) : Boolean {
            var groupsA  : uint = uint(a & 0xffff),
                actionsA : uint = uint((a >> 16) & 0xffff),
                groupsB  : uint = uint(b & 0xffff),
                actionsB : uint = uint((b >> 16) & 0xffff);
            
            return (actionsA & groupsB) != 0 || (actionsB & groupsA) != 0;
        }
        
        //TODOOOOOOOOOOOOOOOOOOOOOOOOOOOOOOOOOOOOOOOOOOOOOOOOOOOOOOOOOOOOOOOOOOOOOOOOOOOOOOOOOOOOOOOOOOOOOOOOOOOOO
        public static function actions( actor:uint, target:uint ) : uint {
            return 0;
        }
        
    }
    
}