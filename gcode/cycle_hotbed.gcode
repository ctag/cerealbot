; Cycle Hotbed
; Custom G-code to unadhere parts
; from build surface via thermal
; expansion.
; By: Christopher Bero [bigbero@gmail.com]

M140 S80.000000 ; Set hotbed to 80C, should only ever reach ~65C

; Wait for 20 minutes
G4 P60000 ; one minute
G4 P60000 ; one minute
G4 P60000 ; one minute
G4 P60000 ; one minute
G4 P60000 ; one minute
G4 P60000 ; one minute
G4 P60000 ; one minute
G4 P60000 ; one minute
G4 P60000 ; one minute
G4 P60000 ; one minute
G4 P60000 ; one minute
G4 P60000 ; one minute
G4 P60000 ; one minute
G4 P60000 ; one minute
G4 P60000 ; one minute
G4 P60000 ; one minute
G4 P60000 ; one minute
G4 P60000 ; one minute
G4 P60000 ; one minute
G4 P60000 ; one minute

M140 S0.000000 ; Turn off hotbed
