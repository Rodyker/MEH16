    INC 
    STW current_display
    LDW rand
    BWC F
    STW rand_sub
rand_find_loop:
    SUB part_const
    JPC display_rand
    STW rand_sub
    LDW current_display
    RTL
    STW current_display
    LDW rand_sub
    JMP rand_find_loop

display_rand:
    LDW current_display
    MWO

wait_for_button:
    MIW                                 
    XOR current_display
    AND bottom
    JPZ correct_button_pressed
    JMP rand_increment                  
correct_button_pressed:
    LDW points
    INC
    STW points
    LDW rand
    STW last_rand

    CLW
debounce_wait:
    INC
    BWJ C
    JMP debounce_wait

correct_button_pressed_loop:
    MIW                                 
    XOR current_display
    AND bottom
    JPZ correct_button_pressed_loop
    CLO
    CLW
    STW current_display
    JMP 000

rand_increment:
    LDW rand                    
    INC
    STW rand
    JPZ timer_increment
    JMP wait_for_button
timer_increment:
    LDW timer
    INC
    STW timer
    BWJ 6
    JMP wait_for_button

    CLW
    INC
    STW current_display
light_1:
    MWO
    CLW
light_loop_1:
    INC
    JPZ light_shift_1
    JMP light_loop_1
light_shift_1:
    LDW current_display
    RTL
    STW current_display
    BWJ 5
    JMP light_1

    CLW
    BWS A
    STW current_display
light_2:
    MWO
    CLW
light_loop_2:
    INC
    JPZ light_shift_2
    JMP light_loop_2
light_shift_2:
    LDW current_display
    RTR
    STW current_display
    BWJ 5
    JMP light_2

points_and_end:
    LDW points
    MWO
    CLW
    STW points
    STW current_display
    STW timer
    LDW last_rand
    STW rand
rst_loop:
    BIJ 0
    JMP rst_loop
    RST

rand:
0000
rand_sub:
0000
last_rand:
0000
timer:
0000
current_display:
0000
bottom:
03FF
points:
0000
part_const:
0CCD